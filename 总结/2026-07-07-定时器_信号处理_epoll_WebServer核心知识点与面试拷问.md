# 7月2日到7月7日：定时器 / 信号处理 / epoll / WebServer 核心知识点与面试拷问

> 学习范围：`timer/lst_timer.h`、`timer/lst_timer.cpp`、`webserver.h`、`webserver.cpp`、`http/http_conn.cpp` 中和 epoll 注册/读写切换相关的部分、`config.cpp` 中触发模式参数解析、`threadpool/threadpool.h` 中 Reactor/Proactor 分支。

这几天学习的主线是：一个 Linux WebServer 如何把“网络事件、定时事件、信号事件、线程池任务”统一调度起来。

可以先记住一句话：

> `epoll` 负责等事件，`WebServer::eventLoop()` 负责分发事件，定时器负责清理超时连接，信号处理函数只负责把信号写进管道，线程池负责处理耗时任务。

## 1. 这几天内容的整体地图

这部分代码围绕 `WebServer` 展开：

```cpp
server.init(...);
server.log_write();
server.sql_pool();
server.thread_pool();
server.trig_mode();
server.eventListen();
server.eventLoop();
```

整体顺序是：

1. `Config::parse_arg()` 解析命令行参数。
2. `WebServer::init()` 保存参数。
3. `log_write()` 初始化日志。
4. `sql_pool()` 初始化数据库连接池。
5. `thread_pool()` 创建线程池。
6. `trig_mode()` 设置监听 socket 和连接 socket 的 LT/ET 模式。
7. `eventListen()` 创建监听 socket、epoll、信号管道、定时器。
8. `eventLoop()` 进入主事件循环。

项目里的核心事件来源有四类：

| 事件来源 | fd 或机制 | 在哪里处理 |
|---|---|---|
| 新客户端连接 | `m_listenfd` | `dealclientdata()` |
| 客户端读事件 | `connfd` 的 `EPOLLIN` | `dealwithread()` |
| 客户端写事件 | `connfd` 的 `EPOLLOUT` | `dealwithwrite()` |
| 信号事件 | `m_pipefd[0]` 可读 | `dealwithsignal()` |

定时器不是直接由 epoll 管理，而是由 `SIGALRM -> 管道 -> epoll -> timer_handler()` 这条链驱动。

## 2. epoll 具体是什么

### 2.1 从直觉上理解 epoll

`epoll` 是 Linux 提供的高性能 I/O 多路复用机制。

它解决的问题是：

> 一个线程如何同时管理大量 socket，而不是给每个连接都创建一个线程。

如果没有 epoll，服务器可能要不断轮询很多 fd：

```cpp
for 每个 fd:
    检查它能不能读/写
```

这样 fd 数量一大，效率很差。

epoll 的思想是：

1. 先告诉内核：我关心哪些 fd，以及关心它们的什么事件。
2. 内核帮你监控这些 fd。
3. 你调用 `epoll_wait()` 睡眠等待。
4. 有事件发生时，内核返回“已经就绪”的 fd。

所以 epoll 不是“处理请求”的东西，它只是事件通知机制。

### 2.2 epoll 三个核心 API

#### `epoll_create`

```cpp
m_epollfd = epoll_create(5);
```

作用：创建一个 epoll 实例，返回一个 epoll 文件描述符。

你可以把 `m_epollfd` 理解为“内核事件表”的句柄。

#### `epoll_ctl`

```cpp
epoll_ctl(epollfd, EPOLL_CTL_ADD, fd, &event);
epoll_ctl(epollfd, EPOLL_CTL_MOD, fd, &event);
epoll_ctl(epollfd, EPOLL_CTL_DEL, fd, nullptr);
```

作用：操作 epoll 关注的 fd。

| 操作 | 含义 |
|---|---|
| `EPOLL_CTL_ADD` | 添加一个 fd 到 epoll |
| `EPOLL_CTL_MOD` | 修改一个 fd 关注的事件 |
| `EPOLL_CTL_DEL` | 从 epoll 删除一个 fd |

#### `epoll_wait`

```cpp
int number = epoll_wait(m_epollfd, events, MAX_EVENT_NUMBER, -1);
```

作用：等待事件发生。

最后一个参数 `-1` 表示一直阻塞，直到有事件发生。

### 2.3 epoll 里注册的是什么

项目里注册的是 `epoll_event`：

