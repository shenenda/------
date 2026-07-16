# 2026-07-16 Reactor `-O2` 数据竞争取证实验

## 最终结论

历史结果中 Reactor 30 秒只完成 108/359 个请求的根因已经复现并确认：

1. TinyWebServer 官方 Reactor 路径使用普通 `int improv`、`int timer_flag` 在主线程和工作线程之间同步，构成 C++ 数据竞争，程序行为未定义。
2. 当时实际使用的构建命令包含 `-O2`。GCC 11.4 在该优化级别下删除了 `while (true)` 中对 `improv` 的等待判断，主线程在工作线程完成前就检查并清零状态。
3. 连接的 `EPOLLONESHOT` 状态和失败清理时序随后被破坏。短暂处理约一百个请求后，主线程进入 `epoll_wait`，8 个工作线程全部进入 `sem_wait`，服务器几乎不再产生有效工作，所以 CPU 约为 0%，但吞吐也接近 0。
4. 同一提交使用 `-O0`、`-O2 + atomic` 或当前正式修复后都恢复到每 30 秒约 36 万至 41 万个请求。
5. 官方固定提交 `4bcf887` 使用 `-O2` 也实际复现了同类低吞吐，证明缺陷来自上游实现，不是本项目的注释、数据库配置或压测文件引入的。

因此，这次故障不是“Reactor 天生不占 CPU”，也不是 Webbench 并发数太少，而是**未定义行为在优化构建中破坏了服务器活性**。

## 为什么前一次复测没有发现

前一次受控复测使用官方 Makefile 的 `-g` 构建和本项目未指定优化级别的 `g++` 构建，实际都相当于 `-O0`。`-O0` 生成的机器码会在循环中反复从内存读取 `improv`，偶然掩盖了数据竞争。

原始会话中实际给出的历史构建命令是：

```bash
DB_FLAGS="$(mysql_config --cflags --libs 2>/dev/null || mariadb_config --cflags --libs)"

g++ -std=c++11 -O2 -Wall \
  main.cpp \
  timer/lst_timer.cpp \
  http/http_conn.cpp \
  log/log.cpp \
  CGImysql/sql_connection_pool.cpp \
  webserver.cpp \
  config.cpp \
  -o server -pthread $DB_FLAGS
```

优化级别对含有未定义行为的程序不是无关变量。前一次“无法复现”的结论漏掉了这个决定性差异，现已由本报告纠正。

## 实验环境

- 日期：2026-07-16
- 主机：阿里云服务器 `didida`
- 内核：Linux `5.15.0-142-generic`
- 逻辑 CPU：2
- 编译器：GCC 11.4.0
- MySQL：运行中
- Webbench：100 客户端，30 秒
- 服务端线程：默认 8
- 日志：`-c 1` 关闭
- 地址：`127.0.0.1:9026`
- 修复前提交：`a57a275b4866cbc309f51f00da24dcc081030775`
- 正式修复代码：`8d225cb523a92472e3141bed542a29eb53879ec1`，业务源码等同于修复提交 `7ab4ec7`
- 官方提交：`4bcf88762f85135e9bd46a1032e815e458de6f2e`

所有模式顺序执行，每组独立启动和停止 WebServer。没有同时运行两个服务器，否则会在 2 核主机上互相争抢 CPU，破坏对照。

修复前 `-O2` 重建二进制大小为 103744 字节，`ls -lh` 显示为 102K，与历史截图中的 102K 一致。由于 `server` 被 `.gitignore` 排除，历史 ELF 没有进入 Git，现已无法进行逐字节或 Build ID 完全一致性校验。

## 核心结果

### 本项目修复前、诊断版本与正式修复

