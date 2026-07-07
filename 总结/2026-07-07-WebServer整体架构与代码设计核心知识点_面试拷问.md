# WebServer 整体架构与代码设计核心知识点

> 学习范围：`main.cpp`、`webserver.h`、`webserver.cpp`，并串联 `http_conn`、`threadpool`、`CGImysql`、`timer`、`log`、`lock`、`block_queue` 等模块。
>
> 这份笔记的目标不是背代码，而是把项目讲成一个完整的高性能服务器架构：谁负责监听，谁负责分发，谁负责读写，谁负责业务，谁负责资源回收，谁负责超时清理。

## 1. 一句话讲清这个项目

这是一个基于 Linux 的轻量级 HTTP WebServer。它用 `epoll` 做事件驱动，用非阻塞 socket 处理高并发连接，用线程池处理 HTTP 请求，用数据库连接池复用 MySQL 连接，用定时器清理超时连接，用日志模块记录运行状态。

面试时可以这样说：

> 这个项目的核心是一个事件驱动的 WebServer。主线程通过 `epoll_wait` 统一监听新连接、客户端读写、异常断开和信号管道事件；网络连接由 `http_conn` 对象封装；耗时的请求解析和业务处理投递到线程池；数据库访问通过连接池和 RAII 自动借还；超时连接通过定时器链表周期性清理。

## 2. 项目整体分层

| 层级 | 主要文件 | 职责 |
| --- | --- | --- |
| 启动配置层 | `main.cpp`、`config.cpp` | 解析命令行参数，确定端口、线程数、触发模式、日志模式、并发模型 |
| 总控调度层 | `webserver.h`、`webserver.cpp` | 组合各个模块，初始化资源，启动监听，运行事件循环 |
| IO 多路复用层 | `epoll`、`Utils::addfd`、`http_conn::modfd` | 把 socket fd 注册进 epoll，等待内核通知就绪事件 |
| 连接对象层 | `http/http_conn.h/.cpp` | 每个客户端连接对应一个 `http_conn` 对象，负责读请求、解析 HTTP、生成响应、写回数据 |
| 并发处理层 | `threadpool/threadpool.h` | 固定数量工作线程，从任务队列取出 `http_conn*` 执行处理 |
| 数据库连接层 | `CGImysql/sql_connection_pool.*` | 预先创建 MySQL 连接，业务线程临时借用，用完归还 |
| 定时器层 | `timer/lst_timer.*` | 每个连接绑定一个定时器，超时后关闭连接并从 epoll 删除 fd |
| 日志层 | `log/log.*`、`log/block_queue.h` | 支持同步/异步日志，异步模式用阻塞队列解耦业务线程和磁盘写入 |
| 同步原语层 | `lock/locker.h` | 封装互斥锁、信号量、条件变量和 RAII 锁守卫 |

这个架构的精华是：`WebServer` 自己不解析 HTTP、不执行 SQL、不直接写业务逻辑，它更像“总调度器”。真正的业务处理被下放到 `http_conn` 和线程池，资源管理被交给连接池、日志、定时器等模块。

## 3. 启动流程

`main.cpp` 的顺序非常重要：

```cpp
config.parse_arg(argc, argv);

WebServer server;
server.init(...);
server.log_write();
server.sql_pool();
server.thread_pool();
server.trig_mode();
server.eventListen();
server.eventLoop();
```

对应的逻辑是：

1. `Config::parse_arg()`：解析命令行参数。
2. `WebServer server`：构造服务器对象，分配 `http_conn` 数组、网站根目录、定时器数据数组。
3. `server.init()`：把配置参数保存进 `WebServer` 成员变量。
4. `server.log_write()`：初始化日志系统。后面连接池、线程池、事件循环都会打日志，所以日志要靠前。
5. `server.sql_pool()`：初始化数据库连接池，并把用户表预加载到内存 map。
6. `server.thread_pool()`：创建线程池。线程池需要数据库连接池指针，所以必须在 `sql_pool()` 后。
7. `server.trig_mode()`：把命令行传入的触发模式转换成监听 socket 和连接 socket 的 LT/ET 配置。
8. `server.eventListen()`：创建监听 socket、绑定端口、创建 epoll、注册监听 fd 和信号管道。
9. `server.eventLoop()`：进入服务器主循环，正式开始处理事件。

## 4. `WebServer` 的核心数据结构