```cpp
epoll_event event;
event.data.fd = fd;
event.events = EPOLLIN | EPOLLET | EPOLLRDHUP;
```

其中：

| 字段 | 含义 |
|---|---|
| `event.data.fd` | 事件发生时要返回哪个 fd |
| `event.events` | 关心哪些事件 |

常见事件：

| 事件 | 含义 |
|---|---|
| `EPOLLIN` | 可读，有数据可读或有新连接可 accept |
| `EPOLLOUT` | 可写，socket 发送缓冲区可写 |
| `EPOLLRDHUP` | 对端关闭或半关闭连接 |
| `EPOLLHUP` | 挂起 |
| `EPOLLERR` | 错误 |
| `EPOLLET` | 边缘触发 ET |
| `EPOLLONESHOT` | 一个事件只触发一次，需要重新注册 |

### 2.4 epoll 在本项目中的位置

`WebServer::eventListen()` 中：

```cpp
m_epollfd = epoll_create(5);
utils.addfd(m_epollfd, m_listenfd, false, m_LISTENTrigmode);
http_conn::m_epollfd = m_epollfd;
```

含义：

1. 创建 epoll 实例。
2. 把监听 socket 加入 epoll。
3. 把同一个 epoll fd 保存到 `http_conn` 的静态成员里，方便所有 HTTP 连接对象后续调用 `modfd()`。

`WebServer::eventLoop()` 中：

```cpp
epoll_wait(m_epollfd, events, MAX_EVENT_NUMBER, -1);
```

这是服务器主线程的核心等待点。

## 3. LT 和 ET 触发方式

### 3.1 LT：水平触发

LT 是 Level Trigger，水平触发。

理解方式：

> 只要 fd 还处于“可读/可写”状态，epoll 就会反复通知你。

比如 socket 里有 1000 字节，你这次只读了 100 字节，还剩 900 字节。下次 `epoll_wait()` 还会继续通知你这个 fd 可读。

优点：不容易漏事件。

缺点：如果数据没有一次处理完，会反复触发，事件通知次数更多。

### 3.2 ET：边缘触发

ET 是 Edge Trigger，边缘触发。

理解方式：

> 只有 fd 状态发生变化时通知一次，例如从“不可读”变成“可读”。

如果你收到通知后没有把数据一次读完，剩余数据可能不会再次通知你。

所以 ET 模式必须配合非阻塞 fd，并循环读到 `EAGAIN` 或 `EWOULDBLOCK`。

项目中 `http_conn::read_once()` 的 ET 分支就是：

```cpp
while (true) {
    bytes_read = recv(...);
    if (bytes_read == -1) {
        if (errno == EAGAIN || errno == EWOULDBLOCK)
            break;
        return false;
    }
    ...
}
```

这就是 ET 的核心要求：一次性把内核缓冲区当前能读的数据读干净。

### 3.3 为什么 ET 必须非阻塞

如果 fd 是阻塞的，在 ET 模式下你循环读：

```cpp
while (true) {
    recv(...);
}
```

读完已有数据后，下一次 `recv` 会因为没有数据而阻塞，整个线程卡住。

所以项目里注册 fd 后会调用：

```cpp
setnonblocking(fd);
```

非阻塞后，没数据时 `recv` 返回 `-1`，`errno == EAGAIN`，循环就能退出。

### 3.4 项目里的触发模式组合

`Config` 中 `TRIGMode` 取值：

| `TRIGMode` | 监听 socket | 连接 socket |
|---|---|---|
| 0 | LT | LT |
| 1 | LT | ET |
| 2 | ET | LT |
| 3 | ET | ET |

`WebServer::trig_mode()` 根据 `m_TRIGMode` 设置：

```cpp
m_LISTENTrigmode;
m_CONNTrigmode;
```

然后：

```cpp
utils.addfd(m_epollfd, m_listenfd, false, m_LISTENTrigmode);
users[connfd].init(..., m_CONNTrigmode, ...);
```

也就是说：

1. `m_LISTENTrigmode` 决定 `accept` 新连接时的触发模式。
2. `m_CONNTrigmode` 决定每个客户端连接读写数据时的触发模式。

### 3.5 监听 socket 的 LT/ET 差异

`dealclientdata()` 中：

LT 模式：

```cpp
int connfd = accept(...);
```

只 accept 一次。

ET 模式：

```cpp
while (1) {
    int connfd = accept(...);
    ...
}
```

循环 accept，直到没有新连接。

