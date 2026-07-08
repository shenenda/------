#include "http_conn.h"

#include <mysql/mysql.h>
#include <fstream>

/* 常量字符串定义了 HTTP 响应中不同状态码的标题和错误信息 */
const char *ok_200_title = "OK";

const char *error_400_title = "Bad Request";
const char *error_400_form = "Your request has bad syntax or is inherently impossible to staisfy.\n";

const char *error_403_title = "Forbidden";
const char *error_403_form = "You do not have permission to get file form this server.\n";

const char *error_404_title = "Not Found";
const char *error_404_form = "The requested file was not found on this server.\n";

const char *error_500_title = "Internal Error";
const char *error_500_form = "There was an unusual problem serving the request file.\n";

locker m_lock;
map<string, string> users;

/* 从数据库中读取用户表中的用户名和密码，并将其存储到一个 map 中，供后续验证使用 */
void http_conn::initmysql_result(connection_pool *connPool) {

    /* 从连接池中获取连接，并用 RAII 保证函数退出时自动归还 */
    MYSQL *mysql = nullptr; //定义一个空的数据库连接裸指针，作为输出型参数，用来接收从连接池取出的连接地址
    connectionRAII mysqlcon(&mysql, connPool); //构造一个 RAII 守卫对象 mysqlcon   mysql 是临时借用指针，不拥有连接；mysqlcon 析构时会把连接还给连接池并把 mysql 置空
    if (!mysql) {
        LOG_ERROR("Failed to get a valid MySQL connection");
        return;
    }

    /* 执行sql查询: 在user表中检索username，passwd数据 */
    const char* query = "SELECT username,passwd FROM user";
    if (mysql_query(mysql, query)) { //mysql_query(已建立的数据库连接句柄， 要执行的SQL语句字符串) 返回0表示成功，否则返回非0值
        LOG_ERROR("SELECT error: %s\n", mysql_error(mysql));
        return;
    }

    /* 获取查询结果集 */
    MYSQL_RES *result = mysql_store_result(mysql);
    if (!result) {
        LOG_ERROR("MySQL store result error: %s\n", mysql_error(mysql));
        return;
    }

    /* 返回结果集中的列数 */
    int num_fields = mysql_num_fields(result);
    if (num_fields < 2) {
        LOG_ERROR("Unexpected number of fields: %d. Expected at least 2.", num_fields);
        mysql_free_result(result);
        return;
    }

    /* 获取结果集中的字段信息 */
    /* mysql_fetch_fields 返回一个指向 MYSQL_FIELD 结构体数组的指针，
        数组的每个元素包含了一个字段（列）的元数据信息，如字段名称、数据类型、长度等 */
    MYSQL_FIELD *fields = mysql_fetch_fields(result);

    MYSQL_ROW row; //MYSQL_ROW 本质是 char** 类型（字符串数组），每一个元素对应一行中的一列数据
    /* 使用 mysql_fetch_row 从结果集中逐行读取用户名和密码 */
    while ((row = mysql_fetch_row(result))) {
        if (row[0] && row[1]) {
            std::string userName(row[0]);
            std::string passWord(row[1]);

            // 打印用户名和密码
            //printf("Username: %-10s | Password: %-10s\n", row[0], row[1]);

            users[userName] = passWord;
        }
    }

    /* 释放结果集，防止内存泄漏 */
    mysql_free_result(result);
}

/* 文件描述符设置非阻塞 */
int setnonblocking(int fd)
{
    int old_option = fcntl(fd, F_GETFL);        /* 获取到文件描述符fd当前的文件状态标志 */

    if (old_option == -1) {
        perror("fcntl F_GETFL failed");
        return -1;
    }

    int new_option = old_option | O_NONBLOCK;  //在保留 old_option 原有所有标志位的基础上，额外开启 O_NONBLOCK（非阻塞模式）标志

    if (fcntl(fd, F_SETFL, new_option) == -1) {
        perror("fcntl F_SETFL failed");
        return -1;
    }

    return old_option;
}