`WebServer` 这个类里最重要的成员可以分为几组：

| 成员 | 含义 |
| --- | --- |
| `m_listenfd` | 监听 socket，专门负责接收新客户端连接 |
| `m_epollfd` | epoll 实例 fd，主事件循环依赖它等待就绪事件 |
| `events[MAX_EVENT_NUMBER]` | `epoll_wait` 的输出数组，保存本轮就绪事件 |
| `m_pipefd[2]` | 信号管道，信号处理函数写端写入，主循环监听读端 |
| `users` | `http_conn` 对象数组，使用 `connfd` 作为下标 |
| `users_timer` | 每个连接对应的定时器数据，也使用 `connfd` 作为下标 |
| `m_pool` | 线程池对象 |
| `m_connPool` | 数据库连接池对象 |
| `utils` | 工具类对象，封装 epoll fd 注册、信号注册、定时器链表 |
| `m_root` | 网站根目录，构造函数中由当前工作目录拼接 `/root` 得到 |

这里有一个非常典型的设计：`users[connfd]` 和 `users_timer[connfd]` 都以文件描述符作为数组下标。这样查找速度是 O(1)，但代价是需要提前分配 `MAX_FD` 大小的数组，空间占用较大。

## 5. 事件监听初始化

`WebServer::eventListen()` 做了服务器启动前最关键的一组系统调用：

1. `socket(PF_INET, SOCK_STREAM, 0)`：创建 TCP socket。
2. `setsockopt(SO_LINGER)`：配置关闭连接时的行为。
3. `setsockopt(SO_REUSEADDR)`：允许快速复用端口，避免服务重启时被 `TIME_WAIT` 卡住。
4. `bind()`：把 socket 绑定到 IP 和端口。
5. `listen()`：把普通 socket 变成监听 socket。
6. `epoll_create()`：创建 epoll 实例。
7. `addfd(m_epollfd, m_listenfd, false, m_LISTENTrigmode)`：把监听 fd 注册到 epoll。
8. `socketpair()`：创建一对管道 fd，用于信号转事件。
9. `addfd(m_epollfd, m_pipefd[0], false, 0)`：把信号管道读端注册到 epoll。
10. `addsig(SIGPIPE/SIGALRM/SIGTERM)`：注册信号处理。
11. `alarm(TIMESLOT)`：启动周期性定时检查。

注意：监听 fd 和普通客户端 fd 是两类不同的 fd。

| fd | 作用 |
| --- | --- |
| `m_listenfd` | 只负责接收新连接，也就是 `accept()` |
| `connfd` | 每个客户端连接自己的 socket，用于 `recv()` / `send()` |

## 6. 主事件循环

`WebServer::eventLoop()` 是整个项目的心脏：

```cpp
while (!stop_server) {
    int number = epoll_wait(m_epollfd, events, MAX_EVENT_NUMBER, -1);

    for (int i = 0; i < number; i++) {
        int sockfd = events[i].data.fd;

        if (sockfd == m_listenfd) {
            dealclientdata();
        } else if (events[i].events & (EPOLLRDHUP | EPOLLHUP | EPOLLERR)) {
            deal_timer(...);
        } else if (sockfd == m_pipefd[0] && events[i].events & EPOLLIN) {
            dealwithsignal(...);
        } else if (events[i].events & EPOLLIN) {
            dealwithread(sockfd);
        } else if (events[i].events & EPOLLOUT) {
            dealwithwrite(sockfd);
        }
    }

    if (timeout) {
        utils.timer_handler();
        timeout = false;
    }
}
```

这段代码可以理解为一个事件分发器：

| 事件类型 | 处理函数 | 含义 |
| --- | --- | --- |
| `sockfd == m_listenfd` | `dealclientdata()` | 有新客户端连接 |
| `EPOLLRDHUP / EPOLLHUP / EPOLLERR` | `deal_timer()` | 客户端异常断开或连接出错 |
| `sockfd == m_pipefd[0]` | `dealwithsignal()` | 有信号被写入管道 |
| `EPOLLIN` | `dealwithread()` | 某个客户端连接有数据可读 |
| `EPOLLOUT` | `dealwithwrite()` | 某个客户端连接可以继续发送响应 |
| `timeout == true` | `timer_handler()` | 定时周期到了，检查超时连接 |

这就是高性能网络编程里常说的“统一事件源”：网络 IO、连接异常、信号、定时任务，都被统一塞进同一个事件循环里处理。

