# WebServer 项目求职掌握路线与综合复盘

> 这份文档专门回答一个问题：学完这个 WebServer 项目后，面向求职，你到底要掌握什么、能体现什么能力、需不需要完整手敲复刻。

## 1. 先给结论

你不需要把这个项目达到“完全脱稿手敲复刻”的程度。

更准确的目标是：

1. 能把项目架构完整讲清楚。
2. 能把一次 HTTP 请求在项目里的流转讲清楚。
3. 能解释每个核心模块为什么存在。
4. 能回答关键技术点的面试追问。
5. 能指出项目中的几个真实不足，并说出改进方向。
6. 能在源码里定位问题、做小范围修改。

对求职而言，面试官通常不要求你现场完整手写一个 WebServer。真正考察的是：

> 你是不是理解 Linux 网络编程、并发模型、资源管理、HTTP 协议解析、项目架构拆分，以及你有没有独立读懂复杂 C++ 工程的能力。

如果你只是背“我用了 epoll、线程池、连接池”，价值不大。

如果你能讲清楚“一个请求从 accept 到 writev 返回浏览器，期间每个模块怎么协作”，这个项目才真正变成你的项目。

## 2. 你现在觉得懵，是正常的

这个项目对初学者难，不是因为单个语法特别高级，而是因为它同时叠了很多层：

```text
Linux 系统调用
    socket / bind / listen / accept / recv / writev / mmap / epoll_ctl

C 风格字符串和缓冲区
    char* / char[] / strcpy / strncpy / strlen / strstr / strpbrk

C++ 封装
    类 / 静态成员 / 析构 / RAII / 模板线程池

并发
    pthread / mutex / semaphore / detached thread / EPOLLONESHOT

网络模型
    epoll / LT / ET / Reactor / Proactor

HTTP 协议
    请求行 / 请求头 / 请求体 / 状态码 / keep-alive

数据库
    MySQL C API / 连接池 / 登录注册

定时器
    alarm / SIGALRM / socketpair / 升序链表
```

你不是只在学一个 cpp 文件，而是在同时补操作系统、网络、C++、并发、数据库、HTTP。感到“懵懵懂懂”是符合学习规律的。

接下来不要再用“我能不能完整手敲”衡量自己，而应该用“我能不能画出三张图”衡量自己。

## 3. 你必须掌握的三张图

### 3.1 启动图

```text
main.cpp
    -> Config::parse_arg()
    -> WebServer::init()
    -> log_write()
    -> sql_pool()
    -> thread_pool()
    -> trig_mode()
    -> eventListen()
    -> eventLoop()
```

这张图回答：

> 服务器是怎么从 main 函数启动起来的？

你要能说出：

- 日志为什么先初始化。
- 数据库连接池为什么在线程池之前初始化。
- `trig_mode()` 为什么要在 `eventListen()` 之前。
- `eventListen()` 做 socket、epoll、信号管道初始化。
- `eventLoop()` 是服务器真正跑起来的地方。

### 3.2 请求图

```text
客户端连接
    -> epoll 检测到 m_listenfd 可读
    -> accept 得到 connfd
    -> users[connfd].init()
    -> 注册 connfd 到 epoll
    -> 绑定定时器

客户端发送 HTTP 请求
    -> EPOLLIN
    -> read_once()
    -> process()
    -> process_read()
    -> do_request()
    -> process_write()
    -> EPOLLOUT
    -> write()
    -> 长连接继续监听 / 短连接关闭
```

这张图回答：

> 一次浏览器请求在项目里怎么走？

这是面试最重要的一张图。

### 3.3 资源图

```text
socket fd
    -> epoll 管理
    -> http_conn 保存状态
    -> timer 管超时

MYSQL*
    -> connection_pool 拥有
    -> connectionRAII 临时借用
    -> 用完自动归还

日志消息
    -> Log 接收
    -> 同步写 / 异步阻塞队列

线程任务
    -> WebServer 投递
    -> threadpool 队列
    -> worker 取出执行
```

这张图回答：

> 项目里的资源分别由谁管理，生命周期如何结束？

这个问题非常关键，因为 C++ 项目最能体现能力的地方，往往不是功能写出来，而是资源不泄漏、并发不乱、生命周期说得清。

## 4. 这个项目到底体现哪些 C++ 能力

它不是一个展示“现代 C++ 语法糖”的项目。

它体现的是“系统方向 C++”能力。

### 4.1 Linux 网络编程能力

你能证明自己接触过：

