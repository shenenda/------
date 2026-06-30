#include "../log/log.h"

#include <cstdio>
#include <ctime>
#include <fstream>
#include <iterator>
#include <string>

int main()
{
    time_t t = time(nullptr);
    tm now_tm;
    if (localtime_r(&t, &now_tm) == nullptr)
    {
        return 1;
    }

    char log_path[256] = {0};
    snprintf(log_path, sizeof(log_path), "./.codex_tmp/%d_%02d_%02d_log_safety_smoke",
             now_tm.tm_year + 1900, now_tm.tm_mon + 1, now_tm.tm_mday);
    std::remove(log_path);

    Log *log = Log::get_instance();
    if (!log->init("./.codex_tmp/log_safety_smoke", 0, 64, 10, 0))
    {
        return 2;
    }

    std::string long_message(4096, 'A');
    log->write_log(1, "%s", long_message.c_str());
    log->flush();

    std::ifstream in(log_path, std::ios::binary);
    std::string content((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    if (content.empty())
    {
        return 3;
    }

    return content.back() == '\n' ? 0 : 4;
}
