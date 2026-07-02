# 锁 / 阻塞队列 / WebServer / 数据库连接池核心知识点与面试拷问

> 学习范围：`lock/locker.h`、`log/block_queue.h`、`webserver.h`、`webserver.cpp`、`threadpool/threadpool.h`、`CGImysql/sql_connection_pool.h/.cpp`、`http/http_conn.cpp` 中和数据库连接相关的部分。

这两天学习的主线不是“某几个类怎么写”，而是一个 Linux C++ WebServer 如何把这些基础模块拼起来：

1. 用 `locker.h` 封装 POSIX 同步原语，解决多线程互斥、等待、唤醒问题。
2. 用 `block_queue` 实现生产者-消费者模型，给异步日志提供缓冲区。
3. 用 `WebServer` 统一组织日志、数据库连接池、线程池、epoll、定时器和信号处理。
4. 用数据库连接池降低 MySQL 连接创建/销毁成本，并用 RAII 保证借出的连接能自动归还。

真正的精华是：锁保护共享数据，信号量控制资源数量，条件变量解决“没数据时等待”，RAII 解决“忘记释放资源”，epoll 负责高并发事件分发。

## 1. 锁模块 `locker.h`

### 1.1 三个底层同步资源

`locker.h` 封装了三类 POSIX 同步资源：

| 类 | 底层资源 | 作用 |
|---|---|---|
| `sem` | `sem_t` | 信号量，控制“还有多少个资源可用” |
| `locker` | `pthread_mutex_t` | 互斥锁，保护共享数据临界区 |
| `cond` | `pthread_cond_t` | 条件变量，让线程在条件不满足时睡眠等待 |

它们不是普通变量，而是操作系统维护状态的同步资源。所以现在代码里禁用了拷贝构造和拷贝赋值：

```cpp
sem(const sem &) = delete;
sem &operator=(const sem &) = delete;

locker(const locker &) = delete;
locker &operator=(const locker &) = delete;

cond(const cond &) = delete;
cond &operator=(const cond &) = delete;
```

原因：复制 `pthread_mutex_t`、`pthread_cond_t`、`sem_t` 不会得到一个“新的独立锁/条件变量/信号量”，反而可能让两个 C++ 对象误以为自己管理同一份底层资源，最终出现状态错乱、重复 destroy、等待线程无法唤醒等问题。

### 1.2 `locker` 和 `locker_guard` 的区别

`locker` 是锁本体，里面真正有一个 `pthread_mutex_t m_mutex`。

`locker_guard` 是锁管理器，里面只是保存 `locker& m_locker`，构造时自动 `lock()`，析构时自动 `unlock()`。

区别可以这样记：

| 类 | 是否拥有锁资源 | 主要职责 |
|---|---|---|
| `locker` | 拥有 | 初始化、销毁、加锁、解锁底层互斥锁 |
| `locker_guard` | 不拥有，只引用 | 用 RAII 自动管理某一段作用域的加锁和解锁 |

`locker_guard` 不能拷贝。否则两个 guard 管同一把锁，第一个析构先解锁，第二个析构又解一次，会造成严重错误。

### 1.3 RAII 的本质

RAII 的核心思想是：资源的申请和释放绑定到对象生命周期。

在 `locker_guard` 中：

```cpp
locker_guard guard(m_mutex);
```

这句一执行，构造函数加锁。当前作用域结束时，析构函数自动解锁。无论是正常走到 `}`、函数 `return`，还是抛出异常，析构函数都会执行。

面试回答重点：

> RAII 不是“省几行 unlock 代码”，而是把资源释放变成确定行为，避免多分支 return、异常路径、错误分支遗漏释放资源。

### 1.4 条件变量的关键点

`cond::wait(pthread_mutex_t *m_mutex)` 内部调用 `pthread_cond_wait`。

这个函数会原子地完成三件事：

1. 释放传入的互斥锁。
2. 让当前线程阻塞等待条件变量。
3. 被唤醒后重新尝试加锁，然后返回。

为什么等待条件变量必须配合互斥锁？

因为条件变量只负责“睡眠和唤醒”，真正的条件判断依赖共享变量，比如队列的 `m_size`。共享变量必须用互斥锁保护。

为什么上层必须用 `while`，不能用 `if`？

因为存在虚假唤醒。线程可能在没有真正满足条件时醒来，所以醒来后必须重新判断条件。

正确思想：

```cpp
while (条件不满足) {
    cond.wait(mutex);
}
```

不是：