原因和读数据一样：ET 只通知一次，所以必须一次把当前已完成三次握手、等待 accept 的连接都取出来。

## 4. EPOLLONESHOT

### 4.1 它解决什么问题

项目中客户端连接 fd 注册时会加：

```cpp
EPOLLONESHOT
```

作用：

> 某个 fd 上的事件被一个线程处理后，epoll 暂时不再触发这个 fd 的事件，直到重新 `MOD` 注册。

为什么需要它？

因为项目使用线程池。一个客户端 fd 的事件可能被主线程分发给某个工作线程。如果没有 `EPOLLONESHOT`，同一个 fd 的新事件可能又被分发给另一个工作线程，导致两个线程同时处理同一个连接。

这会带来：

1. 读缓冲区竞争。
2. 写缓冲区竞争。
3. HTTP 解析状态错乱。
4. 同一个 socket 被并发读写。

所以 `EPOLLONESHOT` 的意义是：

> 保证同一个连接同一时刻只被一个线程处理。

### 4.2 为什么处理完要 `modfd`

`EPOLLONESHOT` 触发一次后就失效，所以处理完必须重新注册。

项目中：

```cpp
modfd(m_epollfd, m_sockfd, EPOLLIN, m_TRIGMode);
modfd(m_epollfd, m_sockfd, EPOLLOUT, m_TRIGMode);
```

含义：

1. 读完请求并生成响应后，改成监听写事件 `EPOLLOUT`。
2. 写完响应后，如果保持连接，改回监听读事件 `EPOLLIN`。

这就是 HTTP 连接在读写阶段之间切换。

## 5. 定时器模块

### 5.1 定时器解决什么问题

WebServer 中客户端连接不能无限占用资源。

如果客户端连接后长时间不发数据，服务器要主动关闭它，否则会浪费：

1. socket fd。
2. `http_conn` 对象。
3. 定时器节点。
4. epoll 事件表项。

所以项目为每个连接创建一个定时器，长时间无活动就关闭连接。

### 5.2 三个核心结构

#### `client_data`

```cpp
struct client_data {
    sockaddr_in address;
    int sockfd;
    util_timer *timer;
};
```

它保存客户端连接数据，并指向对应定时器。

#### `util_timer`

```cpp
class util_timer {
public:
    time_t expire;
    void (* cb_func)(client_data *);
    client_data *user_data;
    util_timer *prev;
    util_timer *next;
};
```

一个定时器节点包含：

| 成员 | 含义 |
|---|---|
| `expire` | 过期时间点 |
| `cb_func` | 超时后执行的回调函数 |
| `user_data` | 指向客户端数据 |
| `prev/next` | 双向链表指针 |

#### `sort_timer_lst`

它是按 `expire` 升序排列的双向链表。

链表头部永远是最早过期的定时器。

### 5.3 为什么用升序链表

`tick()` 处理到期定时器时，从头节点开始：

```cpp
while (tmp) {
    if (cur < tmp->expire) {
        break;
    }
    ...
}
```

因为链表按过期时间升序排列，只要发现某个节点还没过期，后面的节点一定也没过期，可以直接停止遍历。

优点：实现简单。

缺点：

1. 插入定时器最坏 O(n)。
2. 调整定时器也可能 O(n)。
3. 大规模连接下不如最小堆或时间轮。

### 5.4 新连接如何绑定定时器

`WebServer::timer()` 中：

1. 初始化 `users[connfd]`。
2. 填充 `users_timer[connfd]`。
3. 创建 `util_timer`。
4. 设置 `timer->user_data`。
5. 设置 `timer->cb_func = cb_func`。
6. 设置 `timer->expire = cur + 3 * TIMESLOT`。
7. 插入定时器链表。

这说明一个客户端连接对应：

```text
connfd -> users[connfd] -> users_timer[connfd] -> util_timer
```

### 5.5 活跃连接如何延长定时器

当连接有读写活动时：

```cpp
adjust_timer(timer);
```

内部：

```cpp
timer->expire = cur + 3 * TIMESLOT;
utils.m_timer_lst.adjust_timer(timer);
```

含义：

> 客户端有活动，说明它还活着，把超时时间往后延长。

`sort_timer_lst::adjust_timer()` 只适合“过期时间往后延长”的场景，因为它只判断是否需要向链表后方移动。

### 5.6 超时后如何关闭连接

`tick()` 发现定时器过期后：

```cpp
tmp->cb_func(tmp->user_data);
```

