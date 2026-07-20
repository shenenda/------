# TinyWebServer 求职面试核心知识、完整问答与实战验收

> 适用对象：把 TinyWebServer 写进简历、准备 C++ 后端 / Linux 网络编程面试的人。  
> 本文目标：不只告诉你“名词是什么”，还告诉你面试时如何组织答案、面试官会怎样继续追问，以及怎样用代码和实验证明自己确实掌握。  
> 代码基准：当前仓库修复版；讨论“原项目缺陷”时会明确区分官方/历史实现与当前实现，不能把已经修复的问题继续说成当前缺陷。

---

## 0. 先明确：什么才叫“达到面试水平”

“看过源码”“项目能启动”“能背 README”都不等于达到面试水平。真正的面试水平至少有四层：

| 层次 | 你要能做到什么 | 面试官如何验证 |
|---|---|---|
| 1. 能画 | 不看代码画出模块图和一次请求流转 | 让你在白板上从 `accept` 讲到 `writev` |
| 2. 能讲 | 解释关键系统调用、线程职责、状态机和资源所有权 | 连续追问 `EAGAIN`、ONESHOT、部分读写、超时 |
| 3. 能改 | 30 分钟内完成小功能或局部策略调整 | 增加路由、修改空闲超时、增加状态码 |
| 4. 能证 | 能复现故障、提出假设、用工具拿证据并回归验证 | 给你崩溃、卡死、低吞吐，让你定位而不是猜 |

你最终应该能脱离源码讲清这条主链：

```text
socket -> bind -> listen -> epoll_wait
       -> accept -> http_conn::init -> 注册 EPOLLIN
       -> read_once -> process_read -> do_request
       -> process_write -> 注册 EPOLLOUT -> write/writev
       -> keep-alive 重新监听 EPOLLIN / close
```

面试答题统一使用下面这个结构，避免散讲名词：

1. **先下定义**：它是什么、解决什么问题。
2. **再落项目**：本项目由哪个线程、哪个函数负责。
3. **讲边界条件**：`0`、`EAGAIN`、`EINTR`、部分完成、队列满、连接关闭。
4. **讲取舍**：为什么这样选，什么场景不合适。
5. **给证据**：代码路径、实验方法、指标或故障案例。

### 0.1 版本边界：全文出现的“原项目、历史版、当前版”分别指什么

| 层次 | 固定版本 | 已确认事实 | 不能扩大成什么结论 |
|---|---|---|---|
| 官方教学版 | `qinguoyi/TinyWebServer@4bcf887` | 含经典功能，也实际复现了普通共享标志在 `-O2` 下的 Reactor 活性故障 | 不能把官方已有功能说成自己的；也不能把它当生产基线 |
| 本仓库修复前基线 | `a57a275` | 保留普通 `improv/timer_flag`、主线程等待等历史结构，是本次消融实验基线 | 不能用未恢复 `-O2` 的结果否定故障 |
| 当前工作树 | `236d3ff` | 已移除 Reactor 忙等和该共享标志协议；线程池可停止/join；失败通知使用 `eventfd + generation` | generation 只保护迟到的工作线程失败通知；日志线程仍 detached；不代表所有生命周期问题都解决 |
| 当前仍存在的问题 | `236d3ff` | `writev` 部分写进度算法可确定触发错误；路径、Content-Length、SQL、路由耦合、open/mmap 等仍需加固 | 不能把“计划改进”说成已完成 |
| 理想生产方案 | 尚未实现 | 稳定 token、严格 HTTP framing、安全文件访问、参数化 SQL、分层路由、完整超时和监控 | 这是设计方向，不是当前项目能力 |

以后提交变化时先执行 `git rev-parse --short HEAD`，再更新这张表。面试时每提一个缺陷，都要先说“它属于官方/历史版本，还是当前 HEAD 仍存在”。

### 0.2 阅读时对应的当前源码入口

| 要回答的问题 | 当前源码入口 |
|---|---|
| 主事件循环怎样分发事件 | `webserver.cpp:512`，`WebServer::eventLoop()` |
| LT/ET 怎样 accept | `webserver.cpp:287`，`WebServer::dealclientdata()` |
| Reactor/模拟 Proactor 怎样分工 | `webserver.cpp:429`、`webserver.cpp:474` |
| 非阻塞读怎样处理半包 | `http/http_conn.cpp:280`，`http_conn::read_once()` |
| HTTP 状态机怎样推进 | `http/http_conn.cpp:415`，`http_conn::process_read()` |
| URL、文件和登录注册怎样映射 | `http/http_conn.cpp:481`，`http_conn::do_request()` |
| 响应怎样生成 | `http/http_conn.cpp:783`，`http_conn::process_write()` |
| `writev` 怎样推进发送状态 | `http/http_conn.cpp:658`，`http_conn::write()` |
| 定时器怎样周期清理 | `timer/lst_timer.cpp:255`，`Utils::timer_handler()` |
| 线程池怎样投递和消费 | `threadpool/threadpool.h` 中的 `append/append_p/run` |
| 数据库连接怎样借还 | `CGImysql/sql_connection_pool.cpp` 中的 `GetConnection/ReleaseConnection` |
| 异步日志怎样落盘 | `log/log.h` 中的 `flush_log_thread/async_write_log` |

行号对应 2026-07-20 当前工作树；以后源码变动时优先按函数名搜索，不要死记行号。

---

# 第一部分：知识地图中每一项要掌握到什么程度

## 1. TCP / Socket

### 1.1 必须真正掌握的内容

- 服务端启动：`socket -> setsockopt -> bind -> listen -> accept`。
- 网络字节序：端口和 IPv4 地址使用 `htons/htonl`；主机字节序与网络大端序的区别。
- TCP 是**可靠、有序、面向字节流**的传输协议，但不保留应用消息边界。
- 监听 fd 与已连接 fd 的职责不同：前者代表“接收新连接的入口”，后者代表一条 TCP 连接。
- 阻塞与非阻塞 socket；为什么事件驱动服务器通常将监听 fd 和连接 fd 都设为非阻塞。
- `recv/read` 返回值：
  - `> 0`：本次实际读到的字节数，未必是完整请求；
  - `== 0`：对端完成有序关闭，读方向到 EOF；
  - `-1 && errno == EAGAIN/EWOULDBLOCK`：当前数据读空，不是连接错误；
  - `-1 && errno == EINTR`：被信号中断，应根据语义重试；
  - 其他负值：真实错误。
- `send/write/writev` 也可能只写出一部分；返回成功不代表所有待发数据已经发送。
- `SO_REUSEADDR`、`SO_LINGER`、`SO_KEEPALIVE` 的基本语义；不要把它们和 HTTP keep-alive 混淆。
- `listen(backlog)`、SYN 队列、accept 队列之间的关系。
- 四次挥手、`TIME_WAIT`、半关闭、RST 的触发场景。

### 1.2 面试合格回答

> 服务端先创建监听 socket，设置地址复用，绑定 IP 和端口后进入 listen 状态。监听 fd 就绪只说明完成握手的连接可以被 accept；accept 返回的新 fd 才代表具体客户端。项目把 fd 设为非阻塞并交给 epoll，因为单线程不能在某个慢连接的 read 或 write 上长期阻塞。TCP 提供的是字节流，所以一次 recv 可能只有半个请求，也可能包含多个请求；解析器必须根据 HTTP 的行结束符和 Content-Length 自己确定边界。所有系统调用都要按返回值推进状态，尤其要区分 EOF、EAGAIN、EINTR 和真正错误。

### 1.3 白板和代码验收标准

你应该能写出一个最小服务端，并在每个系统调用后检查返回值；能回答“ET 下为何循环 accept”；能用两个 `send` 发送半个请求，证明服务器会保留解析状态，而不是假设“一次 recv 就是一条 HTTP 请求”。

---

## 2. epoll

### 2.1 必须真正掌握的内容

- `epoll_create1` 创建实例，`epoll_ctl` 维护 interest list，`epoll_wait` 取回 ready events。
- interest list 是“关注哪些 fd 和事件”，ready list/ready events 是“当前哪些关注事件已经就绪”。
- `EPOLL_CTL_ADD/MOD/DEL` 的职责。
- `EPOLLIN`、`EPOLLOUT`、`EPOLLRDHUP`、`EPOLLHUP`、`EPOLLERR`。
- LT 与 ET 的通知语义；ET 必须配合非阻塞 I/O，并读/写到 `EAGAIN`。
- `EPOLLONESHOT` 触发一次后会禁用该 fd 的后续通知，处理结束必须 `EPOLL_CTL_MOD` 重新武装。
- epoll 的价值是避免每轮线性扫描所有监听 fd，并通过就绪事件处理大量“连接多、活跃少”的场景；不能说成“epoll 永远 O(1) 或永远比 poll 快”。
- 事件批次只是用户态数组快照：同一批事件处理期间 fd 可能关闭、被复用，必须考虑旧事件和 fd ABA。

### 2.2 面试合格回答

> epoll 的优势不是一句“用了红黑树”，而是应用通过 `epoll_ctl` 维护关注集合，等待时只取得已经就绪的事件，不必像 select/poll 那样每轮把整个 fd 集合从头遍历一遍。这个项目连接数可能很多、每一时刻真正活跃的连接较少，所以 epoll 比较合适。客户端连接使用 ONESHOT，事件交给工作线程后暂时不再重复分发，工作线程完成当前阶段再 MOD 为 EPOLLIN 或 EPOLLOUT。但 ONESHOT 只限制事件重复派发，并不能自动解决对象生命周期、共享状态和 fd 复用问题。

### 2.3 白板和代码验收标准

能写一个单线程 LT epoll echo server；再切到 ET，给监听 fd 和连接 fd 加非阻塞与 drain loop；能解释忘记 rearm 后连接为何“第一次能用、第二次卡住”。

---

## 3. Reactor、Proactor 与本项目并发模型

### 3.1 三种概念先分清

- **Reactor**：内核通知“可以做 I/O 了”，应用线程执行同步 `read/write`，再处理业务。
- **真正的 Proactor**：应用提交异步 I/O，内核或异步运行时完成 I/O 后通知“操作已完成”，业务处理结果。
- **本项目所谓 Proactor**：主线程用非阻塞同步 I/O 完成读写，工作线程做 HTTP 解析和业务，因此更准确叫“同步 I/O 模拟 Proactor”。它不是 Linux AIO/io_uring 意义上的真正 Proactor。

