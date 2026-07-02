#ifndef _CONNECTION_POOL_
#define _CONNECTION_POOL_

#include <stdio.h>
#include <list> // 包含双向链表
#include <mysql/mysql.h>
#include <error.h>
#include <string.h>
#include <iostream>
#include <string>
#include <stdexcept>
#include "../lock/locker.h"
#include "../log/log.h"

using namespace std;

class connection_pool
/*这个类专门负责：
1.初始化若干条 MySQL 连接
2.保存当前空闲连接
3.提供连接给业务线程
4.回收业务线程归还的连接
5.服务器退出时关闭所有数据库连接
它管理的是“数据库连接资源”。*/
{
public:
	MYSQL *GetConnection(); 				/* 获取一个可用的数据库连接；返回的是借用指针，连接的真正所有权仍然在连接池里 */
	bool   ReleaseConnection(MYSQL *con);	/* 释放一个数据库连接，将连接归还到连接池中，使其可以被其他请求再次使用 */
	int    GetFreeConn();					/* 获取当前空闲连接数 */
	void   DestroyPool();					/* 销毁连接池 */

	static connection_pool *GetInstance();	/* 单例模式。 此外这里是static的，因此不需要实例化对象，直接通过类名调用即可 */

	/* 
		初始化连接池，设置数据库的连接信息（包括主机地址、端口号、用户名、密码等），并建立指定数量的数据库连接
		MaxConn 指示了数据库连接池的大小
	*/
	void init(string url, string User, string PassWord, string DataBaseName, int Port, 
					int MaxConn, int close_log); 

private:
	connection_pool();
	~connection_pool();

	int m_MaxConn;  						/* 最大连接数 */
	int m_CurConn;  						/* 当前已使用的连接数 */
	int m_FreeConn; 						/* 当前空闲的连接数 */
	locker lock;                            /* 互斥锁，用于保护连接池的资源 */
	list<MYSQL *> connList; 				/* 数据库连接池保存空闲 MYSQL*；连接池负责 mysql_close，业务线程只临时借用，不拥有连接生命周期 */
	sem reserve;							/* 信号量 */

public:
	string m_url;			 				/* 主机地址 */
	int m_Port;							    /* 数据库端口号 */
	string m_User;							/* 登陆数据库用户名 */
	string m_PassWord;	 					/* 登陆数据库密码 */
	string m_DatabaseName;					/* 使用数据库名 */
	int m_close_log;						/* 日志开关 */
};


/* 实现 RAII（资源获取即初始化）模式，确保数据库连接在使用结束后能自动释放 */
class connectionRAII //创建对象时自动从连接池借连接；对象销毁时自动归还连接
{
public:
	connectionRAII(const connectionRAII&) = delete; // 禁止拷贝构造函数
    connectionRAII& operator=(const connectionRAII&) = delete; // 禁止拷贝赋值操作

    // 构造函数，从连接池中获取连接并交给业务对象临时使用
    connectionRAII(MYSQL **con, connection_pool *connPool)
    {
        if (con == nullptr || connPool == nullptr)
        {
            throw std::runtime_error("Invalid connectionRAII arguments.");
        }

        // 对象创建时，自动从连接池取出一条连接，通过 MYSQL** 写回业务对象的 MYSQL* 成员
        // 这里不用 shared_ptr：连接池要求“一条连接同一时刻只能被一个线程独占使用”，shared_ptr 会制造多个仍然有效的拥有者，破坏这个独占借用语义
        *con = connPool->GetConnection();
        if (*con == nullptr)
        {
            throw std::runtime_error("Failed to get a valid database connection.");
        }
        
        // 把连接指针和连接池指针存到成员变量里，留给析构函数用
        conRAII = *con;
        sqlRAII = con;
        poolRAII = connPool;
    }

    // 析构函数
    ~connectionRAII()
    {
        if (conRAII) //对象生命周期结束时（出作用域、函数 return、抛出异常），自动调用 ReleaseConnection 把连接归还池子。无论业务代码以什么方式退出，连接一定会被归还，彻底杜绝 “忘记归还连接、最终池子被耗空” 的问题，和 locker_guard 防死锁的价值完全一致
        {
            MYSQL *borrowed = conRAII;
            if (sqlRAII != nullptr && *sqlRAII == conRAII)
            {
                *sqlRAII = nullptr; //先把外部 MYSQL* 置空，再归还连接，避免外部变量在“连接已经回池”后仍显示为可用
            }
            conRAII = nullptr;
            poolRAII->ReleaseConnection(borrowed);
        }
    }

private:
    MYSQL *conRAII;        // 当前 RAII 对象借到的数据库连接；它只是借用，不负责 mysql_close
    MYSQL **sqlRAII;       // 指向外部 MYSQL* 变量的地址，析构时可把外部指针置空，防止归还后继续使用
    connection_pool *poolRAII;       // 持有的连接池
};


#endif