/* 将可读事件注册到内核时间表中，设置事件触发类型，选择是否开启EPOLLONESHOT选项 */
void addfd(int epollfd, int fd, bool one_shot, int TRIGMode) {
    
    epoll_event event;                          /* 用于描述要注册的事件 */
    event.data.fd = fd;

    if (1 == TRIGMode) {
        /* 事件类型包括：可读事件/边缘触发模式/检测远程关闭连接或半关闭状态 */
        event.events = EPOLLIN | EPOLLET | EPOLLRDHUP;
    } else {
        /* 可读事件/检测远程关闭连接或半关闭状态 */
        event.events = EPOLLIN | EPOLLRDHUP;
    }
        
    if (one_shot) {
        /* 为事件添加EPOLLONESHOT（一次事件触发后自动注销 fd，必须手动 modfd 重新注册，保证一个连接同一时间只被一个线程处理，线程安全）选项 */
        event.events |= EPOLLONESHOT;
    }

    /* 将配置好的事件注册到指定的epoll实例epollfd中 */
    if (epoll_ctl(epollfd, EPOLL_CTL_ADD, fd, &event) == -1) {
        std::cerr << "epoll_ctl add failed: " << strerror(errno) << std::endl;
        close(fd);                              /* 关闭文件描述符以防资源泄漏 */
        return;
    }
    
    if (setnonblocking(fd) == -1) {
        std::cerr << "setnonblocking failed: " << strerror(errno) << std::endl;
        close(fd);
        return;
    }
}

/* 从 epoll 实例中移除文件描述符，并关闭该文件描述符 */
void removefd(int epollfd, int fd) {

    if (epoll_ctl(epollfd, EPOLL_CTL_DEL, fd, 0) == -1) {
        perror("epoll_ctl EPOLL_CTL_DEL failed");
    }

    if (close(fd) == -1) {
        perror("close failed");
    }
}

/* 修改文件描述符fd的事件类型（读完数据后切换为 EPOLLOUT 写事件，发送响应），并设置是否开启EPOLLONESHOT选项 */
void modfd(int epollfd, int fd, int ev, int TRIGMode) {

    epoll_event event;
    event.data.fd = fd;

    if (1 == TRIGMode)
        event.events = ev | EPOLLET | EPOLLONESHOT | EPOLLRDHUP;
    else
        event.events = ev | EPOLLONESHOT | EPOLLRDHUP;

    if (epoll_ctl(epollfd, EPOLL_CTL_MOD, fd, &event) == -1) {
        perror("epoll_ctl EPOLL_CTL_MOD failed");
    }       
}


int http_conn::m_user_count = 0;  /* 活跃连接数 */
int http_conn::m_epollfd = -1;    /* epoll 实例描述符 */

/* 关闭一个 HTTP 连接 */
void http_conn::close_conn(bool real_close) {

    /* bool real_close：是否真正关闭连接。如果为 true，则执行关闭操作；否则跳过关闭。 */

    if (real_close && (m_sockfd != -1)) {
        printf("close %d\n", m_sockfd);
        removefd(m_epollfd, m_sockfd);
        m_sockfd = -1;
        m_user_count--;
    }
}

/* 初始化 HTTP 连接，新建客户端连接时调用，由外部调用 */
void http_conn::init(int sockfd, const sockaddr_in &addr, char *root, int TRIGMode,
                     int close_log, string user, string passwd, string sqlname)
{
    assert(sockfd >= 0);
    m_sockfd = sockfd;                      /* 文件描述符 */
    m_address = addr;                       /* 套接字地址 */

    addfd(m_epollfd, sockfd, true, m_TRIGMode); /* 注册到HTTP内核事件表 */
    m_user_count++;                         /* 活跃连接数加一 */

    //当浏览器出现连接重置时，可能是网站根目录出错或http响应格式出错或者访问的文件中内容完全为空
    doc_root = root;
    m_TRIGMode = TRIGMode;
    m_close_log = close_log;

    /* 存储数据库连接信息 */
    strncpy(sql_user, user.c_str(), sizeof(sql_user) - 1);
    strncpy(sql_passwd, passwd.c_str(), sizeof(sql_passwd) - 1);
    strncpy(sql_name, sqlname.c_str(), sizeof(sql_name) - 1);

    /* 调用内部init()重置所有缓冲区、状态变量 */
    init();
}

/* 重置连接状态，使得同一个 http_conn 对象可以被复用（例如在连接池场景中） */
void http_conn::init() {

    mysql = nullptr;
    bytes_to_send = 0;      /* 需要发送的数据量 */
    bytes_have_send = 0;    /* 已发送的数据量 */
    m_check_state = CHECK_STATE_REQUESTLINE;
    m_linger = false;       /* 是否保持连接 */
    m_method = GET;
    m_url = 0;
    m_version = 0;
    m_content_length = 0;
    m_host = 0;
    m_start_line = 0;
    m_checked_idx = 0;
    m_read_idx = 0;
    m_write_idx = 0;
    cgi = 0;
    m_state = 0;

    timer_flag = 0;         /* 定时器相关 */
    improv = 0;

    /* 清空缓冲区 */
    memset(m_read_buf, '\0', READ_BUFFER_SIZE);
    memset(m_write_buf, '\0', WRITE_BUFFER_SIZE);
    memset(m_real_file, '\0', FILENAME_LEN);
}