## 7. 一次 HTTP 请求的完整链路

一次请求从客户端到服务器，大致会经历这些步骤：

1. 客户端发起 TCP 连接。
2. `m_listenfd` 在 epoll 中变为可读。
3. `eventLoop()` 发现 `sockfd == m_listenfd`。
4. `dealclientdata()` 调用 `accept()` 得到新的 `connfd`。
5. `timer(connfd, client_address)` 初始化：
   - `users[connfd]` 对应的 `http_conn` 对象；
   - `users_timer[connfd]` 对应的客户端定时器数据；
   - `util_timer` 超时定时器。
6. `http_conn::init()` 把新 `connfd` 注册进 epoll，并设置 `EPOLLONESHOT`。
7. 客户端发送 HTTP 请求，`connfd` 触发 `EPOLLIN`。
8. `dealwithread()` 根据并发模型选择处理方式：
   - Proactor：主线程先 `read_once()`，再把业务处理投给线程池；
   - Reactor：主线程只投递任务，工作线程自己读写和处理。
9. 工作线程执行 `http_conn::process()`：
   - 解析请求行、请求头、请求体；
   - 判断访问资源；
   - 必要时访问数据库；
   - 构造 HTTP 响应。
10. `http_conn::process()` 通过 `modfd(..., EPOLLOUT, ...)` 把连接改成写事件。
11. epoll 后续发现 `connfd` 可写，`dealwithwrite()` 调用 `write()` 发送响应。
12. 如果是长连接，重新监听 `EPOLLIN`；如果不是长连接，发送结束后关闭连接。
13. 每次有效读写都会 `adjust_timer()`，把超时时间往后延。

## 8. Reactor 和 Proactor

项目用 `m_actormodel` 区分两种模型：

| 配置 | 名称 | 谁做 IO | 谁做业务 |
| --- | --- | --- | --- |
| `0` | Proactor 模式 | 主线程先读/写 socket | 工作线程处理业务 |
| `1` | Reactor 模式 | 工作线程读/写 socket | 工作线程处理业务 |

在 `dealwithread()` 中：

```cpp
if (1 == m_actormodel) {
    m_pool->append(users + sockfd, 0);
} else {
    if (users[sockfd].read_once()) {
        m_pool->append_p(users + sockfd);
    }
}
```

在 `threadpool::run()` 中：

```cpp
if (1 == m_actor_model) {
    if (request->m_state == 0) {
        request->read_once();
        request->process();
    } else {
        request->write();
    }
} else {
    request->process();
}
```

面试要点：

- 这个项目里的 Proactor 严格来说是“模拟 Proactor”，不是 Linux 内核真正的异步 IO。
- 主线程同步完成读写，再把业务逻辑交给线程池，这符合 Proactor 的思想，但底层仍然是非阻塞 socket + epoll。
- Reactor 模式下工作线程既做 IO 又做业务，主线程只负责事件分发。

## 9. LT 和 ET

`trig_mode()` 根据 `m_TRIGMode` 设置监听 socket 和连接 socket 的触发方式：

| `m_TRIGMode` | 监听 fd | 连接 fd |
| --- | --- | --- |
| `0` | LT | LT |
| `1` | LT | ET |
| `2` | ET | LT |
| `3` | ET | ET |

LT 和 ET 的核心区别：

| 模式 | 特点 | 编程要求 |
| --- | --- | --- |
| LT 水平触发 | 只要 fd 还有数据没处理，epoll 会持续提醒 | 每次可以只处理一部分，写法简单 |
| ET 边缘触发 | 只在状态从“未就绪”变成“就绪”时提醒一次 | 必须使用非阻塞 fd，并循环读/accept 到 `EAGAIN` |

项目里的体现：

- `dealclientdata()` 中，监听 fd 是 LT 时只 `accept()` 一次；监听 fd 是 ET 时循环 `accept()`，直到返回 `EAGAIN/EWOULDBLOCK`。
- `http_conn::read_once()` 中，连接 fd 是 LT 时只 `recv()` 一次；连接 fd 是 ET 时循环 `recv()`，直到返回 `EAGAIN/EWOULDBLOCK`。

面试回答重点：

> ET 模式必须配合非阻塞 IO。如果 fd 是阻塞的，循环读到没有数据时会卡死；如果不循环读空，剩下的数据可能再也不会触发通知。