### 3.2 两种模式中谁做什么

| 阶段 | Reactor 模式 | 项目中的模拟 Proactor |
|---|---|---|
| 事件检测 | 主线程 `epoll_wait` | 主线程 `epoll_wait` |
| socket 读 | 工作线程 `read_once()` | 主线程 `read_once()` |
| HTTP 解析/业务 | 工作线程 | 工作线程 |
| socket 写 | 工作线程 `write()` | 主线程 `write()` |
| 下一事件 rearm | 完成当前阶段的工作线程 | 主线程或业务完成路径 |

### 3.3 面试合格回答

> 两种模式的关键不是参数名，而是 I/O 责任分配。Reactor 下，主线程只检测和分发就绪事件，工作线程执行同步非阻塞 read/write 和业务；模拟 Proactor 下，主线程先完成 socket I/O，再把解析和业务交给线程池。这个实现并没有向内核提交真正的异步 I/O，所以我会明确称为模拟 Proactor。Reactor 能分散主线程 I/O 压力，但连接状态和跨线程完成通知更难；模拟 Proactor 的连接 I/O 归属更集中，但主线程可能成为读写瓶颈。

### 3.4 必须能指出历史实现的问题

历史 Reactor 分支把任务投递后，主线程围绕普通 `int improv` 忙等工作线程。这里同时有两个问题：

1. 主事件线程等待单个请求，破坏事件循环的异步性并浪费 CPU。
2. 普通整数被不同线程无同步读写，构成 data race，按 C++ 内存模型属于未定义行为。

当前修复版使用不可变任务上下文、ONESHOT 成功路径推进、`eventfd` 失败通知、generation 过滤迟到的工作线程失败关闭，并让线程池线程可停止和 join；它尚未让 epoll 事件本身携带 generation，日志线程也仍需补齐停止协议。

---

## 4. 线程池与 C++ 并发

### 4.1 必须真正掌握的内容

- 线程池的目的：复用线程、限制并发度、把任务生产和消费解耦；不能只回答“减少创建线程开销”。
- 生产者—消费者模型：主线程投递任务，工作线程取任务，队列是两者之间的缓冲。
- 互斥锁保护队列结构；信号量或条件变量表示“是否有任务”，让空闲线程阻塞睡眠而不是轮询。
- 队列必须有容量；满时需要明确拒绝、关闭连接、降级或背压策略。
- 长任务会造成队头阻塞、尾延迟上升和队列堆积；线程池不是无限吞吐机器。
- 线程数不是越多越好：CPU 密集任务大致参考核心数，I/O 等待多可适当增加，但要用吞吐、P95/P99、上下文切换和 CPU 利用率验证。
- 安全停止：停止标志、唤醒阻塞线程、拒绝新任务、处理/丢弃剩余任务、`join`、最后销毁共享资源。
- `volatile` 不提供线程同步；`atomic` 只保证该原子对象的操作，不自动保护复合不变量。
- data race、race condition、happens-before、未定义行为的区别。
- 对象所有权和生命周期：裸指针任务、detached 线程、连接关闭和 fd 复用为什么危险。

### 4.2 面试合格回答

> 项目线程池是有界生产者—消费者模型。事件线程将连接及本次任务状态放入队列，工作线程通过信号量等待任务；队列修改由互斥锁保护。队列容量不仅是实现细节，也是过载边界：如果满了仍无限接收，内存和延迟会持续膨胀，所以应该让 append 返回失败，由主线程关闭、返回 503 或执行限流。析构时不能让 detached 线程继续访问已经释放的连接数组和连接池，应先停止投递、唤醒并 join 工作线程，再销毁共享资源。

---

## 5. HTTP/1.1 解析与状态机

### 5.1 必须真正掌握的内容

- 请求报文：请求行、请求头、空行、可选请求体。
- 请求行包含 method、request-target、HTTP version。
- 先按 HTTP 消息定界规则判断是否有请求体：没有 `Content-Length` 和 `Transfer-Encoding` 的普通请求通常表示没有消息体，并非一律报错；使用固定长度 body 时，必须检查 Content-Length 的重复冲突、负数、整数溢出和上限。当前项目主要支持 Content-Length，不具备完整的 chunked 解析。
- HTTP/1.1 默认持久连接；`Connection: close` 表示响应后关闭。
- TCP 没有“粘包协议错误”。所谓粘包是字节流在一次读取中含多个应用消息；HTTP 解析器必须自行划分消息。
- 半包：当前数据不足时保留 `m_read_idx/m_checked_idx/m_start_line` 等状态，下一次读到数据后继续解析。
- 主从状态机：
  - 从状态机 `parse_line()` 找 `\r\n` 并切行；
  - 主状态机 `process_read()` 在请求行、请求头、请求体之间推进；
  - 完整后进入 `do_request()`。
- GET 与 POST 是语义区别，不对应 TCP 报文数量；不能说“GET 一包、POST 两包”。
- 状态码语义：400 语法错误、403 禁止访问、404 资源不存在、405 方法不允许、413 请求体过大、431 请求头过大、500 内部错误、503 过载。

### 5.2 面试合格回答

> 这个项目不能假设一次 recv 得到完整请求。`read_once()` 只负责把当前可读字节追加进读缓冲区；`parse_line()` 查找 CRLF；`process_read()` 根据当前检查状态解析请求行、请求头和请求体。遇到不完整行或请求体不足就返回 `NO_REQUEST` 并保留游标，下一次 EPOLLIN 继续。解析完成才调用 `do_request()`。消息边界来自 HTTP 语法和 Content-Length，而不是 TCP 分包，也与 GET/POST 没有固定包数关系。

### 5.3 面试必须主动补的安全边界

- URL 解码和规范化后再做根目录约束，防止 `../` 路径穿越。
- 不能直接把用户输入拼 SQL；使用预编译语句和参数绑定。
- 固定缓冲区要有明确上限和对应的 4xx 响应。
- `Host`、方法、版本、行结束符、重复长度头都要校验。
- 慢速客户端需要请求头/请求体超时，不能只做“连接最后活动时间”超时。

---

## 6. 静态文件、`mmap`、`iovec`、`writev` 与部分发送

### 6.1 当前发送路径

```text
stat 检查文件
  -> open
  -> mmap 文件到进程虚拟地址
  -> 响应头放 m_write_buf
  -> iov[0] = 响应头，iov[1] = 文件映射
  -> writev
  -> 全部发送后 munmap
```

`writev` 的价值是一次系统调用可以聚合多段不连续内存，避免先把“响应头 + 文件”复制到一个大用户态缓冲区。`mmap` 避免应用显式 `read` 文件到自建缓冲区。

### 6.2 不要说成“完全零拷贝”

更严谨的话术是：

> `mmap + writev` 减少了应用层文件缓冲和用户态拼接拷贝，但数据仍要经过页缓存、socket 缓冲等路径，我不会笼统称它为完全零拷贝。若只发送文件，`sendfile` 可以直接在文件 fd 与 socket fd 之间传输；若要灵活拼响应头，`writev` 或 `sendmsg` 更方便。具体性能要压测。

### 6.3 部分写必须维护发送进度

假设响应头 200 字节、文件 1000 字节，第一次 `writev` 只返回 120：

```text
第一次后：头还剩 80，文件还剩 1000
第二次如果返回 500：先消费剩余头 80，再消费文件 420
此时文件起点应移动 420，文件还剩 580
```

正确算法不能拿“累计已发送字节”反复减“已经变化过的 iov_len”。稳妥做法是用本次返回值逐段消费：

```cpp
ssize_t n = writev(fd, iov, iovcnt);
if (n > 0) {
    ssize_t left = n;
    while (left > 0 && iovcnt > 0) {
        if (left >= static_cast<ssize_t>(iov[0].iov_len)) {
            left -= iov[0].iov_len;
            ++iov;
            --iovcnt;
        } else {
            iov[0].iov_base = static_cast<char*>(iov[0].iov_base) + left;
            iov[0].iov_len -= left;
            left = 0;
        }
    }
}
```

工程代码通常不会直接移动成员数组指针，而是保存 `header_sent/file_sent`，或写一个 `consume_iovecs(n)`。关键是不丢、不重、不越界。

### 6.4 返回值处理

- `n > 0`：仅消费 `n` 字节，若还有剩余继续写；直到 `EAGAIN` 才等待下一次 EPOLLOUT。
- `n == -1 && EAGAIN`：发送缓冲区暂时满，保存进度并注册 EPOLLOUT。
- `n == -1 && EINTR`：通常重试。
- 其他错误：清理 mmap、定时器和连接。
- `n == 0`：对非零长度写并非常规成功，应避免无限循环，按异常处理或结合具体 API 语义判断。

### 6.5 当前版本已确认的 `writev` 进度缺陷

这不是“可能有问题”，而是当前 `http_conn::write()` 中可以通过数值演算确定触发的缺陷。代码同时使用累计 `bytes_have_send` 和已经被缩短的 `m_iv[0].iov_len`：

```text
初始响应头 200 字节
第一次 writev 返回 120：
  bytes_have_send = 120
  iov[0] 被改为 base + 120、len = 80       （此时正确）

第二次 writev 只返回 10：
  bytes_have_send = 130
  代码比较 130 >= 当前 iov[0].len 80       （成立）
  于是错误地认定响应头已经发完
  但实际上响应头还有 70 字节未发送
```

另一个错误是连续走“头部尚未发完”分支时，用“当前剩余 len”再次减“累计发送量”，会把已经扣过的字节再扣一次。结果可能是头部漏发、过早切到文件段或无符号长度下溢。

因此当前状态应明确写成：**设计意图支持部分写，但实现尚未正确维护 iovec 进度**。可落地修复是引入独立的 `header_sent/file_sent`，或者把“按本次返回值消费 iovec”抽成纯函数并做单元测试；修复前不能把当前发送算法当作正确项目亮点。

---

## 7. 定时器、信号与统一事件源

### 7.1 当前实现

