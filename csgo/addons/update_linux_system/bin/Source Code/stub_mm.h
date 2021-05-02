#pragma once

#include <ISmmPlugin.h>

#include <stdio.h>
#include <stdlib.h>

#if defined WIN32

#include <string.h>

#endif

#define xTo(Var, Type) ((Type)(Var))

class UpdateLinuxSystem : public ISmmPlugin
{
public:

    bool Load(PluginId, ISmmAPI*, char*, unsigned int, bool);
    bool Unload(char*, unsigned int);

    bool Pause(char*, unsigned int);
    bool Unpause(char*, unsigned int);

    void AllPluginsLoaded();

    const char* GetAuthor();
    const char* GetName();
    const char* GetDescription();
    const char* GetURL();
    const char* GetLicense();
    const char* GetVersion();
    const char* GetDate();
    const char* GetLogTag();
};

extern UpdateLinuxSystem g_UpdateLinuxSystem;

PLUGIN_GLOBALVARS();
