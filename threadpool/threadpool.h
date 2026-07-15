#ifndef THREADPOOL_H
#define THREADPOOL_H

#include <list>
#include <cstdio>
#include <exception>
#include <pthread.h>
#include <memory>
#include <cstdint>
#include <functional>
#include <iostream>
#include "../lock/locker.h"
#include "../CGImysql/sql_connection_pool.h"
#include "../log/log.h"     /* 日志 */

// 模板类的所有成员函数（包括构造函数）都必须写在头文件中，因为编译器需要在编译时根据具体类型生成代码，链接器无法处理模板的独立编译
/* 该线程池类(threadpool<T>)是一个模板类，可以接受类型参数 T，通常用于处理 HTTP 连接的 http_conn 对象 */
template <typename T>
class threadpool
{
public:
    typedef std::function<void(T *, std::uint64_t)> failure_handler;

    /* actor_model是一种并发模型，connPool是数据库连接池指针。thread_number是线程池中线程的数量，max_requests是请求队列中最多允许的、等待处理的请求的数量 */
    threadpool(int actor_model, connection_pool *connPool, int thread_number = 8,
               int max_request = 10000, failure_handler on_failure = failure_handler());
    ~threadpool();
    bool append(T *request, int state, std::uint64_t generation);
    bool append_p(T *request, std::uint64_t generation);

private:
    /* 工作线程运行的函数，它不断从工作队列中取出任务并执行之 */
    static void *worker(void *arg);
    void run();

private:
    struct work_item
    {
        T *request;
        int state;
        std::uint64_t generation;
    };

    int m_thread_number;            /* 线程池中的线程数 */
    int m_max_requests;             /* 请求队列中允许的最大请求数 */
    pthread_t *m_threads;           /* 线程ID数组，保存所有工作线程的标识符 */
    std::list<work_item> m_workqueue; /* 每项独立保存请求、读写状态和连接代次 */
    locker m_queuelocker;           /* 保护请求队列并发读写的互斥锁，防止多线程同时修改链表导致错乱 */
    sem m_queuestat;                /* 信号量，计数代表当前待处理任务的数量 */
    connection_pool *m_connPool;    /* 数据库连接池 */
    int m_actor_model;              /* 并发模型切换标志：0=practor模式，1=reactor模式 */
    bool m_stop;                    /* 用于通知线程退出 */
    failure_handler m_on_failure;   /* 失败时通知主事件循环统一关闭连接和定时器 */
};

/* 线程池构造函数 */
template <typename T>
threadpool<T>::threadpool(int actor_model, connection_pool *connPool, int thread_number,
                          int max_requests, failure_handler on_failure)
                                : m_thread_number(thread_number),
                                    m_max_requests(max_requests), 
                                    m_threads(NULL),
                                    m_connPool(connPool),
                                    m_actor_model(actor_model),
                                    m_stop(false),
                                    m_on_failure(on_failure)
{
    if (thread_number <= 0 || max_requests <= 0)
        throw std::exception();

    /* （这里是智能指针模板的写法，这里的模板参数是 pthread_t[]（数组类型），实例化出一个管理 pthread_t 数组的智能指针。）
     使用 unique_ptr 管理线程数组，是异常安全的写法：如果中途创建线程失败抛出异常，智能指针会自动释放已申请的内存，不会泄漏 */
    std::unique_ptr<pthread_t[]> threads(new pthread_t[thread_number]);

    for (int i = 0; i < thread_number; ++i)
    {
        /* 如果线程创建失败 */
        if (pthread_create(&threads[i], NULL, worker, this) != 0) //线程保持可连接状态，析构时统一唤醒并 join
        {
            {
                locker_guard lock(m_queuelocker);
                m_stop = true;
            }
            for (int j = 0; j < i; ++j)
            {
                m_queuestat.post();
            }
            for (int j = 0; j < i; ++j)
            {
                pthread_join(threads[j], NULL);
            }
            throw std::exception();
        }
    }

    /* 成功创建所有线程，释放控制权给成员变量 */ 
    m_threads = threads.release();
}

/* 析构函数 */
template <typename T>
threadpool<T>::~threadpool()
{
    {
        locker_guard lock(m_queuelocker);
        m_stop = true;
    }

    for (int i = 0; i < m_thread_number; ++i)
    {
        m_queuestat.post();
    }
    for (int i = 0; i < m_thread_number; ++i)
    {
        pthread_join(m_threads[i], NULL);
    }

    delete[] m_threads;
}