## 10. EPOLLONESHOT

普通客户端连接注册时使用了 `EPOLLONESHOT`：

```cpp
addfd(m_epollfd, sockfd, true, m_TRIGMode);
```

它的作用是：一个 fd 触发一次事件后，会被 epoll 暂时禁用，直到程序用 `modfd()` 重新注册。

为什么需要它？

- 一个连接可能被多个工作线程同时看到读写事件。
- 如果多个线程同时操作同一个 `http_conn`，读写缓冲区、状态机、文件映射、数据库指针都会出现竞态。
- `EPOLLONESHOT` 保证同一时刻一个连接只被一个线程处理。

处理完成后必须重新激活：

```cpp
modfd(m_epollfd, m_sockfd, EPOLLIN, m_TRIGMode);
modfd(m_epollfd, m_sockfd, EPOLLOUT, m_TRIGMode);
```

面试官常问：

> 为什么用了线程池后还要 `EPOLLONESHOT`？

答：线程池只是并发处理任务，不天然保证同一个 socket 不会被多个线程同时处理。`EPOLLONESHOT` 是对单连接并发访问的保护。

## 11. 信号处理：为什么要用管道

Linux 信号是异步打断程序的，信号处理函数里能安全调用的函数很少。项目采用经典技巧：

1. 信号处理函数 `sig_handler()` 不直接做复杂逻辑。
2. 它只把信号编号写入 `m_pipefd[1]`。
3. 主循环通过 epoll 监听 `m_pipefd[0]`。
4. 管道可读时，`dealwithsignal()` 读取信号，设置 `timeout` 或 `stop_server`。
5. 主循环在普通上下文里执行定时器处理或退出逻辑。

这叫“信号转事件”：

```text
SIGALRM/SIGTERM
    -> sig_handler()
    -> write(pipe)
    -> epoll_wait 返回 pipe 可读
    -> dealwithsignal()
    -> 主循环同步处理
```

好处：

- 信号处理函数保持极简。
- 避免在异步信号上下文里做复杂操作。
- 信号和普通 socket IO 都进入同一个 epoll 事件循环，代码结构统一。

需要注意：

- `write()` 是异步信号安全函数。
- `std::cerr`、`strerror()` 不是异步信号安全函数，严格来说不应该在信号处理函数里调用。
- 本次已经把信号写入改成单字节 `char`，和 `dealwithsignal()` 的 `char signals[1024]` 读取方式保持一致。

## 12. 定时器设计

每个连接创建时都会绑定一个 `util_timer`：

```cpp
users_timer[connfd].address = client_address;
users_timer[connfd].sockfd = connfd;

util_timer *timer = new util_timer;
timer->user_data = &users_timer[connfd];
timer->cb_func = cb_func;
timer->expire = cur + 3 * TIMESLOT;

users_timer[connfd].timer = timer;
utils.m_timer_lst.add_timer(timer);
```

设计思想：

- `client_data` 保存连接相关数据。
- `util_timer` 保存超时时间和回调函数。
- 定时器通过 `user_data` 反向找到要关闭的 socket。
- 每次连接活跃时调用 `adjust_timer()` 延长过期时间。
- 每次 `SIGALRM` 到来时，主循环调用 `timer_handler()`，检查链表头部是否有到期定时器。

为什么链表按超时时间升序？

- 最近到期的定时器在头部。
- `tick()` 从头开始检查，遇到第一个未到期的节点就可以停止。
- 这样避免每次都扫描所有连接。

局限：

- 插入和调整定时器可能需要遍历链表，最坏 O(n)。
- 高并发下更常用小根堆、时间轮等结构。

## 13. 数据库连接池和 RAII

`connection_pool` 的语义是“连接池拥有连接，业务线程临时借用连接”。

核心流程：

```text
服务器启动
    -> connection_pool::init()
    -> 预先创建 N 条 MYSQL 连接
    -> 放入 connList

业务线程需要数据库
    -> connectionRAII 构造
    -> GetConnection()
    -> request->mysql 临时指向这条连接
    -> request->process()
    -> connectionRAII 析构
    -> ReleaseConnection()
    -> request->mysql 置空
```

为什么不用 `shared_ptr<MYSQL>`？