- 每个连接绑定一个 `util_timer`。
- 新连接过期时间为 `now + 3 * TIMESLOT`。
- 当前 `TIMESLOT = 5` 秒，因此名义空闲超时是 15 秒。
- 连接有读写活动时更新 `expire`，并调整升序链表位置。
- `alarm(TIMESLOT)` 周期触发 `SIGALRM`。
- 信号处理函数只把信号编号写入 socketpair；主事件循环监听管道，在正常上下文中调用 `tick()`。
- `tick()` 从链表头处理所有已经到期的节点。

实际关闭可能比名义 expire 晚不到一个检查周期，所以“15 秒超时”不是精确到毫秒的硬截止时间。

### 7.2 为什么不在信号处理函数里直接关闭连接

信号可能打断任意代码，信号处理函数中可安全调用的函数很少。加锁、动态分配、复杂日志和大部分库函数都可能不可重入。self-pipe/socketpair 技巧把异步信号转换成普通 fd 可读事件，真正的定时器处理回到事件循环完成。

### 7.3 数据结构比较

| 结构 | 插入/调整 | 取最近到期 | 适用场景 |
|---|---:|---:|---|
| 升序链表 | 最坏 O(n) | O(1) | 教学、小规模、实现简单 |
| 最小堆 | O(log n) | O(1) | 通用超时队列，删除需索引或惰性删除 |
| 时间轮 | 接近 O(1) | 按槽推进 | 大量定时任务、容许一定时间粒度 |
| `timerfd` + 堆 | 堆 O(log n) | fd 事件驱动 | 避免信号，容易并入 epoll |

### 7.4 面试合格回答

> 项目用升序链表保存连接超时，活动时把过期时间顺延。SIGALRM 只负责通过 socketpair 唤醒 epoll，主循环再执行 tick，这叫统一事件源。优点是结构清晰，缺点是插入和调整最坏 O(n)，检查粒度由 TIMESLOT 决定。更工程化的方案是 `timerfd + 最小堆`，或者在海量定时任务下用时间轮，同时要保证关闭连接和删除定时器只有一个所有者，避免悬空指针和重复关闭。

---

## 8. 数据库连接池与 RAII

### 8.1 必须掌握

- 连接池预先建立有限数量的 MySQL 连接，避免每个请求都创建和认证连接。
- 空闲连接放入容器，借出/归还时加锁；信号量表示可用连接数。
- 池拥有连接，业务线程只是临时、独占借用。
- `connectionRAII` 构造时获取，析构时归还，保证早返回和异常路径也能释放资源。
- 连接数不是越多越好，受数据库 `max_connections`、服务端线程数、单查询耗时和下游承载能力限制。
- 当前表单字符串拼 SQL 的方式不应作为生产范式，应换参数化查询。

### 8.2 面试回答

> 数据库连接池解决建连成本和下游并发上限问题。项目通过锁保护空闲连接容器，用信号量阻塞等待可用连接，再用 RAII 保证作用域结束时归还。这里不是 shared_ptr 的共享所有权语义，而是“池拥有、请求独占借用”。生产环境还需要获取超时、健康检查、断线重连、事务回滚和参数化 SQL。

---

## 9. 异步日志与阻塞队列

### 9.1 必须掌握

- 同步日志：业务线程格式化并直接写文件，简单但磁盘抖动会增加请求延迟。
- 异步日志：业务线程把消息入有界队列，日志线程批量/顺序落盘，解耦请求路径和磁盘 I/O。
- 阻塞队列需要互斥锁保护容器，用条件变量通知“非空/非满”。
- 队列满时必须明确策略：阻塞业务、丢低级别日志、同步降级或覆盖旧日志。
- 异步日志不能保证进程崩溃前所有队列内容都落盘；需要 flush、停止协议和错误处理。
- 日志线程也应当可停止、可 join；单例只解决全局访问入口，不自动保证所有生命周期安全。

### 9.2 面试回答

> 异步日志的本质是用有界队列把业务线程和磁盘 I/O 解耦。业务线程完成格式化后入队，日志线程阻塞等待并写文件。优势是降低请求线程被慢磁盘阻塞的概率，代价是多一次内存拷贝、队列内存和崩溃时尾部日志丢失风险。我要同时说明队列满策略、flush 语义和退出时 join，否则“异步”只是把问题移到了后台。

---

## 10. 性能测试、可观测性与工程安全

达到面试水平不能只背官方 QPS。你要能解释：

- 并发连接数、请求率、完成请求数、错误数、吞吐、平均延迟、P95/P99 各是什么。
- 单个 QPS 没意义，必须同时说明机器、核心数、编译优化、资源大小、并发数、持续时间、网络位置、触发模式、日志开关和错误率。
- 压测客户端与服务端在同机时会竞争 CPU 和网络栈资源。
- Webbench 更适合粗略吞吐回归，不提供完整的尾延迟分析。
- CPU 100% 可能是忙等、锁竞争、系统调用风暴或真正计算繁忙；CPU 接近 0 但吞吐也接近 0，可能是死锁、事件未 rearm、线程都在等待或连接没有建立。
- 工具组合：日志、`strace`、`gdb`、core dump、ASan、UBSan、TSan、Valgrind、`pidstat -t`、`perf`。

面试话术：

> 我不会只报一个 QPS。我会固定代码提交、编译参数和负载，至少记录吞吐、失败、CPU 和延迟分位数，重复多轮。出现异常时先判断是 CPU、锁、I/O、队列还是生命周期问题，再用线程栈、系统调用、sanitizer 和最小对照实验验证。

---

# 第二部分：面试最高频的 15 个主问题与完整回答

## Q1. 请用三分钟介绍这个项目

### 完整回答模板

> 这是一个运行在 Linux 上的 C++ HTTP/1.1 服务器，目标是学习事件驱动网络编程和并发资源管理。主线程使用非阻塞 socket 和 epoll 统一监听新连接、客户端读写、信号管道以及工作线程失败通知；连接由 `http_conn` 保存解析和发送状态，业务通过线程池处理。成功任务不会统一写 eventfd，而是由完成当前阶段的线程直接 rearm ONESHOT；只有需要主线程统一回收的失败走 `eventfd`。HTTP 使用主从状态机支持半包和持久连接，静态文件通过 `mmap + writev` 发送；项目还包含 MySQL 连接池与 RAII、升序链表定时器、同步/异步日志。
>
> 一次请求从 accept 开始，连接注册 EPOLLIN。读就绪后，Reactor 模式由工作线程读并处理；模拟 Proactor 模式由主线程读、工作线程解析。请求完整后经过 `do_request` 做资源映射或登录注册，`process_write` 生成响应，随后监听 EPOLLOUT，由 `writev` 按发送进度写回。长连接发送完重置状态继续读，短连接或错误则统一清理 socket、定时器和映射。
>
> 我没有把 README 功能当作自己的工作。我重点审计和修复了历史 Reactor 路径的并发问题：普通 `int improv/timer_flag` 被跨线程读写，主线程还忙等工作线程。恢复 `-O2` 后，我用优化级别对照、atomic 消融、反汇编和线程栈证明这是数据竞争导致的活性故障。最终改成不可变任务项，成功路径由 ONESHOT rearm 推进，失败路径通过 eventfd 唤醒主循环，使用 fd generation 避免迟到通知误关新连接，并补齐线程停止和 join。
>
> 在同机、100 并发、30 秒、关闭日志的本轮测试中，修复前 `-O2` 只有百次级完成请求，正式修复恢复到约 38 万至 39 万次；相对只改 atomic 的最小版本，吞吐接近，但 CPU 降低约 35% 到 39%。这个结果只代表同一实验条件下消除活性故障，不是通用性能承诺。项目仍是教学型服务器，HTTP 边界、安全、路由解耦和可观测性还需要生产化完善。

### 面试官真正想听什么

- 功能不是重点，架构和请求链才是重点。
- 必须区分“原项目已有”和“你真正做的”。
- 难点要有证据和量化结果，结果还要说明实验边界。
- 主动承认项目不是生产级，反而更可信。

---

## Q2. 一次 HTTP 请求在项目中如何流转？

> 服务器启动时创建监听 socket、epoll、信号 socketpair、线程池、数据库连接池和定时器。监听 fd 出现 EPOLLIN 后，LT 模式 accept 一次，ET 模式循环 accept 到 EAGAIN。新连接用 fd 作为连接数组索引，初始化 `http_conn` 和定时器，并注册客户端 fd 的 EPOLLIN、EPOLLRDHUP 和 EPOLLONESHOT。

accept 之后要分两条路径回答，不能混在一起：

| 阶段 | Reactor `actor=1` | 模拟 Proactor `actor=0` |
|---|---|---|
| EPOLLIN 到来 | 主线程投递 `{request, READ, generation}` | 主线程先执行 `read_once()`，成功后投递业务任务 |
| socket 读 | 工作线程 | 主线程 |
| HTTP 解析、业务、生成响应 | 工作线程执行 `process()` | 工作线程执行 `process()` |
| 生成响应后的 rearm | 工作线程在 `process()` 中 MOD 为 EPOLLOUT | 工作线程在 `process()` 中 MOD 为 EPOLLOUT |
| EPOLLOUT 到来 | 主线程投递 `{request, WRITE, generation}` | 主线程直接执行 `write()` |
| socket 写 | 工作线程 | 主线程 |
| 成功后的 rearm | 完成写的工作线程按剩余状态监听 EPOLLOUT/EPOLLIN | 主线程按剩余状态监听 EPOLLOUT/EPOLLIN |
| 失败清理 | 工作线程把失败与 generation 入队并写 eventfd，主线程校验后清理 | 主线程直接走连接与定时器清理 |

两条路径中的 HTTP 业务相同：`read_once()` 把字节追加到读缓冲区；`process_read()` 调用 `parse_line()`，在请求行、请求头、请求体三个状态间推进。不完整就保存状态；完整后 `do_request()` 做资源/登录注册映射，`process_write()` 生成状态行、响应头和正文，并组成 iovec。

写阶段的正确语义是：`writev` 返回多少就只消费多少；EAGAIN 保存进度等待 EPOLLOUT；全部发送后才 munmap，再根据 HTTP keep-alive 选择 EPOLLIN 或关闭。当前版本的 iovec 进度实现存在第 6.5 节所述确定缺陷，面试时要区分“应有语义”和“当前实现现状”。