```cpp
if (条件不满足) {
    cond.wait(mutex);
}
```

### 1.5 `sem::wait()` 处理 `EINTR`

当前 `sem::wait()` 已经处理了 `EINTR`：

```cpp
while (sem_wait(&m_sem) != 0) {
    if (errno != EINTR) {
        return false;
    }
}
```

原因：`sem_wait` 可能被系统信号打断，此时返回失败但 `errno == EINTR`。这不代表信号量逻辑失败，只是被信号中断了，应该继续等待。

## 2. 阻塞队列 `block_queue.h`

### 2.1 它解决什么问题

`block_queue<T>` 是一个线程安全的循环数组队列。

它在项目中主要用于异步日志：

| 角色 | 对应线程 | 行为 |
|---|---|---|
| 生产者 | 业务线程 | 把日志字符串 `push` 到队列 |
| 消费者 | 后台日志线程 | 从队列 `pop` 日志并写文件 |

这样业务线程不用每次都直接等待磁盘 IO。

### 2.2 循环数组的核心变量

```cpp
T *m_array;
int m_size;
int m_max_size;
int m_front;
int m_back;
```

最容易错的是 `m_front` 的语义。

当前实现里：

```cpp
m_front = -1;
m_back = -1;
```

`m_front` 不是当前队首元素下标，而是“上一次出队的位置”。真正队首位置是：

```cpp
(m_front + 1) % m_max_size
```

所以 `front()` 不能写成：

```cpp
value = m_array[m_front];
```

首次 `push` 后，`m_front` 仍然是 `-1`，这样会访问 `m_array[-1]`。

正确写法是：

```cpp
int front_index = (m_front + 1) % m_max_size;
value = m_array[front_index];
```

### 2.3 `push()` 的流程

`push()` 是生产者操作：

1. 加锁。
2. 判断队列是否满。
3. 更新 `m_back = (m_back + 1) % m_max_size`。
4. 写入元素。
5. `m_size++`。
6. 唤醒等待线程。
7. 解锁。

面试要点：

> `m_back` 是最后一次入队的位置，入队前先往后移动一格，然后写入数据。

### 2.4 `pop()` 的流程

`pop()` 是消费者操作：

1. 加锁。
2. 如果队列为空，用条件变量等待。
3. 被唤醒后重新判断 `m_size`。
4. 更新 `m_front = (m_front + 1) % m_max_size`。
5. 取出元素。
6. `m_size--`。
7. 解锁。

核心点：等待必须用 `while (m_size <= 0)`，因为可能虚假唤醒，也可能多个消费者被唤醒后只有一个真正拿到数据。

### 2.5 带超时的 `pop(item, ms_timeout)`

`pthread_cond_timedwait` 要的不是“等待多少毫秒”，而是“绝对时间点”。

所以要先获取当前时间：

```cpp
gettimeofday(&now, NULL);
```

再把 `ms_timeout` 转成绝对时间：

```cpp
long timeout_usec = now.tv_usec + (ms_timeout % 1000) * 1000;
t.tv_sec = now.tv_sec + ms_timeout / 1000 + timeout_usec / 1000000;
t.tv_nsec = (timeout_usec % 1000000) * 1000;
```

这里有两个容易错的点：

1. 毫秒转纳秒是 `ms * 1000000`，不是 `ms * 1000`。
2. 当前时间的微秒部分 `now.tv_usec` 不能丢，否则计算出来的绝对时间点会偏早。

### 2.6 析构函数的边界

`block_queue` 析构时删除数组：

```cpp
delete [] m_array;
```

但这个析构函数有一个重要前提：

> 必须保证没有其他线程继续 `push/pop`，也没有线程阻塞在条件变量上。

如果还有线程在 `pop()` 中等待，析构函数无法安全处理它。真正严谨的生产级队列通常要有 `close` 标志、广播唤醒所有等待线程、让等待线程主动退出。

## 3. WebServer 头文件与源文件

### 3.1 `webserver.h` 是总控类声明

`WebServer` 类是整个项目的调度中心。它不负责具体处理 HTTP 细节，而是把各个模块组织起来：

| 成员 | 作用 |
|---|---|
| `http_conn *users` | 每个客户端连接对应一个 HTTP 连接对象 |
| `connection_pool *m_connPool` | 数据库连接池 |
| `threadpool<http_conn> *m_pool` | 工作线程池 |
| `int m_epollfd` | epoll 实例 |
| `int m_listenfd` | 监听 socket |
| `int m_pipefd[2]` | 信号处理管道 |
| `client_data *users_timer` | 每个连接对应的定时器数据 |
| `Utils utils` | 信号、定时器、fd 操作工具 |

