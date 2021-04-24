
CMD += gcc
OUT += custom_tickrate_mm.so
SRC += stub_mm.cpp

LIB += ../hl2sdk-csgo/lib/linux/tier1_i486.a
LIB += ../hl2sdk-csgo/lib/linux/interfaces_i486.a

LIB += libvstdlib.so
LIB += libtier0.so

DEF += -DCOMPILER_GCC
DEF += -DPOSIX
DEF += -D_LINUX
DEF += -DSOURCE_ENGINE=SE_CSGO

DEF += -DSE_EPISODEONE=1
DEF += -DSE_DARKMESSIAH=2
DEF += -DSE_ORANGEBOX=3
DEF += -DSE_BLOODYGOODTIME=4
DEF += -DSE_EYE=5
DEF += -DSE_CSS=6
DEF += -DSE_ORANGEBOXVALVE=7
DEF += -DSE_LEFT4DEAD=8
DEF += -DSE_LEFT4DEAD2=9
DEF += -DSE_ALIENSWARM=10
DEF += -DSE_PORTAL2=11
DEF += -DSE_CSGO=12

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