追问时要能指出：任何一步失败都不应只 `close(fd)`，还要考虑 epoll、定时器、mmap、连接计数以及迟到任务。

---

## Q3. 为什么使用 epoll？

> 目标场景是大量长连接中只有一部分在某一时刻活跃。select 和 poll 每次等待都要让应用提供或遍历整个关注集合；epoll 把关注集合长期保存在内核，通过 ctl 增删改，wait 返回当前就绪事件，因此能减少应用层对无关 fd 的重复扫描。它还提供 ET、ONESHOT、RDHUP 等适合事件驱动服务器的语义。
>
> 但我不会说 epoll 永远更快。fd 数量不大、几乎全部活跃，或者业务处理本身才是瓶颈时，差距可能不明显；epoll_ctl、事件回调和缓存行为也有成本。选择依据是连接规模和活跃度，结论要通过实际负载验证。

错误回答：只说“epoll 底层红黑树，所以 O(1)”。红黑树主要维护关注集合，ready 事件也有链表/回调机制，而且一次 wait 的处理成本仍与返回事件数有关。

---

## Q4. select、poll、epoll 有什么区别？

> select 使用位图 fd_set，存在集合容量和最大 fd 相关限制，调用后集合会被改写，下一轮需要重建；内核和用户之间要复制集合，应用还要线性检查哪些 fd 就绪。poll 使用 `pollfd` 数组，摆脱固定 fd_set 位数限制，并能直接返回 revents，但仍要每轮传递并线性扫描整个数组。
>
> epoll 通过 `epoll_ctl` 把关注集合保存在内核，`epoll_wait` 返回就绪事件，适合连接多、活跃少、关注集合变化相对不频繁的服务器。epoll 只在 Linux 上可用；select/poll 可移植性更广。所有机制都只告诉你“操作可能不会阻塞”，不替你处理半包、部分写、线程安全或业务耗时。

| 维度 | select | poll | epoll |
|---|---|---|---|
| fd 表达 | 位图 | 数组 | 内核关注集合 |
| 数量限制 | 受 fd_set 限制 | 无固定小上限，受资源限制 | 受系统资源限制 |
| 每轮集合传递/扫描 | 是 | 是 | wait 返回就绪事件 |
| LT/ET | 通常 LT 语义 | 通常 LT 语义 | 支持 LT/ET |
| 平台 | 广 | 广 | Linux |

---

## Q5. LT 和 ET 有什么区别？为什么 ET 要读到 EAGAIN？

> LT 是电平语义，只要 fd 仍处于可读或可写状态，后续 wait 还可能继续通知；ET 更接近状态变化通知，从未就绪变为就绪时报告。ET 下如果本次只读一点就返回，剩余数据还在内核缓冲区，不是丢失，但因为状态可能没有再次发生边沿变化，应用可能长期收不到新通知，所以要用非阻塞循环一直读到 EAGAIN，表示当前时刻已经排空。
>
> 必须非阻塞是因为循环的最后一次 read/accept 用来确认“已经排空”。若 fd 是阻塞的，当数据刚好读完但连接仍保持时，下一次调用会卡住整个处理线程。写方向同理，能写就尽量推进，直到全部完成或 EAGAIN。

LT 更容易写对；ET 可减少重复通知，但状态机和错误处理要求更高。不能脱离负载宣称 ET 一定更快。

---

## Q6. EPOLLONESHOT 做什么？忘记 rearm 会怎样？

> ONESHOT 让某 fd 的一次事件被报告后暂时禁用后续通知，直到应用执行 `EPOLL_CTL_MOD` 重新武装。线程池服务器用它防止同一连接还没处理完，又被事件循环分发给另一个工作线程。
>
> 处理不完整请求后要 rearm EPOLLIN；生成响应后 rearm EPOLLOUT；部分写遇到 EAGAIN 也要继续监听 EPOLLOUT；长连接响应结束后重新监听 EPOLLIN。忘记 rearm 的典型现象是连接没有关闭、数据也可能仍在内核里，但再也收不到事件，看起来像“卡死”。
>
> ONESHOT 不是互斥锁。它不能保护进程中其他线程主动拿着同一个对象访问，也不能解决旧任务、定时器回调、fd 复用或共享 map 的竞态。

---

## Q7. Reactor 和 Proactor 有何区别？项目属于哪一种？

> Reactor 通知的是 I/O 就绪，应用收到事件后自己做同步 I/O；Proactor 通知的是异步 I/O 完成，应用主要处理结果。本项目的两种模式都使用 `recv/writev` 这样的同步非阻塞调用，不是真正内核异步 I/O。所谓 Reactor 是工作线程做 socket I/O 和业务；所谓 Proactor 是主线程先做 socket I/O、工作线程做解析业务，所以我称后者为模拟 Proactor。
>
> 取舍上，Reactor 能让主线程快速分发，但连接 I/O 状态跨线程，完成通知和生命周期更复杂；模拟 Proactor 让 socket I/O 更集中，连接状态容易约束，但主线程可能因大量拷贝和写操作成为瓶颈。是否选择某种模式要看业务耗时、连接数和线程归属设计。

---

## Q8. 线程池是怎样工作的？为什么要有界队列？

> 主事件线程是生产者，将连接指针、读写状态和 generation 组成任务放入队列；工作线程是消费者，阻塞在信号量上，有任务时加锁取出一项，再做 I/O 或业务。队列锁只保护入队出队，不能拿着锁执行 HTTP 或 SQL，否则会把工作线程串行化。
>
> 有界队列为系统建立明确的过载上限。如果任务产生速度长期大于处理速度，无界队列只会把过载转化为内存膨胀和巨大尾延迟。队列满时应当快速失败、返回 503、关闭低价值连接或触发上游限流，并记录拒绝数和队列长度。
>
> 安全停止时先停止接收新任务，设置停止状态并唤醒所有消费者，按策略排空或放弃剩余任务，然后 join，最后销毁连接池和连接数组。

---

## Q9. 任务太慢、队列满、线程池析构时分别会怎样？

> 长任务占住工作线程，会让后续短任务排队，表现为队列长度和 P99 上升；如果所有线程都等待数据库，下游连接池会成为瓶颈。改进不能只是盲目加线程，应设置数据库/业务超时、拆分不同优先级或不同类型线程池、限制单任务工作量，并观察队列等待时间。
>
> 队列满说明入口速率超过服务能力。append 必须返回失败，主线程执行明确的过载策略，不能忽略失败后还让连接保持 ONESHOT 禁用状态。可以按协议返回 503，也可以在资源极度紧张时直接关闭，并打点 `queue_rejected_total`。
>
> 析构若使用 detached 线程，服务器对象和连接池可能先释放，后台线程继续访问就会 UAF。正确顺序是停止投递、唤醒、join，再释放共享资源。这里考的是生命周期，不只是“减少线程创建开销”。

---

## Q10. HTTP 主从状态机如何处理半包和多个请求？

> `read_once` 只追加字节，不假设完整请求。`parse_line` 是从状态机，利用 `m_checked_idx` 从未检查位置寻找 CRLF，并把一行终止成 C 字符串。`process_read` 是主状态机：先解析请求行，再解析请求头，若 Content-Length 大于 0 则等待请求体；完整时调用 `do_request`。
>
> 若当前只有半行或 body 不够，返回 `NO_REQUEST`，保留缓冲区和游标，重新监听 EPOLLIN；下一次读到字节后继续。若一次 recv 包含完整请求后还有下一请求的数据，健壮实现应消费第一个消息的确切长度并保留剩余字节，在 keep-alive 上继续解析，而不是无条件清空整个缓冲区。当前教学代码在流水线和缓冲区压缩方面能力有限，这是可改进点。

---

## Q11. 为什么用 mmap + writev？和 sendfile 有什么区别？

> 静态文件通过 mmap 映射后，响应头在普通写缓冲区，文件在映射区域。writev 可以把两个 iovec 一次提交，避免为了拼接而把整个文件复制到一个连续用户缓冲区，也减少系统调用。但 mmap 建立映射和处理缺页有成本，且不能把它笼统说成完全零拷贝。
>
> sendfile 的接口是文件 fd 到 socket fd，内核可直接在页缓存和 socket 之间搬运，适合纯静态大文件；writev 适合把多段用户内存聚合发送。若要头部 + 文件，可以分别发送、使用 sendmsg 的能力或平台特定方案。选择要看文件大小、缓存命中、并发和平台，并处理 open/mmap/send 的所有错误。

---

## Q12. 什么是部分读写？项目如何处理？

> TCP 是字节流，read 返回的是“当前能交付的字节”，write 返回的是“本次内核接受的字节”，都不保证等于应用期望长度。部分读时把新字节追加到缓冲区，解析器只消费完整语法单元；数据不足就保存状态等待下一次 EPOLLIN。ET 模式要读到 EAGAIN。
>
> 部分写时根据 writev 的实际返回值推进每个 iovec 的 base 和 len，未发送部分必须原样保留；EAGAIN 表示背压，注册 EPOLLOUT 后返回事件循环，不能忙等，也不能从头重发。发送完成才 munmap，并根据 keep-alive 决定继续读还是关闭。
>
> 我会用小 socket 发送缓冲区、一个大文件和限速客户端，通过 `strace -f -e writev` 或断点观察多次短写与 EAGAIN，校验最终文件哈希一致，证明没有重发或漏发。

最后必须主动交代版本事实：上面是正确设计语义；当前 `236d3ff` 的 `http_conn::write()` 仍有第 6.5 节的累计进度错误，不能声称已经正确实现所有连续短写。

---

## Q13. 定时器如何清理超时连接？为什么用信号管道？

> 每个连接保存一个定时器节点，过期时间初始为 `now + 3 * TIMESLOT`，有活动就顺延并调整链表。SIGALRM 周期到来后，信号处理函数只写一个字节到 socketpair，epoll 收到管道可读事件后，主线程调用 tick，从有序链表头依次处理到期连接，然后重新 alarm。
>
> 这样做是为了避免在异步信号上下文中加锁、写复杂日志或操作链表，把信号转换成普通事件。当前实现名义 15 秒空闲超时，实际有一个扫描粒度误差。升序链表插入和调整最坏 O(n)，更工程化可改 `timerfd + 最小堆`；同时必须统一连接关闭所有权，避免定时器和异常事件重复 close。

