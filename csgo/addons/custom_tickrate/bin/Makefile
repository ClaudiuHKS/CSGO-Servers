HL2SDK = ../hl2sdk-csgo
MMSOURCE = ../metamod-source-master
PROJECT = custom_tickrate_mm
BIN_DIR = Release
OBJECTS = stub_mm.cpp
OPT_FLAGS = -O3 -funroll-loops -pipe
GCC4_FLAGS = -fvisibility=hidden -fvisibility-inlines-hidden -std=c++11
CPP = gcc
CFLAGS = -DSOURCE_ENGINE=12
HL2PUB = $(HL2SDK)/public
INCLUDE = -I$(HL2SDK)/public/game/server
METAMOD = $(MMSOURCE)/core
LIB_EXT = so
BINARY = $(PROJECT).$(LIB_EXT)
HL2LIB = $(HL2SDK)/lib/linux
LIB_PREFIX = lib
LIB_SUFFIX = .$(LIB_EXT)
STATIC_SUFFIX = _i486
CFLAGS += -DSE_EPISODEONE=1 -DSE_DARKMESSIAH=2 -DSE_ORANGEBOX=3 -DSE_BLOODYGOODTIME=4 -DSE_EYE=5
CFLAGS += -DSE_CSS=6 -DSE_ORANGEBOXVALVE=7 -DSE_LEFT4DEAD=8 -DSE_LEFT4DEAD2=9 -DSE_ALIENSWARM=10
CFLAGS += -DSE_PORTAL2=11 -DSE_CSGO=12
LINK = $(HL2LIB)/tier1$(STATIC_SUFFIX).a $(LIB_PREFIX)vstdlib$(LIB_SUFFIX) $(LIB_PREFIX)tier0$(LIB_SUFFIX)
LINK += $(HL2LIB)/interfaces$(STATIC_SUFFIX).a
INCLUDE += -I. -I.. -I$(HL2PUB) -I$(HL2PUB)/engine -I$(HL2PUB)/mathlib -I$(HL2PUB)/vstdlib
INCLUDE += -I$(HL2PUB)/tier0 -I$(HL2PUB)/tier1 -I$(METAMOD) -I$(METAMOD)/sourcehook
CFLAGS += $(OPT_FLAGS) -D_LINUX -m32
LINK += -shared -m32
CFLAGS += -DPOSIX -Dstricmp=strcasecmp -D_stricmp=strcasecmp -D_strnicmp=strncasecmp
CFLAGS += -Dstrnicmp=strncasecmp -D_snprintf=snprintf -D_vsnprintf=vsnprintf -D_alloca=alloca
CFLAGS += -Dstrcmpi=strcasecmp -DCOMPILER_GCC -Wno-non-virtual-dtor -Wno-overloaded-virtual
CFLAGS += -Werror -fPIC -fno-exceptions -fno-rtti -msse -fno-strict-aliasing
CFLAGS += $(GCC4_FLAGS)
CFLAGS += -Wno-delete-non-virtual-dtor -Wno-unused-private-field -Wno-deprecated-register
LINK += -static-libgcc

OBJ_BIN := $(OBJECTS:%.cpp=$(BIN_DIR)/%.o)

$(BIN_DIR)/%.o: %.cpp
	$(CPP) $(INCLUDE) $(CFLAGS) -o $@ -c $<

all: check
	mkdir -p $(BIN_DIR)
	ln -sf $(HL2LIB)/$(LIB_PREFIX)vstdlib$(LIB_SUFFIX)
	ln -sf $(HL2LIB)/$(LIB_PREFIX)tier0$(LIB_SUFFIX)
	$(MAKE) -f Makefile custom_tickrate_mm

check:

custom_tickrate_mm: check $(OBJ_BIN)
	$(CPP) $(INCLUDE) $(OBJ_BIN) $(LINK) -ldl -lm -o $(BIN_DIR)/$(BINARY)

default: all

clean: check
	rm -rf $(BIN_DIR)/*.o
	rm -rf $(BIN_DIR)/$(BINARY)

