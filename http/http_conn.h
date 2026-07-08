#ifndef HTTPCONNECTION_H
#define HTTPCONNECTION_H
#include <unistd.h>
#include <memory>
#include <signal.h>
#include <sys/types.h>
#include <sys/epoll.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <assert.h>
#include <sys/stat.h>
#include <string.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <stdarg.h>
#include <errno.h>
#include <sys/wait.h>
#include <sys/uio.h>
#include <map>

#include "../lock/locker.h"
#include "../CGImysql/sql_connection_pool.h"
#include "../timer/lst_timer.h"
#include "../log/log.h"

class http_conn {
public:

    /* 静态常量 */
    static const int FILENAME_LEN = 200;        /* 文件路径长度 */
    static const int READ_BUFFER_SIZE = 2048;   /* 读取缓冲区的大小 */
    static const int WRITE_BUFFER_SIZE = 1024;  /* 写入缓冲区的大小 */

    /* 这是无名称枚举的写法，第一个给赋值0，后面不带赋值的常量，自动在上一个值基础上 + 1.目的是用英文单词代替数字，可读性强 */
    /* 支持的 HTTP 请求方法 */
    enum METHOD {
        GET = 0,
        POST,
        HEAD,
        PUT,
        DELETE,
        TRACE,
        OPTIONS,
        CONNECT,
        PATH
    };

    /* HTTP 请求的解析状态 */
    enum CHECK_STATE {
        CHECK_STATE_REQUESTLINE = 0,  //请求行
        CHECK_STATE_HEADER,           //请求头
        CHECK_STATE_CONTENT           //请求体
    };

    /* 定义服务器处理请求后的状态（服务器业务处理结果码） */
    enum HTTP_CODE {
        NO_REQUEST,
        GET_REQUEST,        //当前 HTTP 请求已经解析完整，可以开始处理了（这里在工程里是想表示什么含义，是不是叫REQUEST_COMPLETE更好？）
        BAD_REQUEST,        //请求行格式错误，返回400
        NO_RESOURCE,        //文件不存在，返回404
        FORBIDDEN_REQUEST,  //权限不足，返回403
        FILE_REQUEST,
        INTERNAL_ERROR,     //服务器内部错误，返回500
        CLOSED_CONNECTION
    };

    /* HTTP请求解析后的状态。 单行读取状态机 */
    enum LINE_STATUS {
        LINE_OK = 0,  //收到了完整的行
        LINE_BAD,     //行格式错误
        LINE_OPEN     //数据还没收完整，继续等
    };

public:
    http_conn() {}
    ~http_conn() {}

// 对外接口  服务器主线程/线程池调用
public:

    /* 初始化新的TCP连接，注册epoll事件 */
    void init(int sockfd, const sockaddr_in &addr, char *, int, int, string user, string passwd, string sqlname);
    
    /* 关闭当前TCP连接，从epoll中移除fd */
    void close_conn(bool real_close = true);
    
    /* 主业务处理函数：读数据→解析 HTTP→生成响应→发送 */
    void process();

    /* 一次性从 socket 读取客户端全部数据（ET 模式循环 recv） */
    bool read_once();

    /* 调用 writev 发送 HTTP 响应，处理发送缓冲区剩余数据 */
    bool write();

    sockaddr_in *get_address() { return &m_address; }

    /* 初始化 MySQL 结果集 */
    void initmysql_result(connection_pool *connPool);

