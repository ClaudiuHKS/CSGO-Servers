#pragma once

#if !defined WIN32

#include <sys/resource.h>

#else

#include <algorithm>

#include <Windows.h>

#endif

#include <ISmmPlugin.h>
#include <filesystem.h>
#include <igameevents.h>
#include <iplayerinfo.h>

#include <iomanip>
#include <iostream>
#include <fstream>

#include "nlohmann/json.hpp"

#define xTo(Var, Type) ((Type)(Var))
#define maxRealPrecision (::std::numeric_limits<long double>::max_digits10)
#define defTickRate (128)

class CustomTickRate : public ISmmPlugin, public IMetamodListener
{
public:

    bool Load(PluginId, ISmmAPI*, char*, unsigned int, bool);
    bool Unload(char*, unsigned int);

    bool Pause(char*, unsigned int);
    bool Unpause(char*, unsigned int);

    void AllPluginsLoaded();

    void OnVSPListening(IServerPluginCallbacks*);

    float Hook_GetTickInterval() const noexcept;

    const char* GetAuthor();
    const char* GetName();
    const char* GetDescription();
    const char* GetURL();
    const char* GetLicense();
    const char* GetVersion();
    const char* GetDate();
    const char* GetLogTag();

    static constexpr auto const nDefaultTickRate{ defTickRate, };
    static constexpr auto const fDefaultIntervalPerTick{ (1.0f / xTo(nDefaultTickRate, float)), };
};

extern CustomTickRate g_CustomTickRate;

PLUGIN_GLOBALVARS();
