#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <stdarg.h>         // 可变参数处理头文件
#include "log.h"
#include <pthread.h>

using namespace std;

Log::Log() {
    m_count = 0;            /* 初始化日志行数计数器 */
    m_is_async = false;     /* 初始化为同步日志模式 （异步：asynchronous）*/
    m_fp = nullptr;
    m_buf = nullptr;
    m_log_queue = nullptr;
    m_close_log = 1;
    m_today = 0;
    m_split_lines = 0;
    m_log_buf_size = 0;
    memset(dir_name, 0, sizeof(dir_name));
    memset(log_name, 0, sizeof(log_name));
}

Log::~Log()
{
    if (m_fp != nullptr) //Log 对象销毁时，如果日志文件已经打开，就先 fflush(m_fp) 刷新缓冲区，再 fclose(m_fp) 关闭文件
    {
        fflush(m_fp);  //m_fp是日志文件指针
        fclose(m_fp);
        m_fp = nullptr;
    }

    if (m_is_async && m_log_queue != nullptr)
    {
        delete m_log_queue; /* 如果是异步模式，析构时需要释放在构造函数中分配的阻塞队列资源 */ 
        m_log_queue = nullptr;
    }

    delete[] m_buf;         /* 释放日志缓冲区 */
    m_buf = nullptr;
}

bool Log::init(const char *file_name, int close_log, int log_buf_size, int split_lines, int max_queue_size)
{
    if (file_name == nullptr || log_buf_size <= 2 || split_lines <= 0)
        {
        std::cerr << "Invalid log configuration." << std::endl;
            return false;
        }

    const bool use_async = max_queue_size >= 1;
    m_close_log = close_log;
    m_log_buf_size = log_buf_size;
    m_buf = new char[m_log_buf_size];       /* 用于日志的缓存，在初始化时分配缓冲区的大小 */
    memset(m_buf, '\0', m_log_buf_size);    /* 把缓冲区清零*/
    m_split_lines = split_lines;            /* 当日志文件的行数达到 m_split_lines 的值时，程序会自动创建一个新的日志文件以继续记录，避免单个日志文件过大 */

    time_t t = time(NULL);                  /* 获取当前的系统时间，返回的是从 1970 年 1 月 1 日（即 Unix 纪元）到现在的秒数 */
    struct tm my_tm;                        /* 包含了当前的本地时间信息 */
    if (localtime_r(&t, &my_tm) == nullptr) {
        std::cerr << "Failed to get local time." << std::endl;
        delete[] m_buf;
        m_buf = nullptr;
        return false;                       /* 初始化失败 */
    }
        
    const char *p = strrchr(file_name, '/');    /* strrchr作用是从字符串右侧开始找某个字符第一次出现的位置，用于提取文件名部分 */
    char log_full_name[256] = {0};              /* 存储日志文件的完整路径，最大长度为 256 字节 */

    if (p == NULL)  /* file_name中没有路径 */
    {
        //snprintf的功能是：按照指定格式生成一段字符串，写入到目标字符数组中；同时通过参数限制最大写入长度，避免缓冲区溢出
        dir_name[0] = '\0';
        snprintf(log_name, sizeof(log_name), "%s", file_name);
        snprintf(log_full_name, sizeof(log_full_name), "%d_%02d_%02d_%s", my_tm.tm_year + 1900, my_tm.tm_mon + 1, my_tm.tm_mday, log_name);
    }
    else
    {
        snprintf(log_name, sizeof(log_name), "%s", p + 1);
        size_t dir_len = static_cast<size_t>(p - file_name + 1);
        if (dir_len >= sizeof(dir_name))
        {
            dir_len = sizeof(dir_name) - 1;
        }
        memcpy(dir_name, file_name, dir_len);
        dir_name[dir_len] = '\0';
        snprintf(log_full_name, sizeof(log_full_name), "%s%d_%02d_%02d_%s", dir_name, my_tm.tm_year + 1900, my_tm.tm_mon + 1, my_tm.tm_mday, log_name);
    }

    m_today = my_tm.tm_mday;        /* 表示当前日期的天 */
    
    m_fp = fopen(log_full_name, "a");   /* 参数 "a" 表示以 追加模式 打开日志文件：如果文件已经存在，日志将追加到文件末尾；如果文件不存在，会创建一个新的文件。*/
    if (m_fp == NULL)
    {
        std::cerr << "Failed to open log file: " << log_full_name << std::endl;
        delete[] m_buf;
        m_buf = nullptr;
        return false;               /* 初始化失败 */
    }

    if (use_async)
    {
        m_log_queue = new block_queue<string>(max_queue_size);
        pthread_t tid;

        if (pthread_create(&tid, NULL, flush_log_thread, NULL) != 0)
        {
            std::cerr << "Failed to create log thread." << std::endl;
            delete m_log_queue;
            m_log_queue = nullptr;
            fclose(m_fp);
            m_fp = nullptr;
            delete[] m_buf;
            m_buf = nullptr;
            return false;
        }

        pthread_detach(tid);
        m_is_async = true;
        /*
         * 注意：分离线程本身不是错误，但这里没有配套的停止标志、唤醒机制和 join 等待。
         * 后台日志线程会一直在 async_write_log() 中访问 m_log_queue 和 m_fp。
         * 如果要彻底修正，应保存线程 id，增加退出标志，通知阻塞队列醒来，
         * 再 join 等线程结束后释放队列和关闭文件；这属于日志线程生命周期改造。
         */
    }

    return true;
}