    int timer_flag;             /* 定时器标志位 */
    int improv;

// 内部私有工具函数，做业务拆分
private:
    void init();
    /* 读解析链路：process_read() 总解析入口 → parse_line() 分行 → parse_request_line/parse_headers/parse_content 三段解析 */
    HTTP_CODE process_read(); 
    /* 响应生成：process_write() 根据 HTTP_CODE 拼接对应响应头、正文 */
    bool process_write(HTTP_CODE ret);
    HTTP_CODE parse_request_line(char *text);
    HTTP_CODE parse_headers(char *text);
    HTTP_CODE parse_content(char *text);
    /* 业务处理：do_request() 解析完 URL，区分静态文件 / CGI 登录注册，操作数据库 */
    HTTP_CODE do_request();
    char *get_line() { return m_read_buf + m_start_line; };
    LINE_STATUS parse_line();
    /* 辅助工具：unmap() 释放 mmap 内存 */
    void unmap();
    /* parse_form_data() 解析 POST 表单参数 */
    void parse_form_data(const char *form_data, char *name, char *password);
    /* 响应拼接工具：add_response() 可变参数格式化写入写缓冲区，封装 add_status_line/add_headers 等 */
    bool add_response(const char *format, ...);
    bool add_content(const char *content);
    bool add_status_line(int status, const char *title);
    bool add_headers(int content_length);
    bool add_content_type();
    bool add_content_length(int content_length);
    bool add_linger();
    bool add_blank_line();

public:
    static int m_epollfd;                   /* 内核事件表（是静态成员的原因：不是某一个连接独有的，而是整个服务器共享的epoll实例） */
    static int m_user_count;                /* 记录服务器当前活跃连接的总数 */
    MYSQL *mysql;                           /* MySQL连接 */
    int m_state;                            /* HTTP请求状态：0表示未处理，1表示正在处理，2表示处理完成 */

private:
    int m_sockfd;                            /* 通信的socket */
    sockaddr_in m_address;                   /* 客户端的socket地址 */
    char m_read_buf[READ_BUFFER_SIZE];       /* 读取缓冲区 */
    long m_read_idx;                         /* 已经从socket中读取到的字节数 */
    long m_checked_idx;                      /* HTTP解析器已经扫描到哪里了 */
    int m_start_line;                        /* 当前准备解析的这一行从哪里开始 */
    char m_write_buf[WRITE_BUFFER_SIZE];     /* 写入缓冲区 */
    int m_write_idx;                         /* 写入缓冲区的写入位置 */
    CHECK_STATE m_check_state;               /* 解析状态 */
    METHOD m_method;                         /* HTTP请求方法 */
    char m_real_file[FILENAME_LEN];          /* 读取到的文件名 */
    char *m_url;                             /* 请求的URL */
    char *m_version;                         /* HTTP协议版本 */
    char *m_host;                            /* 请求的主机名 */
    long m_content_length;                   /* 请求体的长度 */
    bool m_linger;                           /* 是否启用长连接 */
    char *m_file_address;                    /* 文件的地址 */
    struct stat m_file_stat;                 /* 文件状态信息 */
    struct iovec m_iv[2];                    /* 写入缓冲区的IOVEC数组 */
    int m_iv_count;                          /* IOVEC数组的长度 */
    int cgi;                                 /* 是否启用CGI */
    char *m_string;                          /* 用于存储解析到的表单数据 */
    int bytes_to_send;                       /* 需要发送的字节数 */
    int bytes_have_send;                     /* 已经发送的字节数 */
    char *doc_root;                          /* 服务器的根目录 */

    map<string, string> m_users;             /* 用户名密码表 */
    int m_TRIGMode;                          /* 事件触发模式 */
    int m_close_log;                         /* 是否关闭日志 0关闭 1打开 2关闭日志但记录错误 3打开日志但记录错误 4关闭日志但记录错误 5打开日志但记录错误 6打开日志但记录错误 7打开日志但记录错误 8打开日志但记录错误 9打开日志但记录错误 10打开日志但记录错误 11打开日志但记录错误 12打开日志但记录*/

    char sql_user[100];                      /* 用户名 用于连接数据库 */
    char sql_passwd[100];                    /* 密码 用于连接数据库 */
    char sql_name[100];                      /* 数据库名 用于连接数据库 */
};

#endif


/*
一次浏览器请求在项目中的流程：
accept
↓
http_conn::init
↓
read_once
↓
process
↓
process_read
↓
do_request
↓
process_write
↓
write
↓
close_conn / init
*/