回调函数 `cb_func()` 做三件事：

1. 从 epoll 中删除 fd。
2. `close(sockfd)` 关闭连接。
3. `http_conn::m_user_count--`。

所以定时器真正的作用不是“定时打印日志”，而是清理长期无活动的连接。

### 5.7 `deal_timer()` 的作用

在异常事件或读写失败时：

```cpp
deal_timer(timer, sockfd);
```

它会：

1. 调用定时器回调关闭连接。
2. 从定时器链表中删除对应定时器。

这样连接关闭和定时器删除可以保持一致。

## 6. 信号处理函数

### 6.1 项目中处理了哪些信号

`eventListen()` 中：

```cpp
utils.addsig(SIGPIPE, SIG_IGN);
utils.addsig(SIGALRM, utils.sig_handler, false);
utils.addsig(SIGTERM, utils.sig_handler, false);
```

| 信号 | 含义 | 项目处理 |
|---|---|---|
| `SIGPIPE` | 向已关闭连接写数据 | 忽略，防止服务器进程退出 |
| `SIGALRM` | 定时器信号 | 写入管道，通知主循环处理超时 |
| `SIGTERM` | 终止进程信号 | 写入管道，通知主循环退出 |

### 6.2 为什么信号处理函数不能做复杂逻辑

信号可能在程序执行任意位置打断当前流程。

如果信号处理函数里做复杂操作，比如加锁、写日志、分配内存、调用非安全函数，可能导致死锁或状态错乱。

所以项目把信号处理函数做得很轻：

```cpp
write(u_pipefd[1], &msg, sizeof(msg));
```

它只把信号写入管道，真正的处理交给主循环。

这就是典型的统一事件源思想：

> 把异步信号转换成 epoll 能监听的普通 fd 读事件。

### 6.3 socketpair 的作用

`eventListen()` 中：

```cpp
socketpair(PF_UNIX, SOCK_STREAM, 0, m_pipefd);
```

它创建一对互相连接的本地 socket：

| fd | 作用 |
|---|---|
| `m_pipefd[1]` | 信号处理函数写入信号 |
| `m_pipefd[0]` | 主循环通过 epoll 监听 |

然后：

```cpp
utils.addfd(m_epollfd, m_pipefd[0], false, 0);
```

把管道读端加入 epoll。

信号来了以后，流程是：

```text
SIGALRM / SIGTERM
    -> sig_handler
    -> write(m_pipefd[1])
    -> m_pipefd[0] 变为可读
    -> epoll_wait 返回
    -> dealwithsignal()
```

### 6.4 `dealwithsignal()` 做什么

`dealwithsignal()` 从管道读信号：

```cpp
ret = recv(m_pipefd[0], signals, sizeof(signals), 0);
```

然后根据不同信号设置标志：

| 信号 | 标志 |
|---|---|
| `SIGALRM` | `timeout = true` |
| `SIGTERM` | `stop_server = true` |

主循环后面看到：

```cpp
if (timeout) {
    utils.timer_handler();
    timeout = false;
}
```

所以信号处理函数本身不处理定时器，主循环才处理定时器。

### 6.5 当前代码里可以被面试官追问的细节

#### 细节 1：为什么保存和恢复 `errno`

`sig_handler()` 中：

```cpp
int save_errno = errno;
...
errno = save_errno;
```

原因：信号处理函数可能打断正常代码。如果信号处理过程中改变了 `errno`，被打断的代码恢复执行后可能读到错误的 `errno`。

#### 细节 2：`write` 比 `send` 更适合信号处理函数

`write` 是异步信号安全函数，更适合在信号处理函数中使用。

项目注释里也说明“将 send 替换为 write”。

#### 细节 3：错误分支里 `std::cerr` 和 `strerror()` 不够严谨

当前代码在 `sig_handler()` 的错误分支里用了：

```cpp
std::cerr << ... << strerror(errno)
```

严格来说，`std::cerr` 和 `strerror()` 都不是异步信号安全函数。

面试中如果被问，可以说：

> 生产级代码里信号处理函数应尽量只调用异步信号安全函数。这里正常路径只用 `write`，但错误分支输出日志不够严谨，可以改成记录最小错误状态或直接忽略非关键错误。

#### 细节 4：写入 `int`，读取 `char[]` 不够统一

`sig_handler()` 写入：

```cpp
int msg = sig;
write(u_pipefd[1], &msg, sizeof(msg));
```