//返回值为行的读取状态，有LINE_OK,LINE_BAD,LINE_OPEN。   这个函数的作用是：把连续的二进制 HTTP 报文，切分成一行一行文本，方便分段解析请求行、请求头
/* 从状态机，用于解析 HTTP 请求的缓冲区内容，按行读取数据。它通过检查缓冲区中的特殊字符 \r（回车）和 \n（换行），判断当前是否完成了一行的读取 */
http_conn::LINE_STATUS http_conn::parse_line() //HTTP 分行解析 parse_line () 次要状态机
{
    char temp;

    /* 遍历缓冲区，从 m_checked_idx 开始检查字符，直到已读取的末尾位置 m_read_idx */
    for (; m_checked_idx < m_read_idx; ++m_checked_idx) 
    {
        temp = m_read_buf[m_checked_idx];

        /* 检查 \r（回车）*/
        if (temp == '\r')
        {
            /* 如果 \r 是缓冲区的最后一个字符，表示行数据未完整，返回 LINE_OPEN */
            if ((m_checked_idx + 1) == m_read_idx)
            {
                return LINE_OPEN;
            }

            /* 如果下一个字符是 \n，说明读取到完整的一行，将 \r\n 替换为字符串结束符 \0，然后返回 LINE_OK */    
            else if (m_read_buf[m_checked_idx + 1] == '\n')
            {
                m_read_buf[m_checked_idx++] = '\0';
                m_read_buf[m_checked_idx++] = '\0';
                return LINE_OK;
            }

            /* 如果没有匹配的 \n，说明行数据格式错误，返回 LINE_BAD */
            return LINE_BAD;
        }

        /* 检查 \n（换行）*/
        else if (temp == '\n') 
        {
            /* 检查前一个字符是否为 \r */
            /* 是：说明读取到完整的一行，将 \r\n 替换为字符串结束符 \0，然后返回 LINE_OK */
            if (m_checked_idx > 1 && m_read_buf[m_checked_idx - 1] == '\r') 
            {
                m_read_buf[m_checked_idx - 1] = '\0';
                m_read_buf[m_checked_idx++] = '\0';
                return LINE_OK;
            }

            /* 否：说明行数据格式错误，返回 LINE_BAD */
            return LINE_BAD;
        }
    }
    return LINE_OPEN;   /* 如果遍历到 m_read_idx 仍未找到完整的行，则返回 LINE_OPEN，表明需要等待更多数据 */
}

//循环读取客户数据，直到无数据可读或对方关闭连接
//非阻塞ET工作模式下，需要一次性将数据读完
bool http_conn::read_once() {

    if (m_read_idx >= READ_BUFFER_SIZE) {
        return false;
    }

    int bytes_read = 0;

    //LT读取数据：单次 recv，读多少算多少，缓冲区剩余数据下次 epoll_wait 继续触发读事件
    if (0 == m_TRIGMode) {
        bytes_read = recv(m_sockfd, m_read_buf + m_read_idx, READ_BUFFER_SIZE - m_read_idx, 0);
        m_read_idx += bytes_read;

        if (bytes_read <= 0) {
            return false;
        }

        return true;
    }
    //ET读数据：while 循环持续 recv 直到返回 EAGAIN，必须一次性读完缓冲区所有数据，否则内核不会再通知该 fd 读事件，造成数据卡死
    else {
        while (true) {
            bytes_read = recv(m_sockfd, m_read_buf + m_read_idx, READ_BUFFER_SIZE - m_read_idx, 0);
            if (bytes_read == -1) {
                if (errno == EAGAIN || errno == EWOULDBLOCK) //没有数据了
                    break;
                return false;
            } else if (bytes_read == 0) {
                return false;
            }
            m_read_idx += bytes_read;
        }
        return true;
    }
}

