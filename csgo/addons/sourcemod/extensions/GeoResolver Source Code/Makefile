
CMD += gcc
OUT += GeoResolver.ext.so

SRC += 

# SRC += stub_mm.cpp

# SRC += detours.cpp
# SRC += disasm.cpp
# SRC += modules.cpp

SRC += GeoIP.c
SRC += GeoIPCity.c

SRC += GeoIP_deprecated.c

SRC += regionName.c
SRC += timeZone.c

SRC += maxminddb.c
SRC += data-pool.c

# SRC += pread.c

SRC += ../sourcemod-master/public/smsdk_ext.cpp

SRC += extension.cpp

LIB += 

# LIB += ../hl2sdk-csgo/lib/linux/tier1_i486.a
# LIB += ../hl2sdk-csgo/lib/linux/interfaces_i486.a

# LIB += libvstdlib.so
# LIB += libtier0.so

DEF += 

DEF += -D_COMPILER_GCC
DEF += -D_GCC
DEF += -D_GEOIP_STATIC
DEF += -D_GEOIPDATADIR=\"\"
DEF += -D_GNU
DEF += -D_GNU_C
DEF += -D_GNU_SOURCE
DEF += -D_GNUC
DEF += -D_HAS_EXCEPTIONS=0
DEF += -D_LINUX
DEF += -D_META_NO_HL2SDK
DEF += -D_METAMOD_BUILD
DEF += -D_NDEBUG
DEF += -D_PACKAGE_VERSION=\"1.6.0\"
DEF += -D_POSIX
DEF += -D_POSIX_SOURCE
DEF += -D_SOURCE_ENGINE=SE_CSGO
DEF += -D_SOURCEMOD_BUILD
DEF += -D_USE_MATH_DEFINES

DEF += -DCOMPILER_GCC
DEF += -DGCC
DEF += -DGEOIP_STATIC
DEF += -DGEOIPDATADIR=\"\"
DEF += -DGNU
DEF += -DGNU_C
DEF += -DGNU_SOURCE
DEF += -DGNUC
# DEF += -DHAS_EXCEPTIONS=0
DEF += -DLINUX
DEF += -DMETA_NO_HL2SDK
DEF += -DMETAMOD_BUILD
DEF += -DNDEBUG
DEF += -DPACKAGE_VERSION=\"1.6.0\"
DEF += -DPOSIX
DEF += -DPOSIX_SOURCE
DEF += -DSOURCE_ENGINE=SE_CSGO
DEF += -DSOURCEMOD_BUILD
DEF += -DUSE_MATH_DEFINES

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

HDR += 

HDR += -I.

# HDR += -I../hl2sdk-csgo/public/game/server
# HDR += -I../hl2sdk-csgo/public
# HDR += -I../hl2sdk-csgo/public/engine
# HDR += -I../hl2sdk-csgo/public/mathlib
# HDR += -I../hl2sdk-csgo/public/vstdlib
# HDR += -I../hl2sdk-csgo/public/tier0
# HDR += -I../hl2sdk-csgo/public/tier1

HDR += -I../amtl-master
HDR += -I../amtl-master/amtl

HDR += -I../sourcepawn-master/include

HDR += -I../sourcemod-master/public

# HDR += -I../metamod-source-master/core
HDR += -I../metamod-source-master/core/sourcehook

OPT += -fno-exceptions
OPT += -fno-rtti
OPT += -fno-strict-aliasing
OPT += -fno-threadsafe-statics
OPT += -fvisibility-inlines-hidden
OPT += -fvisibility=hidden

# OPT += -lstdc++

OPT += -m32
OPT += -mfpmath=sse
OPT += -msse

OPT += -o3

OPT += -pipe

OPT += -s
OPT += -shared
OPT += -static-libgcc

# OPT += -std=c++11
OPT += -std=c++14

OPT += -std=c11

OPT += -w

default:

	$(CMD) $(SRC) $(LIB) $(DEF) $(HDR) $(OPT) -o $(OUT)