- `shared_ptr` 表示共享拥有。
- 数据库连接池要求一条连接同一时刻只能被一个线程独占使用。
- 如果多个 `shared_ptr` 指向同一条连接，连接归还池子后，外部旧指针仍然可能继续操作它。
- 新线程又可能从池中借到同一条连接，于是两个线程并发操作同一个 MySQL 连接，破坏连接池语义。

这个项目修正后的设计是：

- `connList` 只保存空闲连接。
- `GetConnection()` 会把连接从空闲链表中取出。
- `ReleaseConnection()` 才把连接放回空闲链表。
- `connectionRAII` 析构时会把外部 `MYSQL*` 置空，避免连接归还后继续误用。

面试回答重点：

> 连接池管理生命周期，业务对象只在 RAII 守卫对象的作用域内借用连接。RAII 析构时自动归还，防止忘记释放，同时通过置空外部指针避免归还后继续访问。

## 14. 线程池设计

线程池的核心成员：

| 成员 | 作用 |
| --- | --- |
| `m_threads` | 工作线程数组 |
| `m_workqueue` | 任务队列，保存 `http_conn*` |
| `m_queuelocker` | 保护任务队列 |
| `m_queuestat` | 信号量，表示当前有多少任务 |
| `m_connPool` | 数据库连接池指针 |
| `m_actor_model` | 并发模型 |

典型生产者-消费者模型：

```text
主线程
    -> epoll 检测到读写事件
    -> append / append_p
    -> 往任务队列 push 一个 http_conn*
    -> sem.post()

工作线程
    -> sem.wait()
    -> 从队列 pop 一个任务
    -> 处理请求
```

为什么取出任务后要立刻解锁？

```cpp
T *request = m_workqueue.front();
m_workqueue.pop_front();
m_queuelocker.unlock();
```

因为锁只应该保护队列本身。真正处理 HTTP 请求可能很耗时，如果拿着队列锁处理任务，其他线程就无法取任务，线程池会退化成串行。

需要注意的隐患：

- 当前线程设置为分离状态，析构时不能 `pthread_join()` 等待线程真正退出。
- Reactor 模式下主线程用 `while (true)` 自旋等待工作线程修改 `improv`，会浪费 CPU，并且可能阻塞事件循环。
- 更工程化的做法是使用条件变量、事件通知，或者避免主线程同步等待工作线程。

## 15. `webserver.cpp` 函数地图

| 函数 | 作用 | 面试关键词 |
| --- | --- | --- |
| `WebServer::WebServer()` | 分配连接数组、根目录、定时器数据数组 | 资源初始化、数组按 fd 索引 |
| `~WebServer()` | 关闭 fd，释放数组、线程池、根目录 | 资源释放、析构顺序 |
| `init()` | 保存配置参数 | 配置注入 |
| `trig_mode()` | 设置 LT/ET 组合 | epoll 触发模式 |
| `log_write()` | 初始化日志系统 | 同步/异步日志 |
| `sql_pool()` | 初始化数据库连接池并预加载用户表 | 连接池、空间换时间 |
| `thread_pool()` | 创建线程池 | 生产者-消费者 |
| `eventListen()` | socket、bind、listen、epoll、signal pipe 初始化 | 网络编程启动流程 |
| `timer()` | 初始化连接对象和连接定时器 | fd 到对象的映射 |
| `adjust_timer()` | 活跃连接延后超时 | 心跳刷新 |
| `deal_timer()` | 关闭超时/异常连接 | 回调清理 |
| `dealclientdata()` | accept 新连接 | LT/ET accept 差异 |
| `dealwithsignal()` | 读取信号管道 | 统一事件源 |
| `dealwithread()` | 处理读事件 | Reactor/Proactor |
| `dealwithwrite()` | 处理写事件 | 响应发送 |
| `eventLoop()` | 主事件循环和事件分发 | 项目核心 |

## 16. 这次根据注释顺手修正的点

这些修改都属于小范围修正，不改变项目架构：