/* HTTP请求行解析器，把浏览器发来的第一行数据（比如 GET /index.html HTTP/1.1）拆解成三个部分：方法、URL 和 协议版本，并填充到类的成员变量中 */
http_conn::HTTP_CODE http_conn::parse_request_line(char *text)
{
    m_url = strpbrk(text, " \t");
    if (!m_url) {
        return BAD_REQUEST;
    }
    *m_url++ = '\0'; //将空格的位置替换为字符串结束符 \0，然后把指针 m_url 向后移动一位
    char *method = text;

    /* 比较解析出的 method 字符串，支持 GET索要资源 和 POST提交数据给服务器 方法（忽略大小写) */
    if (strcasecmp(method, "GET") == 0)
    {
        m_method = GET;
    }
    else if (strcasecmp(method, "POST") == 0) 
    {
        m_method = POST;
        cgi = 1;
    } else {
        return BAD_REQUEST;
    } 

    /* 提取 URL 和协议版本 */
    m_url += strspn(m_url, " \t");
    m_version = strpbrk(m_url, " \t");
    if (!m_version)
        return BAD_REQUEST;
    *m_version++ = '\0';
    m_version += strspn(m_version, " \t");

    /* 校验协议版本 */
    if (strcasecmp(m_version, "HTTP/1.1") != 0) { return BAD_REQUEST; }

    /* 处理 URL（http:// 和 https://） */
    if (strncasecmp(m_url, "http://", 7) == 0) {
        m_url += 7;
        m_url = strchr(m_url, '/');
    }
    if (strncasecmp(m_url, "https://", 8) == 0) {
        m_url += 8;
        m_url = strchr(m_url, '/');
    }

    /* 校验 URL */
    if (!m_url || m_url[0] != '/')
        return BAD_REQUEST;
    //当url为/时，显示判断界面
    if (strlen(m_url) == 1) {
        strcat(m_url, "home.html");
    }

    /* 更新状态机状态 */
    m_check_state = CHECK_STATE_HEADER; //请求行解析成功了！将状态机状态从 CHECK_STATE_REQUESTLINE 切换到 CHECK_STATE_HEADER，告诉主循环：“下一批数据来了，要去解析请求头（Header）了。”
    return NO_REQUEST; //代表“当前的请求行处理完毕，数据完整，可以继续往下解析”
}

//解析http请求的一个头部信息。 "路由分发器"：根据每行开头的固定关键词，把请求头的值分别提取到对应的成员变量中，为后续的 Body 读取和业务逻辑做准备
http_conn::HTTP_CODE http_conn::parse_headers(char *text) {

    if (text[0] == '\0') {
        if (m_content_length != 0) {
            m_check_state = CHECK_STATE_CONTENT;
            return NO_REQUEST;
        }
        return GET_REQUEST;
    } else if (strncasecmp(text, "Connection:", 11) == 0) { //要通过它来知道是否要关闭连接
        text += 11;
        text += strspn(text, " \t");
        if (strcasecmp(text, "keep-alive") == 0) {  //长连接Connection: keep-alive实现连接复用，减少 TCP 三次握手开销
            m_linger = true;
        }
    } else if (strncasecmp(text, "Content-length:", 15) == 0) { //要通过它知道Body有多大
        text += 15;
        text += strspn(text, " \t");
        m_content_length = atol(text);
    } else if (strncasecmp(text, "Host:", 5) == 0) { //要通过它知道服务器的主机名，必须解析，因为 HTTP/1.1 规定每个请求都必须带 Host，用于虚拟主机路由
        text += 5;
        text += strspn(text, " \t");
        m_host = text;
    } else {
        LOG_INFO("oop!unknow header: %s", text);
    }
    return NO_REQUEST;
}

// 读取POST表单数据
http_conn::HTTP_CODE http_conn::parse_content(char *text) {
    // 判断缓冲区读取长度 >= Content-Length，取出表单字符串存入m_string
    if (m_read_idx >= (m_content_length + m_checked_idx)) {
        text[m_content_length] = '\0';
        //POST请求中最后为输入的用户名和密码
        m_string = text;
        return GET_REQUEST;
    }
    return NO_REQUEST;
}

/* 总解析流程：三层状态机联动的核心 */
/* 完整执行链路：recv 读数据 → parse_line 分行 → process_read 状态机逐段解析 HTTP → 解析完成调用 do_request 执行业务 */
http_conn::HTTP_CODE http_conn::process_read() {

    LINE_STATUS line_status = LINE_OK;
    HTTP_CODE ret = NO_REQUEST;
    char *text = 0;

    /* 处于解析内容阶段时，如果已经读取到完整的请求体，则调用 do_request() 处理请求 */
    /*
    在这个 while 条件下，循环体内通常是一个巨大的 switch-case 状态机，根据当前解析到的行内容，切换 m_check_state 状态。例如：
    读到 GET / HTTP/1.1 → 解析请求行。
    读到 Host: www.example.com → 解析请求头。
    读到空行（\r\n）→ 切换为 CHECK_STATE_CONTENT。
    进入 Body 处理 → 依靠条件A让循环继续，而不再调用 parse_line()。
    */
   /*条件A：如果我们正在解析 Body 部分，并且上一次读行操作是成功的，那么循环继续
   条件B: 从缓冲区读取一行数据，如果成功读到了完整的一行，那么循环继续 */
    while ((m_check_state == CHECK_STATE_CONTENT && line_status == LINE_OK) || ((line_status = parse_line()) == LINE_OK))
    {
        text = get_line(); //获取当前行首地址
        m_start_line = m_checked_idx;
        LOG_INFO("%s", text);
        switch (m_check_state) {

        // 解析请求行，切换状态到头部
        case CHECK_STATE_REQUESTLINE: {
            ret = parse_request_line(text);

            if (ret == BAD_REQUEST)
                return BAD_REQUEST;

            break;
        }

        // 解析请求头；读到空行（text[0]=='\0'）代表头部结束；有Content-Length则切换到读取请求体；解析完成返回GET_REQUEST进入业务处理
        case CHECK_STATE_HEADER: {
            ret = parse_headers(text);

            if (ret == BAD_REQUEST)
                return BAD_REQUEST;
            else if (ret == GET_REQUEST)
            {
                return do_request();
            }

            break;
        }

        // 读取POST表单body，长度达标则解析完成
        case CHECK_STATE_CONTENT: {
            ret = parse_content(text);

            if (ret == GET_REQUEST)
                return do_request();

            line_status = LINE_OPEN;
            break;
        }

        default:
            return INTERNAL_ERROR;
        }
    }
    return NO_REQUEST; // 数据未完整，下次继续读
}

