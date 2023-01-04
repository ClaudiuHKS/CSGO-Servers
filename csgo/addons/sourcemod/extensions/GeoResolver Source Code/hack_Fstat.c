
#ifndef WIN32

#include <sys/types.h>
#include <sys/stat.h>

#include <unistd.h>

__asm__(".symver fstat, __fxstat@GLIBC_2.0");

int __wrap_fstat(int _0, struct stat* _1)
{
    return __fxstat(_STAT_VER, _0, _1);
}

#endif
