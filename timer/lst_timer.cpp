#include "lst_timer.h"
#include "../http/http_conn.h"

/* 构造函数 */
sort_timer_lst::sort_timer_lst() {
    head = NULL;
    tail = NULL;
}

sort_timer_lst::~sort_timer_lst() {

    util_timer *tmp = head;

    while (tmp) {
        head = tmp->next;
        delete tmp;
        tmp = head;
    }
}

void sort_timer_lst::add_timer(util_timer *timer) {

    if (!timer) { return; }

    /* 如果链表为空 */
    if (!head) {
        head = tail = timer;
        return;
    }

    /* 插入节点的到期时间小于头节点 */
    if (timer->expire < head->expire) { //expire是定时器类中的time_t类型，表示过期时间点
        timer->next = head;
        head->prev = timer;
        head = timer;
        timer->prev = nullptr;
        return;
    }

    add_timer(timer, head); //调用另一个重载函数sort_timer_lst::add_timer
}

/*客户端刚刚又发送了一次数据，说明它仍然活跃，把它的超时时间往后延长（只能处理延长的）*/
void sort_timer_lst::adjust_timer(util_timer *timer) {

    if (!timer) { return; }

    util_timer *tmp = timer->next;

    /* 如果 (不存在下一个定时器 || 当前定时器到期时间仍然小于下一个定时器), 不需要调整位置 */
    if (!tmp || (timer->expire < tmp->expire)) {
        return;
    }

    /* 需要调整位置 */
    if (timer == head) {
        head = head->next;
        head->prev = NULL;
        timer->next = NULL;//将头节点拿出去，断开其与后一节点的连接关系
        add_timer(timer, head);
    } else { //将要延长的当前节点从中间拿出去，断开其与前后节点的连接关系
        timer->prev->next = timer->next;
        timer->next->prev = timer->prev;
        add_timer(timer, timer->next);
    }
}

void sort_timer_lst::del_timer(util_timer *timer) {
    /* 
        从链表中删除指定的定时器。需要考虑五种情况：
            定时器为空
            定时器是唯一的节点。
            定时器是头节点。
            定时器是尾节点。
            定时器是中间节点。
    */

    if (!timer) { return; }

    if ((timer == head) && (timer == tail)) {
        delete timer;
        head = NULL;
        tail = NULL;
        return;
    }

    if (timer == head) {
        head = head->next;
        head->prev = NULL;
        delete timer;
        return;
    }

    if (timer == tail) {
        tail = tail->prev;
        tail->next = NULL;
        delete timer;
        return;
    }

    timer->prev->next = timer->next;
    timer->next->prev = timer->prev;
    delete timer;
}

/* 调用定时器链表 m_timer_lst 的 tick 方法，检查处理所有到期的定时器 */
void sort_timer_lst::tick() {

    if (!head) { return; }
    
    time_t cur = time(NULL);    /* 获取系统当前时间（time_t 通常表示从 1970 年 1 月 1 日到现在经过的秒数） */
    util_timer *tmp = head;

    while (tmp) {
        if (cur < tmp->expire) {    /* 如果当前时间小于定时器到期时间，直接终止遍历（因为链表已经按时间升序排列） */
            break;
        }

        tmp->cb_func(tmp->user_data); //当前定时器到期，执行回调函数：从 epoll 删除 fd，  关闭客户端 socket，  用户数减一

        head = tmp->next; //把到期的tmp删了，因为本身是排好序的，所以新的头节点就是下一个到期的定时器
        if (head) {
            head->prev = nullptr;
        } else {
            tail = nullptr; //如果删除的是仅有的那个节点，头尾节点都需要置空
        }

        delete tmp;
        tmp = head;
    }
}

/*重载了add_timer函数，用于在链表中插入节点，插入位置是根据定时器的到期时间进行的。如果定时器的到期时间小于链表头节点的到期时间，直接插入到链表头部。否则，调用另一个重载函数sort_timer_lst::add_timer进行插入。 */
void sort_timer_lst::add_timer(util_timer *timer, util_timer *lst_head)
{
    util_timer *prev = lst_head;
    util_timer *tmp = prev->next;
    while (tmp) {
        /* 找到了插入位置 */
        if (timer->expire < tmp->expire) {
            prev->next = timer;
            timer->next = tmp;
            tmp->prev = timer;
            timer->prev = prev;
            break;
        }
        prev = tmp;
        tmp = tmp->next;
    }

    /* 插入链表尾部 */
    if (!tmp) {
        prev->next = timer;
        timer->prev = prev;
        timer->next = NULL;
        tail = timer;
    }
}

/* 初始化定时信号的时间间隔 */
void Utils::init(int timeslot) {
    m_TIMESLOT = timeslot;
}

/* 文件描述符设置非阻塞，让 read / recv / accept / send 等操作不会一直卡住线程。 */
int Utils::setnonblocking(int fd) {
    int old_option = fcntl(fd, F_GETFL);        /* 获取到文件描述符fd当前的文件状态标志 */

    if (old_option == -1) {
        perror("fcntl F_GETFL failed");
        return -1;
    }

    int new_option = old_option | O_NONBLOCK; //按位或操作，保留原有所有标志，额外打开非阻塞选项O_NONBLOCK

    if (fcntl(fd, F_SETFL, new_option) == -1) {
        perror("fcntl F_SETFL failed");
        return -1;
    }

    return old_option;
}