---

## Q14. 异步日志和数据库连接池分别解决什么问题？

> 异步日志解决业务线程被慢磁盘 I/O 阻塞的问题：请求线程把日志入有界阻塞队列，日志线程消费并写文件。完整设计必须说明队列满、flush、文件滚动、写失败和退出 join。
>
> 数据库连接池解决频繁建连成本并限制下游并发：池预建连接，信号量控制可借数量，互斥锁保护空闲容器，RAII 保证请求结束归还。它还需要获取超时、坏连接淘汰和事务清理。两者共同点都是复用资源和隔离慢操作，但队列/池的容量也会形成背压，不能无限扩大。

---

## Q15. 你相对原项目做了什么？还存在哪些问题？

> 我先区分上游代码、仓库历史基线和当前修复，避免把原作者功能说成自己的。我的重点是 Reactor 并发故障审计：恢复历史 `-O2` 条件后复现百次级低吞吐；通过 `-O0/-O2/volatile/atomic/正式修复` 矩阵、反汇编、GDB 全线程栈和 CPU 数据，确认普通标志跨线程数据竞争让编译器删除等待读取，而 atomic 只能恢复活性、不能消除主线程忙等。
>
> 正式方案移除主线程等待，把状态和 generation 固化进任务项；成功路径直接 rearm ONESHOT，失败路径用 eventfd 唤醒主线程统一回收；再用 generation 防止旧失败通知误关复用 fd，并让线程池可停止和 join。在同一轮对照中吞吐恢复到约 1.28 万到 1.31 万 req/s，相对 atomic 版本 CPU 下降约 35% 到 39%。
>
> 但我不会说项目已生产可用。原始路由和 HTTP/SQL 高度耦合，路径规范化、Content-Length 边界、部分写、open/mmap 错误、慢请求超时、可观测性、测试和 TLS 都还需要完善。我能给出具体修复和验证方法，而不是只说“代码结构不好”。

---

# 第三部分：第二层连环拷问及向外引申

## A. 网络与 epoll

### A1. ET 为什么必须配合非阻塞 socket？

> ET 处理通常循环 read/accept 直到 EAGAIN，以确认当前就绪状态已排空。如果是阻塞 fd，当最后一次把数据读完但连接未关闭时，下一次调用会等待未来数据，把事件线程卡住。非阻塞让“读空”以 EAGAIN 返回，事件循环可以去处理其他连接。

### A2. 监听 socket 使用 ET，为什么要循环 accept？

> 一次就绪期间 accept 队列里可能已有多个完成握手的连接。ET 可能只报告一次状态变化，只 accept 一个会让其余连接继续留在队列而没有新的边沿。应循环 accept4 到 EAGAIN，同时分别处理 EMFILE/ENFILE、ECONNABORTED 和 EINTR。

引申：可用 `accept4(..., SOCK_NONBLOCK | SOCK_CLOEXEC)` 原子设置标志，避免 accept 后再 fcntl 的窗口。

### A3. EPOLLIN、EPOLLOUT、EPOLLRDHUP、EPOLLERR 分别是什么？

- `EPOLLIN`：读不会阻塞，可能有普通数据，也可能随后读到 EOF。
- `EPOLLOUT`：当前可写；大多数 socket 平时都可写，不应无条件长期订阅，否则容易事件风暴。
- `EPOLLRDHUP`：流式 socket 对端关闭写方向，便于检测半关闭。
- `EPOLLERR`：fd 有错误；应通过 `getsockopt(SO_ERROR)` 取得具体错误。
- `EPOLLHUP`：挂起/连接端点关闭。错误和挂起通常即使未显式订阅也会报告。

回答时补一句：同一事件可以同时带多个 bit，代码要明确处理优先级，不能用错误的互斥假设。

### A4. 忘记 ONESHOT rearm 会怎样？

> fd 仍存在，内核缓冲区也可能有数据，但 epoll 不再报告该 fd。现象通常是首个请求正常、后续 keep-alive 请求永久等待。排查时查看 epoll_ctl MOD 是否覆盖所有成功、半包、EAGAIN 和异常恢复分支。

### A5. epoll 返回一批事件，其中一个 fd 被提前关闭，后面的缓存事件怎么办？

> `events[]` 是本轮快照，关闭不能抹掉数组里已经返回的条目。当前数组项只有 `data.fd` 时，即使查询“这个 fd 当前的 generation”，也无法知道该事件是旧连接产生还是复用后的新连接产生；因此当前 generation 不能解决这类旧 epoll 事件。

完整方案是在注册时把稳定 token 或 `(fd,generation)` 编码进 `epoll_event.data.u64`，或者让 `data.ptr` 指向生命周期受控的 Channel/Connection token；取出事件后将“事件携带的 generation”与连接表当前 generation 比较，不匹配就丢弃。关闭仍要幂等并由所属 EventLoop 统一完成。这里必须区分：当前 generation 已经保护迟到的工作线程失败通知，但没有保护所有旧 epoll 事件和旧任务。

### A6. fd 为什么会很快复用？如何避免旧任务操作新连接？

> fd 是进程描述符表中的最小可用整数，关闭后新 accept/open 很可能立即获得同一个值，形成 ABA。做法是任务携带 `(fd, generation)` 或稳定连接 ID，执行副作用前同时校验；对象生命周期使用明确所有权，关闭回到所属 EventLoop；异步回调用 `weak_ptr` 或代次检查。当前 generation 主要保护迟到失败通知，不等于解决所有旧任务访问。

### A7. listen backlog、SYN 队列、accept 队列是什么？

> SYN 队列保存尚未完成三次握手的半连接，accept 队列保存已经完成握手、等待应用 accept 的连接。Linux 上 backlog 主要影响完成队列上限，但实际值还受 `somaxconn`、`tcp_max_syn_backlog`、syncookies 等配置影响。应用 accept 太慢会让完成队列积压；SYN flood 主要冲击半连接路径。不要把 backlog 说成“服务器最大并发连接数”。

### A8. 三次握手、四次挥手、TIME_WAIT、半关闭怎样发生？

> 三次握手同步双方初始序列号并确认双向通信能力。TCP 是全双工，主动关闭一方先发 FIN，只关闭自己的发送方向；对端 ACK 后仍可以发送剩余数据，最后再发 FIN，所以通常是四次。主动关闭方进入 TIME_WAIT，等待 2MSL，防止旧报文污染同四元组的新连接，并保证最后 ACK 丢失时还能重传。半关闭就是一端已经发 FIN，但另一方向仍可传输。

### A9. HTTP keep-alive 和 TCP keepalive 是一回事吗？

> 不是。HTTP keep-alive 是应用层复用同一 TCP 连接承载多个请求响应；TCP keepalive 是内核在连接长时间空闲后发送探测，判断对端是否仍存活。HTTP 的空闲超时通常是秒到分钟级的业务策略，TCP keepalive 默认可能很久，不能替代应用超时。

### A10. “粘包”的本质是什么？HTTP/1.1 如何确定消息边界？

> TCP 只交付有序字节流，不保留 send 次数，因此一次 recv 可以得到半条、一条或多条应用消息。“粘包”不是 TCP 出错，而是应用协议必须 framing。HTTP/1.1 通过起始行和头部 CRLF、空行、Content-Length、Transfer-Encoding: chunked，以及某些响应的关闭连接语义确定边界。本项目主要覆盖 Content-Length，对 chunked 和流水线支持有限。

---

## B. 线程与 C++ 内存模型

### B1. mutex、condition_variable、semaphore 分别适合什么？

> mutex 保护共享不变量；条件变量让线程在某个受 mutex 保护的条件不成立时睡眠，唤醒后必须用 while 重新检查谓词；信号量保存许可计数，适合表示任务数或资源数。项目中队列结构由 mutex 保护，任务数量由 semaphore 通知。一个原语不能替代另一个职责。

### B2. 工作线程没任务时 CPU 为什么不应升高？

> 应阻塞在 semaphore/condition_variable/futex 等等待点，由生产者唤醒。如果写 `while(queue.empty()) {}` 会忙等，消耗核心且产生缓存一致性流量。用 `top -H/pidstat -t` 看线程 CPU，再用 GDB 栈确认等待位置。

### B3. 线程数怎样确定？

> 先按任务性质给初值：CPU 密集接近可用核心数；存在可测 I/O 等待时可适当增加。然后固定负载扫描线程数，观察吞吐、P95/P99、CPU、上下文切换、队列等待和数据库连接池等待。最佳点由瓶颈决定，不是公式直接给答案。

### B4. volatile、atomic、mutex 有什么区别？

> `volatile` 主要约束对该对象的某些编译器优化，适用于内存映射 I/O 等场景，不建立线程间 happens-before。atomic 让单个原子操作无 data race，并可通过内存序发布/获取数据；mutex 能保护多个字段组成的复合不变量，并在 unlock/lock 间建立同步。把普通标志改 volatile 不是并发修复。

### B5. data race 和 race condition 有何区别？

> data race 是 C++ 的严格概念：两个线程并发访问同一内存位置，至少一个写，且没有 happens-before、也不是合适的原子访问，会导致未定义行为。race condition 是更广的逻辑结果依赖时序，即使全用 atomic，也可能先检查后执行而产生逻辑竞态。前者一定要消除，后者要通过协议和状态机设计保证不变量。

### B6. 为什么 atomic 可能修好吞吐，但仍不是最终方案？

> atomic 能让忙等条件被正确观察，消除该标志的 data race，所以活性恢复；但主事件线程仍然等待某个工作线程，每轮都在反复加载原子，事件循环被串行化且 CPU 高。最终应改变控制流，用事件通知或任务完成队列异步推进，而不是把错误的忙等写得“线程安全”。

### B7. detached 线程为什么容易 UAF？

> detached 线程没有可等待的生命周期。如果拥有它所访问资源的对象先析构，线程仍可能访问已释放的队列、连接池、回调捕获的 this。应明确线程归属，提供 stop token/停止标志，唤醒等待线程并 join，再释放共享资源。

### B8. 数据库连接为什么用 RAII，而不是 shared_ptr？