1. `eventListen()` 里原来定义了一个局部 `epoll_event events[MAX_EVENT_NUMBER]`，但真正给 `epoll_wait()` 使用的是 `WebServer::events` 成员数组。局部变量没被使用，还容易让人误解，所以去掉了。
2. ET 模式下 `accept()` 循环读空监听队列后，非阻塞 socket 返回 `EAGAIN/EWOULDBLOCK` 是正常结束条件，不应该打印成 `accept error`。现在只在真正错误时打日志。
3. 信号处理函数原来写入的是 `int`，而 `dealwithsignal()` 按 `char` 缓冲区逐字节解析。现在统一成写入一个 `char` 信号编号，注释和实现一致。
4. 信号处理失败时日志原来写成 `dealclientdata failure`，实际失败的是 `dealwithsignal()`，已改成正确日志。
5. `Utils::u_epollfd` 注释原来说它保存 `WebServer::m_pipefd` 地址，这是错误的。`u_epollfd` 保存的是 epoll 实例 fd 的整数值，不拥有 epoll 资源。

## 17. 代码里值得继续留意的隐患

这些点不一定要马上改，但面试或复盘时要能说清楚：

1. `deal_timer(timer, sockfd)` 默认认为 `timer` 非空，健壮性上可以增加空指针保护。
2. Reactor 分支里主线程自旋等待 `improv`，高并发下会浪费 CPU，也可能拖慢事件循环。
3. 线程池工作线程是 detached 状态，析构时无法 join，优雅关闭语义不够严格。
4. 定时器用升序链表，结构简单，但大规模连接下插入和调整成本较高。
5. `MAX_FD` 大数组按 fd 直接索引，速度快，但空间占用固定较大。
6. `main.cpp` 中数据库用户名、密码、库名硬编码，不适合生产环境，实际项目应放配置文件或环境变量。
7. `sig_handler()` 中如果写管道失败后使用 `std::cerr` 和 `strerror()`，严格来说不符合异步信号安全要求。
8. `listen(m_listenfd, 5)` 的 backlog 较小，高并发压测时可能成为瓶颈。

## 18. 面试拷问点

### 1. 这个项目的整体架构是什么？

答：

> 主线程负责 epoll 事件监听和分发，连接对象由 `http_conn` 封装，业务处理交给线程池，数据库访问通过连接池复用连接，超时连接通过定时器链表清理，日志模块支持同步和异步写入。`WebServer` 是总控类，负责把这些模块组织起来。

### 2. 为什么主线程要用 epoll？

答：

> 一个线程不可能给每个客户端都阻塞等待，所以使用 IO 多路复用。`epoll` 把大量 fd 交给内核监听，只有就绪 fd 才返回，主线程只处理有事件的连接，适合高并发场景。

### 3. epoll 的 LT 和 ET 区别是什么？

答：

> LT 是只要数据还没处理完就会持续通知；ET 是状态变化时只通知一次。ET 性能更高但要求非阻塞 IO，并且必须循环读或 accept 到 `EAGAIN`，否则可能遗漏数据。

### 4. 为什么要设置非阻塞？

答：

> epoll 只告诉你 fd 当前可能可读/可写，不代表一次系统调用能完成所有操作。尤其 ET 模式下要循环读到 `EAGAIN`，如果 fd 是阻塞的，读到没有数据时线程会卡死。

### 5. 为什么要用 `EPOLLONESHOT`？

答：

> 防止同一个连接同时被多个线程处理。一个连接事件触发后会被禁用，工作线程处理完后通过 `modfd()` 重新注册，保证单连接上的读写缓冲区和状态机不会发生多线程竞态。

### 6. 项目里的 Reactor 和 Proactor 是怎么体现的？

答：

> `actor_model == 1` 是 Reactor：主线程只分发事件，工作线程负责读写和业务处理。`actor_model == 0` 是模拟 Proactor：主线程先完成读写，再把业务处理交给线程池。它不是真正内核异步 IO，而是同步非阻塞 IO 上模拟出的 Proactor 思想。

### 7. 为什么信号要通过管道传给 epoll？

答：

> 信号处理函数处在异步上下文，不能做复杂逻辑。项目只在信号处理函数里把信号编号写入管道，主线程通过 epoll 监听管道读端，把信号变成普通 IO 事件处理，实现统一事件源。

### 8. 定时器如何清理超时连接？

答：

> 每个连接创建时绑定一个定时器，定时器保存过期时间、回调函数和 `client_data`。有读写活动时刷新过期时间。`SIGALRM` 周期触发后，主循环调用 `timer_handler()` 扫描升序链表，关闭已经超时的连接。

### 9. 为什么数据库要用连接池？

答：

> 建立 MySQL 连接成本高，如果每次请求都连接和断开，会严重影响性能。连接池启动时预创建若干连接，请求处理时临时借用，用完归还，减少连接建立开销并限制数据库并发压力。

