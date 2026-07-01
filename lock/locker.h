#ifndef LOCKER_H
#define LOCKER_H

#include <cerrno>
#include <exception>
#include <stdexcept>
#include <pthread.h>
#include <semaphore.h>

/* 信号量类 */
class sem {
public:

    /* 构造函数 - 默认信号量值为 0，这表示 一开始没有任务、没有资源，线程调用wait()时必须阻塞等待 */
    sem() {
        if (sem_init(&m_sem, 0, 0) != 0) { //底层函数：sem_init(sem_t* sem, int pshared, unsigned int value); 要初始化信号量对象地址  只在线程间使用（pshared为0），不在进程间共享（pshared非0）的标志  初始信号量值
            throw std::runtime_error("Failed to initialize semaphore");
        }
    }

    /* 构造函数 - 可以设置初始信号量值，表示初始有多少个资源可用 */
    sem(unsigned int num) {
        if (sem_init(&m_sem, 0, num) != 0) {
            throw std::runtime_error("Failed to initialize semaphore");
        }
    }

    ~sem() { //对象销毁时，释放信号量相关资源。但有一个前提，销毁信号量时，不能还有线程阻塞在这个信号量上
        sem_destroy(&m_sem);
    }

    // 禁用拷贝构造和赋值操作：sem_t 是底层同步资源，不能像普通变量一样复制，否则两个 sem 对象可能管理同一份系统资源，析构时会重复 destroy
    sem(const sem &) = delete;
    sem &operator=(const sem &) = delete;

    bool wait() {                                   /* 等待信号量，类似于 P 操作，信号量值大于0时将信号量的值 - 1  若信号量值==0，当前线程阻塞等待，直到别的线程调用post() */
        while (sem_wait(&m_sem) != 0) {             /* sem_wait 被系统信号打断时会返回 EINTR，这种情况不代表真正失败，继续等待即可 */
            if (errno != EINTR) {
                return false;
            }
        }
        return true;
    }
    bool post() { return sem_post(&m_sem) == 0; }   /* 释放信号量，类似于 V 操作，将信号量的值 + 1  若有线程正在wait()阻塞，唤醒其中一个线程 */

private:
    sem_t m_sem;  //sem_t是POSIX底层使用的信号量类型，m_sem是真正的信号量对象
};

/* 锁 */
class locker {
public:
    locker() { //构造函数无返回值，所以初始化成功返回可用实例，失败则抛出异常中断构造
        if (pthread_mutex_init(&m_mutex, NULL) != 0) { //底层函数：pthread_mutex_init(pthread_mutex_t *mutex, const pthread_mutexattr_t *mutexattr); 初始化互斥锁对象地址  mutexattr为NULL表示使用默认属性
            throw std::exception(); //执行到 throw 时，会立刻中断当前函数的执行，不会继续往下走。  std::exception()是抛出的异常类型，它是基类，无自定义错误信息
        }
    }

    ~locker() {
        pthread_mutex_destroy(&m_mutex); //对象销毁时，释放互斥锁相关资源。但有一个前提，销毁互斥锁时，不能还有线程持有这个互斥锁
    }

    // 禁用拷贝构造和赋值操作：pthread_mutex_t 是一把真正的系统互斥锁，复制它不会得到两把独立的锁，反而会造成锁状态错乱或重复 destroy
    locker(const locker &) = delete;
    locker &operator=(const locker &) = delete;

    bool lock() { return pthread_mutex_lock(&m_mutex) == 0; } //锁空闲：当前线程获得锁，继续执行   锁被其他线程持有：当前线程阻塞等待，直到锁被释放

    bool unlock() { return pthread_mutex_unlock(&m_mutex) == 0; } //释放锁，让其他等待线程有机会获得锁，

    pthread_mutex_t *get() { return &m_mutex; } //返回底层原始互斥锁地址。因为调用pthread_cond_wait()的时候，它要求的参数类型是pthread_mutex_t*而不是封装的locker*，所以需要提供一个接口让外部调用者获取底层的互斥锁地址。

private:
    pthread_mutex_t m_mutex;
};

/* 与 std::lock_guard 类似的 RAII 风格的锁   locker 是“锁本体”，locker_guard 是“锁的自动管理器 */
class locker_guard {
public:
    explicit locker_guard(locker &l) : m_locker(l) {  //explicit：禁止隐式类型转换，防止意外创建临时锁守卫对象    m_locker(l)：初始化列表，把成员引用绑定到传入的外部锁对象上
        m_locker.lock();        /* 在构造时加锁。 只要定义了 locker_guard 对象，就立刻进入临界区 */
    }
    