> 池对连接有所有权，请求只是独占租借。RAII guard 表达“作用域内借用、离开自动归还”。普通 shared_ptr 表达共享所有权，无法天然阻止连接归还后仍被旧持有者使用，也不能保证同一 MySQL 连接只有一个线程操作。

### B9. 单例就是线程安全吗？

> C++11 局部静态对象的初始化是线程安全的，但单例内部的可变状态仍需同步，析构顺序、后台线程、flush 和测试隔离也仍是问题。只能说“初始化安全”，不能扩大成“所有成员操作安全”。

---

## C. HTTP、文件与安全

### C1. 如果 Content-Length 是负数、极大值或重复冲突怎么办？

> 按无符号受限整数解析，检查非数字、符号、溢出和上限；多个 Content-Length 值不一致应拒绝；长度超过缓冲/策略限制返回 413。验证 `body_start + length` 前先做减法式边界检查，避免整数溢出。绝不能直接 `atoi` 后无条件写固定数组。

### C2. GET 和 POST 的核心区别是什么？

> 它们是 HTTP 方法语义：GET 用于获取资源，应当安全且幂等；POST 提交要处理的表示，通常不保证幂等。它们都可以有头部，消息可能跨任意数量 TCP 段。请求体有无和分包数量不能用方法名推断。

### C3. 为什么“GET 一次读完，POST 需要两次读”是错的？

> TCP 分段受 MSS、拥塞、Nagle、客户端写法和调度影响。很短的 POST 可能一次 recv 全到，很短的 GET 也可能分两次。服务器必须只依据已经收到的字节和 HTTP framing 判断完整性。

### C4. 空 POST、超长请求行、畸形 CRLF 应怎样处理？

> 解析前验证指针和长度；空 body 不能对空指针做 `strchr/strcpy`；请求行和头部超过上限返回 414/431 或 400；裸 LF、非法方法、非法版本按明确兼容策略拒绝。错误路径也必须生成正确 Content-Length 并决定是否关闭连接。

### C5. 如何防路径穿越？

> 先百分号解码，再规范化 `.`、`..` 和重复分隔符，拒绝 NUL 等非法字节；使用 `openat` 从预先打开的 docroot 目录逐级解析，并配合 `O_NOFOLLOW` 防符号链接逃逸；或者取 `realpath` 后验证结果仍在规范化 docroot 边界内。简单检查 URL 是否包含字符串 `..` 不充分。

### C6. 如何防 SQL 注入？

> 不把用户名密码拼进 SQL 字符串，使用 MySQL 预处理语句和参数绑定；同时限制字段长度、处理编码、最小化数据库账号权限，并给唯一键和错误返回建立正确语义。转义字符串只是次优防线，不应代替参数化查询。

### C7. 全局用户 map 有什么问题？

> 启动时缓存可减少查询，但注册写与登录读需要一致的同步；多进程/多实例之间不会自动同步；密码明文驻留内存也不安全；数据库更新成功但 map 更新失败或反之会出现一致性问题。生产中应使用密码哈希、数据库唯一约束、合适缓存及失效策略。

### C8. mmap 失败、零长度文件、客户端中途断开怎么处理？

> `open` 检查负值；零长度文件不应盲目 mmap，直接发只含头部的 200；`mmap` 返回 `MAP_FAILED` 而不是 nullptr；writev 若遇 EPIPE/ECONNRESET 要停止发送并只 unmap 一次；忽略 SIGPIPE 或使用 MSG_NOSIGNAL。所有退出分支要保持 fd、映射和定时器所有权一致。

### C9. HTTPS 应放在哪里？

> TLS 位于 TCP 与 HTTP 解析之间。事件循环仍监听 socket 就绪，但读写要经过 SSL 状态机，`SSL_read/SSL_write` 可能要求等待相反方向的事件。工程上也可让 Nginx/Envoy 终止 TLS，后端保留 HTTP。不能只在 URL 支持 `https://` 字符串就宣称服务器支持 HTTPS。

---

## D. 性能与故障定位

### D1. Webbench 的结果怎样讲才可信？

> 说明代码提交、编译器和优化级别、机器、核数、并发、时长、URL/文件大小、触发模式、日志开关、客户端位置、成功失败数。重复多轮报告分布。Webbench 的 speed 可做回归，但没有 P95/P99，所以不能据此声称低延迟。

### D2. 为什么“官方 7 万 QPS，我也是 7 万”没有意义？

> 机器、资源大小、网络、连接复用、编译优化、并发和工具都可能不同。数字只有在同条件对照中才有解释力。面试中应该讲自己的可复现实验和边界，不搬 README 数字。

### D3. ET 一定比 LT 快吗？

> 不一定。ET 可能减少重复通知和系统调用，但 drain loop 单次处理更久，公平性更难；LT 更简单稳定。差异取决于连接活跃度、每次数据量和业务成本。要在相同工作量与错误率下测吞吐和尾延迟。

### D4. CPU 100% 但吞吐低，先查什么？

> 先看每线程 CPU 和运行/等待状态；检查忙等、错误日志风暴、频繁 epoll_ctl、锁自旋和无进展重试。用 `pidstat -t`、`perf top/record`、GDB 栈和 strace 建证据。若热点在等待标志循环，先做同步和控制流对照，不要盲目扩线程。

### D5. CPU 接近 0、吞吐也接近 0，意味着什么？

> 可能所有线程都睡眠：主线程在 epoll_wait，工作线程在 semaphore；真正的问题可能是 ONESHOT 未 rearm、任务未入队、通知丢失、监听错误或连接建立失败。低 CPU 不代表健康，要结合线程栈、fd/epoll 状态和网络抓包。

### D6. 一个月才崩一次，怎样定位？

> 先开启 core dump、构建带符号且保留优化的二进制，记录提交和运行配置；增加连接 ID/generation、状态转换和资源计数日志；用 ASan/UBSan 做压力回归，用 TSan 在较小负载查 data race；为 fd 高频复用、断开、超时、队列满建立故障注入。崩溃后先保存 core、二进制和库，再 `thread apply all bt full`，不能重启后只靠猜。

---

# 第四部分：四项“真正掌握项目”的实战能力

## 11. “30 分钟内增加一个简单路由或修改超时策略”到底是什么？

它不是要求 30 分钟重写路由框架，而是考你是否知道一个需求应该落在哪一层、改哪些状态、如何验证且不破坏其他路径。

## 11.1 任务 A：增加一个简单静态路由

需求示例：访问 `/about` 时返回 `root/about.html`。

### 你要先定位

- 请求目标在 `parse_request_line()` 中写入 `m_url`。
- 资源映射在 `http_conn::do_request()`。
- 现有 `/0`、`/1`、`/5` 等魔法路由也在这里。
- 文件检查、mmap 和响应生成已经存在，不要重复造发送逻辑。

### 最小实现思路

下面是一种与当前 C++11 构建兼容的最小写法。它只把两个已知路由映射到固定文件名；固定目标不含用户输入，`snprintf` 负责长度检查：

```cpp
const char* target = nullptr;
if (strcmp(m_url, "/about") == 0) {
    target = "/about.html";
} else if (strcmp(m_url, "/") == 0) {
    target = "/home.html";
}

if (target != nullptr) {
    const int n = snprintf(m_real_file, FILENAME_LEN, "%s%s", doc_root, target);
    if (n < 0 || n >= FILENAME_LEN) {
        return BAD_REQUEST;
    }
    // 后续复用已有 stat/open/mmap 流程
}
```

实际操作还要先在 `root/about.html` 准备资源。未知 URL 不能直接套用这段固定路由逻辑；仍要经过路径规范化和 docroot 限制。更进一步可把魔法字符分支重构为 C++11 可用的只读路由表：

```cpp
static const std::unordered_map<std::string, std::string> routes{
    {"/", "/home.html"},
    {"/about", "/about.html"},
    {"/login", "/log.html"},
};
```

但 30 分钟小题不要顺手重写整个 HTTP 模块。先做有边界检查的最小变更，再说明生产化会把路由、静态文件和认证从 `http_conn` 拆开。

### 验收

```bash
curl -i http://127.0.0.1:9006/about
curl -i http://127.0.0.1:9006/not-found
curl -i 'http://127.0.0.1:9006/../../etc/passwd'
```

至少确认：新路由 200；旧路由不回归；未知路由 404；路径穿越不能逃出 docroot；keep-alive 下连续请求仍正常。

### 路由题面试时怎么讲

> 我会先沿 `parse_request_line -> do_request -> process_write` 定位职责。简单静态路由只改变 URL 到资源的映射，不改 epoll 和发送状态机。我会使用有长度检查的映射函数，不继续堆 strcpy；然后用 200、404、路径穿越和 keep-alive 四组用例回归。如果需求继续增长，再引入路由表和 handler，把认证、数据库和文件服务从 http_conn 拆开。

## 11.2 任务 B：修改空闲超时策略

当前代码中：

```text
TIMESLOT = 5 秒
新连接/活动后 expire = now + 3 * TIMESLOT = 15 秒
alarm 每 5 秒扫描一次
```

### 最粗糙的改法

直接改 `TIMESLOT`。例如从 5 改到 10，会同时把：

- 扫描周期从 5 秒改成 10 秒；
- 名义连接超时从 15 秒改成 30 秒。

这能跑，但把“检查粒度”和“业务超时”耦合在一起，不是好设计。

### 面试级改法

拆成两个参数：

```cpp
constexpr int TIMER_TICK_SECONDS = 5;
constexpr int IDLE_TIMEOUT_SECONDS = 30;

timer->expire = time(nullptr) + IDLE_TIMEOUT_SECONDS;
alarm(TIMER_TICK_SECONDS);
```

进一步可以区分：

- header timeout：多久没收完请求头；
- body timeout：多久没收完请求体；
- keep-alive idle timeout：两次请求之间空闲多久；
- write timeout：客户端长时间不读时停止占用发送资源。

只在任何字节到来时无限续期也会被 slowloris 利用，因此生产策略通常还需要绝对截止时间或最小传输速率。

### 如何验证

1. 建立 TCP 连接但不发数据，记录实际关闭时间。
2. 每隔小于 idle timeout 的时间发合法数据，确认定时器会续期。
3. 只发送半个请求并极慢续字节，确认 header deadline 能生效。
4. 检查超时后 fd、epoll 注册、定时器节点和连接计数都只清理一次。