- socket 编程基本流程：`socket -> bind -> listen -> accept`
- 非阻塞 IO：`fcntl` 设置 `O_NONBLOCK`
- IO 多路复用：`epoll_create`、`epoll_ctl`、`epoll_wait`
- LT/ET 触发方式
- `EPOLLONESHOT` 防止同一连接被多线程并发处理
- `EPOLLRDHUP` 检测对端关闭

这对 C++ 后端、基础架构、服务端开发是有价值的。

### 4.2 并发编程能力

你能证明自己理解：

- 线程池为什么存在。
- 任务队列为什么要加锁。
- 信号量为什么能让工作线程睡眠等待任务。
- Reactor 和 Proactor 模型怎么分工。
- 为什么不能让多个线程同时处理同一个 socket。
- detached 线程有什么生命周期隐患。

### 4.3 资源管理能力

项目里有很多资源：

- socket fd
- epoll fd
- pipe fd
- MYSQL 连接
- mmap 映射
- 日志文件句柄
- 线程
- 动态分配数组

你能讲清楚：

- 哪些资源必须 close。
- 哪些资源必须 `delete[]`。
- 哪些资源必须 `free`。
- 哪些资源用 RAII 自动释放。
- 哪些资源归连接池所有，业务只是借用。

这就是 C++ 项目非常核心的能力。

### 4.4 协议解析能力

`http_conn` 体现了：

- HTTP 请求行解析。
- HTTP 请求头解析。
- POST 请求体解析。
- 有限状态机设计。
- 长连接处理。
- 状态码响应。

这说明你不是只会写业务 CRUD，而是读过协议层代码。

### 4.5 性能意识

项目里有几个典型性能点：

- epoll 支持高并发连接。
- 线程池避免频繁创建线程。
- 数据库连接池避免频繁连接 MySQL。
- 异步日志减少业务线程磁盘阻塞。
- `mmap + writev` 减少文件发送开销。
- 定时器清理空闲连接，避免资源被长期占用。

求职时这可以体现：

> 我不仅能写功能，也能理解服务端程序为什么要做资源复用和 IO 优化。

## 5. 这个项目不能夸大的地方

你也要清醒：这个项目不是大型工业级 WebServer。

它的定位更像“教学型高性能服务器项目”。

不能过度包装成：

- 支持完整 HTTP 协议。
- 支持复杂路由。
- 支持 HTTPS。
- 支持高可靠生产部署。
- 支持完整异步 IO。
- 支持优雅停机和完整线程回收。

正确说法是：

> 这是一个基于 Linux epoll 的轻量级 HTTP 服务器，实现了静态资源访问、登录注册、线程池、连接池、定时器和日志模块。它覆盖了服务端开发中比较核心的系统编程知识点。

这种说法稳，不虚。

## 6. 需要掌握到什么程度

可以分五层。

### 第一层：能跑通

知道：

- 怎么配置数据库。
- 怎么编译运行。
- 访问哪个端口。
- root 目录下有哪些页面。

这一层只是入门，不够面试。

### 第二层：能画模块图

能说出：

```text
main/config
    -> WebServer
    -> epoll
    -> http_conn
    -> threadpool
    -> connection_pool
    -> timer
    -> log
```

这一层能说明你不再只盯着单个文件。

### 第三层：能讲一次请求流程

这是面试核心。

你要能不看代码讲：

```text
accept 新连接
    -> 初始化 http_conn 和 timer
    -> epoll 监听读事件
    -> read_once 读取请求
    -> process_read 状态机解析
    -> do_request 处理文件或登录注册
    -> process_write 生成响应
    -> writev 发送响应
    -> 长连接复用或关闭
```

达到这一层，项目就已经能讲了。

### 第四层：能解释关键机制

至少要能解释：

- epoll 为什么高效。
- LT 和 ET 的区别。
- ET 为什么必须非阻塞循环读。
- EPOLLONESHOT 为什么必要。
- Reactor / Proactor 在这个项目里怎么体现。
- 线程池为什么要用任务队列和信号量。
- 连接池为什么不能用 `shared_ptr<MYSQL>` 表达共享拥有。
- 定时器为什么用信号管道统一事件源。
- HTTP 状态机如何解析请求。
- `mmap + writev` 为什么能优化静态文件发送。

达到这一层，你可以比较从容地面对项目追问。

### 第五层：能指出问题并改进

这是真正能拉开差距的地方。

你能说：

- Reactor 分支自旋等待 `improv` 会浪费 CPU。
- detached 线程池不利于优雅退出。
- 定时器链表在大规模连接下调整成本较高。
- `http_conn::init()` 中触发模式赋值顺序有隐患。
- `process_write(BAD_REQUEST)` 返回 404 语义不严谨。
- 全局用户 map 的并发读写保护不完整。
- C 风格字符串和固定缓冲区存在越界风险。
- 信号处理函数里不能做非异步信号安全操作。

