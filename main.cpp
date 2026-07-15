#include "config.h"

int main(int argc, char *argv[])
{
    /* 需要修改的数据库信息,登录名,密码,库名 */
    string user = "webserver";
    string passwd = "126634";
    string databasename = "yourdb";

    Config config;
    config.parse_arg(argc, argv);//调用Config类的parse_arg函数解析命令行参数（该方法属于Config类）

    WebServer server;

    server.init(config.PORT, user, passwd, databasename, config.LOGWrite, 
                config.OPT_LINGER, config.TRIGMode,  config.sql_num,  config.thread_num, 
                config.close_log, config.actor_model);
    

    server.log_write();

    server.sql_pool();

    server.thread_pool();

    server.trig_mode();

    //监听
    server.eventListen();

    //运行
    server.eventLoop();

    return 0;
}