`dealwithsignal()` 读取：

```cpp
char signals[1024];
recv(..., signals, ...);
```

这在小端机器上通常能工作，因为第一个字节就是信号值，但类型不统一，不够严谨。

更规范的做法是：

1. 要么写 `char msg = sig`，读 `char[]`。
2. 要么写 `int msg`，按 `int[]` 读取和解析。

这个点很适合作为面试中的“代码审查题”。

## 7. `Utils::timer_handler()` 和 alarm

`timer_handler()` 做三件事：

1. 临时阻塞 `SIGALRM`。
2. 调用 `m_timer_lst.tick()` 处理到期定时器。
3. 再次调用 `alarm(m_TIMESLOT)` 设置下一次定时信号。

核心代码：

```cpp
m_timer_lst.tick();
alarm(m_TIMESLOT);
```

为什么要重新 `alarm`？

因为 `alarm()` 只触发一次。想周期性触发，必须每次处理完后重新设置。

为什么临时阻塞 `SIGALRM`？

为了避免正在处理定时器链表时再次被 `SIGALRM` 打断，造成定时器链表操作重入。

## 8. `WebServer::eventListen()`

这个函数是网络初始化核心。

### 8.1 socket 创建

```cpp
m_listenfd = socket(PF_INET, SOCK_STREAM, 0);
```

含义：

| 参数 | 含义 |
|---|---|
| `PF_INET` | IPv4 |
| `SOCK_STREAM` | TCP 字节流 |
| `0` | 默认协议，即 TCP |

### 8.2 SO_LINGER

```cpp
setsockopt(m_listenfd, SOL_SOCKET, SO_LINGER, &tmp, sizeof(tmp));
```

控制 `close(socket)` 时如何处理未发送完的数据。

面试中重点不是背结构体，而是说清楚：

> 它影响 socket 关闭时是立即丢弃，还是等待数据发送/关闭过程。

### 8.3 SO_REUSEADDR

```cpp
setsockopt(m_listenfd, SOL_SOCKET, SO_REUSEADDR, &flag, sizeof(flag));
```

作用：允许地址端口快速复用。

常见场景：服务器刚关闭，端口还处于 `TIME_WAIT` 相关状态，如果不设置，马上重启可能 bind 失败。

### 8.4 bind / listen

```cpp
bind(m_listenfd, ...);
listen(m_listenfd, 5);
```

`bind`：把 socket 绑定到 IP 和端口。

`listen`：把 socket 变成监听 socket，开始接收连接。

`listen` 的 backlog 不是“最大客户端数量”，而是已完成连接队列的长度参数。高并发下通常要调大。

### 8.5 注册监听 fd 到 epoll

```cpp
utils.addfd(m_epollfd, m_listenfd, false, m_LISTENTrigmode);
```

监听 socket 的可读事件表示：有新客户端连接可以 `accept`。

## 9. `WebServer::eventLoop()`

`eventLoop()` 是整个服务器的主循环。

逻辑可以背成：

```text
while 服务器不停止:
    epoll_wait 等事件
    遍历每个事件:
        如果是监听 fd：处理新连接
        如果是异常关闭：关闭连接并删定时器
        如果是信号管道：读信号，设置 timeout/stop_server
        如果是客户端读事件：处理读
        如果是客户端写事件：处理写
    如果 timeout：处理到期定时器
```

对应代码中的分支：

| 条件 | 处理 |
|---|---|
| `sockfd == m_listenfd` | `dealclientdata()` |
| `EPOLLRDHUP \| EPOLLHUP \| EPOLLERR` | `deal_timer()` |
| `sockfd == m_pipefd[0] && EPOLLIN` | `dealwithsignal()` |
| `EPOLLIN` | `dealwithread()` |
| `EPOLLOUT` | `dealwithwrite()` |

注意这个函数不直接解析 HTTP，也不直接操作数据库。它负责事件分发。

## 10. `dealclientdata()`：接收新连接

这个函数根据监听 socket 的触发模式分两种：

### 10.1 LT 模式

```cpp
int connfd = accept(...);
timer(connfd, client_address);
```

一次事件 accept 一个连接。

### 10.2 ET 模式

```cpp
while (1) {
    int connfd = accept(...);
    ...
    timer(connfd, client_address);
}
```

一次事件循环 accept 多个连接，直到没有更多连接。

### 10.3 新连接为什么立刻创建定时器

