#ifndef LOG_H
#define LOG_H  //如果没有保护宏，编译器会看见两次这个头文件中的东西，比如class Log类，会报类重复定义

#include <stdio.h>           // 包含标准输入输出库的函数和宏定义，如 printf、scanf 等
#include <iostream>
#include <string>
#include <stdarg.h>          // 包含处理可变参数的宏和类型，如 va_list、va_start、va_end 等
#include <pthread.h>         // 包含 POSIX 线程库的函数和类型，如 pthread_create、pthread_mutex_t 等
#include "block_queue.h"     // 包含自定义的阻塞队列类，用于线程间通信和同步
#include <exception>         // 用于捕获和处理异常

//using namespace std;

/*定义了一个单例模式的的日志类*/
class Log {
public:
    /* C++11以后,使用局部变量懒汉不用加锁
    对象不是程序一启动就创建，而是第一次真正需要日志时才创建，所以叫懒汉式单例模式 */
    static Log *get_instance() {
        static Log instance; // 在第一次调用get_instance()时，会自动调用构造函数，创建一个静态的 Log 实例，确保在第一次调用时才创建，并且在程序结束时自动销毁。懒汉式单例模式，线程安全
        return &instance;    // 返回 Log 实例的指针
    }

    /* 线程入口函数，用于异步写入日志 */
    static void *flush_log_thread(void *args) { //pthread_ceraete要求线程函数形状固定. 而普通成员函数有隐藏参数this，不符合 pthread_create 需要的：void* (*)(void*)
        (void)args; // 告诉编译器：这个参数我故意不用，别报警告。因为创建线程的时候要求所有线程入口函数必须遵守固定的函数签名：void* 函数名(void* 参数);
        //try-catch 是 C++ 标准的异常处理机制，核心作用是捕获并处理程序运行时抛出的异常
        /*try 块：把「可能抛出异常、有出错风险」的代码包裹起来。
        如果 try 内部代码正常执行、没有抛出异常，catch 块会被完全跳过，程序继续往下走。
        如果 try 内部抛出了异常，程序会立刻中断当前执行流程，跳转到匹配的 catch 块中处理错误。
        catch 块：定义「要捕获的异常类型」和「错误处理逻辑」。
        只有当 try 里抛出的异常类型和 catch 括号里的类型匹配时，才会进入这个 catch 块。
        一个 try 可以对应多个 catch，分别捕获不同类型的异常。*/
        try
            {
                // 获取日志单例并执行异步写入：不断从阻塞队列中取出日志并写入文件
                Log::get_instance()->async_write_log();
            }
        // 捕获所有 C++ 标准异常
        catch (const std::exception &e) //是 C++ 所有标准异常类的基类，用它做捕获类型可以一次性捕获所有标准库抛出的异常
            {
                // 异常处理：把异常原因输出到标准错误流
                std::cerr << "Exception in flush_log_thread: " << e.what() << std::endl;
            }
        // 无论是否发生异常，最终正常返回，线程安全退出
        return nullptr;
    }

    /* 
        初始化日志，可选择的参数包括:
            日志文件名称
            缓冲区大小
            大行数
            日志阻塞队列的最大长度 
    */
    bool init(
        const char *file_name,
        int close_log, // 是否关闭日志
        int log_buf_size = 8192,
        int split_lines = 5000000,
        int max_queue_size = 0
    );

    /* 将日志内容写入文件 */
    void write_log(int level, const char *format, ...);

    /* 将缓冲区的数据刷新到文件中    flush 是 “刷新缓冲区” 这个通用动作的概念统称；
    fflush 是 C 标准库中，专门针对 FILE* 文件流执行 flush 操作的具体函数
    C 库用户态缓冲区 → 内核页缓存：由 fflush 完成（库函数，速度快）
    内核页缓存 → 物理磁盘：由 fsync 完成（操作系统系统调用，速度慢）*/
    void flush(void);

    /* 公共方法，用于获取 m_close_log 的值 */
    int get_close_log() const {   //这个成员函数承诺：const约束的是当前调用的这个函数的 Log 对象不能被修改
        return m_close_log;
    }

private:
    Log();  /* 私有的构造函数，用于实现懒加载 */
    virtual ~Log(); //这里虽然是虚析构函数，但Log类没有继承关系，所以不需要加virtual，直接写成~Log()即可。加上virtual是为了防止将来有人继承Log类时，delete子类对象时不会调用父类的析构函数，造成资源泄漏。