头文件里定义的是“服务器有什么能力、保存什么状态”。源文件里实现的是“这些能力如何按顺序运行”。

### 3.2 构造函数做了什么

`WebServer::WebServer()` 主要做三件事：

1. 创建 `http_conn[MAX_FD]`，准备管理大量客户端连接。
2. 拼接网站根目录 `m_root`。
3. 创建 `client_data[MAX_FD]`，给每个客户端准备定时器数据。

注意这里是大数组和堆内存，需要析构函数释放。

### 3.3 初始化流程

`WebServer` 的典型启动顺序可以理解为：

1. `init()` 保存配置参数。
2. `trig_mode()` 设置 LT/ET 触发模式。
3. `log_write()` 初始化日志系统。
4. `sql_pool()` 初始化数据库连接池，并读取用户表。
5. `thread_pool()` 创建线程池。
6. `eventListen()` 创建监听 socket、epoll、信号管道。
7. `eventLoop()` 进入主事件循环。

面试回答时，不要把这些函数当散点，要说出生命周期顺序。

### 3.4 `eventListen()` 做了什么

`eventListen()` 是服务器网络初始化的核心：

1. `socket()` 创建监听套接字。
2. `setsockopt(SO_LINGER)` 配置关闭行为。
3. `setsockopt(SO_REUSEADDR)` 允许地址复用。
4. `bind()` 绑定 IP 和端口。
5. `listen()` 开始监听。
6. `epoll_create()` 创建 epoll 实例。
7. 把监听 socket 加入 epoll。
8. `socketpair()` 创建管道，用于信号通知主循环。
9. 注册 `SIGPIPE`、`SIGALRM`、`SIGTERM`。
10. `alarm(TIMESLOT)` 启动定时信号。

核心思想：

> 网络事件、定时器信号、关闭信号最终都统一交给 epoll 主循环处理。

### 3.5 为什么要用管道处理信号

信号处理函数里不能做复杂逻辑，因为它可能打断程序任意位置。

这个项目的做法是：

1. 信号来了。
2. 信号处理函数把信号值写入管道。
3. epoll 监听管道读端。
4. 主循环读管道，再执行真正逻辑。

这是一种典型的“统一事件源”思想：把异步信号转换成普通 fd 可读事件。

### 3.6 `eventLoop()` 的主逻辑

`eventLoop()` 中：

```cpp
epoll_wait(m_epollfd, events, MAX_EVENT_NUMBER, -1);
```

返回后逐个处理事件：

| 事件 | 处理函数 |
|---|---|
| 新连接 | `dealclientdata()` |
| 异常关闭 | `deal_timer()` |
| 信号管道可读 | `dealwithsignal()` |
| 客户端可读 | `dealwithread()` |
| 客户端可写 | `dealwithwrite()` |

循环末尾如果 `timeout == true`，就调用：

```cpp
utils.timer_handler();
```

处理超时连接。

### 3.7 Reactor 和 Proactor 在这个项目里的区别

项目中用 `m_actormodel` 区分并发模型。

Reactor 思路：

主线程监听到读/写事件，把任务交给工作线程，工作线程自己执行读/写或业务处理。

Proactor 思路：

主线程先完成读/写，再把业务处理交给工作线程。

在当前代码里：

| 模式 | 读事件处理 |
|---|---|
| Reactor | `m_pool->append(users + sockfd, 0)`，线程池中执行 `read_once()` 和 `process()` |
| Proactor | 主线程先 `read_once()`，再 `append_p()` 给线程池处理 |

面试中不要纠结名字，要讲清楚“谁负责 IO，谁负责业务处理”。

## 4. 线程池 `threadpool.h`

线程池负责把 HTTP 请求交给多个工作线程处理。

核心成员：

```cpp
std::list<T *> m_workqueue;
locker m_queuelocker;
sem m_queuestat;
pthread_t *m_threads;
```

### 4.1 为什么任务队列既要锁又要信号量

互斥锁 `m_queuelocker` 保护任务队列本身，防止多个线程同时修改 `m_workqueue`。

信号量 `m_queuestat` 表示“当前有多少个任务可取”。工作线程调用 `wait()`，没有任务时睡眠，有任务时被唤醒。

这两个东西解决的问题不同：

