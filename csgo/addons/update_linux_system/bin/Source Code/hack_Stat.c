
#ifndef WIN32

#include <sys/types.h>
#include <sys/stat.h>

#include <unistd.h>

__asm__(".symver stat, __xstat@GLIBC_2.0");

int __wrap_stat(const char* _0, struct stat* _1)
{
    return __xstat(_STAT_VER, _0, _1);
}

#endif