这说明你不是只会背项目，而是真的审视过代码。

## 7. 不需要完整手敲复刻

你不需要做到：

- 不看资料手写所有 `epoll_ctl` 参数。
- 背出 `mysql_real_connect` 的 8 个参数。
- 背出 `strpbrk`、`strspn`、`strcasecmp` 的所有细节。
- 手写完整 HTTP 状态机。
- 手写完整线程池模板。
- 手写完整连接池和日志系统。

初学阶段更应该做到：

1. 知道每个系统调用是干什么的。
2. 知道它在项目哪个阶段被调用。
3. 知道失败时大概会发生什么。
4. 知道哪些函数必须成对使用，比如 `mmap/munmap`、`open/close`、`lock/unlock`、`new/delete`。
5. 能照着已有代码改一个小功能或修一个小 bug。

真正工作中也不是靠背 API 写代码，而是靠理解模型、会查文档、会定位问题、会控制资源生命周期。

## 8. 求职时怎么介绍这个项目

### 8.1 简历写法

可以写成：

```text
基于 Linux epoll 实现轻量级 HTTP WebServer，支持静态资源访问、GET/POST 请求解析、登录注册、MySQL 连接池、线程池、定时器超时清理和同步/异步日志。
负责阅读和梳理核心模块，包括 WebServer 事件循环、http_conn HTTP 状态机、线程池任务调度、数据库连接 RAII 借还、定时器信号管道机制，并针对部分资源管理和并发隐患进行分析与修正。
```

如果你想更偏工程能力，可以写：

```text
深入分析项目中 epoll LT/ET、EPOLLONESHOT、Reactor/Proactor、mmap/writev、连接池 RAII、定时器链表等机制，能够完整说明一次 HTTP 请求从 accept 到响应发送的完整链路，并识别线程退出、连接借用、状态码、触发模式等实现隐患。
```

不要写成：

```text
独立开发高性能 WebServer，支持千万级并发。
```

这种容易被问穿。

### 8.2 一分钟项目介绍

可以这样讲：

> 这个项目是一个基于 Linux epoll 的轻量级 HTTP 服务器。主线程通过 epoll 统一监听监听 socket、客户端 socket、信号管道和异常事件；新连接到来后用 `http_conn` 对象保存连接状态，并绑定定时器；读事件到来后根据配置选择 Reactor 或模拟 Proactor 模型，把请求交给线程池处理。`http_conn` 内部用主从状态机解析 HTTP 请求，通过 `do_request` 处理静态资源和登录注册，成功的静态文件响应使用 `mmap + writev` 发送。数据库连接通过连接池和 RAII 临时借用，日志支持同步和异步模式，超时连接通过 `SIGALRM + socketpair + 定时器链表` 清理。

这段话背熟，比背代码有用。

## 9. 面试官会怎么追问

### 9.1 架构追问

问题：

> 你这个项目的整体架构是什么？

回答方向：

> 主线程负责 epoll 事件监听和分发，`http_conn` 负责单连接 HTTP 状态机，线程池负责并发处理任务，连接池负责 MySQL 连接复用，定时器负责超时连接清理，日志模块负责运行记录。

### 9.2 请求流程追问

问题：

> 浏览器发起一次请求，项目内部怎么处理？

回答方向：

```text
listenfd 可读
    -> accept
    -> http_conn::init
    -> addfd 注册 EPOLLIN
    -> read_once
    -> process_read
    -> do_request
    -> process_write
    -> modfd EPOLLOUT
    -> writev
```

### 9.3 epoll 追问

问题：

> 为什么用 epoll，不用 select？

回答方向：

- `select` 每次要拷贝 fd 集合，并线性扫描。
- `epoll` 在内核维护事件表，只返回就绪事件。
- 对大量连接更适合。

不要把话说绝对成“epoll 一定比 select 快”。更严谨的说法是：

> 在大量 fd、活跃连接比例较低的服务器场景下，epoll 更适合。

### 9.4 LT/ET 追问

问题：

> LT 和 ET 有什么区别？

回答方向：

- LT：只要数据没处理完就会持续提醒。
- ET：只在状态变化时提醒一次。
- ET 必须非阻塞，并循环读到 `EAGAIN`。

### 9.5 Reactor/Proactor 追问

问题：

> 你项目里 Reactor 和 Proactor 怎么体现？

