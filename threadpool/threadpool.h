#ifndef THREADPOOL_H
#define THREADPOOL_H

#include <list>
#include <cstdio>
#include <exception>
#include <pthread.h>
#include <memory>
#include "../lock/locker.h"
#include "../CGImysql/sql_connection_pool.h"
#include "../log/log.h"     /* 日志 */

// 模板类的所有成员函数（包括构造函数）都必须写在头文件中，因为编译器需要在编译时根据具体类型生成代码，链接器无法处理模板的独立编译
/* 该线程池类(threadpool<T>)是一个模板类，可以接受类型参数 T，通常用于处理 HTTP 连接的 http_conn 对象 */
template <typename T>
class threadpool
{
public:
    /* actor_model是一种并发模型，connPool是数据库连接池指针。thread_number是线程池中线程的数量，max_requests是请求队列中最多允许的、等待处理的请求的数量 */
    threadpool(int actor_model, connection_pool *connPool, int thread_number = 8, int max_request = 10000);
    ~threadpool();
    bool append(T *request, int state);
    bool append_p(T *request);

private:
    /* 工作线程运行的函数，它不断从工作队列中取出任务并执行之 */
    static void *worker(void *arg);
    void run();

private:
    int m_thread_number;            /* 线程池中的线程数 */
    int m_max_requests;             /* 请求队列中允许的最大请求数 */
    pthread_t *m_threads;           /* 线程ID数组，保存所有工作线程的标识符 */
    std::list<T *> m_workqueue;     /* 任务请求队列，存放待处理的任务指针 */
    locker m_queuelocker;           /* 保护请求队列并发读写的互斥锁，防止多线程同时修改链表导致错乱 */
    sem m_queuestat;                /* 信号量，计数代表当前待处理任务的数量 */
    connection_pool *m_connPool;    /* 数据库连接池 */
    int m_actor_model;              /* 并发模型切换标志：0=practor模式，1=reactor模式 */
    bool m_stop;                    /* 用于通知线程退出 */
};

/* 线程池构造函数 */
template <typename T>
threadpool<T>::threadpool( int actor_model, connection_pool *connPool, int thread_number, int max_requests) 
                                : m_actor_model(actor_model),
                                    m_thread_number(thread_number), 
                                    m_max_requests(max_requests), 
                                    m_threads(NULL),
                                    m_connPool(connPool),
                                    m_stop(false)
{
    if (thread_number <= 0 || max_requests <= 0)
        throw std::exception();

    /* 使用 unique_ptr 管理线程数组，是异常安全的写法：如果中途创建线程失败抛出异常，智能指针会自动释放已申请的内存，不会泄漏 */
    std::unique_ptr<pthread_t[]> threads(new pthread_t[thread_number]);

    pthread_attr_t attr;                                            /* 线程属性对象，其作用是在调用 pthread_create 创建线程时，告诉操作系统「这个新线程要按什么参数来创建」 */
    pthread_attr_init(&attr);                                       /* 初始化 attr 为默认值 */
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);    /* 设置线程为分离状态 */
    //分离状态的线程，运行结束后会自动回收系统资源，不需要主线程调用 pthread_join 等待回收，适合线程池这种常驻后台的线程

    for (int i = 0; i < thread_number; ++i)
    {
        /* 如果线程创建失败 */
        if (pthread_create(&threads[i], &attr, worker, this) != 0) //在进行if判断工程中，pthread_create函数已经完成了线程创建的工作（成功返回0，失败返回非零）
        {
            pthread_attr_destroy(&attr);                            /* 销毁线程属性对象 */
            
            for (int j = 0; j < i; ++j)
            {
                pthread_cancel(threads[j]);                         /* 取消已经创建的线程 */
            }
            throw std::exception();                                 /* 如果创建线程失败，抛出异常 */
        }
    }

    /*为什么要等所有线程都创建完再销毁？
    因为所有线程都复用同一个属性配置，循环里每创建一个线程都用同一个 attr。
    等全部线程创建完成后，这个模板再也用不到了，此时销毁是最合理的时机：既不影响前面的线程创建，又能及时释放资源，不占用多余内存。*/
    pthread_attr_destroy(&attr); //pthread_attr_t 只是创建线程时的「配置模板」，线程创建完成后它就没用了；而 pthread_attr_init 初始化时可能分配了内部系统资源，必须调用 pthread_attr_destroy 配对释放，否则会造成资源泄漏

    /* 成功创建所有线程，释放控制权给成员变量 */ 
    m_threads = threads.release();
}

/* 析构函数 */
template <typename T>
threadpool<T>::~threadpool()
{
    
    m_stop = true;              /* 通知所有线程停止 */

    locker_guard lock(m_queuelocker); /* 加锁互斥锁，防止在析构函数中修改请求队列导致错乱 */
    m_workqueue.clear();        /* 清空请求队列，防止线程在析构后继续取任务 */

    delete[] m_threads;         /* 释放线程标识符数组内存 */

    /* 当 locker_guard（RAII 锁守卫，出作用域自动解锁，不需要手动写解锁代码） 对象 lock 离开作用域时（即析构函数中的作用域结束时），locker_guard 的析构函数被调用，它会自动在 m_queuelocker 上调用 unlock() 方法，解锁互斥锁 */
}