### 超时题面试时怎么讲

> 这个小题考的不是改常量，而是理解超时语义。当前 TIMESLOT 同时决定扫描粒度，连接超时是三倍时间片。我会先拆分 tick 和 idle timeout，避免改业务超时同时降低扫描精度；再说明实际关闭有一个 tick 的误差。生产化还应拆 header/body/keep-alive/write timeout，并对慢速攻击设置绝对截止时间。

---

## 12. “能解释并演示一次部分读写”怎样做？

## 12.1 部分读的可复现实验

把一个 HTTP 请求故意拆成三次发送，每次间隔一秒：

```bash
python3 - <<'PY'
import socket, time
s = socket.create_connection(("127.0.0.1", 9006))
for part in [b"GET / HTTP/1.1\r\nHo", b"st: localhost\r\nConnec", b"tion: close\r\n\r\n"]:
    s.sendall(part)
    time.sleep(1)
print(s.recv(4096).decode("latin1", errors="replace"))
PY
```

预期观察：

1. 第一次只形成不完整头部，`process_read()` 返回 `NO_REQUEST`。
2. 连接被 rearm 为 EPOLLIN，游标不清零。
3. 第三次收到空行后，请求才变成完整请求并生成响应。

可以在 `read_once()`、`parse_line()`、`process_read()` 打条件日志或下断点，记录：

```text
m_read_idx, m_checked_idx, m_start_line, m_check_state, return_code
```

演示重点不是“sendall 被拆成三个 TCP 包”——实际网络分段仍由系统决定——而是应用在三个时间点只提供部分字节，服务器不能依赖一次读完整。

## 12.2 部分写的可复现实验

目标是让服务端发送速度大于客户端接收速度，直到 socket 发送缓冲区装不下：

1. 准备一个较大的静态文件，例如几十 MB。
2. 测试构建中把已连接 socket 的 `SO_SNDBUF` 调小，例如 4 KiB。
3. 客户端限速或故意暂停读取。
4. 用 `strace -f -e trace=writev -p <pid>`，或在 `http_conn::write()` 对 `temp` 下断点。

慢客户端示例：

```bash
curl --limit-rate 1k -o received.bin http://127.0.0.1:9006/large.bin
sha256sum root/large.bin received.bin
```

预期观察：

- 一次 `writev` 返回值小于总待发送字节；
- 若缓冲区满，出现 `-1 EAGAIN`；
- fd 被监听 EPOLLOUT，下一次从原进度继续；
- 最终哈希一致，证明没有遗漏和重复；
- 发送完成后才 unmap。

慢客户端只能提高短写概率。为了**确定性**复现当前 bug，还要把 iovec 消费逻辑抽成不依赖 socket 的纯函数，直接喂入固定返回序列：

| 初始段 | 模拟 writev 返回序列 | 每一步正确剩余 |
|---|---|---|
| 头 200、文件 1000 | `120` | 头 80、文件 1000 |
| 接上一步 | `10` | 头 70、文件 1000 |
| 接上一步 | `100` | 头 0、文件 970 |

断言每一步满足：

```text
剩余总长度 = 上一步剩余总长度 - 本次返回值
base 只向前移动，不回退
任一 len 不下溢
所有模拟返回值之和 + 最终剩余值 = 初始总长度
```

当前算法在第二步就会把累计 130 与当前头部 len 80 比较，错误进入文件段。这个纯函数测试比依赖真实网络调度更稳定；网络慢客户端测试用于验证集成路径和 EPOLLOUT rearm。

## 12.3 面试时的完整表述

> 部分读写不是异常，而是流式非阻塞 I/O 的正常语义。我的解析状态跨事件保存，读到完整 HTTP 边界才消费；写路径根据实际返回值消费 iovec，EAGAIN 时保存剩余进度并等待 EPOLLOUT。我用拆分请求演示半包，用小 SO_SNDBUF、大文件和慢客户端制造短写，并用 writev 跟踪和文件哈希验证结果。这样证明的不是“代码里有 while”，而是状态确实能跨多次事件正确推进。

---

## 13. “能复现、定位一个崩溃或并发问题”怎样做？

最有价值的案例是本仓库已经完成证据链的 Reactor `-O2` 活性故障。

## 13.1 现象

- 历史 Reactor 在 `-O2` 下，30 秒只完成百次级请求。
- CPU 不是持续高占用，主线程多在 `epoll_wait`，工作线程多在 `sem_wait`。
- 不能仅凭现象说“线程池坏了”或“epoll 丢事件”。

## 13.2 源码假设

历史路径大致是：

```text
main: append(request) -> while (!request->improv) {} -> 看 timer_flag
worker: 执行 read/write -> 写 timer_flag/improv
```

`improv/timer_flag` 是普通整数，被不同线程无同步访问，构成 data race；忙等还让事件循环等待工作线程。

## 13.3 建立最小对照矩阵

保持机器、负载和代码尽量不变，只改变一个变量：

| 组别 | 目的 |
|---|---|
| `-O0 + 普通 int` | 看未优化构建表现 |
| `-O2 + 普通 int` | 复现历史故障 |
| `-O2 + volatile` | 证明 volatile 不是 C++ 同步方案 |
| `-O2 + atomic` | 验证正确可见性/同步能否恢复活性 |
| `-O2 + 异步重构` | 验证取消等待后的正确性和 CPU |

### 可直接复用的仓库证据和命令

本仓库已经保存完整脚本与原始输出，不要在当前工作树里反复 checkout。先阅读：

```bash
cd benchmark_results/2026-07-16-o2-race-forensics
less README.md
```

在 Linux 环境准备好 MySQL/MariaDB 开发库和 Webbench 后，可让脚本从固定提交导出到临时目录并顺序测试。路径按实际机器替换：

```bash
cd benchmark_results/2026-07-16-o2-race-forensics

SOURCE_REPO=/absolute/path/to/myWebserver-main \
WEBBENCH_BIN=/absolute/path/to/webbench \
FORENSIC_SCOPE=all \
bash ./run_forensics.sh
```

只复现官方固定提交或 atomic 消融时：

```bash
FORENSIC_SCOPE=official \
WEBBENCH_BIN=/absolute/path/to/webbench \
bash ./run_forensics.sh

FORENSIC_SCOPE=atomic \
SOURCE_REPO=/absolute/path/to/myWebserver-main \
WEBBENCH_BIN=/absolute/path/to/webbench \
bash ./run_forensics.sh
```

若手工构建，决定性条件是保留 `-O2`，源码列表与历史命令一致：

```bash
DB_FLAGS="$(mysql_config --cflags --libs 2>/dev/null || mariadb_config --cflags --libs)"

g++ -std=c++11 -O2 -Wall \
  main.cpp timer/lst_timer.cpp http/http_conn.cpp log/log.cpp \
  CGImysql/sql_connection_pool.cpp webserver.cpp config.cpp \
  -o server -pthread $DB_FLAGS

./server -p 9026 -a 1 -m 0 -c 1
webbench -c 100 -t 30 http://127.0.0.1:9026/
```

其中 `-a 1` 选择 Reactor，`-m 0` 是 LT/LT；ET/ET 使用仓库配置约定的 `-m 3`。每组必须独立启动和停止服务器，不能让两个服务端在同一台 2 核机器上同时争抢 CPU。脚本还会保存 ELF、元数据、CPU、线程状态、反汇编和 Webbench 原始输出，优先使用脚本而不是只截图终端结果。

## 13.4 收集证据

```bash
# 进程/线程 CPU
pidstat -p <pid> -t 1

# 所有线程栈
gdb -p <pid>
(gdb) thread apply all bt

# 反汇编关键函数
objdump -dC ./server | less

# data race（使用适合 TSan 的独立构建）
-fsanitize=thread -fno-omit-frame-pointer -g
```

本次证据显示，普通 `int + -O2` 的机器码不再反复读取 `improv` 等待条件；atomic 对照恢复了读取循环和吞吐。这比“可能是缓存没刷新”更准确：根因是源码 data race 导致未定义行为，编译器优化只是把它暴露出来。

## 13.5 修复层次

1. 最小 atomic 修复：消除该 data race，验证根因；但保留忙等，不作为最终架构。
2. 正式修复：不可变任务项携带状态与 generation；主线程不等待。
3. 成功路径：工作线程完成后 rearm ONESHOT。
4. 失败路径：失败记录入互斥队列，写 eventfd 唤醒主循环统一清理。
5. 生命周期：generation 拒绝迟到的工作线程失败关闭；线程池可停止并 join。

## 13.6 回归验证

- LT/LT、ET/ET 和两种 actor 模式。
- 正常请求、半包、keep-alive、异常断开、队列满、超时。
- 吞吐、失败、CPU、线程栈。
- ASan/UBSan/TSan 分别验证内存、未定义行为和数据竞争。
- 多轮测试，不能只选最好的一轮。

## 13.7 两分钟 STAR 回答

> **S**：历史 Reactor 在恢复 `-O2` 后出现百次级低吞吐，但进程 CPU 接近空闲。  
> **T**：我要区分负载问题、epoll 通知问题、线程池问题和编译优化暴露的并发错误。  
> **A**：我沿 eventLoop、dealwithread/write 和 threadpool::run 追踪共享状态，建立 `-O0/-O2/volatile/atomic/正式重构` 矩阵，保存反汇编、线程 CPU 和 GDB 栈。机器码证明普通 int 版本删除了等待读取，atomic 恢复活性但 CPU 仍高。最终我移除主线程忙等，用不可变任务、ONESHOT、eventfd、generation 和 joinable 线程完成异步化。  
> **R**：同机同负载下恢复到约 1.28 万至 1.31 万 req/s；相对 atomic 对照，吞吐接近但 CPU 下降约 35% 至 39%，错误为 0。我把结论限定为该版本和实验条件，不宣称通用千倍优化。

### 如果面试官给的是“偶发崩溃”而不是低吞吐

遵循同一方法：

```text
保留现场 -> 固定版本和二进制 -> core + 全线程栈
-> 确认崩溃类型 -> 缩小到对象/线程/状态
-> sanitizer 或故障注入复现 -> 最小修复
-> 原失败用例 + 全量回归 -> 再谈性能
```

