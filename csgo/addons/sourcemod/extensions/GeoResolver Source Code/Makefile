
CMD += gcc
OUT += GeoResolver.ext.so

SRC += data-pool.c
SRC += GeoIP.c
SRC += GeoIP_deprecated.c
SRC += GeoIPCity.c
SRC += maxminddb.c
# SRC += pread.c
SRC += regionName.c
SRC += timeZone.c

SRC += ../sourcemod-master/public/smsdk_ext.cpp
SRC += extension.cpp

LIB += 

DEF += -D_COMPILER_GCC
DEF += -D_HAS_EXCEPTIONS=0
DEF += -D_LINUX
DEF += -D_NDEBUG
DEF += -D_POSIX
DEF += -D_USE_MATH_DEFINES
DEF += -DCOMPILER_GCC
DEF += -DLINUX
DEF += -DNDEBUG
DEF += -DPOSIX
DEF += -DSOURCE_ENGINE=SE_CSGO
DEF += -DPACKAGE_VERSION=__DATE__
DEF += -DGEOIP_STATIC
DEF += -DSOURCEMOD_BUILD
DEF += -DGEOIPDATADIR=\"\"
DEF += -D_GNU_SOURCE

DEF += -DSE_ALIEN_SWARM=10
DEF += -DSE_ALIENSWARM=10
DEF += -DSE_BLOODY_GOOD_TIME=4
DEF += -DSE_BLOODY_GOODTIME=4
DEF += -DSE_BLOODYGOOD_TIME=4
DEF += -DSE_BLOODYGOODTIME=4
DEF += -DSE_CS_GO=12
DEF += -DSE_CS_S=6
DEF += -DSE_CS_SOURCE=6
DEF += -DSE_CSGO=12
DEF += -DSE_CSS=6
DEF += -DSE_CSSOURCE=6
DEF += -DSE_DARK_MESSIAH=2
DEF += -DSE_DARKMESSIAH=2
DEF += -DSE_EPISODE1=1
DEF += -DSE_EPISODE_1=1
DEF += -DSE_EPISODE_ONE=1
DEF += -DSE_EPISODEONE=1
DEF += -DSE_EYE=5
DEF += -DSE_EYES=5
DEF += -DSE_LEFT4DEAD2=9
DEF += -DSE_LEFT4DEAD=8
DEF += -DSE_LEFT4DEAD_2=9
DEF += -DSE_LEFT4DEAD_TWO=9
DEF += -DSE_LEFT4DEADTWO=9
DEF += -DSE_LEFT_4_DEAD2=9
DEF += -DSE_LEFT_4_DEAD=8
DEF += -DSE_LEFT_4_DEAD_2=9
DEF += -DSE_LEFT_4_DEAD_TWO=9
DEF += -DSE_LEFT_4_DEADTWO=9
DEF += -DSE_LEFT_FOR_DEAD2=9
DEF += -DSE_LEFT_FOR_DEAD=8
DEF += -DSE_LEFT_FOR_DEAD_2=9
DEF += -DSE_LEFT_FOR_DEAD_TWO=9
DEF += -DSE_LEFT_FOR_DEADTWO=9
DEF += -DSE_LEFTFORDEAD2=9
DEF += -DSE_LEFTFORDEAD=8
DEF += -DSE_LEFTFORDEAD_2=9
DEF += -DSE_LEFTFORDEAD_TWO=9
DEF += -DSE_LEFTFORDEADTWO=9
DEF += -DSE_ORANGE_BOX=3
DEF += -DSE_ORANGE_BOX_VALVE=7
DEF += -DSE_ORANGE_BOXVALVE=7
DEF += -DSE_ORANGEBOX=3
DEF += -DSE_ORANGEBOX_VALVE=7
DEF += -DSE_ORANGEBOXVALVE=7
DEF += -DSE_PORTAL2=11
DEF += -DSE_PORTAL_2=11
DEF += -DSE_PORTAL_TWO=11
DEF += -DSE_PORTALTWO=11

HDR += -I.
HDR += -I../amtl-master
HDR += -I../amtl-master/amtl
HDR += -I../sourcepawn-master/include
HDR += -I../sourcemod-master/public
HDR += -I../metamod-source-master/core
HDR += -I../metamod-source-master/core/sourcehook

OPT += -fno-exceptions
OPT += -fno-rtti
OPT += -fno-strict-aliasing
OPT += -fno-threadsafe-statics
OPT += -fomit-frame-pointer
OPT += -funroll-loops
OPT += -fvisibility-inlines-hidden
OPT += -fvisibility=hidden
OPT += -ldl
OPT += -lm
OPT += -lpthread
OPT += -lstdc++
OPT += -m32
OPT += -o3
OPT += -pipe
OPT += -s
OPT += -shared
OPT += -static-libgcc
OPT += -std=c11
OPT += -w

default:

	$(CMD) $(SRC) $(LIB) $(DEF) $(HDR) $(OPT) -o $(OUT)
