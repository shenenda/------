/*************************************************************
*循环数组实现的阻塞队列，m_back = (m_back + 1) % m_max_size;  
*线程安全，每个操作前都要先加互斥锁，操作完后，再解锁
**************************************************************/

#ifndef BLOCK_QUEUE_H
#define BLOCK_QUEUE_H

#include <iostream>
#include <stdlib.h>              //C语言通用工具库头文件：有malloc、free、exit等函数
#include <pthread.h>
#include <sys/time.h>
#include "../lock/locker.h"

using namespace std;

template <class T>
class block_queue //block_queue是一个模板类，T是占位符，表示队列中存放的元素类型可以是任意类型
{
public:
    block_queue(int max_size = 1000)
    {
        if (max_size <= 0)
        {
            //exit(-1);
            throw std::invalid_argument("max_size must be positive");
        }

        m_max_size = max_size;      //最大元素个数
        m_array = new T[max_size];  //动态创建一个元素类型为T的数组，m_array是一个T*指针，指向数组首地址
        m_size = 0;                //当前元素个数
        m_front = -1;              //上一次出队被pop出去的位置，不是当前队首元素索引；真正队首在 (m_front + 1) % m_max_size
        m_back = -1;               //最后一次入队的位置
    }

    void clear()
    {
        m_mutex.lock();
        m_size = 0;
        m_front = -1;
        m_back = -1;
        m_mutex.unlock();
    }

    ~block_queue()
    {
        //析构函数只能在没有其他线程继续 push/pop、也没有线程阻塞在条件变量上时调用；它不能负责安全唤醒仍在等待的线程
        m_mutex.lock();
        if (m_array != NULL)
            delete [] m_array; //因为创建的时候是创建了  new T[max_size]

        m_mutex.unlock();
    }

    //判断队列是否满了。  但是full这个函数不是一个整体的原子操作，所以某个线程在调用它的同时，如果有其他线程也操作了队列，比如push，那么状态就发生了改变，因此它只能作为状态查询，不能代替push函数内部的满队列检查
    bool full() 
    {
        m_mutex.lock();
        if (m_size >= m_max_size)
        {

            m_mutex.unlock();
            return true;
        }
        m_mutex.unlock();
        return false;
    }

    //判断队列是否为空
    bool empty() 
    {
        m_mutex.lock();
        if (0 == m_size)
        {
            m_mutex.unlock();
            return true;
        }
        m_mutex.unlock();
        return false;
    }

    //返回队首元素
    bool front(T &value) 
    {
        m_mutex.lock();
        if (0 == m_size)
        {
            m_mutex.unlock();
            return false;
        }
        int front_index = (m_front + 1) % m_max_size; //出队了之后（虽然内存中还存着，但是下一次有元素入队可以直接覆盖，所以认为逻辑上出队了），认为不在队列中了（虽然实际上在），所以新的队首往后移一位
        value = m_array[front_index];
        m_mutex.unlock();
        return true;
    }

    //返回队尾元素
    bool back(T &value) 
    {
        m_mutex.lock();
        if (0 == m_size)
        {
            m_mutex.unlock();
            return false;
        }
        value = m_array[m_back];
        m_mutex.unlock();
        return true;
    }

    int size() 
    {
        int tmp = 0;

        m_mutex.lock();
        tmp = m_size;

        m_mutex.unlock();
        return tmp;
    }

    int max_size()
    {
        int tmp = 0;

        m_mutex.lock();
        tmp = m_max_size;

        m_mutex.unlock();
        return tmp;
    }

    //往队列添加元素，需要将所有使用队列的线程先唤醒
    //当有元素push进队列,相当于生产者生产了一个元素
    //若当前没有线程等待条件变量,则唤醒无意义
    bool push(const T &item)
    {

        m_mutex.lock();
        if (m_size >= m_max_size)
        {

            m_cond.broadcast(); 
            m_mutex.unlock();
            return false;       //队列满了，直接返回false
        }

        m_back = (m_back + 1) % m_max_size; //计算新队尾
        m_array[m_back] = item;             //把传入的元素放到新队尾的位置

        m_size++;

        m_cond.broadcast();  //现在队列可能不为空了，所有在等待的消费者都醒来重新检查（实际上唤醒1个最好，因为如果只多了一个元素，那么只能有一个线程拿到，剩余的发现队列又空了，再次去wait）
        m_mutex.unlock();
        return true;
    }

    //pop时,如果当前队列没有元素,将会等待条件变量
    bool pop(T &item)  //消费者取数据
    {

        m_mutex.lock();
        while (m_size <= 0) //队列为空时
        {
            
            if (!m_cond.wait(m_mutex.get())) //这里会调用cond类中的pthread_cond_wait(&m_cond, m_mutex);调用前必须持有锁
            /* wait 它会自动释放传入的互斥锁 m_mutex，并让当前线程进入阻塞状态，直到条件变量被其他线程唤醒（signal 或 broadcast）。当线程被唤醒后，它会重新尝试获取互斥锁 m_mutex，然后继续执行后续代码。*/
            {
                m_mutex.unlock();
                return false;
            }
        }

        m_front = (m_front + 1) % m_max_size;  //计算新队首位置
        item = m_array[m_front];
        m_size--; //这里不用通知生产者，
        m_mutex.unlock();
        return true;
    }

    //增加了超时处理：尝试取元素，如果队列为空，则最多等待 ms_timeout 毫秒，超时还没有数据，则返回 false
    bool pop(T &item, int ms_timeout)
    {
        struct timespec t = {0, 0};  //timespec 结构体，表示绝对时间点，包含秒和纳秒
        struct timeval now = {0, 0}; //timeval 结构体，表示相对时间点，包含秒和微秒
        m_mutex.lock();              //队列的 m_size、m_front、m_array 都是多线程共享的数据，必须加锁才能读写，不然会出现竞态错乱
        gettimeofday(&now, NULL);    //获取当前时间，精度到微秒，用于计算超时时间点。 要在加锁成功后再获取，以保证超时是从进入临界区开始计时的
        
        // 计算绝对超时时间点
        long timeout_usec = now.tv_usec + (ms_timeout % 1000) * 1000;
        t.tv_sec = now.tv_sec + ms_timeout / 1000 + timeout_usec / 1000000;
        t.tv_nsec = (timeout_usec % 1000000) * 1000;
        
        // 直接用 while 循环等待数据，天然处理空队列 + 虚假唤醒
        while (m_size <= 0)
        {
            if (!m_cond.timewait(m_mutex.get(), t))
            /*m_cond.timewait(m_mutex.get(), t)
            带超时的条件变量等待，内部自动完成三步：
            自动释放互斥锁，让生产者能往队列里放数据
            阻塞当前线程，直到被唤醒，或者到了 t 这个超时时间点
            被唤醒 / 超时后，自动重新加锁，再返回*/
            {
                // 超时或出错，解锁后返回
                m_mutex.unlock();
                return false;
            }
        }
    
        // 能走到这里，说明队列一定有数据（要么一开始就有，要么等到了），所以直接执行正常出队逻辑
        m_front = (m_front + 1) % m_max_size;
        item = m_array[m_front];
        m_size--;

        m_mutex.unlock();
        return true;
    }

private:
    locker m_mutex;    //保护队列共享数据的互斥锁
    cond m_cond;       //队列为空时，让消费者线程等待的条件变量

    T *m_array;        //存储队列元素的数组
    int m_size;        //当前队列中元素数量
    int m_max_size;    //队列最大容量
    int m_front;       //上一次出队的位置
    int m_back;        //最后一次入队的位置
};

#endif