| 版本 | 模式 | 成功请求/30s | 吞吐 req/s | 服务器 CPU | 失败 |
|---|---|---:|---:|---:|---:|
| `a57a275 -O0` | LT/LT | 382123 | 12737.43 | 115.77% | 0 |
| `a57a275 -O0` | ET/ET | 360313 | 12010.43 | 117.11% | 0 |
| `a57a275 -O2` | LT/LT | **110** | **3.67** | **0.06%** | 0 |
| `a57a275 -O2` | ET/ET | **119** | **3.97** | **0.06%** | 0 |
| `a57a275 -O2 + volatile` | LT/LT | 206628 | 6887.60 | 59.23% | 0 |
| `a57a275 -O2 + volatile` | ET/ET | 227330 | 7577.67 | 60.93% | 0 |
| `a57a275 -O2 + atomic` | LT/LT | 408165 | 13605.50 | 114.33% | 0 |
| `a57a275 -O2 + atomic` | ET/ET | 384738 | 12824.60 | 115.99% | 0 |
| 正式修复版 `-O2` | LT/LT | 394167 | 13138.90 | 74.42% | 0 |
| 正式修复版 `-O2` | ET/ET | 382802 | 12760.07 | 71.33% | 0 |

这组消融实验把两个问题分开了：

- `atomic` 保留原等待循环，只修复共享标志的数据竞争。吞吐恢复，但 CPU 仍为 114% 至 116%。
- 正式修复版取消主事件线程等待，以 `EPOLLONESHOT` 推进成功路径，以 `eventfd` 通知失败路径。相对 `atomic` 版本，LT/LT CPU 降低 34.91%，ET/ET CPU 降低 38.50%，吞吐分别变化 -3.43% 和 -0.50%。
- `volatile` 仅用于诊断。它迫使编译器重新读取字段，所以恢复了活性，但不建立 happens-before，不能作为 C++ 线程同步修复。

正式修复版相对故障 `-O2` 版，本轮完成请求数恢复为 LT/LT 3583.34 倍、ET/ET 3216.82 倍。这应表述为**消除活性故障后的恢复倍数**，不能宣传为所有环境下都成立的通用性能加速比。

### 官方原版 `-O2` 实测

官方源码通过 `core.autocrlf=false` 从 Git 对象导出，仅替换 `main.cpp` 中数据库用户名、密码和库名，以连接现有 MySQL；并发实现保持提交 `4bcf887` 原样。首页为官方 `root/judge.html`，响应 586 字节。

| 官方版本 | 模式 | 成功请求/30s | 吞吐 req/s | 服务器 CPU | 失败 |
|---|---|---:|---:|---:|---:|
| `4bcf887 -O2` | LT/LT | **149** | **4.97** | **0.09%** | 0 |
| `4bcf887 -O2` | ET/ET | **440** | **14.67** | **0.16%** | 0 |

这两组不是只看相同源码得出的判断，而是在云服务器上完整执行了构建、启动、HTTP smoke、30 秒 Webbench、CPU 采样、进程状态采样和停止流程。结果与历史 359/108 同属百次级请求、近零 CPU、零失败的故障形态。由于程序已经发生数据竞争，不应期待 LT/ET 每轮都得到相同的精确百次数字；可重复的是数量级、线程停滞状态和机器码控制流。

## 机器码证据

`http_conn` 中 `timer_flag` 位于对象偏移 `0`，`improv` 位于偏移 `4`。这一点也能从 `volatile/atomic` 版本反汇编中看到。

### `-O0` 和 `-O2 + atomic`

两者都会生成重新读取 `improv` 的循环。`atomic` 版本关键指令为：

```text
db70: mov    0x28(%rbp),%rax
db74: mov    0x4(%rax,%rbx,1),%eax   # 读取 improv
db78: cmp    $0x1,%eax
db7b: jne    db70                    # 未完成则重新读取
```

### 普通 `int` 的 `-O2` 版本

`append()` 返回后，机器码中已经没有读取偏移 `4` 的等待条件：

```text
db67: call   threadpool<http_conn>::append(...)
db6c: mov    0x28(%rbp),%rax
db70: add    %rbx,%rax
db73: cmpl   $0x1,(%rax)             # 直接检查 timer_flag
db76: je     dd30
db7c: movl   $0x0,0x4(%rax)          # 直接清零 improv
db83: ...
db91: ret
```

源码中的 `while (true)` 只有在另一个线程修改 `improv` 时才能退出，但这种普通变量跨线程修改在 C++ 抽象机中没有合法同步。GCC 因此可以基于未定义行为和前进保证优化掉等待条件。这里不能只描述为“CPU 缓存没刷新”，因为实际机器码已经根本不再执行该条件读取。