新连接建立后：

```cpp
timer(connfd, client_address);
```

这不仅初始化 `http_conn`，还给这个连接创建了超时定时器。

所以连接生命周期从进入服务器开始，就被定时器管理。

## 11. `dealwithread()` 和 `dealwithwrite()`

这两个函数是 Reactor/Proactor 的交界点。

### 11.1 Reactor 模式

在 Reactor 模式下，主线程只负责把事件扔给线程池：

```cpp
m_pool->append(users + sockfd, 0); // 读事件
m_pool->append(users + sockfd, 1); // 写事件
```

工作线程自己执行 `read_once()`、`write()` 或 `process()`。

当前代码中主线程会忙等：

```cpp
while (true) {
    if (1 == users[sockfd].improv) {
        ...
        break;
    }
}
```

这个设计可以让主线程等工作线程处理结果，但缺点是主线程可能被忙等占住，降低事件循环效率。面试被问到时要能指出这一点。

### 11.2 Proactor 模式

在 Proactor 模式下：

读事件：

```cpp
if (users[sockfd].read_once()) {
    m_pool->append_p(users + sockfd);
}
```

主线程先完成读，再把业务处理交给线程池。

写事件：

```cpp
if (users[sockfd].write()) {
    adjust_timer(timer);
}
```

主线程自己完成写。

### 11.3 活跃连接为什么要调整定时器

读写成功都说明这个连接仍然活跃，所以会：

```cpp
adjust_timer(timer);
```

把超时时间往后延长，避免活跃连接被误杀。

## 12. `http_conn` 中的 epoll 事件切换

### 12.1 注册连接 fd

`http_conn::init()` 中：

```cpp
addfd(m_epollfd, sockfd, true, m_TRIGMode);
```

这里 `one_shot = true`，说明客户端连接需要 `EPOLLONESHOT` 保护。

### 12.2 写完后切回读事件

`http_conn::write()` 中，如果发送完成：

```cpp
modfd(m_epollfd, m_sockfd, EPOLLIN, m_TRIGMode);
```

说明下次继续等客户端请求。

### 12.3 写不完时继续等写事件

如果发送缓冲区暂时不可写：

```cpp
if (errno == EAGAIN) {
    modfd(m_epollfd, m_sockfd, EPOLLOUT, m_TRIGMode);
    return true;
}
```

说明响应还没发完，等 socket 下次可写再继续。

### 12.4 处理完请求后切到写事件

`process()` 最后：

```cpp
modfd(m_epollfd, m_sockfd, EPOLLOUT, m_TRIGMode);
```

说明已经生成响应，下一步要等 socket 可写，把响应发出去。

## 13. 这几天最有价值的坑

### 坑 1：epoll 只负责通知，不负责处理

很多初学者会把 epoll 理解成“高性能处理请求”。准确说，epoll 只告诉你哪些 fd 就绪。真正处理请求的是 `WebServer::eventLoop()`、`http_conn` 和线程池。

### 坑 2：ET 模式必须非阻塞并循环读

ET 只通知一次，如果不循环读到 `EAGAIN`，可能把数据留在缓冲区里却再也收不到通知。

### 坑 3：监听 fd 和连接 fd 可以用不同触发模式

项目中 `TRIGMode` 同时控制 `m_LISTENTrigmode` 和 `m_CONNTrigmode`，不要把它们混成一个概念。

### 坑 4：`EPOLLONESHOT` 之后必须重新 `modfd`

否则 fd 只触发一次，后续事件不会再被处理。

### 坑 5：信号处理函数不能做复杂事

正常路径最好只做 `write` 这类异步信号安全操作。日志、锁、内存分配、复杂输出都不适合放在信号处理函数里。

### 坑 6：信号管道是为了统一事件源

`SIGALRM` 不是直接在信号处理函数中清理定时器，而是写入管道，让 epoll 主循环处理。

### 坑 7：升序链表定时器简单但不是最高性能

插入和调整最坏 O(n)。连接数很大时，可以讨论最小堆、时间轮。

### 坑 8：Reactor 分支中的忙等会拖慢主循环

`while(true)` 等 `improv` 会让主线程卡在一个连接上。面试时如果被问优化点，可以指出这里可以用更合理的通知机制或彻底异步化。

### 坑 9：`int` 信号写入、`char[]` 读取不够严谨

当前实现通常能工作，但类型语义不统一。更好做法是统一写读 `char` 或统一写读 `int`。

