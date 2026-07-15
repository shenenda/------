#include "webserver.h"

WebServer::WebServer()
{
    m_root = NULL;
    m_connPool = NULL;
    m_pool = NULL;
    m_epollfd = -1;
    m_listenfd = -1;
    m_worker_eventfd = -1;
    m_pipefd[0] = -1;
    m_pipefd[1] = -1;

    //http_conn类对象
    users = new http_conn[MAX_FD]; //在堆区创建 MAX_FD 个 http_conn 对象，并让 users 指向第一个对象
    m_connection_generation = new std::uint64_t[MAX_FD]();

    //root文件夹路径
    char server_path[200];     //定义当前路径缓冲区
    if (!getcwd(server_path, sizeof(server_path))) //获取当前工作目录 Current Working Directory
    {
        perror("getcwd failed");
        exit(EXIT_FAILURE);
    }
    const char root[6] = "/root";
    m_root = static_cast<char*>(malloc(strlen(server_path) + strlen(root) + 1)); //动态分配内存，用于存储根目录路径
    strcpy(m_root, server_path); //将右边的 C 字符串完整复制到左边。
    strcat(m_root, root);        //把右边字符串追加到左边字符串末尾

    //定时器
    users_timer = new client_data[MAX_FD](); //为每一个可能的客户端连接准备一份定时器相关数据
}

// 可以写一个有参构造函数，然后实现时使用成员初始化列表来实现。这样就可以先解析命令行后，再初始化服务器对象。 */

WebServer::~WebServer()
{
    delete m_pool;        //先停止并等待工作线程，防止线程继续访问后续资源
    m_pool = NULL;

    /* 释放内存和资源 */
    if (m_worker_eventfd >= 0) close(m_worker_eventfd);
    if (m_epollfd >= 0) close(m_epollfd);     //关闭 epoll 文件描述符，释放内核资源
    if (m_listenfd >= 0) close(m_listenfd);   //关闭监听套接字文件描述符，释放内核资源
    if (m_pipefd[1] >= 0) close(m_pipefd[1]); //关闭管道写端，释放内核资源  管道：信号处理函数把信号写进管道，主线程通过epoll监听管道事件，收到信号后再处理
    if (m_pipefd[0] >= 0) close(m_pipefd[0]); //关闭管道读端，释放内核资源
    delete[] users;       //释放 http_conn 对象数组
    delete[] users_timer; //释放 client_data 对象数组
    delete[] m_connection_generation;
    free(m_root);         //释放根目录路径字符串（因为是malloc分配的内存，所以需要手动释放）
}

/* init：初始化服务器，配置从命令行解析到的8个选项参数，以及用户数据库相关的三个参数，如果没有配置，则初始化为默认参数 */
void WebServer::init(int port, string user, string passWord, string databaseName, int log_write, 
                     int opt_linger, int trigmode, int sql_num, int thread_num, int close_log, int actor_model)
{
    m_port = port;
    m_user = user;
    m_passWord = passWord;
    m_databaseName = databaseName;
    m_sql_num = sql_num;
    m_thread_num = thread_num;
    m_log_write = log_write;
    m_OPT_LINGER = opt_linger;
    m_TRIGMode = trigmode;
    m_close_log = close_log;
    m_actormodel = actor_model;
}

/* 配置触发模式, 设置服务器的监听套接字（m_LISTENTrigmode）和连接套接字（m_CONNTrigmode）的触发模式 */
void WebServer::trig_mode()
{
    
    if (0 == m_TRIGMode) {
        m_LISTENTrigmode = 0;   /* 监听套接字设置为 LT 模式   m_listenfd：专门负责“接收新客户端连接” */
        m_CONNTrigmode = 0;     /* 连接套接字设置为 LT 模式   connfd：专门负责“和某一个客户端收发 HTTP 数据” */
    }

    else if (1 == m_TRIGMode) {
        m_LISTENTrigmode = 0;   /* 监听套接字设置为 LT 模式 */
        m_CONNTrigmode = 1;     /* 连接套接字设置为 ET 模式 */
    }

    else if (2 == m_TRIGMode) {
        m_LISTENTrigmode = 1;   /* 监听套接字设置为 ET 模式 */
        m_CONNTrigmode = 0;     /* 连接套接字设置为 LT 模式 */
    }

    else if (3 == m_TRIGMode) {
        m_LISTENTrigmode = 1;   /* 监听套接字设置为 ET 模式 */
        m_CONNTrigmode = 1;     /* 连接套接字设置为 ET 模式 */
    }
}