官方 `4bcf887 -O2` 生成了相同结构：调用 `append()` 后不读取 `improv`，直接检查 `timer_flag` 并清零 `improv`。

## 运行状态证据

故障版压测中和压测后的线程状态一致：

```text
主线程       ep_poll
8 个工作线程 futex_wait_queue_me
```

GDB 调用栈显示主线程位于：

```text
epoll_wait
WebServer::eventLoop()
main
```

工作线程均位于：

```text
sem_wait
threadpool<http_conn>::run()
threadpool<http_conn>::worker(void*)
```

这解释了为什么故障时 CPU 基本为 0：服务器不是高效地空闲，而是在短暂错误执行后失去可继续推进的事件和任务。只看 CPU，不结合完成请求数与线程等待点，会得到相反结论。

## 完整根因链

```text
普通 int 被主线程读取、工作线程写入
    -> 没有 mutex/atomic/happens-before
    -> C++ data race，行为未定义
    -> GCC -O2 删除对 improv 的等待判断
    -> 主线程在工作线程完成前检查状态并返回
    -> 完成、失败、EPOLLONESHOT 重新武装和连接清理失去可靠时序
    -> 初始少量请求后没有可推进工作
    -> 主线程 epoll_wait，工作线程 sem_wait
    -> CPU 接近 0，30 秒只完成百次级请求
```

此外，即使使用 `atomic` 使等待语义正确，唯一的 epoll 分发线程仍会为每个任务原地轮询，造成高 CPU 和逐事件串行等待。因此正式方案不能停在“把 `int` 改成 atomic”。

## 可以和不可以宣称的结论

可以说：

- 我在历史提交和官方固定提交上都实际复现了 `-O2` 触发的 Reactor 活性故障。
- 我用优化级别、`volatile`、`atomic`、反汇编、线程状态和正式修复组成了因果证据链。
- 正式修复既消除了未定义行为，又取消了事件线程等待，并补齐失败通知与 fd 复用保护。
- 在本轮 100 并发、30 秒、2 核同机测试中，故障版由百次级恢复到约 38 万至 39 万次，失败为 0；相对最小 atomic 修复，CPU 进一步降低约 35% 至 39%。

不可以说：

- 所有机器、负载和页面下都固定提升 3000 多倍；
- `volatile` 能修复 C++ 多线程同步；
- Reactor 模型本身有这个 bug；
- 这是 Linux、epoll 或 GCC 的 bug；
- 当前项目已经达到生产级。

## 文件说明

- `run_forensics.sh`：从固定提交构建并顺序执行所有实验；支持 `FORENSIC_SCOPE=official` 和 `FORENSIC_SCOPE=atomic`。
- `*-webbench.txt`：Webbench 原始输出。
- `*-metadata.txt`：源码提交、构建类型、命令、CPU、smoke 和退出状态。
- `*-cpu.txt`：`pidstat` 原始采样。
- `*-during-process.txt`、`*-post-process.txt`：各线程 CPU 和等待点。
- `*-post-backtrace.txt`：GDB 全线程调用栈。
- `*-elf.txt`：ELF 大小、Build ID 和 SHA-256。
- `*-reactor-entry-disassembly.txt`：`dealwithread/dealwithwrite` 入口的关键反汇编，用于核对优化后的控制流；完整反汇编可由脚本重新生成。
- `atomic/`：最小 `std::atomic<int>` 诊断版本结果。
- `official/`：官方固定提交的实际 `-O2` 结果。

Webbench 1.5 的 `bench()` 会返回局部变量而不是固定返回 0，所以即使输出包含完整 `Speed` 和 `Requests`，进程也可能非零退出。脚本保留退出码，并以两行结果是否齐全判断压测输出是否完整。

## 实验边界

- 每种模式只有一轮正式数据，没有均值、方差或置信区间。
- 压测端和服务端在同一台 2 核主机上，会竞争 CPU。
- Webbench 不提供 P95/P99 延迟。
- 官方页面与本项目页面大小不同，只用于证明官方是否出现同类活性故障，不用于直接比较正常吞吐。
- 原历史 ELF 未被 Git 跟踪，不能证明本次重建与当时二进制逐字节相同；但历史命令、二进制大小、源码结构和百次级故障均已重新对应。