| 工具 | 解决什么 |
|---|---|
| mutex | 共享队列的互斥访问 |
| semaphore | 任务数量和等待唤醒 |

### 4.2 线程池工作流程

1. 主线程调用 `append()` 或 `append_p()` 把请求放入队列。
2. `m_queuestat.post()` 通知工作线程有任务。
3. 工作线程 `m_queuestat.wait()` 等任务。
4. 加锁取出队首任务。
5. 解锁，执行请求处理。

注意取出任务后要尽快解锁。否则工作线程处理 HTTP 请求时一直占着队列锁，其他线程就无法继续取任务。

### 4.3 数据库连接如何进入请求处理

现在代码中：

```cpp
connectionRAII mysqlcon(&request->mysql, m_connPool);
request->process();
```

含义：

1. 从连接池借一条 `MYSQL*`。
2. 写入 `request->mysql`，让 `process()` 使用。
3. `process()` 结束后，`mysqlcon` 析构。
4. 析构时把 `request->mysql` 置空，并把连接归还池子。

这里不能用 `shared_ptr<MYSQL>` 表达借用，因为 `shared_ptr` 是共享所有权，连接池要求的是独占借用。

## 5. 数据库连接池

### 5.1 为什么需要连接池

如果每次 HTTP 请求都执行：

1. 创建 MySQL 连接。
2. 登录认证。
3. 执行 SQL。
4. 关闭连接。

并发量一高，连接创建和销毁会非常浪费。

连接池的思路是：服务器启动时预先建立若干条连接，请求来了直接借，用完归还。

### 5.2 当前连接池的数据结构

```cpp
list<MYSQL *> connList;
locker lock;
sem reserve;
int m_FreeConn;
int m_CurConn;
```

含义：

| 成员 | 作用 |
|---|---|
| `connList` | 保存当前空闲连接 |
| `lock` | 保护链表和计数器 |
| `reserve` | 记录可借连接数量 |
| `m_FreeConn` | 空闲连接数 |
| `m_CurConn` | 已借出连接数 |

### 5.3 `GetConnection()` 流程

1. `reserve.wait()` 等待有空闲连接。
2. 加锁。
3. 从 `connList.front()` 取一条连接。
4. `pop_front()` 从空闲链表移除。
5. 更新计数器。
6. 解锁。
7. 返回 `MYSQL*`。

重点：

> 返回的 `MYSQL*` 是借用指针，不拥有连接释放权。

### 5.4 `ReleaseConnection()` 流程

1. 检查 `con != nullptr`。
2. 加锁。
3. 把连接放回 `connList`。
4. 更新计数器。
5. 解锁。
6. `reserve.post()` 唤醒等待连接的线程。

重点：

> 连接归还后，原线程不能继续使用这个 `MYSQL*`，因为它可能马上被别的线程借走。

### 5.5 为什么不用 `shared_ptr<MYSQL>`

这是这两天非常重要的一个点。

`shared_ptr` 表达的是“共享拥有”。如果外部复制了一份 `shared_ptr<MYSQL>`，即使 RAII 析构时把连接归还池子，外部那份 `shared_ptr` 仍然有效，仍然可以继续 `mysql_query()`。

这会导致：

1. 线程 A 的 RAII 析构，把连接归还池子。
2. 线程 B 从池子借到同一条连接。
3. 线程 A 手里复制出的 `shared_ptr` 仍然能操作这条连接。
4. 两个线程并发操作同一个 MySQL 连接。

MySQL 连接不是给多个线程同时共享使用的资源，所以这是严重并发隐患。

正确语义：

| 概念 | 应该用什么表达 |
|---|---|
| 连接池拥有连接生命周期 | 连接池负责 `mysql_close` |
| 工作线程临时使用连接 | `MYSQL*` 借用指针 |
| 作用域结束自动归还 | `connectionRAII` |

### 5.6 `connectionRAII` 的意义

`connectionRAII` 不是用来关闭数据库连接，而是用来归还数据库连接。

构造时：

```cpp
*con = connPool->GetConnection();
```

析构时：

```cpp
*sqlRAII = nullptr;
poolRAII->ReleaseConnection(borrowed);
```

先把外部指针置空，再归还连接，目的是降低“归还后继续误用”的风险。

面试回答重点：

> 数据库连接池里的 RAII 管的是“借还关系”，不是“创建销毁关系”。连接创建和销毁属于连接池，业务线程只借用。

## 6. 这两天代码里最有价值的坑

### 坑 1：POSIX 同步资源不能默认拷贝