void Log::write_log(int level, const char *format, ...)
{
    if (format == nullptr || m_buf == nullptr || m_fp == nullptr || m_log_buf_size <= 2 || m_split_lines <= 0)
    {
        return;
    }

    struct timeval now = {0, 0};
    gettimeofday(&now, NULL);
    time_t t = now.tv_sec;
    struct tm my_tm;
    if (localtime_r(&t, &my_tm) == nullptr)
    {
        return;
    }

    char s[16] = {0};

    switch (level)
    {
    case 0:
        strcpy(s, "[debug]:");
        break;
    case 1:
        strcpy(s, "[info]:");
        break;
    case 2:
        strcpy(s, "[warn]:");
        break;
    case 3:
        strcpy(s, "[error]:");
        break;
    default:
        strcpy(s, "[info]:");
        break;
    }

    {
        locker_guard lock(m_mutex);
        m_count++;

        if (m_today != my_tm.tm_mday || m_count % m_split_lines == 0) //everyday log
        {      
            char new_log[256] = {0};
            fflush(m_fp);
            fclose(m_fp);
            m_fp = nullptr;

            char tail[16] = {0};
            snprintf(tail, 16, "%d_%02d_%02d_", my_tm.tm_year + 1900, my_tm.tm_mon + 1, my_tm.tm_mday);
        
            if (m_today != my_tm.tm_mday)
            {
                snprintf(new_log, sizeof(new_log), "%s%s%s", dir_name, tail, log_name);
                m_today = my_tm.tm_mday;
                m_count = 0;
            }
            else
            {
                snprintf(new_log, sizeof(new_log), "%s%s%s.%lld", dir_name, tail, log_name, m_count / m_split_lines);
            }
            m_fp = fopen(new_log, "a");
            if (m_fp == nullptr)
            {
                std::cerr << "Failed to open log file: " << new_log << std::endl;
                return;
            }
        }
    }

    va_list valst;
    va_start(valst, format);

    string log_str;
    bool format_ok = true;
    {
        locker_guard lock(m_mutex);
        int n = snprintf(m_buf, m_log_buf_size, "%d-%02d-%02d %02d:%02d:%02d.%06ld %s ",
                        my_tm.tm_year + 1900, my_tm.tm_mon + 1, my_tm.tm_mday,
                        my_tm.tm_hour, my_tm.tm_min, my_tm.tm_sec, now.tv_usec, s);

        if (n < 0)
        {
            format_ok = false;
        }
        else
        {
            int used = n;
            if (used > m_log_buf_size - 2)
            {
                used = m_log_buf_size - 2;
            }

            int available = m_log_buf_size - used - 1;
            int m = vsnprintf(m_buf + used, available, format, valst);
            if (m < 0)
            {
                format_ok = false;
            }
            else
            {
                if (m >= available)
                {
                    used = m_log_buf_size - 2;
                }
                else
                {
                    used += m;
                }

                m_buf[used++] = '\n';
                m_buf[used] = '\0';
                log_str = m_buf;
            }
        }
    }

    va_end(valst);
    if (!format_ok)
    {
        return;
    }

    if (m_is_async && m_log_queue != nullptr)
    {
        static int dropped_logs = 0;
        if (!m_log_queue->push(log_str))
        {
            locker_guard lock(m_mutex);
            dropped_logs++;
            if (dropped_logs % 100 == 0)
            {
                std::cerr << "Log queue full. Dropped logs count: " << dropped_logs << std::endl;
            }
        }
        return;
    }

    locker_guard lock(m_mutex);
    if (m_fp != nullptr)
    {
        fputs(log_str.c_str(), m_fp);
    }
}

void Log::flush(void)
{
    locker_guard lock(m_mutex); // 使用 lock_guard 自动管理锁的生命周期
    if (m_fp != nullptr)
    {
        fflush(m_fp); //  强制刷新输出缓冲区，将缓冲区中的内容立即写入到文件中，确保日志内容不会滞留在缓冲区
    }
}
