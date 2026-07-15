/*
    “#ifndef” 是 C、C++ 等编程语言中的预编译指令，全称为 “if not defined”，即 “如果未定义”。
    它通常用于防止头文件被重复包含。
*/
#ifndef WEBSERVER_H
#define WEBSERVER_H

#include <cstdlib>                   /* 包含 C++ 标准库中的通用工具函数和宏定义，如内存分配、程序退出等 */
#include <cstdio>                    /* 包含 C 标准输入输出库的函数和宏定义，如 printf、scanf 等 */
#include <getopt.h>                  /* 包含 getopt 函数的声明，用于解析命令行参数 */
#include <sys/socket.h>              /* 包含套接字编程相关的函数和数据结构，如 socket、bind、listen 等 */
#include <netinet/in.h>              /* 包含 Internet 协议族相关的函数和数据结构，如 sockaddr_in、htons、htonl 等 */
#include <arpa/inet.h>               /* 包含 IP 地址转换函数，如 inet_ntoa、inet_pton 等 */
#include <stdio.h>                   /* 包含标准输入输出库的函数和宏定义，如 printf、scanf 等 */
#include <unistd.h>                  /* 包含对 POSIX 操作系统 API 的访问，如 read、write、close 等 */
#include <errno.h>                   /* 包含错误码定义和全局变量 errno 的声明，用于错误处理 */
#include <fcntl.h>                   /* 包含文件控制函数的声明，如 fcntl 等 */
#include <stdlib.h>                  /* 包含 C 标准库中的通用工具函数和宏定义，如内存分配、程序退出等 */
#include <cassert>                   /* 断言头文件，用于在调试阶段检查程序的假设条件 */ 
#include <sys/epoll.h>               /* epoll 相关头文件 */
#include <sys/eventfd.h>             /* eventfd：工作线程向主事件循环发送失败通知 */
#include <cstddef>
#include <cstdint>
#include <mutex>
#include <queue>

#include "./threadpool/threadpool.h" /*线程池头文件*/
#include "./http/http_conn.h"        /*HTTP连接处理类头文件*/

const int MAX_FD = 65536;           /* 最大文件描述符 */
const int MAX_EVENT_NUMBER = 10000; /* 最大事件数 */
const int TIMESLOT = 5;             /* 最小超时单位 */

class WebServer
{
public:
    WebServer();
    ~WebServer();

    void init(int port , string user, string passWord, string databaseName,
              int log_write , int opt_linger, int trigmode, int sql_num,
              int thread_num, int close_log, int actor_model);

    void thread_pool();
    void sql_pool();
    void log_write();
    void trig_mode();
    void eventListen();
    void eventLoop();
    void timer(int connfd, struct sockaddr_in client_address);
    void adjust_timer(util_timer *timer);
    void deal_timer(util_timer *timer, int sockfd);
    bool dealclientdata();
    bool dealwithsignal(bool& timeout, bool& stop_server);
    void dealwithread(int sockfd);
    void dealwithwrite(int sockfd);

private:
    struct worker_failure
    {
        int sockfd;
        std::uint64_t generation;
    };

    void notify_worker_failure(http_conn *request, std::uint64_t generation);
    void dealwithworkerfailure();

public:
    
    int m_port;                     /* 服务器端口号 */
    char *m_root;                   /* 根目录 */
    int m_log_write;                /* 0：同步日志; 1: 异步日志 */
    int m_close_log;                /* 0：开启日志； 1：关闭日志 */
    int m_actormodel;               /* 线程池并发模式 */

    int m_pipefd[2];                /* 用于进程间通信的管道文件描述符 */
    int m_worker_eventfd;           /* 工作线程失败通知描述符，由主事件循环监听 */
    int m_epollfd;                  /* epoll 文件描述符 */
    http_conn *users;               /* HTTP 连接对象数组 users 是一个指向 http_conn 对象数组的指针，数组里的每一个元素对应一个和服务器建立了 TCP 连接的客户端，用来集中管理所有并发连接的全部状态 */
    std::uint64_t *m_connection_generation; /* fd 每次复用时递增，过滤旧任务的迟到通知 */
    std::mutex m_worker_failure_mutex;
    std::queue<worker_failure> m_worker_failures;

    connection_pool *m_connPool;    /* 数据库连接池对象的指针 */
    string m_user;                  /* 登陆数据库用户名 */
    string m_passWord;              /* 登陆数据库密码 */
    string m_databaseName;          /* 使用数据库名 */
    int m_sql_num;                  /* 数据库连接池大小, 默认为8 */

    threadpool<http_conn> *m_pool;  /* 线程池 */
    int m_thread_num;               /* 线程池线程数目，默认为8 */

    //epoll_event相关
    epoll_event events[MAX_EVENT_NUMBER]; /* epoll 事件数组 */

    int m_listenfd;                 /* 监听套接字文件描述符 */
    int m_OPT_LINGER;               /* 延迟关闭/优雅关闭，这个选项主要影响当服务器调用close(socket)时，内核如何处理还没有发送完的数据 */
    int m_TRIGMode;                 /* 触发模式 */
    int m_LISTENTrigmode;           /* 监听套接字触发模式 */
    int m_CONNTrigmode;             /* 连接套接字触发模式 */

    //定时器相关
    client_data *users_timer;       /* 客户端数据指针 */
    Utils utils;                    /* 工具类对象，用于处理定时器和信号 */
};
#endif
