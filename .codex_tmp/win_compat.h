#pragma once

#include <ctime>

#if defined(_WIN32)
static inline tm *localtime_r(const time_t *timep, tm *result)
{
    return localtime_s(result, timep) == 0 ? result : nullptr;
}
#endif