/* 创建并初始化日志 */
void WebServer::log_write()
{
    if (0 == m_close_log) //如果日志开关为 0，表示开启日志功能
    {
        // 日志文件路径和名称
        const char *log_file_name = "./ServerLog";

        // 日志缓冲区大小
        const int log_buffer_size = 2000;

        // 日志文件最大行数
        const int max_lines = 800000;

        // 阻塞队列大小（仅异步模式下使用）
        const int max_queue_size = (m_log_write == 1) ? 800 : 0;

        // 初始化日志系统
        bool init_status = Log::get_instance()->init(log_file_name, m_close_log, log_buffer_size, max_lines, max_queue_size);
        if (!init_status)
        {
            std::cerr << "Failed to initialize log system." << std::endl;
            exit(EXIT_FAILURE);
        }
    }
}

/* 创建并初始化数据库连接池：为什么用连接池？ 不用的话，每次一个HTTP请求要查数据库，就要先连接MYSQL，再执行再关闭，而建立数据库连接的成本比较高，尤其是并发请求多时。所以先一次性建立好多个，放进连接池里，用的时候去取，用完了放回去 */
void WebServer::sql_pool()
{
    // 取得全局唯一的数据库连接池对象，然后按当前 WebServer 的配置，预先创建若干个 MySQL 连接。
    /* 初始化数据库连接池，设置数据库的连接信息（包括主机地址、端口号、用户名、密码等），并建立指定数量的数据库连接 */
    m_connPool = connection_pool::GetInstance(); // WebServer 拿到唯一的数据库连接池地址，并保存起来。
    m_connPool->init("localhost", m_user, m_passWord, m_databaseName, 3306, m_sql_num, m_close_log);

    /* 初始化数据库读取表 */
    /* 为什么要预加载到内存： 登录是高频请求，如果每次登录都查数据库，数据库会成为性能瓶颈。预加载到内存后，登录校验是 O (1) 级别的内存查找，并发性能提升非常明显，属于典型的空间换时间。*/
    users->initmysql_result(m_connPool);
}

/* 创建并初始化服务器的线程池 */
void WebServer::thread_pool()
{
    /* 输入参数: 并发模型，数据库连接池，线程池线程数。把线程池实例化为http_conn类型，模板类中原来所以写T的地方的函数任务都被替换成处理接收http_conn类型的函数。  进而，模板类实现了：将通用线程池模具和项目的HTTP业务绑定，变成了专门处理HTTP请求的线程池 */
    threadpool<http_conn>::failure_handler on_failure =
        [this](http_conn *request, std::uint64_t generation)
        {
            notify_worker_failure(request, generation);
        };
    m_pool = new threadpool<http_conn>(m_actormodel, m_connPool, m_thread_num, 10000, on_failure);
}