`sem`、`locker`、`cond` 都必须禁用拷贝。

否则两个对象可能管理同一份底层资源，析构时重复销毁或状态错乱。

### 坑 2：`m_front` 不是当前队首

在当前循环队列实现里，`m_front` 是上一次出队位置。

所以 `front()` 必须读：

```cpp
(m_front + 1) % m_max_size
```

### 坑 3：条件变量要用 `while`

因为虚假唤醒和多消费者竞争，`wait()` 返回不代表条件一定成立。

### 坑 4：超时等待要传绝对时间点

`pthread_cond_timedwait` 需要绝对时间，不是相对时间。毫秒、微秒、纳秒之间的换算必须准确。

### 坑 5：析构函数不是线程退出协议

`block_queue`、`locker`、`cond`、连接池析构时都默认没有其他线程还在使用它们。

如果还有线程在等待或持有资源，单靠析构函数不能安全解决。

### 坑 6：数据库连接池不能用共享所有权表达独占借用

`shared_ptr<MYSQL>` 看起来能自动释放资源，但它表达的语义和连接池要求冲突。

连接池要求同一时刻一条连接只能被一个线程借用。

### 坑 7：线程池队列锁不能覆盖任务执行全过程

锁只保护“取任务”这个共享队列操作。取出任务后应该释放锁，再处理请求。

否则线程池会退化成串行处理。

### 坑 8：epoll 主循环要统一处理多类事件

监听 socket、客户端 socket、信号管道、定时器触发，都通过主循环协调。

这就是服务器总控层的核心价值。

## 7. 面试拷问点

### 7.1 锁和 RAII

**Q1：为什么要自己封装 `locker`，不直接用 `pthread_mutex_t`？**

答题方向：封装可以统一初始化、销毁、加锁、解锁接口，减少直接操作 C API 的重复代码，也方便在项目里形成一致的使用方式。

**Q2：`locker_guard` 和 `locker` 有什么区别？**

答题方向：`locker` 是锁本体，拥有 `pthread_mutex_t`；`locker_guard` 是 RAII 管理器，只引用锁，构造加锁，析构解锁。

**Q3：为什么 `locker_guard` 要禁用拷贝？**

答题方向：如果两个 guard 管同一把锁，会出现重复解锁、提前解锁等问题，破坏临界区安全。

**Q4：`sem`、`locker`、`cond` 为什么也要禁用拷贝？**

答题方向：它们封装的是底层同步资源，不是普通值对象。默认拷贝会造成两个对象管理同一份系统资源。

**Q5：RAII 在这个项目里出现了哪些地方？**

答题方向：`locker_guard` 管理锁，`connectionRAII` 管理数据库连接借还，日志和队列中也体现资源生命周期管理思想。

### 7.2 条件变量和阻塞队列

**Q6：条件变量为什么必须和互斥锁一起使用？**

答题方向：条件变量只负责睡眠和唤醒，真正的条件依赖共享变量，共享变量需要互斥锁保护。

**Q7：为什么 `pop()` 等待条件要用 `while`，不能用 `if`？**

答题方向：虚假唤醒；多个消费者竞争；唤醒不等于条件成立。

**Q8：`m_front` 和 `m_back` 分别表示什么？**

答题方向：`m_front` 表示上一次出队的位置，`m_back` 表示最后一次入队的位置。真正队首是 `(m_front + 1) % m_max_size`。

**Q9：`pop(item, ms_timeout)` 为什么要用绝对时间？**

答题方向：因为 `pthread_cond_timedwait` 接收的是绝对超时时间点，不是相对等待时长。

**Q10：为什么阻塞队列析构时不能安全处理仍在等待的线程？**

答题方向：析构只能释放对象资源，不能自动建立线程退出协议。若线程还在 `wait()`，销毁条件变量和数组都会导致未定义行为。

### 7.3 WebServer 总控流程

**Q11：`WebServer` 类在项目里承担什么职责？**

答题方向：它是总控层，负责初始化日志、数据库连接池、线程池、监听 socket、epoll、信号管道、定时器，并在主事件循环中调度请求。

**Q12：服务器启动流程是什么？**

答题方向：保存配置 -> 设置触发模式 -> 初始化日志 -> 初始化数据库连接池 -> 创建线程池 -> 初始化网络监听和 epoll -> 进入事件循环。

**Q13：为什么用 epoll？**

答题方向：epoll 适合大量 fd 的事件驱动模型，避免为每个连接创建一个线程，提升高并发连接管理能力。