/* 静态资源 + CGI（通用网关接口）登陆注册 */
http_conn::HTTP_CODE http_conn::do_request() {

    strcpy(m_real_file, doc_root);
    int len = strlen(doc_root);
    //printf("m_url:%s\n", m_url);
    const char *p = strrchr(m_url, '/');

    //处理cgi
    if (cgi == 1 && (*(p + 1) == '2' || *(p + 1) == '3')) {

        //根据标志判断是登录检测还是注册检测
        char flag = m_url[1];

        char *m_url_real = (char *)malloc(sizeof(char) * 200);
        strcpy(m_url_real, "/");
        strcat(m_url_real, m_url + 2);
        strncpy(m_real_file + len, m_url_real, FILENAME_LEN - len - 1);
        free(m_url_real);

        //将用户名和密码提取出来
        //user=123&passwd=123

        // 打印 m_string 内容
        // Debug: m_string = user=12345&password=Password1&confirm_password=Password1
        // if (m_string) {
        //     printf("Debug: m_string = %s\n", m_string);
        // } else {
        //     printf("Debug: m_string is NULL\n");
        //     return BAD_REQUEST;
        // }
        char name[100], password[100];
        parse_form_data(m_string, name, password); //提取用户名和密码

        //printf("Debug: Username = %s, Password = %s\n", name, password);

        if (*(p + 1) == '3') {
            // 如果是注册，先检测数据库中是否有重名的
            // 没有重名的，进行增加数据
            char sql_insert[512]; // 使用固定大小的缓冲区
            char escaped_name[256], escaped_password[256];

            // 转义用户输入，防止 SQL 注入
            mysql_real_escape_string(mysql, escaped_name, name, strlen(name));
            mysql_real_escape_string(mysql, escaped_password, password, strlen(password));

            // 构建 SQL 插入语句。执行 INSERT 插入用户，成功写入全局 map 缓存，跳转登录页面；用户名已存在跳转注册错误页
            snprintf(sql_insert, sizeof(sql_insert),
                    "INSERT INTO user(username, passwd) VALUES('%s', '%s')",
                    escaped_name, escaped_password);

            // 检查内存中的哈希表是否存在该用户
            if (users.find(name) == users.end()) {
                m_lock.lock(); // 加锁，确保线程安全

                // 执行 SQL 语句，并检查返回值
                int res = mysql_query(mysql, sql_insert);
                if (res == 0) { // 插入成功
                    users.insert(std::make_pair(name, password)); // 更新内存中的哈希表
                    strcpy(m_url, "/log.html");
                } else { // 插入失败，打印错误信息
                    fprintf(stderr, "MySQL Insert Error: %s\n", mysql_error(mysql));
                    strcpy(m_url, "/registerError.html");
                }

                m_lock.unlock(); // 解锁
            } else {
                // 用户名已存在
                strcpy(m_url, "/registerError.html");
            }
        }
        //如果是登录，直接判断
        //若浏览器端输入的用户名和密码在表中可以查找到，返回1，否则返回0
        else if (*(p + 1) == '2') {
            // 验证用户名和密码
            if (users.find(name) != users.end() && users[name] == password) {
                strcpy(m_url, "/welcome.html");
            } else {
                strcpy(m_url, "/logError.html");
            }
        }
    }

    // URL 标记映射本地 html：/0 注册页 /1 登录页 /5 图片 /6 视频 /7 粉丝页
    if (*(p + 1) == '0') {
        char *m_url_real = (char *)malloc(sizeof(char) * 200);
        strcpy(m_url_real, "/register.html");
        strncpy(m_real_file + len, m_url_real, strlen(m_url_real));

        free(m_url_real);
    } else if (*(p + 1) == '1') {
        char *m_url_real = (char *)malloc(sizeof(char) * 200);
        strcpy(m_url_real, "/log.html");
        strncpy(m_real_file + len, m_url_real, strlen(m_url_real));

        free(m_url_real);
    } else if (*(p + 1) == '5') {
        char *m_url_real = (char *)malloc(sizeof(char) * 200);
        strcpy(m_url_real, "/picture.html");
        strncpy(m_real_file + len, m_url_real, strlen(m_url_real));

        free(m_url_real);
    } else if (*(p + 1) == '6') {
        char *m_url_real = (char *)malloc(sizeof(char) * 200);
        strcpy(m_url_real, "/video.html");
        strncpy(m_real_file + len, m_url_real, strlen(m_url_real));

        free(m_url_real);
    } else if (*(p + 1) == '7') {
        char *m_url_real = (char *)malloc(sizeof(char) * 200);
        strcpy(m_url_real, "/fans.html");
        strncpy(m_real_file + len, m_url_real, strlen(m_url_real));

        free(m_url_real);
    }
    else
        strncpy(m_real_file + len, m_url, FILENAME_LEN - len - 1); //拼接网站根目录 + url 得到本地真实文件路径m_real_file

    if (stat(m_real_file, &m_file_stat) < 0) //stat() 获取文件属性：文件不存在 → NO_RESOURCE 404    无读权限 → FORBIDDEN_REQUEST 403     是目录 → BAD_REQUEST 400
        return NO_RESOURCE;

    if (!(m_file_stat.st_mode & S_IROTH))
        return FORBIDDEN_REQUEST;

    if (S_ISDIR(m_file_stat.st_mode))
        return BAD_REQUEST;

    // open打开文件，mmap将文件映射到内存（零拷贝发送，不用 read 缓冲区），关闭 fd；返回 FILE_REQUEST（正常 200 响应）
    int fd = open(m_real_file, O_RDONLY);
    m_file_address = (char *)mmap(0, m_file_stat.st_size, PROT_READ, MAP_PRIVATE, fd, 0); //把磁盘上的 html/png/jpg 文件直接映射到进程虚拟内存，不需要用 read() 把文件拷贝到自定义缓冲区
    close(fd);
    return FILE_REQUEST;
}

