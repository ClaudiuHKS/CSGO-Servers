
CMD += gcc
OUT += custom_tickrate_mm.so
SRC += stub_mm.cpp

LIB += ../hl2sdk-csgo/lib/linux/tier1_i486.a
LIB += ../hl2sdk-csgo/lib/linux/interfaces_i486.a

LIB += libvstdlib.so
LIB += libtier0.so

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

HDR += -I../hl2sdk-csgo/public/game/server
HDR += -I../hl2sdk-csgo/public
HDR += -I../hl2sdk-csgo/public/engine
HDR += -I../hl2sdk-csgo/public/mathlib
HDR += -I../hl2sdk-csgo/public/vstdlib
HDR += -I../hl2sdk-csgo/public/tier0
HDR += -I../hl2sdk-csgo/public/tier1

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