**Q14：LT 和 ET 有什么区别？**

答题方向：LT 只要缓冲区还有数据就会持续通知；ET 状态变化时通知一次，所以 ET 模式必须循环读到 `EAGAIN`。

**Q15：为什么用 socketpair 管道处理信号？**

答题方向：信号处理函数中只做简单写管道操作，把异步信号转成 epoll 可监听的 fd 事件，由主循环统一处理。

**Q16：定时器在项目里解决什么问题？**

答题方向：关闭长期不活跃连接，释放 fd 和连接对象资源，避免大量空闲连接占用服务器资源。

**Q17：Reactor 和 Proactor 在当前项目中的区别是什么？**

答题方向：Reactor 下主线程把读写事件交给工作线程处理；Proactor 下主线程先完成 IO，再把业务处理交给线程池。

### 7.4 线程池

**Q18：线程池为什么需要任务队列？**

答题方向：主线程只负责接收和分发事件，工作线程从队列中取任务处理，实现请求削峰和并发处理。

**Q19：线程池里为什么既有互斥锁又有信号量？**

答题方向：互斥锁保护任务队列，信号量表示任务数量并负责阻塞/唤醒工作线程。

**Q20：为什么取出任务后要立即解锁？**

答题方向：队列锁只保护队列操作，不应该覆盖耗时的请求处理过程，否则其他线程无法取任务。

### 7.5 数据库连接池

**Q21：为什么需要数据库连接池？**

答题方向：避免每个请求反复创建/关闭 MySQL 连接，降低连接建立成本，提高并发性能。

**Q22：连接池里的信号量 `reserve` 表示什么？**

答题方向：表示当前可借连接数量。借连接前 `wait()`，归还连接后 `post()`。

**Q23：连接池里的互斥锁保护什么？**

答题方向：保护 `connList`、`m_FreeConn`、`m_CurConn`，避免多个线程同时修改连接池内部状态。

**Q24：为什么连接池当前不用 `shared_ptr<MYSQL>`？**

答题方向：`shared_ptr` 是共享拥有，外部复制后可能在连接归还池子后继续使用同一条连接，破坏“一条连接同一时刻只被一个线程独占使用”的要求。

**Q25：`connectionRAII` 管理的是连接销毁吗？**

答题方向：不是。它管理的是借还关系。连接销毁由连接池在 `DestroyPool()` 里统一 `mysql_close`。

**Q26：为什么 `connectionRAII` 析构时要把外部 `MYSQL*` 置空？**

答题方向：连接归还后可能马上被其他线程借走，外部指针继续非空容易误用。置空能降低归还后继续使用的风险。

**Q27：`DestroyPool()` 有什么前提？**

答题方向：正常应保证没有线程还在借用连接。当前实现只关闭空闲链表里的连接，不应该在工作线程还运行时强行销毁连接池。

## 8. 可以背下来的整体回答

这个项目的核心是一个 Linux 高并发 WebServer。主线程通过 epoll 监听网络事件、信号管道和定时器事件，收到请求后交给线程池处理。线程池用互斥锁保护任务队列，用信号量通知工作线程有任务。日志模块用阻塞队列实现生产者-消费者模型，把业务线程和磁盘 IO 解耦。数据库连接池预先创建 MySQL 连接，用信号量表示可借连接数量，用互斥锁保护连接链表和计数器，用 RAII 保证业务处理结束后自动归还连接。锁、条件变量、信号量和 RAII 是这个项目线程安全和资源安全的基础。

## 9. 复习时优先看哪些代码

建议按这个顺序复习：

1. `lock/locker.h`：先理解互斥锁、信号量、条件变量、RAII。
2. `log/block_queue.h`：理解生产者-消费者、循环数组、条件变量等待。
3. `threadpool/threadpool.h`：理解任务队列、信号量唤醒、工作线程循环。
4. `CGImysql/sql_connection_pool.h/.cpp`：理解连接池和 RAII 借还。
5. `webserver.h`：看服务器有哪些成员，建立整体地图。
6. `webserver.cpp`：按启动顺序和事件循环把整个项目串起来。

复习时不要只问“这一行代码是什么意思”，要追问三件事：

1. 这个资源是谁拥有的？
2. 多线程下谁会同时访问它？
3. 出作用域、异常、线程退出时它如何释放或归还？

这三个问题能把锁、阻塞队列、线程池、数据库连接池和 WebServer 主循环全部串起来。