/* 从m_string中提取用户名和密码，提取表单数据，确保动态兼容性 */
void http_conn::parse_form_data(const char *form_data, char *name, char *password) {
    const char *user_key = "user=";
    const char *password_key = "password=";

    // 初始化缓冲区
    name[0] = '\0';
    password[0] = '\0';

    // 提取用户名
    const char *user_start = strstr(form_data, user_key);
    if (user_start) {
        user_start += strlen(user_key);
        const char *user_end = strchr(user_start, '&'); // 查找分隔符
        size_t user_length = user_end ? user_end - user_start : strlen(user_start);
        if (user_length < 100) { // 防止越界
            strncpy(name, user_start, user_length);
            name[user_length] = '\0';
        }
    }

    // 提取密码
    const char *password_start = strstr(form_data, password_key);
    if (password_start) {
        password_start += strlen(password_key);
        const char *password_end = strchr(password_start, '&'); // 查找分隔符
        size_t password_length = password_end ? password_end - password_start : strlen(password_start);
        if (password_length < 100) { // 防止越界
            strncpy(password, password_start, password_length);
            password[password_length] = '\0';
        }
    }
}

/* 辅助工具：unmap() 释放 mmap 内存 */
void http_conn::unmap() {

    if (m_file_address) {
        munmap(m_file_address, m_file_stat.st_size);
        m_file_address = 0;
    }
}