/* 将可读事件注册到内核时间表中，设置事件触发类型，选择是否开启EPOLLONESHOT选项 */
void Utils::addfd(int epollfd, int fd, bool one_shot, int TRIGMode) {

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
        /* 为事件添加EPOLLONESHOT选项：本次事件交给某个工作线程处理后，暂时禁止其他线程再次处理同一个fd */
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

/* 信号处理函数,将接收到的信号写入 u_pipefd 管道中，将信号传递到主事件循环 */
void Utils::sig_handler(int sig) {

    int save_errno = errno;                     /* 保证函数的可重入性，保留原来的errno */
    char msg = static_cast<char>(sig);              /* 和 WebServer::dealwithsignal 的 char 缓冲区保持一致：每次只写入一个信号编号字节 */
       
    /* 将send替换为write, write异步信号安全 */ 
    if (write(u_pipefd[1], &msg, sizeof(msg)) == -1) {
        if (errno != EAGAIN) {
            std::cerr << "write to pipe failed: " << strerror(errno) << std::endl; //这里的std::cerr和strerror()都不是异步信号安全函数
        }
    }

    errno = save_errno;
}

/* 设置收到指定信号 sig 时所去调用的信号处理函数 handler，restart 为 true 时，表示信号处理函数在被信号中断后自动重启被中断的系统调用 */
void Utils::addsig(int sig, void(handler)(int), bool restart) {
    struct sigaction sa;
    memset(&sa, '\0', sizeof(sa));              /*创建并清空信号处理配置 */
    sa.sa_handler = handler;                    /* 指定收到这个信号时执行哪个信号处理函数 */

    if (restart) {
        sa.sa_flags |= SA_RESTART;              /* 设置信号处理函数在被信号中断后自动重启被中断的系统调用 */
    }
        
    sigfillset(&sa.sa_mask);                    /* 执行该信号处理函数期间，屏蔽所有信号，防止信号处理函数被中断 */

    if (sigaction(sig, &sa, NULL) == -1) {       /* 向内核注册信号处理规则 */
        std::cerr << "sigaction failed for signal " << sig << ": " << strerror(errno) << std::endl;
        exit(-1);
    }
}

/* 处理定时任务，并重新设置定时器，以确保定时信号（SIGALRM）能够持续触发 */
void Utils::timer_handler() {
    sigset_t mask;   /* 创建一个信号集，用于阻塞指定信号。 这里使用了信号集，而不是信号掩码，因为信号集可以阻塞多个信号，而信号掩码只能阻塞一个信号 */
    sigemptyset(&mask); /* 初始化信号集，清空信号集  */
    sigaddset(&mask, SIGALRM); /* 将 SIGALRM 信号添加到信号集 mask 中 */
    sigprocmask(SIG_BLOCK, &mask, NULL); /* 阻塞指定信号，防止信号处理函数被中断 */  

    m_timer_lst.tick();/* 调用定时器链表 m_timer_lst 的 tick 方法，处理所有到期的定时器 */
    alarm(m_TIMESLOT); /* 使用 alarm 函数重新设置定时器，使得下一个 SIGALRM 信号在 m_TIMESLOT 秒后触发 */

    sigprocmask(SIG_UNBLOCK, &mask, NULL); /* 解除对指定信号的阻塞 */
}

/* 向客户端发送错误信息，并关闭相应的连接 */
void Utils::show_error(int connfd, const char *info)
{
    ssize_t bytes_sent = send(connfd, info, strlen(info), 0); //把错误信息发送给客户端

    if (bytes_sent == -1) {
        std::cerr << "send failed: " << strerror(errno) << std::endl;
    }
              
    /* 优雅关闭本端的写方向：服务器不会再向客户端发送数据，但仍然可以接收客户端发送的数据，直到客户端关闭连接。 优雅关闭本端的写方向，可以避免资源泄漏和不必要的系统调用。 */
    if (shutdown(connfd, SHUT_WR) == -1) {
        std::cerr << "shutdown failed: " << strerror(errno) << std::endl;
    }

    if (close(connfd) == -1) {
        std::cerr << "close failed: " << strerror(errno) << std::endl;
    }
}

// 静态成员变量的“定义和分配存储空间”
int *Utils::u_pipefd = 0; /* 用于存储管道文件描述符，用于传递信号。将接收到的信号写入u_pipefd[1]中，而事件主循环监听管道的另一端u_pipefd[0]的可读事件，以异步处理信号 */
int Utils::u_epollfd = 0; //存储 epoll 实例的文件描述符；这里只保存 fd 数值，不拥有 epoll 资源，真正的创建和关闭由 WebServer 管理


class Utils; //前置声明： 因为Utils::u_epollfd是Utils的静态成员，静态成员的访问不依赖于Utils类的实例。前置声明用于减少编译依赖
/* 定时器回调函数（普通全局函数）： 某个客户端连接超时时，会进入这里 */
void cb_func(client_data *user_data) {

    if (!user_data) {
        std::cerr << "cb_func received null user_data" << std::endl;
        return;
    }

    /* 从 epoll 中删除超时的客户端的文件描述符 */
    if (epoll_ctl(Utils::u_epollfd, EPOLL_CTL_DEL, user_data->sockfd, nullptr) == -1) {
        std::cerr << "epoll_ctl DEL failed: " << strerror(errno) << std::endl;
    }
    /* 关闭超时的客户端的连接 */
    if (close(user_data->sockfd) == -1) {
        std::cerr << "close failed: " << strerror(errno) << std::endl;
    }

    http_conn::m_user_count--;                  /* 减少当前在线用户计数 */
}
