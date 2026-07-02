#include <mysql/mysql.h>
#include <stdio.h>
#include <string>
#include <string.h>
#include <stdlib.h>
#include <list>
#include <pthread.h>
#include <iostream>
#include "sql_connection_pool.h"

using namespace std;

/* 默认构造函数 */
connection_pool::connection_pool()
{
	m_CurConn = 0;	/* 当前已使用的连接数 */
	m_FreeConn = 0;	/* 当前空闲的连接数 */
}

/* 获取单例对象 */ /* C++11 之后，可以通过静态局部变量（其初始化是原子的）来实现线程安全的单例模式 */
connection_pool* connection_pool::GetInstance() //返回一个指向connection_pool 类型的对象的指针
{ //因为函数的实现写在了类的外面（.cpp 文件里），必须通过 类名::函数名 的形式告诉编译器：这个 GetInstance 函数是 connection_pool 类的成员函数，不是全局函数
	static connection_pool connPool; //它虽然生命周期和程序一样长，但名字只在 GetInstance 函数内部有效，外部代码不能直接访问它，只能通过函数返回的指针来使用，保证了封装性和访问入口唯一
	return &connPool;
}

/* 构造初始化并一次性创建所有连接并放进池子 */
void connection_pool::init(string url, string User, string PassWord, string DBName, int Port, int MaxConn, int close_log)
{
	m_url = url;
	m_Port = Port;
	m_User = User;
	m_PassWord = PassWord;
	m_DatabaseName = DBName;
	m_close_log = close_log;

	// 循环 MaxConn 次，逐个创建 MySQL 连接，成功就入池，失败就跳过并打日志
	for (int i = 0; i < MaxConn; i++)
	{
		MYSQL* raw_con = mysql_init(NULL);		/* mysql_init：创建并初始化 MYSQL 连接句柄 */

		if (raw_con == NULL)
		{
			LOG_ERROR("MySQL init Error: %s", mysql_error(raw_con));
			continue;  							/* 记录错误但不退出程序 */ 
		}

		/* 连接到数据库 */
		MYSQL *connected = mysql_real_connect(raw_con, url.c_str(), User.c_str(), PassWord.c_str(), DBName.c_str(), Port, NULL, 0);
		//mysql_real_connect 是真正建立 TCP 连接、完成账号认证、选中数据库的函数，8 个参数分别是：1.已初始化的 MYSQL 句柄2.数据库主机地址3.用户名4.密码5.数据库名6.端口号7.Unix 套接字（这里传 NULL，用 TCP 连接）8.客户端标志位（这里传 0，默认行为）

		if (connected == NULL) // 用connected专门接收连接结果，raw_con始终保留初始化得到的句柄
		{
			LOG_ERROR("MySQL init Error: %s", mysql_error(raw_con));
			mysql_close(raw_con);  				/* 释放当前连接资源 */
			continue;  							/* 记录错误但不退出程序 */
		}

		/* 连接池自己保存 MYSQL*，并在 DestroyPool 中统一 mysql_close。
		这里故意不用 shared_ptr：shared_ptr 表达的是“共享拥有”，多个 shared_ptr 可以同时认为自己持有同一条连接；
		而数据库连接池的语义是“独占借用”，一条 MYSQL 连接从池中取出后，同一时刻只能被一个线程使用，归还后才能给下一个线程。
		所以 connList 只保存空闲连接，GetConnection 会把连接从链表中移除，ReleaseConnection 才把它放回来。*/
		connList.push_back(connected);			/* 将连接加入连接池 */
		++m_FreeConn;							/* 增加空闲连接计数 */
		reserve.post();							/* reserve 默认信号量值为 0；每成功创建一个连接就 post 一次，使信号量数量和空闲连接数保持一致 */
	}

	/* 如果没有任何连接被成功创建 */ 
    if (m_FreeConn == 0)
    {
        LOG_ERROR("All database connections failed to initialize.");
        exit(1);  								/* 没有连接被创建成功，退出程序 */
    }

	m_MaxConn = m_FreeConn;						/* 最大连接数设为实际成功创建的数量，而不是传入的 MaxConn，保证计数准确 */
}


/* 获取连接时，直接从 connList 中弹出一个 MYSQL* */
MYSQL *connection_pool::GetConnection()
{	
	reserve.wait();   				/* 阻塞等待信号量，直到有可用连接 信号量 reserve：控制“有多少条连接可借” */

	lock.lock();                    /* 获取互斥锁，保护连接池资源 互斥锁 lock：保护 connList、m_FreeConn、m_CurConn 的读写过程 */

	if (connList.empty())
    {
        lock.unlock();
		reserve.post();  //如果信号量被误唤醒，保证信号量数量和空闲连接数保持一致
        return nullptr;
    }

	MYSQL *con = connList.front(); //取出链表头部的连接；它是借用指针，不代表业务线程拥有连接的释放权
	connList.pop_front();

	--m_FreeConn;
	++m_CurConn;

	lock.unlock(); // 锁只保护共享资源的操作。连接借到以后，当前线程拿着con去执行SQL，不应该一直占着连接池。否则其他线程无法借还连接，吞吐会很差。

	return con;
}

/* 释放当前使用的连接 */
bool connection_pool::ReleaseConnection(MYSQL *con)
{
	if (con == nullptr)
    {
        return false;
    }

	lock.lock();

	connList.push_back(con);		/* 将连接放回连接池；归还后这条 MYSQL* 可能马上被其他线程借走，原借用者不能再继续使用 */
	++m_FreeConn;
	--m_CurConn;

	lock.unlock();

	reserve.post();					/* 增加信号量，释放连接。 信号量V操作，唤醒等待的线程 */

	return true;
}

/* 销毁数据库连接池 */
void connection_pool::DestroyPool()
{

	lock.lock();

    if (!connList.empty())
    {
        for (auto con : connList)
        {
            mysql_close(con); // MYSQL* 来自 mysql_init/mysql_real_connect，必须用 mysql_close 释放，不能用 delete
        }
        connList.clear();  // 清空空闲连接链表；注意正常退出时应先保证没有线程还在借用连接
    }

    m_CurConn = 0;
    m_FreeConn = 0;
	
    lock.unlock();
}

/* 返回当前空闲的连接数 */
int connection_pool::GetFreeConn()
{
	lock.lock();
	int free_conn = m_FreeConn;
	lock.unlock();
	return free_conn;
}

/* 析构函数 */
connection_pool::~connection_pool()
{
	DestroyPool();
}