/* 发送循环，处理 TCP 缓冲区满（EAGAIN） */
bool http_conn::write() {

    int temp = 0;

    // 如果缓冲区中没有数据，修改 epoll 监听事件为读事件 EPOLLIN，等待客户端下一次 HTTP 请求
    if (bytes_to_send == 0) {
        modfd(m_epollfd, m_sockfd, EPOLLIN, m_TRIGMode); 
        init(); //清空缓冲区、重置解析状态，复用当前连接对象
        return true;
    }

    while (1) {
        //writev() 支持一次性发送多块不连续内存，只调用一次系统调用，减少系统调用开销
        //发送过程中内核 TCP 缓冲区满，返回 EAGAIN，修改 epoll 事件为 EPOLLOUT，下次可写时继续发送
        temp = writev(m_sockfd, m_iv, m_iv_count); 

        if (temp < 0) {
            // 当前 TCP 内核发送缓冲区满了，非阻塞 IO 无法继续写入数据
            if (errno == EAGAIN) {
                modfd(m_epollfd, m_sockfd, EPOLLOUT, m_TRIGMode);//通过 modfd 修改该 fd 在 epoll 中的监听事件，从读事件改成写事件 EPOLLOUT
                return true;
            }
            //其他错误（连接断开、非法 fd 等）
            unmap();//释放mmap内存
            return false;
        }

        bytes_have_send += temp;
        bytes_to_send -= temp;

        if (bytes_have_send >= m_iv[0].iov_len) {
            // 场景A：第一块内存（响应头缓冲区）已经全部发送完毕
            m_iv[0].iov_len = 0; // 第一块长度置0，不再使用
            // 偏移：总发送字节 - 响应头总长度 = 文件部分已经发走的字节
            m_iv[1].iov_base = m_file_address + (bytes_have_send - m_write_idx);
            m_iv[1].iov_len = bytes_to_send;
        } else {
            // 场景B：还在发送第一块（响应头缓冲区），文件内容还没开始发
            // 缓冲区起始地址向后偏移已经发送的字节
            m_iv[0].iov_base = m_write_buf + bytes_have_send;
            // 剩余未发送的缓冲区长度 = 原长度 - 本次发走的字节
            m_iv[0].iov_len = m_iv[0].iov_len - bytes_have_send;
        }

        // 所有数据发送完毕分支
        if (bytes_to_send <= 0) {
            unmap(); // 释放文件映射内存，防止内存泄漏
            modfd(m_epollfd, m_sockfd, EPOLLIN, m_TRIGMode); // 改回监听读事件

            if (m_linger) {
                init(); // 长连接：重置所有状态，等待下一次HTTP请求
                return true;
            } else {
                return false; // 短连接：上层收到false，关闭TCP连接
            }
        }
    }
}

// 读取数据并解析（这是一个可变参数函数，后面的函数都是基于此作为底层依赖进行封装的）
bool http_conn::add_response(const char *format, ...) {
    // 1. 缓冲区已满，无法继续写入，直接失败
    if (m_write_idx >= WRITE_BUFFER_SIZE)
        return false;

    va_list arg_list;              // 定义可变参数列表变量
    va_start(arg_list, format);    // 初始化可变参数，绑定格式化字符串format

    // 2. 格式化字符串写入缓冲区剩余空间
    int len = vsnprintf(
        m_write_buf + m_write_idx,            // 写入起点：缓冲区当前游标位置
        WRITE_BUFFER_SIZE - 1 - m_write_idx, // 剩余可写入字节（预留1字节存'\0'）
        format,                              // 格式化模板，支持 %d %s
        arg_list                             // 可变参数
    );

    // 3. 写入内容超出剩余空间，写入失败
    if (len >= (WRITE_BUFFER_SIZE - 1 - m_write_idx)) {
        va_end(arg_list); // 释放可变参数资源
        return false;
    }

    m_write_idx += len; // 写入成功，游标向后移动len字节
    va_end(arg_list);    // 清理可变参数，必须成对调用va_start/va_end

    LOG_INFO("request:%s", m_write_buf); // 日志打印当前缓冲区全部内容
    return true;
}

// 添加 HTTP 状态行
bool http_conn::add_status_line(int status, const char *title) {
    return add_response("%s %d %s\r\n", "HTTP/1.1", status, title);
}

// 批量组装所有响应头（串联多个头函数）
bool http_conn::add_headers(int content_len) {
    return add_content_length(content_len) && add_linger() && add_blank_line();
}

// 写入内容长度头
bool http_conn::add_content_length(int content_len) {
    return add_response("Content-Length:%d\r\n", content_len);
}

// 写入内容类型头
bool http_conn::add_content_type() {
    return add_response("Content-Type:%s\r\n", "text/html");
}

// 写入长连接 / 短连接头部
bool http_conn::add_linger() {
    return add_response("Connection:%s\r\n", (m_linger == true) ? "keep-alive" : "close");
}

// 写入头与正文的分隔空行
bool http_conn::add_blank_line() {
    return add_response("%s", "\r\n");
}

// 拼接页面正文文本（仅用于错误页面 / 空文件）
bool http_conn::add_content(const char *content) {
    return add_response("%s", content);
}

