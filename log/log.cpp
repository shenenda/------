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
        m_fp = nullptr; /* 关闭文件后把指针置空，避免后续误以为它还指向有效文件 */
    }

    if (m_is_async && m_log_queue != nullptr)
    {
        delete m_log_queue; /* 如果是异步模式，析构时需要释放在 init() 中分配的阻塞队列资源 */
        m_log_queue = nullptr; /* delete 后置空，避免悬空指针 */
    }

    delete[] m_buf;         /* 释放日志缓冲区 */
    m_buf = nullptr;        /* delete[] 后置空，避免悬空指针 */
}

bool Log::init(const char *file_name, int close_log, int log_buf_size, int split_lines, int max_queue_size)
{
    /*
        参数检查：
        1. file_name 不能为空，否则后面 strrchr/fopen 会访问空指针。
        2. log_buf_size 至少要能放下 '\n' 和 '\0'，所以不能太小。
        3. split_lines 必须大于 0，否则 m_count % m_split_lines 会发生除 0 错误。
    */
    if (file_name == nullptr || log_buf_size <= 2 || split_lines <= 0)
    {
        std::cerr << "Invalid log configuration." << std::endl;
        return false;
    }

    const bool use_async = max_queue_size >= 1; /* 队列长度大于等于 1，说明使用异步日志模式 */
    m_close_log = close_log;                    /* 保存日志开关，0 表示开启日志，1 表示关闭日志 */
    m_log_buf_size = log_buf_size;              /* 保存日志缓冲区大小，后面格式化日志时要用 */
    m_buf = new char[m_log_buf_size];           /* 用于日志的缓存，在初始化时分配缓冲区的大小 */
    memset(m_buf, '\0', m_log_buf_size);        /* 把缓冲区清零*/
    m_split_lines = split_lines;                /* 当日志文件的行数达到 m_split_lines 的值时，程序会自动创建一个新的日志文件以继续记录，避免单个日志文件过大 */

    time_t t = time(NULL);                      /* 获取当前的系统时间，返回的是从 1970 年 1 月 1 日（即 Unix 纪元）到现在的秒数 */
    struct tm my_tm;                            /* 包含了当前的本地时间信息 */
    /*
        localtime_r 是 localtime 的线程安全版本：
        它把转换后的本地时间写入 my_tm，而不是返回一个共享的静态缓冲区。
        多线程服务器中应优先使用这种线程安全版本。
    */
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
        dir_name[0] = '\0'; /* 没有路径时，目录名就是空字符串 */
        snprintf(log_name, sizeof(log_name), "%s", file_name); /* 保存纯文件名，后面日志切分还要复用 */
        snprintf(log_full_name, sizeof(log_full_name), "%d_%02d_%02d_%s", my_tm.tm_year + 1900, my_tm.tm_mon + 1, my_tm.tm_mday, log_name); /* 生成最终日志文件名，例如 2026_07_01_ServerLog */
    }
    else
    {
        snprintf(log_name, sizeof(log_name), "%s", p + 1); /* p 指向最后一个 '/'，p + 1 就是文件名开始的位置 */
        size_t dir_len = static_cast<size_t>(p - file_name + 1); /* 目录长度要包含最后那个 '/' */
        if (dir_len >= sizeof(dir_name))
        {
            dir_len = sizeof(dir_name) - 1; /* 给字符串结尾的 '\0' 预留一个位置 */
        }
        memcpy(dir_name, file_name, dir_len); /* 这里只复制目录部分，不复制文件名 */
        dir_name[dir_len] = '\0';             /* memcpy 不会自动补 '\0'，所以必须手动补上字符串结束符 */
        snprintf(log_full_name, sizeof(log_full_name), "%s%d_%02d_%02d_%s", dir_name, my_tm.tm_year + 1900, my_tm.tm_mon + 1, my_tm.tm_mday, log_name); /* 路径 + 日期 + 文件名 */
    }

    m_today = my_tm.tm_mday;        /* 表示当前日期的天 */
    
    m_fp = fopen(log_full_name, "a");   /* 参数 "a" 表示以 追加模式 打开日志文件：如果文件已经存在，日志将追加到文件末尾；如果文件不存在，会创建一个新的文件。*/
    if (m_fp == NULL)
    {
        std::cerr << "Failed to open log file: " << log_full_name << std::endl;
        delete[] m_buf;
        m_buf = nullptr; /* 打开文件失败，前面 new 出来的缓冲区要释放干净 */
        return false;               /* 初始化失败 */
    }

    if (use_async)  // 如果是异步日志模式，创建阻塞队列和后台线程
    {
        m_log_queue = new block_queue<string>(max_queue_size); /* 异步模式下，先创建生产者-消费者之间的阻塞队列 */
        pthread_t tid;                                         /* pthread_t 用来保存新创建的日志线程的线程 id */

        if (pthread_create(&tid, NULL, flush_log_thread, NULL) != 0)
        {
            std::cerr << "Failed to create log thread." << std::endl;
            delete m_log_queue; /* 线程创建失败时，队列已经 new 出来了，必须释放 */
            m_log_queue = nullptr;
            fclose(m_fp);       /* 日志文件也已经打开了，失败回滚时要关闭 */
            m_fp = nullptr;
            delete[] m_buf;     /* 日志缓冲区也要释放，避免内存泄漏 */
            m_buf = nullptr;
            return false;
        }

        pthread_detach(tid); /* 分离线程：线程退出后由系统自动回收线程自身的资源，不需要主线程 pthread_join */
        m_is_async = true;   /* 线程创建成功后再标记为异步模式，避免初始化失败时状态不一致 */
        /* 这里的问题实际上不是detach后为什么还要join来回收资源；而是释放log的成员资源前，怎么确保后台线程已经彻底不再使用他们

         * 注意：分离线程本身不是错误，但这里没有配套的停止标志、唤醒机制和 join 等待。
         * 后台日志线程会一直在 async_write_log() 中访问 m_log_queue 和 m_fp。
         * 如果要彻底修正，应保存线程 id，增加退出标志，通知阻塞队列醒来，
         * 再 join 等线程结束后释放队列和关闭文件；这属于日志线程生命周期改造。
         * 这个join 是等待线程真的结束之后，能保证它不再访问外部资源
         */
    }

    return true;
}