回答方向：

- Reactor：主线程只负责事件分发，工作线程执行 `read_once/write/process`。
- Proactor：主线程先完成 IO 读写，再把业务处理交给线程池。
- Linux 下这里是模拟 Proactor，不是真正内核异步 IO。

### 9.6 线程池追问

问题：

> 为什么要用线程池？

回答方向：

- 避免每个请求都创建和销毁线程。
- 控制并发线程数量。
- 主线程专注事件分发，工作线程处理耗时任务。
- 任务队列 + 信号量构成生产者消费者模型。

### 9.7 连接池追问

问题：

> 数据库连接池为什么不能简单用 `shared_ptr`？

回答方向：

> 连接池的语义是独占借用，不是共享拥有。同一条 MySQL 连接同一时刻只能被一个线程使用。`shared_ptr` 可能让连接归还池子后外部仍然持有有效指针，导致两个线程并发使用同一条连接。

### 9.8 定时器追问

问题：

> 超时连接怎么处理？

回答方向：

- 每个连接绑定一个定时器。
- 有读写活动就刷新过期时间。
- `SIGALRM` 周期触发。
- 信号处理函数写管道。
- 主循环通过 epoll 读管道事件。
- 调用定时器链表 `tick()` 清理过期连接。

### 9.9 HTTP 状态机追问

问题：

> HTTP 请求怎么解析？

回答方向：

- `parse_line()` 从状态机逐行切分。
- `process_read()` 主状态机按请求行、请求头、请求体推进。
- 请求完整后调用 `do_request()`。
- 响应由 `process_write()` 生成。

### 9.10 性能优化追问

问题：

> 项目有哪些性能优化？

回答方向：

- epoll 多路复用。
- 非阻塞 IO。
- 线程池复用线程。
- 数据库连接池复用连接。
- 异步日志减少阻塞。
- `mmap + writev` 发送静态文件。
- 定时器清理空闲连接。

## 10. 面试时最应该主动讲的亮点

你可以主动强调这几个点。

### 10.1 统一事件源

信号本来是异步事件，项目通过 `socketpair` 把信号转成管道可读事件，让 epoll 统一处理。

这比“我用了信号”更有水平。

### 10.2 单连接状态封装

`http_conn` 把每个连接的读缓冲区、解析状态、响应状态都封装在对象里。

这体现了 C++ 封装和状态管理。

### 10.3 RAII 的资源安全

数据库连接借用通过 `connectionRAII` 管理，锁通过 `locker_guard` 管理。

这体现了 C++ 和 C 风格系统资源结合时的工程意识。

### 10.4 能指出项目不足

主动讲一两个不足，会比只讲优点更可信。

比如：

> 这个项目的线程池使用 detached 线程，退出时不能 join，优雅停机不够完整；Reactor 分支里主线程自旋等待工作线程处理结果，也会浪费 CPU。这些是我后续会优先改进的点。

这说明你真的读过。

## 11. 你应该掌握的 10 个函数

不需要全部手写，但这 10 个必须知道职责。

| 函数 | 必须会说什么 |
| --- | --- |
| `WebServer::eventListen()` | socket、epoll、信号管道初始化 |
| `WebServer::eventLoop()` | 主事件循环和事件分发 |
| `WebServer::dealwithread()` | 根据 Reactor/Proactor 处理读事件 |
| `threadpool::run()` | 工作线程如何取任务并处理 |
| `http_conn::read_once()` | LT/ET 模式下如何读取 socket |
| `http_conn::process_read()` | HTTP 主状态机 |
| `http_conn::do_request()` | 静态文件和登录注册业务 |
| `http_conn::process_write()` | 生成 HTTP 响应 |
| `http_conn::write()` | `writev` 发送响应 |
| `connectionRAII::~connectionRAII()` | 自动归还数据库连接 |

如果只能背一个流程，就背：

```text
eventLoop -> dealwithread -> read_once -> process -> process_read -> do_request -> process_write -> dealwithwrite -> write
```

## 12. 你需要补的语法，不要一次性全补

你现在的语法不熟，主要集中在四类。

### 12.1 C 字符串和指针

需要补：

- `char*` 和 `char[]`
- `strlen`
- `strcpy`
- `strncpy`
- `strcat`
- `strchr`
- `strrchr`
- `strstr`
- `strpbrk`
- `strspn`
- `strcasecmp`

学习目标不是背函数，而是理解：

> 这些函数都在操作一段以 `\0` 结尾的内存。

### 12.2 Linux fd 和系统调用

需要补：