    ~locker_guard() {
        m_locker.unlock();      /* 在析构时解锁 */
        /*当 locker_guard 对象离开作用域（走到大括号 } 结尾、函数 return、抛出异常）时，对象自动销毁，析构函数自动执行解锁。
        这是整个类最有价值的地方：
        手动写锁时，每个 return 分支都要补 unlock()，漏写一个就会死锁；
        如果临界区内代码抛出异常，手动写的 unlock() 根本执行不到，直接死锁；
        用锁守卫后，无论以任何方式退出作用域，析构一定会执行，锁一定会被释放，天然异常安全。*/
    }

    // 禁用拷贝构造和赋值操作  = delete 是 C++11 语法，显式删除这两个函数，意思是：这个类不允许拷贝、不允许赋值
    locker_guard(const locker_guard &) = delete; //函数名和类名一样，且没有返回类型 说明是构造函数。拷贝构造：locker_guard &：传入同类对象的引用，避免传值时又触发拷贝构造，造成无限递归。   const：表示拷贝过程中不会修改原对象，符合 “拷贝不修改源” 的语义
    locker_guard &operator=(const locker_guard &) = delete; //禁止拷贝赋值运算符  返回值：locker_guard &  赋值运算符的标准返回类型：返回自身对象的引用，支持链式赋值语法（比如 a = b = c）    operator= ：  C++ 运算符重载的固定写法

private:
    locker& m_locker;  // 引用自定义锁，互斥锁本身是不可复制的系统资源，不能拷贝
};

/* 条件变量 */
class cond {
public:
    cond() {
        if (pthread_cond_init(&m_cond, NULL) != 0) { //底层函数：pthread_cond_init(pthread_cond_t *cond, const pthread_condattr_t *condattr); 初始化条件变量对象地址  condattr为NULL表示使用默认属性
            //pthread_mutex_destroy(&m_mutex);
            throw std::exception(); //执行到 throw 时，会立刻中断当前函数的执行，不会继续往下走。  std::exception()是抛出的异常类型，它是基类，无自定义错误信息
        }
    }

    ~cond() {
        pthread_cond_destroy(&m_cond); //对象销毁时，释放条件变量相关资源。但有一个前提，销毁条件变量时，不能还有线程阻塞在这个条件变量上
    }

    // 禁用拷贝构造和赋值操作：pthread_cond_t 保存条件变量内部等待队列等状态，复制后 signal/wait 的对应关系会变得不可控
    cond(const cond &) = delete;
    cond &operator=(const cond &) = delete;

    bool wait(pthread_mutex_t *m_mutex) { /* 这是对条件变量等待操作的封装，它会自动释放传入的互斥锁 m_mutex，并让当前线程进入阻塞状态，直到条件变量被其他线程唤醒（signal 或 broadcast）。当线程被唤醒后，它会重新尝试获取互斥锁 m_mutex，然后继续执行后续代码。*/
        int ret = 0;
        //调用进来时线程已经拿着锁了
        ret = pthread_cond_wait(&m_cond, m_mutex); //pthread_cond_wait() 是一个原子操作，它会自动释放传入的互斥锁 m_mutex，并让当前线程进入阻塞状态，直到条件变量被其他线程唤醒（signal 或 broadcast）。当线程被唤醒后，它会重新尝试获取互斥锁 m_mutex，然后继续执行后续代码。
        //函数返回时线程已经重新持有锁了
        return ret == 0;
    }  //操作系统可能会在没有任何线程发信号的情况下，意外唤醒等待的线程，这叫虚假唤醒。 所以上层调用时，永远要用 while 循环包裹判断，而不是 if

    bool timewait(pthread_mutex_t *m_mutex, struct timespec t) { //带超时的条件变量等待，不会一直死等，到指定时间后会自动返回，避免线程永久阻塞
        int ret = 0;
        ret = pthread_cond_timedwait(&m_cond, m_mutex, &t); //原子地释放锁 → 阻塞等待 → 被唤醒 / 超时后自动重新加锁再返回
        return ret == 0;
    }

    bool signal() { //唤醒一个正在等待这个条件变量的线程
        return pthread_cond_signal(&m_cond) == 0;
    }

    bool broadcast() { //唤醒所有正在等待这个条件变量的线程
        return pthread_cond_broadcast(&m_cond) == 0;
    }

private:
    pthread_cond_t m_cond; //pthread_cond_t是POSIX底层使用的条件变量类型，m_cond是真正的条件变量对象
};

#endif