    /* 从阻塞队列中取日志写入文件 */
    void async_write_log() { /*async_write_log() 只是 flush_log_thread() 内部调用的私有辅助函数，用于实现异步写入日志的功能
        它不是直接传给 pthread_create() 的线程入口，因此不需要返回void* 类型；真正需要返回 nullptr 的是 flush_log_thread()。*/
        string single_log; //用于接收从队列取出来的一条日志

        /* 从阻塞队列中取出一个日志string，写入文件 */
        while (m_log_queue->pop(single_log)) {
            locker_guard lock(m_mutex); /* 使用 lock_guard 自动管理互斥锁的生命周期   除了后台线程的写操作，还有其他操作会在别的线程里执行，并且会访问同一批共享变量。所以要加锁*/
            fputs(single_log.c_str(), m_fp);
        }
    }

    char dir_name[128];                 /* 路径名 */
    char log_name[128];                 /* log文件名 */
    int m_split_lines;                  /* 日志最大行数 */
    int m_log_buf_size;                 /* 日志缓冲区大小 */
    long long m_count;                  /* 日志行数记录 */
    int m_today;                        /* 因为按天分类,记录当前时间是哪一天 */
    FILE *m_fp;                         /* 打开log的文件指针 */
    char *m_buf;                        /* 日志缓冲区  用于临时保存 时间戳+日志等级+格式化内容 */
    block_queue<string> *m_log_queue;   /* 异步日志队列 阻塞队列 */
    bool m_is_async;                    /* 是否异步标志位 （asynchronous: 异步） */
    locker m_mutex;                      /* 互斥锁 用于保护共享变量 */
    int m_close_log;                    /* 关闭日志 */
};

/* 使用宏 LOG_DEBUG、LOG_INFO、LOG_WARN、LOG_ERROR 定义了日志记录的接口，简化调用 */
#define LOG_DEBUG(format, ...) if(0 == Log::get_instance()->get_close_log()) {Log::get_instance()->write_log(0, format, ##__VA_ARGS__); Log::get_instance()->flush();}
#define LOG_INFO(format, ...) if(0 == Log::get_instance()->get_close_log()) {Log::get_instance()->write_log(1, format, ##__VA_ARGS__); Log::get_instance()->flush();}
#define LOG_WARN(format, ...) if(0 == Log::get_instance()->get_close_log()) {Log::get_instance()->write_log(2, format, ##__VA_ARGS__); Log::get_instance()->flush();}
#define LOG_ERROR(format, ...) if(0 == Log::get_instance()->get_close_log()) {Log::get_instance()->write_log(3, format, ##__VA_ARGS__); Log::get_instance()->flush();}
/*
 * 当前四个日志宏存在几个设计问题：
 * 1. 宏体没有使用 do { ... } while (0) 包裹。现在多数调用点是独立语句或在花括号内使用，暂时问题不明显；
 *    但如果以后写成 if (cond) LOG_INFO(...); else ... 这种形式，宏展开后可能破坏 if/else 绑定关系。
 * 2. 每个宏都会多次调用 Log::get_instance()。功能上通常没问题，但不如先取一次实例再调用清晰。
 * 3. 每条日志后都立即 flush。同步日志下会牺牲缓冲性能；异步日志下，生产线程 flush 时后台线程未必已经写入该条日志，
 *    因而并不能严格保证“刚提交的这一条日志已经落到文件缓冲区/磁盘”。
 * 4. ##__VA_ARGS__ 是 GNU 扩展写法，当前项目使用 g++/Linux 风格一般可用；若迁移到更严格的标准 C++ 环境，
 *    可以考虑 C++20 的 __VA_OPT__ 或改成普通函数/模板接口。
 * 5. 从项目整体看，如果配置关闭日志，WebServer::log_write() 会跳过 Log::init()，宏只能依赖 Log 构造函数里的默认开关值；
 *    因此构造函数应默认关闭日志，只有 init() 明确传入 close_log=0 后才允许宏真正写日志。
 */

#endif