/* 事件监听 */
void WebServer::eventListen()
{
    m_listenfd = socket(PF_INET, SOCK_STREAM, 0);   /* 创建一个套接字，PF_INET（Protocol Family，协议族）：使用IPv4；SOCK_STREAM：指定套接字类型为流式套接字，对应TCP协议；0：表示使用默认协议，对SOCK_STREAM来说默认是TCP */
    
    if (m_listenfd < 0) {                           /* 确保创建成功  m_listenfd是套接字文件描述符 */
        perror("socket creation failed");
        exit(EXIT_FAILURE);
    }                      

    /* 优雅关闭连接 */
    if (0 == m_OPT_LINGER)              /* 立即关闭套接字 */
    {
        struct linger tmp = {0, 1};     /* 用于操作SO_LINGER选项的结构体 */
        setsockopt(m_listenfd, SOL_SOCKET, SO_LINGER, &tmp, sizeof(tmp));
    }
    else if (1 == m_OPT_LINGER)         /* 启用延迟关闭*/
    {
        struct linger tmp = {1, 1};    /* 此结构体有两个成员 l_onoff 和 l_linger，分别表示是否关闭套接字，以及延迟关闭的时间。 */
        setsockopt(m_listenfd, SOL_SOCKET, SO_LINGER, &tmp, sizeof(tmp));   /* 设置套接字选项，确保套接字在关闭时能优雅地处理未完成的连接。 */
    }

    struct sockaddr_in address;                     /* TCP/IP 协议族结构体 */
    bzero(&address, sizeof(address));               /* 将 address 结构体的所有字节设置为 0，确保未使用的字段被清零 */
    address.sin_family = AF_INET;                   /* Address Family地址族，IPv4 */
    address.sin_addr.s_addr = htonl(INADDR_ANY);    /* INADDR_ANY 表示监听本机所有可用的接口（IPv4地址） */
    address.sin_port = htons(m_port);               /* htons 将端口号的主机字节序转换为网络字节序（固定是大端序） */

    int flag = 1;
    /* 
        设置的具体选项为地址重用。
        当设置了这个选项后，允许在相同的 IP 地址和端口上快速重用套接字，即使之前的连接还处于 TIME_WAIT 状态。
        这在服务器程序中很有用，特别是当服务器需要快速重启时，可以避免因为等待 TIME_WAIT 状态结束而导致的延迟。 
    */
    setsockopt(m_listenfd, SOL_SOCKET, SO_REUSEADDR, &flag, sizeof(flag));/*setsockopt(socket文件描述符,选项所在层级,选项名称,选项值地址,选项值大小);用来设置socket的属性 */

    /* 绑定套接字到指定的地址和端口 */
    if (bind(m_listenfd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("Bind failed");
        close(m_listenfd);
        exit(EXIT_FAILURE);
    }

    /* 把普通套接字转为监听套接字。高并发下使用系统允许的最大完成连接队列，避免 backlog=5 造成瞬时拒绝。 */
    if (listen(m_listenfd, SOMAXCONN) < 0) {
        perror("Listen failed");
        close(m_listenfd);
        exit(EXIT_FAILURE);
    }

    utils.init(TIMESLOT);                           /* 初始化定时器   作用：后续用来周期性检查超时连接，把长时间不活动的客户端连接踢掉，释放服务器资源*/

    //epoll创建内核事件表；真正接收 epoll_wait 输出的是 WebServer::events 成员数组
    m_epollfd = epoll_create(5);                    /* 创建一个 epoll 实例 */
    if (m_epollfd == -1) {
        perror("Epoll creation failed");
        close(m_listenfd);
        exit(EXIT_FAILURE);
    }

    utils.addfd(m_epollfd, m_listenfd, false, m_LISTENTrigmode); /*调用工具类封装的函数，把监听 fd 注册到 epoll 中，监听它的读事件（有新连接到来就是读事件就绪）*/
    http_conn::m_epollfd = m_epollfd;               /* 将 epoll 文件描述符赋值给 http_conn 类的静态成员变量，用于处理 HTTP 连接，所有HTTP连接对象共享同一个epoll实例 */

    /* 创建一对无名管道，用于在进程内部进行双向通信，常用于信号处理 */
    if (socketpair(PF_UNIX, SOCK_STREAM, 0, m_pipefd) == -1) {
        perror("Socketpair creation failed");
        close(m_listenfd);
        exit(EXIT_FAILURE);
    }

    utils.setnonblocking(m_pipefd[1]);              /* 将管道的写端设置为非阻塞模式，信号处理函数写管道时，如果管道满了不会阻塞，避免信号处理函数卡住 */
    utils.addfd(m_epollfd, m_pipefd[0], false, 0);  /* 将管道的读端添加到 epoll 实例中，用于监听信号，有信号写入时epoll就能检测到 */

    m_worker_eventfd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    if (m_worker_eventfd == -1) {
        perror("eventfd creation failed");
        exit(EXIT_FAILURE);
    }
    utils.addfd(m_epollfd, m_worker_eventfd, false, 0); /* 工作线程只报告失败，主线程负责关闭连接和删除定时器 */

    utils.addsig(SIGPIPE, SIG_IGN); /*当客户端异常断开后，服务器还往 socket 写数据时，会收到这个信号，默认行为是直接终止进程。服务器必须忽略它，防止因为一个客户端掉线导致整个服务崩溃*/
    utils.addsig(SIGALRM, utils.sig_handler, false);/*闹钟超时信号，由 alarm 函数触发，用来驱动定时器，周期性清理超时连接*/
    utils.addsig(SIGTERM, utils.sig_handler, false);/*进程终止信号（比如 kill 命令默认发送的信号），收到后通知服务器优雅退出*/

    alarm(TIMESLOT);/*设置一个定时器，TIMESLOT 秒后触发 SIGALRM 信号，启动定时器循环。每次信号触发、处理完超时任务后，会再调用一次 alarm，实现周期性的定时检查*/

    //把管道、epoll 的 fd 赋值给工具类的静态成员，让工具类里的信号处理、fd 操作等全局函数可以直接使用这些资源，不用每次传参，方便全局调用
    Utils::u_pipefd = m_pipefd;
    Utils::u_epollfd = m_epollfd;
}

void WebServer::timer(int connfd, struct sockaddr_in client_address)
{
    ++m_connection_generation[connfd];
    if (m_connection_generation[connfd] == 0) {
        ++m_connection_generation[connfd];
    }

    /*初始化http连接，user数组中的每一个元素，都对应一个可能的客户端连接*/
    users[connfd].init(connfd, client_address, m_root, m_CONNTrigmode, m_close_log, m_user, m_passWord, m_databaseName);

    //初始化client_data数据
    //创建定时器，设置回调函数和超时时间，绑定用户数据，将定时器添加到链表中
    users_timer[connfd].address = client_address; //客户端数据指针，是client_data类型的数组
    users_timer[connfd].sockfd = connfd; //sockfd：保存连接的 socket 描述符，超时关闭连接时要用到它
    util_timer *timer = new util_timer; //在堆上新建一个定时器对象。每个客户端连接都对应一个独立的定时器，各自管理自己的超时时间
    timer->user_data = &users_timer[connfd];//把刚才的 client_data 结构体地址，存到定时器的 user_data 成员里。作用：定时器超时触发时，回调函数本身不知道该处理哪个连接，通过 user_data 就能拿到连接的 socket、地址等全部信息，执行关闭清理操作
    timer->cb_func = cb_func;
    time_t cur = time(NULL);
    timer->expire = cur + 3 * TIMESLOT;
    users_timer[connfd].timer = timer; //把新建的定时器指针，存回 users_timer 数组里。 作用：后续这个连接有数据传输时（读 / 写事件触发），可以通过 connfd 立刻找到对应的定时器，调用 adjust_timer 把超时时间往后顺延（也就是「刷新心跳」），这就是为什么有数据交互的连接不会被超时踢掉。
    utils.m_timer_lst.add_timer(timer);
}

//若有数据传输，则将定时器往后延迟3个单位
//并对新的定时器在链表上的位置进行调整
void WebServer::adjust_timer(util_timer *timer)
{
    time_t cur = time(NULL);
    timer->expire = cur + 3 * TIMESLOT;
    utils.m_timer_lst.adjust_timer(timer);

    LOG_INFO("%s", "adjust timer once");
}

/* 处理超时连接，执行关闭与清理
当某个连接判定为超时（或出错需要主动关闭）时，执行超时回调回收连接资源，再把定时器从全局链表中移除，同时打印日志记录。 */
void WebServer::deal_timer(util_timer *timer, int sockfd)
{
    if (!timer) return;

    const int closed_fd = users_timer[sockfd].sockfd;
    timer->cb_func(&users_timer[sockfd]); //传入 &users_timer[sockfd] 是因为回调函数自身不知道要关闭哪个连接，通过用户数据可以拿到 sockfd、客户端地址等全部信息
    users_timer[sockfd].timer = NULL;
    utils.m_timer_lst.del_timer(timer);

    LOG_INFO("close fd %d", closed_fd);
}

/*处理新客户端连接请求  当监听套接字 m_listenfd 上有新连接事件触发时，调用此函数执行 accept 接收新连接，并完成连接初始化与定时器绑定*/
bool WebServer::dealclientdata()
{
    struct sockaddr_in client_address;
    socklen_t client_addrlength = sizeof(client_address);
    if (0 == m_LISTENTrigmode)
    {
        int connfd = accept(m_listenfd, (struct sockaddr *)&client_address, &client_addrlength); //只accept一次，因为accept是非阻塞的，只要监听队列里还有未处理的连接，epoll 就会持续触发读事件。本次处理一个，剩下的下次 epoll_wait 还会提醒，不会丢失连接。
        if (connfd < 0)
        {
            LOG_ERROR("%s:errno is:%d", "accept error", errno);
            return false;
        }
        if (http_conn::m_user_count >= MAX_FD) //过载保护
        {
            utils.show_error(connfd, "Internal server busy");
            LOG_ERROR("%s", "Internal server busy");
            return false;
        }
        timer(connfd, client_address); //初始化 HTTP 连接对象、绑定超时定时器、加入全局定时器链表
    }

    else
    {
        while (1)
        {
            int connfd = accept(m_listenfd, (struct sockaddr *)&client_address, &client_addrlength); //循环accept，直到没有新连接为止。 这是 ET 模式的强制要求：新连接到来只会触发一次事件通知，必须一次性把所有已就绪的连接全部处理完；否则剩下的连接会一直留在队列里，再也不会被通知到，造成连接泄漏。
            if (connfd < 0)
            {
                //ET 模式下，非阻塞 accept 返回 EAGAIN/EWOULDBLOCK 表示监听队列已经被取空，这是正常结束条件，不应该当成错误日志刷屏。
                if (errno != EAGAIN && errno != EWOULDBLOCK)
                {
                    LOG_ERROR("%s:errno is:%d", "accept error", errno);
                }
                break;
            }
            if (http_conn::m_user_count >= MAX_FD)
            {
                utils.show_error(connfd, "Internal server busy");
                LOG_ERROR("%s", "Internal server busy");
                break;
            }
            timer(connfd, client_address);
        }
        return false;
    }
    return true;
}

/*处理管道传递的信号事件  从信号管道的读端读取信号编号，解析出是「超时信号」还是「终止信号」，通过引用参数把结果回传给主循环，让主循环统一处理超时检查和服务器退出。*/
bool WebServer::dealwithsignal(bool &timeout, bool &stop_server)
{
    int ret = 0;
    char signals[1024]; //读取缓冲区。信号处理函数会把信号编号（如 SIGALRM、SIGTERM 的整数值）作为单个字节写入管道，这里用来批量接收
    ret = recv(m_pipefd[0], signals, sizeof(signals), 0); //从管道读端 m_pipefd[0] 读取数据
    if (ret == -1) //读取出错
    {
        return false;
    }
    else if (ret == 0) //管道的对端已关闭，异常情况，返回失败
    {
        return false;
    }
    else
    {
        for (int i = 0; i < ret; ++i) //遍历读到的所有信号字节
        {
            switch (signals[i])
            {
            case SIGALRM: //SIGALRM（闹钟超时信号）：把 timeout 置为 true，告诉主循环「定时时间到了，该检查所有超时连接了」
            {
                timeout = true;
                break;
            }
            case SIGTERM: //SIGTERM（进程终止信号）：把 stop_server 置为 true，告诉主循环「收到退出指令，该停止服务了」
            {
                stop_server = true;
                break;
            }
            }
        }
    }
    return true;
}

void WebServer::notify_worker_failure(http_conn *request, std::uint64_t generation)
{
    const std::ptrdiff_t index = request - users;
    if (index < 0 || index >= MAX_FD || m_worker_eventfd < 0)
    {
        return;
    }

    {
        std::lock_guard<std::mutex> lock(m_worker_failure_mutex);
        worker_failure failure = {static_cast<int>(index), generation};
        m_worker_failures.push(failure);
    }

    const std::uint64_t one = 1;
    if (write(m_worker_eventfd, &one, sizeof(one)) == -1 && errno != EAGAIN)
    {
        LOG_ERROR("worker eventfd write failed: %s", strerror(errno));
    }
}

void WebServer::dealwithworkerfailure()
{
    std::uint64_t notifications = 0;
    while (read(m_worker_eventfd, &notifications, sizeof(notifications)) == sizeof(notifications))
    {
    }
    if (errno != EAGAIN && errno != EWOULDBLOCK)
    {
        LOG_ERROR("worker eventfd read failed: %s", strerror(errno));
    }

    std::queue<worker_failure> failures;
    {
        std::lock_guard<std::mutex> lock(m_worker_failure_mutex);
        failures.swap(m_worker_failures);
    }

    while (!failures.empty())
    {
        const worker_failure failure = failures.front();
        failures.pop();

        if (failure.sockfd < 0 || failure.sockfd >= MAX_FD ||
            m_connection_generation[failure.sockfd] != failure.generation)
        {
            continue;
        }

        util_timer *timer = users_timer[failure.sockfd].timer;
        if (timer)
        {
            deal_timer(timer, failure.sockfd);
        }
    }
}

/*处理客户端读就绪事件  当 epoll 检测到某个客户端 socket 有数据可读时触发，根据配置的并发模型（Reactor / Proactor），以不同的分工方式读取客户端数据、投递业务任务、刷新超时定时器*/
void WebServer::dealwithread(int sockfd)
{
    util_timer *timer = users_timer[sockfd].timer; //执行前先取出该连接对应的定时器，后续要么刷新它的超时时间（活跃连接），要么触发它关闭连接（出错 / 断开）

    //reactor 工作线程负责IO读写+业务处理，主线程只负责事件分发和失败清理
    if (1 == m_actormodel)
    {
        if (timer)
        {
            adjust_timer(timer); //先刷新定时器：有数据交互说明连接是活跃的，把超时时间往后顺延 3 个时间片，重置超时倒计时
        }

        //若监测到读事件，将该事件放入请求队列。成功路径由工作线程重置 EPOLLONESHOT，主线程不再等待
        if (!m_pool->append(users + sockfd, 0, m_connection_generation[sockfd]))
        {
            deal_timer(timer, sockfd);
        }
    }
    else
    {
        //proactor   主线程负责 IO 读写，数据读完之后再把业务处理任务投给线程池，工作线程只负责纯业务逻辑
        if (users[sockfd].read_once()) //主线程直接调用 read_once()，把客户端的数据从 socket 读到连接的读缓冲区中
        {
            LOG_INFO("deal with the client(%s)", inet_ntoa(users[sockfd].get_address()->sin_addr));

            //若监测到读事件，将该事件放入请求队列
            if (!m_pool->append_p(users + sockfd, m_connection_generation[sockfd])) // 把业务任务投到线程池 —— IO 已经做完，工作线程直接执行 process()
            {
                deal_timer(timer, sockfd);
                return;
            }

            if (timer)
            {
                adjust_timer(timer); //刷新定时器，活跃连接延后超时
            }
        }
        else
        {
            deal_timer(timer, sockfd); //读取失败（客户端主动断开、网络出错）：直接调用 deal_timer，执行关闭连接、移除定时器的完整清理操作。
        }
    }
}

//处理客户端写就绪事件  当 epoll 检测到某个客户端 socket 有数据可写时触发，根据配置的并发模型（Reactor / Proactor），以不同的分工方式向客户端发送响应数据、刷新超时定时器
void WebServer::dealwithwrite(int sockfd)
{
    util_timer *timer = users_timer[sockfd].timer; ////执行前先取出该连接对应的定时器，后续要么刷新它的超时时间（活跃连接），要么触发它关闭连接（出错 / 断开）
    //reactor 模式下工作线程执行 write()；只有关闭连接时才通过 eventfd 通知主线程清理定时器。
    if (1 == m_actormodel)
    {
        if (timer)
        {
            adjust_timer(timer);
        }

        if (!m_pool->append(users + sockfd, 1, m_connection_generation[sockfd])) //状态参数 1 表示「写事件」
        {
            deal_timer(timer, sockfd);
        }
    }
    else
    {
        //proactor
        if (users[sockfd].write())
        {
            LOG_INFO("send data to the client(%s)", inet_ntoa(users[sockfd].get_address()->sin_addr));

            if (timer)
            {
                adjust_timer(timer); //发送成功：打日志，刷新定时器
            }
        }
        else
        {
            deal_timer(timer, sockfd); //发送失败：调用 deal_timer 关闭连接、清理定时器
        }
    }
}


/*基于 epoll 事件驱动模型，以「阻塞等待事件 → 分类分发处理 → 周期检查超时」的方式无限循环，
直到收到退出信号为止。所有的新连接、数据读写、异常断开、信号、超时清理，都在这个循环里统一调度*/
void WebServer::eventLoop()
{
    bool timeout = false; //超时标记，收到 SIGALRM 闹钟信号后会被置为 true，用于触发一轮超时连接检查
    bool stop_server = false; //服务器退出标志，收到 SIGTERM 终止信号后会被置为 true，循环结束，服务优雅退出

    while (!stop_server)
    {
        int number = epoll_wait(m_epollfd, events, MAX_EVENT_NUMBER, -1); //调用 epoll_wait 阻塞等待内核事件表中有事件就绪
        /*m_epollfd：epoll 实例的文件描述符；
        events：输出数组，内核会把所有就绪的事件填到这个数组里；
        MAX_EVENT_NUMBER：数组最大长度，一次最多返回这么多个就绪事件；
        -1：超时时间，负数表示永久阻塞，直到有事件就绪才返回*/
        if (number < 0 && errno != EINTR) //如果错误是 EINTR：表示 epoll_wait 被信号中断了，这是正常情况（比如闹钟信号触发），不报错，直接进入下一轮循环
        {
            LOG_ERROR("%s", "epoll failure");
            break;
        }

        for (int i = 0; i < number; i++) //遍历本次所有就绪事件，根据事件所属的 fd 和事件类型，分成 5 个分支分别处理。这就是事件分发器的核心逻辑
        {
            int sockfd = events[i].data.fd;

            //处理新到的客户端连接事件
            if (sockfd == m_listenfd) //触发条件：就绪的 fd 是监听套接字，说明有新客户端完成了三次握手，等待被接收。
            {
                bool flag = dealclientdata(); //处理逻辑：调用 dealclientdata() 执行 accept 接收连接、初始化 HTTP 对象、绑定定时器。
                if (false == flag)
                    continue; //LT 下多表示处理失败；ET 分支处理完 accept 循环后也会返回 false，用于结束当前分支
            }
            //处理信号事件（统一事件源）：信号也变成了 epoll 里的 IO 事件，在主循环同步处理，彻底避免异步竞态
            else if ((sockfd == m_pipefd[0]) && (events[i].events & EPOLLIN)) //触发条件：管道读端有数据可读，说明信号处理函数往管道里写入了信号值
            {
                bool flag = dealwithsignal(timeout, stop_server); //处理逻辑：调用 dealwithsignal 读取管道里的信号，通过引用参数修改 timeout 和 stop_server 两个标记，把异步信号转成同步的状态标志，交给循环后续统一处理
                if (false == flag)
                    LOG_ERROR("%s", "dealwithsignal failure");
            }
            else if ((sockfd == m_worker_eventfd) && (events[i].events & EPOLLIN))
            {
                dealwithworkerfailure();
            }
            //连接异常/断开事件 ： 服务器自动清理异常连接的重要机制，避免无效连接长期占用资源
            else if (events[i].events & (EPOLLRDHUP | EPOLLHUP | EPOLLERR))
            {
                //服务器端关闭连接，移除对应的定时器
                util_timer *timer = users_timer[sockfd].timer;
                if (timer)
                {
                    deal_timer(timer, sockfd);
                }
            }
            //处理客户连接上接收到的数据，客户端读就绪事件
            else if (events[i].events & EPOLLIN) //触发条件：某个客户端连接的 socket 有数据可读，客户端发来了 HTTP 请求数据
            {
                dealwithread(sockfd); //处理逻辑：调用 dealwithread，按 Reactor/Proactor 模式分工，完成数据读取、业务任务投递、定时器刷新
            }
            //处理客户连接上要发送的数据，客户端写就绪事件
            else if (events[i].events & EPOLLOUT) //触发条件：某个客户端连接的 socket 可写，服务器可以向客户端发送 HTTP 响应数据
            {
                dealwithwrite(sockfd); //处理逻辑：调用 dealwithwrite，按模式分工完成响应发送、定时器刷新
            }
        }
        if (timeout) //当 timeout 被信号处理置为 true 时，说明一个定时周期到了，需要检查所有超时连接
        {
            utils.timer_handler(); //遍历定时器链表，把所有已经超时的连接依次触发回调、关闭连接、移除定时器；同时重新调用 alarm 设置下一次闹钟，形成周期性循环

            LOG_INFO("%s", "timer tick");

            timeout = false;
        }
    }
}

/*统一事件源思想
新连接、读写 IO、异常断开、信号、定时，所有事件全部通过 epoll 在同一个循环里同步处理，
架构清晰、竞态少，是 Linux 高性能网络编程的经典架构。*/