### 10. `connectionRAII` 的价值是什么？

答：

> 它把“借连接”和“还连接”绑定到对象生命周期。构造时从连接池取连接，析构时自动归还。即使中间 return 或抛异常，也能归还连接，防止泄漏。

### 11. 为什么不能用 `shared_ptr<MYSQL>` 管理池中连接？

答：

> `shared_ptr` 表达共享拥有，但连接池需要独占借用。同一条 MySQL 连接同一时刻只能被一个线程使用。`shared_ptr` 可能导致连接归还后外部旧指针仍然可用，从而和新借到该连接的线程并发操作同一连接。

### 12. 线程池为什么要用信号量？

答：

> 任务队列为空时工作线程应该阻塞等待，而不是空转。主线程投递任务后 `post()`，工作线程 `wait()` 被唤醒，从队列取任务执行。

### 13. 线程池为什么取出任务后要释放队列锁？

答：

> 队列锁只保护队列结构。真正处理请求可能很耗时，如果不释放锁，其他线程无法取任务，线程池并发能力会被锁住。

### 14. 为什么 `users` 和 `users_timer` 用 fd 当数组下标？

答：

> 这样从 fd 找连接对象和定时器都是 O(1)，非常快。缺点是要按最大 fd 数量提前分配数组，空间利用率不一定高。

### 15. `WebServer` 类为什么不直接处理 HTTP 解析？

答：

> 这是职责分离。`WebServer` 管整体生命周期和事件分发，`http_conn` 管单个 HTTP 连接的状态机和响应生成。这样模块边界清晰，后续维护和定位问题更容易。

## 19. 面试时的项目讲述模板

可以按这个顺序讲：

1. 先讲整体架构：`epoll + 线程池 + 连接池 + 定时器 + 日志`。
2. 再讲主线程：创建监听 socket，注册 epoll，进入 `eventLoop()`。
3. 再讲连接流转：`accept -> http_conn::init -> EPOLLIN -> read/process -> EPOLLOUT -> write`。
4. 再讲并发模型：支持 Reactor 和模拟 Proactor。
5. 再讲资源管理：数据库连接 RAII、锁 RAII、日志异步队列。
6. 再讲超时管理：信号管道 + 定时器链表。
7. 最后主动讲几个不足：自旋等待、链表定时器、detached 线程关闭、backlog 小、信号处理函数日志不严格安全。

一段完整回答示例：

> 我的 WebServer 项目采用主从 Reactor 思想，主线程通过 epoll 统一监听监听 socket、客户端 socket、信号管道和异常事件。新连接到来时，主线程 accept 并初始化 `http_conn` 对象和定时器；读写事件到来时，根据配置选择 Reactor 或模拟 Proactor 模型投递给线程池。业务处理过程中如果需要访问数据库，会通过 `connectionRAII` 从连接池临时借用 MySQL 连接，作用域结束后自动归还。长时间无活动的连接通过 `SIGALRM + socketpair + 定时器链表` 周期性清理。项目里还使用 `EPOLLONESHOT` 避免同一连接被多个线程同时处理。

## 20. 初学者复习路线

建议按下面顺序复习：

1. `main.cpp`：先看启动顺序，知道每个模块什么时候初始化。
2. `webserver.h`：看成员变量，理解服务器持有哪些资源。
3. `webserver.cpp::eventListen()`：掌握 socket、bind、listen、epoll、signal pipe。
4. `webserver.cpp::eventLoop()`：理解事件分发主线。
5. `dealclientdata()`：理解新连接如何进入系统。
6. `http_conn::init()`、`read_once()`、`process()`、`write()`：理解单连接生命周期。
7. `threadpool::append/run()`：理解任务投递和工作线程处理。
8. `connection_pool`、`connectionRAII`：理解数据库连接的独占借用。
9. `timer/lst_timer.cpp`：理解超时连接清理。
10. `log` 和 `block_queue`：理解同步/异步日志。

真正能讲清这个项目，不是记住每一行代码，而是能画出这条链：

```text
main.cpp 启动配置
    -> WebServer 初始化资源
    -> eventListen 建立监听与 epoll
    -> eventLoop 等待事件
    -> accept 新连接
    -> http_conn 管理单连接
    -> threadpool 并发处理
    -> connection_pool 复用数据库连接
    -> timer 清理超时连接
    -> log 记录运行状态
```