### 坑 10：定时器回调关闭 fd 后要同步清理 epoll 和用户计数

超时连接不是只 `close(fd)`，还要从 epoll 删除 fd，并维护 `http_conn::m_user_count`。

## 14. 面试拷问点

### 14.1 epoll 基础

**Q1：epoll 是什么？**

答题方向：epoll 是 Linux 的 I/O 多路复用机制。它让一个线程可以同时监听大量 fd，内核负责通知哪些 fd 就绪，应用层再处理这些事件。

**Q2：epoll 的三个核心 API 是什么？**

答题方向：`epoll_create` 创建 epoll 实例，`epoll_ctl` 增删改监听 fd，`epoll_wait` 等待就绪事件。

**Q3：epoll_wait 返回后，返回的是什么？**

答题方向：返回就绪事件数量，事件数组中包含就绪 fd 和对应事件类型。不是返回所有 fd。

**Q4：epoll 为什么比简单轮询高效？**

答题方向：应用不需要反复遍历所有 fd 检查状态，而是由内核维护事件并返回就绪 fd，尤其适合大量连接但活跃连接较少的场景。

**Q5：epoll 是同步还是异步？**

答题方向：从编程模型看，`epoll_wait` 是同步等待就绪事件；它不是异步 IO。真正的数据读写仍然由应用调用 `recv/send/writev` 完成。

### 14.2 LT / ET

**Q6：LT 和 ET 的区别是什么？**

答题方向：LT 只要 fd 仍然可读/可写就会持续通知；ET 只在状态变化时通知一次。ET 要求非阻塞并循环读到 `EAGAIN`。

**Q7：为什么 ET 模式下必须把数据读完？**

答题方向：因为 ET 不会因为缓冲区里还有旧数据而反复通知。如果不读完，剩余数据可能长期留在内核缓冲区。

**Q8：为什么 ET 必须配合非阻塞 IO？**

答题方向：循环读到没有数据时，如果 fd 是阻塞的，线程会卡住；非阻塞 fd 会返回 `EAGAIN`，让循环退出。

**Q9：项目里监听 socket 的 ET 是怎么处理的？**

答题方向：`dealclientdata()` 中 ET 分支用 `while` 循环 `accept`，一次性接收当前所有就绪的新连接。

**Q10：项目里连接 socket 的 ET 是怎么处理的？**

答题方向：`http_conn::read_once()` 的 ET 分支循环 `recv`，直到 `EAGAIN` 或 `EWOULDBLOCK`。

### 14.3 EPOLLONESHOT

**Q11：EPOLLONESHOT 的作用是什么？**

答题方向：保证一个 fd 的事件同一时刻只被一个线程处理。触发一次后该 fd 暂时失效，需要 `epoll_ctl MOD` 重新激活。

**Q12：为什么线程池服务器常用 EPOLLONESHOT？**

答题方向：防止多个工作线程同时处理同一个连接 fd，避免读写缓冲区和 HTTP 状态机竞争。

**Q13：为什么 `modfd()` 中要重新加 EPOLLONESHOT？**

答题方向：因为一次触发后需要重新注册关注事件，否则后续读写事件不会再通知。

### 14.4 信号处理

**Q14：为什么信号处理函数不直接处理定时器？**

答题方向：信号处理函数执行环境特殊，不能做复杂逻辑。项目通过管道把信号转成 epoll 事件，由主循环处理。

**Q15：socketpair 在项目里有什么作用？**

答题方向：创建一对本地通信 fd。信号处理函数写一端，epoll 监听另一端，从而把信号纳入事件循环。

**Q16：为什么信号处理函数里要保存 errno？**

答题方向：信号可能打断正常系统调用，处理过程中可能改变 errno。恢复 errno 可以避免影响被打断代码的错误判断。

**Q17：SIGPIPE 为什么要忽略？**

答题方向：客户端异常关闭后，服务器继续写 socket 可能触发 SIGPIPE。默认行为是终止进程，服务器必须忽略它。

**Q18：当前信号处理函数有什么不够严谨的地方？**

答题方向：错误分支使用 `std::cerr` 和 `strerror()` 不属于异步信号安全；另外写入 `int`、读取 `char[]` 类型不统一。

### 14.5 定时器

**Q19：定时器在 WebServer 中解决什么问题？**

答题方向：清理长期不活跃连接，释放 fd、epoll 表项、HTTP 连接对象和用户计数。