/* 往工作队列中添加一个任务请求 request，并设置任务的状态 state */
template <typename T>
bool threadpool<T>::append(T *request, int state, std::uint64_t generation) //Reactor任务把状态保存在队列项中，避免并发修改连接对象
{
    /* 对工作队列的访问必须是线程安全的 */
    locker_guard lock(m_queuelocker);

    /* 如果请求队列已满 */
    if (m_stop || m_workqueue.size() >= static_cast<std::size_t>(m_max_requests))
    {
        std::cerr << "Request queue is full, failed to add task."  << std::endl;
        LOG_ERROR("%s", "Request queue is full, failed to add task.");
        return false;
    }

    work_item item = {request, state, generation};
    m_workqueue.push_back(item);
    
    m_queuestat.post(); /* 信号量的P操作，通知有新任务到来，等待中的工作线程将开始处理这个请求 */

    return true;
}

/* 往工作队列中添加一个任务请求 request，但不设置任务的状态 state */
template <typename T>
bool threadpool<T>::append_p(T *request, std::uint64_t generation)
{
    locker_guard lock(m_queuelocker);

    if (m_stop || m_workqueue.size() >= static_cast<std::size_t>(m_max_requests))
    {
        std::cerr << "Request queue is full, failed to add task."  << std::endl;
        LOG_ERROR("%s", "Request queue is full, failed to add task.");
        return false;
    }

    work_item item = {request, -1, generation};
    m_workqueue.push_back(item);
    
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

    while (true)
    {
        if (!m_queuestat.wait())            /* 等待信号量，确保有任务可执行，在信号量为零时，线程会阻塞 */
        {
            continue;
        }

        m_queuelocker.lock();

        if (m_stop && m_workqueue.empty())
        {
            m_queuelocker.unlock();
            break;
        }

        if (m_workqueue.empty())            /* 如果任务队列为空，解锁并继续等待 */
        {
            m_queuelocker.unlock();
            continue;
        }

        work_item item = m_workqueue.front(); /* 从队列中取出任务及其不可变上下文 */
        m_workqueue.pop_front();

        m_queuelocker.unlock();             /* 这里使用手动解锁，是为了及时解锁，减小锁的持有时间，提升线程池的并发性能（因为任务执行是耗时操作，不能拿着锁来执行，这样所有线程都在等，变成串行执行，线程池失去了并发意义） */

        T *request = item.request;
        if (!request) {                     /* 如果请求为空，则跳过 */
            continue;
        }

        bool success = true;

        /* 根据actor模型处理不同的请求 */
        if (1 == m_actor_model) {
            // 工作线程自己完成IO读写，所以这是Reactor模式  （ read_once() 读取一次/read() 读取所有数据/write() 这类是socket读写函数 ）
            if (0 == item.state) {          /* 读取请求 */
                if (request->read_once()) {
                    /* 使用 connectionRAII 来管理连接。它会把借到的 MYSQL* 写入 request->mysql，供 request->process() 使用；
                    process() 结束后 mysqlcon 析构，连接归还池子，同时 request->mysql 被置空，避免归还后继续误用 */
                    connectionRAII mysqlcon(&request->mysql, m_connPool);
                    success = request->process(); /* 处理请求；成功路径自行重置 EPOLLONESHOT */
                }
                else {
                    success = false;
                }
            } else {                         /* 写入请求 */
                success = request->write();
            }
        } else {  // 工作线程只负责处理业务逻辑，IO读写由主线程完成，所以这是Proactor模式
            /* 使用 connectionRAII 来管理连接。连接池负责连接生命周期，业务线程只在这个作用域内独占借用 MYSQL*    线程和数据库连接不是绑定的，每个任务临时借用、用完就还，实现了连接的跨线程复用，大幅提升数据库访问性能。*/
            connectionRAII mysqlcon(&request->mysql, m_connPool); //进入业务处理前，自动从连接池借一个数据库连接。  出作用域后 mysqlcon 自动析构，把连接归还到连接池
            success = request->process();  //process() 执行业务
        }

        if (!success && m_on_failure)
        {
            m_on_failure(request, item.generation);
        }
    }
}

#endif