void Log::write_log(int level, const char *format, ...)
{
    /*
        写日志前先做保护：
        如果 format 为空、缓冲区没初始化、文件没打开，说明日志系统当前不可用，直接返回。
        这里不是业务错误，而是防止空指针访问和未初始化资源访问。
    */
    if (format == nullptr || m_buf == nullptr || m_fp == nullptr || m_log_buf_size <= 2 || m_split_lines <= 0)
    {
        return;
    }

    struct timeval now = {0, 0}; /* timeval 通常包含两个成员：tv_sec 表示秒，tv_usec 表示微秒 */
    gettimeofday(&now, NULL);    /* 获取当前时间，精度到微秒，用于生成日志时间戳 */
    time_t t = now.tv_sec;       /* localtime_r 需要的是秒级 time_t，所以取 now.tv_sec */
    struct tm my_tm;             /* 保存转换后的本地时间，如年、月、日、时、分、秒 */
    if (localtime_r(&t, &my_tm) == nullptr)
    {
        return;
    }

    char s[16] = {0}; /* 保存日志级别字符串，例如 [info]:，长度不大，所以 16 字节够用 */

    /* 根据传入的 level 数字，转换成日志级别前缀 */
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
        locker_guard lock(m_mutex); /* m_count、m_today、m_fp 都是共享状态，文件切分过程必须加锁 */
        m_count++;                  /* 当前日志行数加 1，用于判断是否达到切分行数 */

        if (m_today != my_tm.tm_mday || m_count % m_split_lines == 0) //everyday log
        {      
            char new_log[256] = {0}; /* 保存切分后新日志文件的完整路径 */
            fflush(m_fp);            /* 切换文件前，先把旧文件缓冲区刷出去 */
            fclose(m_fp);            /* 关闭旧日志文件 */
            m_fp = nullptr;          /* 文件关闭后置空，避免后面误用旧文件指针 */

            char tail[16] = {0};     /* 日期前缀，例如 2026_07_01_ */
            snprintf(tail, 16, "%d_%02d_%02d_", my_tm.tm_year + 1900, my_tm.tm_mon + 1, my_tm.tm_mday); /* tm_year 从 1900 年开始算，tm_mon 从 0 开始算，所以要修正 */
        
            if (m_today != my_tm.tm_mday)
            {
                snprintf(new_log, sizeof(new_log), "%s%s%s", dir_name, tail, log_name); /* 日期变了，直接使用新日期文件名 */
                m_today = my_tm.tm_mday; /* 更新当前记录的日期 */
                m_count = 0;             /* 新的一天重新计数 */
            }
            else
            {
                snprintf(new_log, sizeof(new_log), "%s%s%s.%lld", dir_name, tail, log_name, m_count / m_split_lines); /* 同一天内按行数切分，加 .1 .2 这类后缀 */
            }
            m_fp = fopen(new_log, "a"); /* 用追加模式打开新日志文件，文件不存在会自动创建 */
            if (m_fp == nullptr)
            {
                std::cerr << "Failed to open log file: " << new_log << std::endl;
                return;
            }
        }
    }

    va_list valst;           /* va_list 是访问可变参数的工具，本质上记录了参数读取位置 */
    va_start(valst, format); /* format 是最后一个固定参数，va_start 通过它定位后面的可变参数 */

    string log_str;          /* 保存最终拼好的完整日志字符串 */
    bool format_ok = true;   /* 标记格式化是否成功，失败时不写入日志 */
    {
        locker_guard lock(m_mutex); /* m_buf 是 Log 对象共享的临时缓冲区，多线程格式化时必须加锁 */

        /*
            先写日志头：日期、时间、微秒、日志级别。
            snprintf 的好处是会限制最多写入 m_log_buf_size 个字节，避免像 sprintf 那样不受控制地溢出。
        */
        int n = snprintf(m_buf, m_log_buf_size, "%d-%02d-%02d %02d:%02d:%02d.%06ld %s ",
                        my_tm.tm_year + 1900, my_tm.tm_mon + 1, my_tm.tm_mday,
                        my_tm.tm_hour, my_tm.tm_min, my_tm.tm_sec, now.tv_usec, s);

        if (n < 0)
        {
            format_ok = false; /* snprintf 返回负数，说明格式化失败 */
        }
        else
        {
            /*
                注意：snprintf 返回的是“理论上想写入的字符数”，不是实际写入的字符数。
                如果缓冲区太小，n 可能大于 m_log_buf_size。
                所以不能直接拿 n 当数组下标，必须先限制在缓冲区范围内。
            */
            int used = n; /* used 表示当前已经占用的缓冲区长度 */
            if (used > m_log_buf_size - 2)
            {
                used = m_log_buf_size - 2; /* 至少给 '\n' 和 '\0' 留两个位置 */
            }

            int available = m_log_buf_size - used - 1; /* 剩余可写空间，还要预留字符串结束符 '\0' */
            int m = vsnprintf(m_buf + used, available, format, valst); /* 在日志头后面写业务日志内容 */
            if (m < 0)
            {
                format_ok = false; /* vsnprintf 返回负数，说明格式化失败 */
            }
            else
            {
                if (m >= available)
                {
                    used = m_log_buf_size - 2; /* 业务内容被截断时，把写入位置固定到缓冲区末尾安全位置 */
                }
                else
                {
                    used += m; /* 没有截断时，used 正常后移 m 个字符 */
                }

                m_buf[used++] = '\n'; /* 每条日志最后补换行，方便日志文件按行阅读 */
                m_buf[used] = '\0';   /* C 字符串必须以 '\0' 结尾 */
                log_str = m_buf;      /* 把 C 字符串转成 string，后续同步写或异步入队都用它 */
            }
        }
    }

    va_end(valst); /* va_start 和 va_end 必须成对出现，表示结束可变参数访问 */
    if (!format_ok)
    {
        return;
    }

    if (m_is_async && m_log_queue != nullptr)
    {
        static int dropped_logs = 0; /* 统计因为队列满而丢弃的日志数量 */
        if (!m_log_queue->push(log_str))
        {
            locker_guard lock(m_mutex); /* dropped_logs 是静态局部变量，多线程更新也要保护 */
            dropped_logs++;
            if (dropped_logs % 100 == 0)
            {
                std::cerr << "Log queue full. Dropped logs count: " << dropped_logs << std::endl;
            }
        }
        return;
    }

    locker_guard lock(m_mutex); /* 同步模式下，业务线程直接写文件，也要保护共享文件指针 m_fp */
    if (m_fp != nullptr)
    {
        fputs(log_str.c_str(), m_fp); /* fputs 把字符串写入 FILE* 对应的文件流 */
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