- fd 是什么。
- socket fd、epoll fd、pipe fd 都是文件描述符。
- 为什么要 close。
- `errno` 怎么看。
- 非阻塞系统调用为什么会返回 `EAGAIN`。

### 12.3 线程和同步

需要补：

- `pthread_create`
- `pthread_detach`
- 互斥锁
- 信号量
- 条件变量
- RAII 锁守卫

学习目标：

> 能区分“保护共享数据用锁”和“通知任务数量用信号量”。

### 12.4 C++ 类和对象生命周期

需要补：

- 构造函数和析构函数。
- 静态成员变量。
- 拷贝控制。
- 模板类为什么写在头文件。
- RAII 是什么。

## 13. 一条可执行的复习路线

### 第 1 天：只画总图

目标：不看代码，画出模块关系。

输出：

```text
main -> WebServer -> epoll -> http_conn -> threadpool -> connection_pool -> timer -> log
```

### 第 2 天：只讲一次请求

目标：能讲 3 分钟请求流程。

不要管每个系统调用细节，只管链路。

### 第 3 天：专攻 epoll

目标：

- 知道 addfd、modfd、removefd。
- 知道 LT/ET。
- 知道 EPOLLONESHOT。
- 知道 EPOLLIN/EPOLLOUT 怎么切换。

### 第 4 天：专攻 `http_conn`

目标：

- 能说出读缓冲区 3 个下标。
- 能说出主从状态机。
- 能说出 `mmap + writev`。

### 第 5 天：专攻线程池和连接池

目标：

- 能讲生产者消费者。
- 能讲 RAII 借还连接。
- 能讲为什么一条 MySQL 连接同一时间只能一个线程用。

### 第 6 天：专攻定时器和信号

目标：

- 能讲 `SIGALRM -> pipe -> epoll -> timer_handler`。
- 能讲为什么信号处理函数不能做复杂逻辑。

### 第 7 天：模拟面试

目标：

- 1 分钟介绍项目。
- 3 分钟讲请求流程。
- 回答 10 个追问。
- 主动讲 2 个不足和改进。

## 14. 怎么判断你真的掌握了

你可以用下面问题自测。

如果你能不看代码回答 80%，就可以写进简历并准备面试。

1. `WebServer` 和 `http_conn` 的职责边界是什么？
2. 新连接进来后，哪个函数创建 `http_conn` 和定时器绑定？
3. `read_once()` 在 Reactor 和 Proactor 中分别由谁调用？
4. `process()` 为什么最后要 `modfd(..., EPOLLOUT, ...)`？
5. `parse_line()` 为什么要把 `\r\n` 改成 `\0\0`？
6. `process_read()` 的三个状态是什么？
7. POST 登录注册时，请求体从哪里来？
8. `do_request()` 如何把 URL 映射成本地文件？
9. `mmap` 映射后的内存什么时候释放？
10. `write()` 遇到 `EAGAIN` 为什么不关闭连接？
11. 长连接发送完后为什么调用 `init()`？
12. `EPOLLONESHOT` 如果不重新 `modfd` 会怎样？
13. 连接池的连接归还时为什么要把外部 `MYSQL*` 置空？
14. 定时器回调如何找到要关闭的 socket？
15. 这个项目最明显的三个不足是什么？

## 15. 推荐你最终形成的表达

你不是要证明“我能背下整套代码”。

你要证明：

> 我能读懂一个 Linux C++ 服务端项目，能把复杂工程拆成网络监听、事件分发、连接状态、线程池、连接池、日志、定时器几个模块；能说明一次请求的完整路径；能理解其中的资源管理、并发控制和性能优化；也能识别其中的工程隐患并给出改进方向。

这就是这个项目对求职的价值。

## 16. 最后给你的学习建议

你现在不应该继续死磕“每一行语法都完全熟练”。

更好的学习方式是：

1. 先背项目结构，不背代码。
2. 再背请求流程，不背 API 参数。
3. 再挑关键函数逐个看。
4. 每看一个函数，只问三个问题：
   - 它的输入是什么？
   - 它改了哪些成员变量？
   - 它决定下一步调用谁？
5. 最后做小修改，而不是从零手写。

比如你后续可以做的小修改：

- 修正 `http_conn::init()` 中 `m_TRIGMode` 赋值顺序。
- 把 `BAD_REQUEST` 响应从 404 改成 400。
- 给 `mmap()`、`open()` 增加失败处理。
- 把 URL 魔法数字 `/0 /1 /2 /3` 封装成更清晰的路由函数。
- 给项目补一张请求流程图。

这些比“手敲复刻”更能体现你真正掌握了项目。