/* 根据 HTTP_CODE 拼接完整 HTTP 响应 */
bool http_conn::process_write(HTTP_CODE ret) {
    switch (ret) {

    //服务器内部错误
    case INTERNAL_ERROR: {
        add_status_line(500, error_500_title); //写入 HTTP 状态行
        add_headers(strlen(error_500_form));   //写入响应头

        if (!add_content(error_500_form))      //写入页面正文内容
            return false;

        break;
    }

    //请求非法
    case BAD_REQUEST: {
        add_status_line(404, error_404_title);
        add_headers(strlen(error_404_form));

        if (!add_content(error_404_form))
            return false;

        break;
    }

    //权限不足
    case FORBIDDEN_REQUEST: {
        add_status_line(403, error_403_title);
        add_headers(strlen(error_403_form));

        if (!add_content(error_403_form))
            return false;

        break;
    }

    //成功响应，静态文件页面
    case FILE_REQUEST: {
        /*
        为什么 FILE_REQUEST 要分开两块内存发送？
        1、性能优化：零拷贝
            如果把大文件全部读进 m_write_buf，需要一次内存拷贝；mmap 直接映射文件，避免用户态缓冲区拷贝，减少 CPU 开销。
        2、减少系统调用次数
            如果不用 writev 分散 IO，需要先 write 发送响应头，再 write 发送文件内容，两次系统调用；
            writev 一次系统调用发送两块内存，提升并发性能。
        3、缓冲区大小有限制
            WRITE_BUFFER_SIZE = 1024，缓冲区很小，大图片 / 视频根本放不下，不能把文件全读到缓冲区。
        */
        add_status_line(200, ok_200_title);

        if (m_file_stat.st_size != 0) {
            add_headers(m_file_stat.st_size);
            // ========== 核心：两块iovec分散写 ==========
            // iov[0]：存放拼接好的HTTP响应头（存在m_write_buf）
            m_iv[0].iov_base = m_write_buf;
            m_iv[0].iov_len = m_write_idx;
            // iov[1]：存放本地静态文件（mmap映射到内存m_file_address）
            m_iv[1].iov_base = m_file_address;
            m_iv[1].iov_len = m_file_stat.st_size;
            m_iv_count = 2;
            //使用两块内存区域发送，总待发送字节 = 响应头长度 + 文件内容长度
            bytes_to_send = m_write_idx + m_file_stat.st_size;
            return true;
        } else {
            const char *ok_string = "<html><body></body></html>";
            add_headers(strlen(ok_string));

            if (!add_content(ok_string))
                return false;
        }
    }

    default:
        return false;
    }

    // 只有错误分支、空文件才会走到这里。 只使用一块缓冲区m_write_buf发送全部数据
    m_iv[0].iov_base = m_write_buf; //iov_base 内存起始地址
    m_iv[0].iov_len = m_write_idx;  //iov_len 这块内存的长度
    m_iv_count = 1;
    bytes_to_send = m_write_idx;

    return true;
}

void http_conn::process() {

    // 读取客户端数据并解析
    HTTP_CODE read_ret = process_read();

    if (read_ret == NO_REQUEST) { // 读取不完整，继续监听
        modfd(m_epollfd, m_sockfd, EPOLLIN, m_TRIGMode); //继续监听
        return;
    }

    bool write_ret = process_write(read_ret); //生成响应

    if (!write_ret) {
        close_conn();
    }

    modfd(m_epollfd, m_sockfd, EPOLLOUT, m_TRIGMode); //注册写事件发送响应
}



/*
完整一次 HTTP 请求全流程：

1、主线程 epoll_wait 监听到 listen_fd 新连接，accept 得到客户端 sockfd

2、线程池分配 http_conn 对象，调用http_conn::init()：
   - addfd 将 sockfd 注册 epoll，ET+ONESHOT+EPOLLIN 读事件
   - 重置所有缓冲区、解析状态

3、客户端浏览器发送 HTTP GET/POST 报文，epoll 触发 EPOLLIN 事件，线程池执行process()

4、process()调用read_once()循环 recv 读取全部客户端数据存入 m_read_buf

5、process_read()状态机逐行解析 HTTP 报文：
    解析请求行获取方法、URL、版本
    解析请求头，记录长连接标记、Content-Length
    POST 请求读取表单 body 存入 m_string

6、完整请求解析完成，调用do_request()业务处理：
    静态 URL：mmap 映射本地文件，返回 FILE_REQUEST
    POST 登录 / 注册：取出数据库连接，解析表单，执行 SQL，跳转对应页面

7、process_write()根据业务状态码拼接完整 HTTP 响应头与正文，填充 iovec 两块内存

8、write()调用 writev 分散发送响应数据，循环处理 TCP 缓冲区满阻塞情况

9、全部数据发送完成：
    长连接：调用 init () 重置状态，重新注册 EPOLLIN 等待下一次请求
    短连接：调用 close_conn ()，epoll 删除 fd，关闭套接字，在线用户数 - 1
*/