**Q20：项目中的定时器数据结构是什么？**

答题方向：按过期时间升序排列的双向链表，节点是 `util_timer`，每个节点绑定一个 `client_data`。

**Q21：为什么 `tick()` 可以遇到未过期节点就停止？**

答题方向：链表按过期时间升序排列，当前节点未过期，后面节点的过期时间更晚，也不会过期。

**Q22：升序链表定时器的优缺点是什么？**

答题方向：实现简单，处理到期定时器高效；但插入和调整可能 O(n)，大量连接时性能不如最小堆或时间轮。

**Q23：连接有活动时为什么要调整定时器？**

答题方向：读写成功说明连接仍活跃，需要把过期时间往后延长，避免误关闭。

**Q24：定时器回调函数做了什么？**

答题方向：从 epoll 删除 fd，关闭 socket，减少在线用户计数。

### 14.6 WebServer 主流程

**Q25：`eventListen()` 主要做什么？**

答题方向：创建监听 socket，设置 socket 选项，bind/listen，创建 epoll，注册监听 fd，创建信号管道，注册信号，启动 alarm。

**Q26：`eventLoop()` 的事件分发逻辑是什么？**

答题方向：`epoll_wait` 等事件；监听 fd 处理新连接；异常事件关闭连接；信号管道处理信号；`EPOLLIN` 处理读；`EPOLLOUT` 处理写；最后处理 timeout 定时任务。

**Q27：Reactor 和 Proactor 在项目里的区别是什么？**

答题方向：Reactor 下主线程把读写事件交给线程池，工作线程负责 IO 和业务；Proactor 下主线程先完成 IO，再把业务处理交给线程池。

**Q28：为什么 `dealwithread()` / `dealwithwrite()` 要调整定时器？**

答题方向：说明连接有活动，应延长生命周期。

**Q29：为什么 `http_conn::process()` 处理完后要切换到 EPOLLOUT？**

答题方向：请求已经解析并生成响应，下一步要等 socket 可写，把响应发送给客户端。

**Q30：`write()` 里遇到 `EAGAIN` 为什么要继续监听 EPOLLOUT？**

答题方向：说明发送缓冲区暂时不可写，响应还没发完，需要等下次可写继续发送。

## 15. 可以背下来的整体回答

这个项目的主线程通过 epoll 管理所有事件。启动时先创建监听 socket，把监听 fd 注册到 epoll，再用 socketpair 创建信号管道，把 `SIGALRM` 和 `SIGTERM` 这类信号转成管道可读事件。每个客户端连接建立后，会创建一个定时器节点并加入按过期时间排序的双向链表。主循环中 `epoll_wait` 返回后，服务器根据 fd 和事件类型分发：监听 fd 负责 accept 新连接，客户端 fd 的 `EPOLLIN/EPOLLOUT` 负责读写处理，管道 fd 负责处理信号。定时器由 `alarm` 周期性触发，信号进入管道后由主循环调用 `timer_handler()`，最终 `tick()` 清理超时连接。LT 模式会反复通知未处理完的事件，ET 模式只通知状态变化，所以 ET 必须配合非阻塞 IO 并循环读到 `EAGAIN`。项目还使用 `EPOLLONESHOT` 保证同一个连接不会被多个线程同时处理。

## 16. 复习顺序

建议按这个顺序复习：

1. `webserver.cpp::eventListen()`：看服务器如何创建 socket、epoll、管道、信号。
2. `webserver.cpp::eventLoop()`：看所有事件如何分发。
3. `timer/lst_timer.h`：看定时器三类结构：`client_data`、`util_timer`、`sort_timer_lst`。
4. `timer/lst_timer.cpp::tick()`：看超时连接如何被清理。
5. `timer/lst_timer.cpp::sig_handler()` 和 `dealwithsignal()`：看信号如何转成 epoll 事件。
6. `http/http_conn.cpp::addfd/modfd/read_once/write()`：看 fd 如何注册、重置和切换读写事件。
7. `config.cpp` 和 `WebServer::trig_mode()`：看触发模式参数如何影响 listenfd 和 connfd。

复习时抓住四个问题：

1. 这个 fd 是谁创建的？
2. 它注册到了哪个 epoll 实例？
3. 它触发事件后由哪个函数处理？
4. 如果连接长时间不活跃，谁负责把它关闭？

这四个问题能把 epoll、信号处理、定时器和 `WebServer` 主循环全部串起来。