/* 往工作队列中添加一个任务请求 request，并设置任务的状态 state */
template <typename T>
bool threadpool<T>::append(T *request, int state) //设置了任务状态，用于Reactor模式，标记任务是读请求还是写请求
{
    /* 对工作队列的访问必须是线程安全的 */
    locker_guard lock(m_queuelocker);

    /* 如果请求队列已满 */
    if (m_workqueue.size() >= m_max_requests)
    {
        std::cerr << "Request queue is full, failed to add task."  << std::endl;
        LOG_ERROR("Request queue is full, failed to add task.");
        return false;
    }

    request->m_state = state;
    m_workqueue.push_back(request);
    
    m_queuestat.post(); /* 信号量的P操作，通知有新任务到来，等待中的工作线程将开始处理这个请求 */

    return true;
}

/* 往工作队列中添加一个任务请求 request，但不设置任务的状态 state */
template <typename T>
bool threadpool<T>::append_p(T *request)
{
    locker_guard lock(m_queuelocker);

    if (m_workqueue.size() >= m_max_requests)
    {
        std::cerr << "Request queue is full, failed to add task."  << std::endl;
        LOG_ERROR("Request queue is full, failed to add task.");
        return false;
    }

    m_workqueue.push_back(request);
    
    m_queuestat.post();

    return true;
}

/* 工作线程的入口函数： 把传入的void* 参数转换为 （线程池对象指针）threadpool<T>* 类型，并调用非静态的 run() 方法处理任务 */
template <typename T>
void *threadpool<T>::worker(void *arg)
{
    threadpool *pool = (threadpool *)arg;   /* 将传入的 void* 参数转换为 threadpool<T>* 类型 */
    pool->run();                            /* 调用线程池的 run() 方法，处理任务 */
    return pool;                            /* 返回 pool 指针 */
}

/* 工作线程的核心任务处理逻辑 */
template <typename T>
void threadpool<T>::run() {

    /* 当工作线程没有停止 */
    while (!m_stop)
    {
        m_queuestat.wait();                 /* 等待信号量，确保有任务可执行，在信号量为零时，线程会阻塞 */

        m_queuelocker.lock();

        if (m_workqueue.empty())            /* 如果任务对列为空，解锁并继续等待 */
        {
            m_queuelocker.unlock();
            continue;
        }

        T *request = m_workqueue.front();   /* 从队列中取出任务 */
        m_workqueue.pop_front();

        m_queuelocker.unlock();             /* 这里使用手动解锁，是为了及时解锁，减小锁的持有时间，提升线程池的并发性能（因为任务执行是耗时操作，不能拿着锁来执行，这样所有线程都在等，变成串行执行，线程池失去了并发意义） */

        if (!request) {                     /* 如果请求为空，则跳过 */
            continue;
        }

        /* 根据actor模型处理不同的请求 */
        if (1 == m_actor_model) {
            // 工作线程自己完成IO读写，所以这是Reactor模式  （ read_once() 读取一次/read() 读取所有数据/write() 这类是socket读写函数 ）
            if (0 == request->m_state) {    /* 读取请求 */
                if (request->read_once()) {
                    request->improv = 1; //improv标记任务是否处理完成

                    /* 使用 connectionRAII 来管理连接。它会把借到的 MYSQL* 写入 request->mysql，供 request->process() 使用；
                    process() 结束后 mysqlcon 析构，连接归还池子，同时 request->mysql 被置空，避免归还后继续误用 */
                    connectionRAII mysqlcon(&request->mysql, m_connPool);
                    request->process();     /* 处理请求 */
                }
                else {
                    request->improv = 1;
                    request->timer_flag = 1; //timer_flag 标记是否出错 / 超时，用于后续定时器清理连接
                }
            } else {                         /* 写入请求 */
                if (request->write()) {
                    request->improv = 1;
                } else {
                    request->improv = 1;
                    request->timer_flag = 1;
                }
            }
        } else {  // 工作线程只负责处理业务逻辑，IO读写由主线程完成，所以这是Proactor模式
            /* 使用 connectionRAII 来管理连接。连接池负责连接生命周期，业务线程只在这个作用域内独占借用 MYSQL*    线程和数据库连接不是绑定的，每个任务临时借用、用完就还，实现了连接的跨线程复用，大幅提升数据库访问性能。*/
            connectionRAII mysqlcon(&request->mysql, m_connPool); //进入业务处理前，自动从连接池借一个数据库连接。  出作用域后 mysqlcon 自动析构，把连接归还到连接池
            request->process();  //process() 执行业务
        }
    }
}

#endif