不要先加锁或 catch；那可能掩盖 UAF、重复关闭或越界。

---

## 14. “至少五个原项目缺陷及可落地改进”怎样回答？

面试中不要只列“代码耦合、性能不好”。每个缺陷按五句话讲：**触发条件—根因—影响—改法—验证**。

下表列出 12 个可选问题，并直接标出当前 `236d3ff` 的状态。

| # | 原始/历史问题 | 当前状态 | 根因与影响 | 可落地改进 | 验证方法 |
|---:|---|---|---|---|---|
| 1 | 路径穿越 | **仍存在** | URL 直接拼 docroot，`../`、编码和符号链接可能逃出站点目录，泄露系统文件 | URL 解码与规范化；`openat` + `O_NOFOLLOW`；验证解析结果仍在 docroot | 请求明文/编码 `../`、符号链接，确认 403 且敏感文件不可读 |
| 2 | Content-Length 越界 | **仍存在** | `atoi`/固定缓冲区和不完整边界校验可导致负数、溢出、越界或请求走私 | 受限整数解析；冲突长度拒绝；header/body 上限；返回 400/413/431 | 负数、超大、非数字、重复冲突、刚好边界做单测和 ASan |
| 3 | 空或畸形 POST 崩溃 | **仍需加固** | 登录注册路径假设 body 和分隔符存在，对空指针做字符串操作 | 先验证 method、content-type、长度和键值；使用长度安全解析器 | 空 body、缺 `&`、缺 `=`、超长字段、二进制 NUL fuzz |
| 4 | Reactor 普通标志 data race + 忙等 | **当前已修复** | 历史版跨线程读写 `improv/timer_flag` 无 happens-before；`-O2` 出现 UB；即使可见仍阻塞事件循环 | 当前已使用不可变任务、ONESHOT 成功推进和 eventfd 失败通知；保留消融回归 | `-O0/-O2/atomic` 矩阵、TSan、反汇编、CPU 和吞吐回归 |
| 5 | fd ABA / 迟到任务 | **部分缓解** | fd 关闭后整数迅速复用，旧回调可能关闭或操作新连接 | 当前 generation 过滤失败通知；进一步让 epoll 事件携带 token，并统一连接所有权 | 高频 connect/close + 延迟失败/旧事件注入，确认新连接不被误关 |
| 6 | 定时器悬空、重复关闭 | **部分缓解，仍需系统验证** | 异常事件、超时、工作线程失败可能同时清理同一 fd/timer | 单线程统一关闭；状态机 CAS/幂等 close；删除后置空；timer 持稳定 ID | 超时与 RST 同时注入，ASan，连接计数和 close 次数断言 |
| 7 | detached 线程析构 UAF | **线程池已修；日志线程仍 detached** | 后台线程无法 join，共享资源可能先析构 | 日志线程也增加停止协议；唤醒、join 后再释放队列和文件 | 循环启动停止、队列非空析构，ASan/TSan 验证 |
| 8 | `writev` 部分写进度错误 | **当前已确认存在** | 把累计值与已修改 iov_len 混用，连续短写会漏发、过早切段或长度下溢 | 用本次返回值逐段 consume；保存稳定 header/file sent 计数 | 纯函数短写序列单测 + 小 SO_SNDBUF + 慢客户端 + 哈希比对 |
| 9 | `open/mmap`/零长度处理不足 | **仍存在** | 未完整检查 open、`MAP_FAILED`、空文件和关闭时序 | 封装 FileRegion RAII；空文件不 mmap；每个错误映射 4xx/5xx | 权限、删除竞态、空文件、映射失败、客户端中断 |
| 10 | SQL 注入和固定 C 字符串 | **仍存在** | 表单值拼接 SQL、`strcpy/sprintf` 容易注入和溢出 | prepared statement；字段上限；密码哈希；数据库唯一约束 | 注入 payload、超长用户名、并发注册、数据库失败回滚 |
| 11 | 信号处理函数错误分支不安全 | **仍存在** | 正常路径 write 安全，但错误分支使用 iostream/strerror 等非异步信号安全操作 | handler 只保存 `sig_atomic_t` 或 write 固定字节；日志回主循环 | 信号风暴、管道写满，检查无死锁/递归日志 |
| 12 | `http_conn` 职责过重和魔法路由 | **仍存在** | HTTP 解析、文件、认证、SQL、路由、发送耦合，难测难扩展 | 拆 `HttpParser/HttpRequest/Router/StaticFileHandler/AuthService/HttpResponse` | 各模块单测；增加路由不改解析/epoll；依赖方向检查 |

## 14.1 面试中挑五个怎样组合最好

推荐组合覆盖五种能力：

1. **协议安全**：路径穿越。
2. **边界与内存安全**：Content-Length / 空 POST。
3. **并发正确性**：Reactor data race 和忙等。
4. **生命周期**：fd ABA、定时器或 detached 线程。
5. **流式 I/O**：writev 部分写。

这比连续说五个“性能优化点”更能证明 C++ 服务端能力。

## 14.2 五个缺陷的三分钟示范回答

> 第一，原始 URL 直接拼接站点根目录，存在路径穿越风险。我会做 URL 解码和规范化，并用 openat/O_NOFOLLOW 限定目录，再用编码 ../ 和符号链接回归。  
> 第二，Content-Length 与固定缓冲区边界不严谨，畸形长度可能越界。我会用受限整数解析、请求上限和冲突长度拒绝，配合 ASan 和边界用例。  
> 第三，历史 Reactor 用普通 int 跨线程同步且主线程忙等，`-O2` 下触发 UB。我通过反汇编和 atomic 消融验证，最终改成异步任务和 eventfd 通知。  
> 第四，fd 是可复用整数，迟到的工作线程失败通知可能误关新连接。我给每次连接建立 generation，并让这类失败关闭回到事件循环校验；用高频复用和延迟通知做故障注入。当前实现尚未让 epoll 事件本身携带代次，所以我把它表述为部分修复，而不是万能 ABA 方案。  
> 第五，writev 允许部分完成，若偏移更新混用累计长度会漏发或重发。我会按本次返回值逐段消费 iovec，用小发送缓冲区、慢客户端和文件哈希验证。

---

# 第五部分：面试前的可执行验收清单

## 15. 必须能白板写出的最小代码

- `socket/bind/listen/accept`，完整错误检查。
- 非阻塞 `fcntl` 或 `accept4`。
- `epoll_create1/epoll_ctl/epoll_wait` 主循环。
- ET `accept/read` 到 EAGAIN。
- 一个带剩余缓冲区的发送状态机。
- `mutex + condition_variable` 有界任务队列。
- RAII guard：构造获取资源、析构释放。

## 16. 必须能脱稿画出的四张图

1. 项目模块图：epoll、连接对象、线程池、定时器、日志、数据库池。
2. 请求时序图：accept 到 writev，再到 keep-alive/close。
3. HTTP 主从状态机。
4. 修复前 busy-wait 与修复后 eventfd/ONESHOT 流程。

## 17. 必须亲手完成的四个实验

- 拆成三段发送一个 HTTP 请求，展示半包状态保留。
- 大文件 + 慢客户端制造部分写/EAGAIN，最终哈希一致。
- 增加 `/about` 路由或把 idle timeout 与 timer tick 解耦。
- 用 `-O0/-O2/atomic` 对照和线程栈解释 Reactor 并发故障。

## 18. 自测题：答不完整就继续补

1. `recv == 0`、`EAGAIN`、`EINTR` 分别是什么？
2. 为什么 ET 未读数据不是丢失，却可能永久卡住？
3. 为什么 EPOLLOUT 不能一直订阅？
4. ONESHOT 能保证什么，不能保证什么？
5. 项目模拟 Proactor 为什么不是真正 Proactor？
6. HTTP 请求边界由什么确定，和 TCP 包有什么关系？
7. 部分 writev 如何跨过头部进入文件段？
8. 客户端不读响应时，服务器如何做背压？
9. 队列满为什么是容量规划问题，不只是 append 返回 false？
10. volatile 为什么不能修 data race？
11. fd generation 解决了什么，仍没解决什么？
12. 15 秒超时为什么可能约 15 到 20 秒才执行清理？
13. 路径规范化为何不能只查字符串 `..`？
14. 怎样证明性能提升不是客户端、编译参数或错误响应造成的？
15. 你亲自完成的改动与原作者功能分别是什么？

## 19. 最后的面试表达原则

- 不说“epoll 永远 O(1)”；说关注集合、就绪事件和适用负载。
- 不说“ET 数据会丢”；说未排空可能不再收到边沿通知。
- 不说“mmap + writev 就是完全零拷贝”；说减少应用侧拷贝和聚合发送。
- 不说“volatile 保证线程可见性”；说 C++ 同步必须用 atomic、锁或明确事件协议。
- 不说“项目是 Proactor”；说同步非阻塞 I/O 模拟 Proactor。
- 不说“我做了 TinyWebServer 全部功能”；严格区分上游与自己的审计、修复和实验。
- 不只报 QPS；同时报条件、失败、CPU、延迟和重复性。
- 不只列缺陷；给出触发、根因、影响、修复和验证。

当你能够完成本文的四个实验、脱稿回答 15 个主问题，并经得住第三部分至少两层追问时，这个项目才真正达到“可以写进 C++ 求职简历并承担追问”的程度。

---

## 20. 规范与延伸阅读

- [TinyWebServer 官方仓库](https://github.com/qinguoyi/TinyWebServer)
- [Linux epoll(7)](https://man7.org/linux/man-pages/man7/epoll.7.html)
- [Linux recv(2)](https://man7.org/linux/man-pages/man2/recv.2.html)
- [Linux writev(2)](https://man7.org/linux/man-pages/man2/writev.2.html)
- [Linux sendfile(2)](https://man7.org/linux/man-pages/man2/sendfile.2.html)
- [Linux tcp(7)](https://man7.org/linux/man-pages/man7/tcp.7.html)
- [RFC 9112: HTTP/1.1](https://www.rfc-editor.org/rfc/rfc9112)
- 本仓库专题笔记：[2026-07-15-Reactor并发模型缺陷修复与面试复盘.md](./2026-07-15-Reactor并发模型缺陷修复与面试复盘.md)
