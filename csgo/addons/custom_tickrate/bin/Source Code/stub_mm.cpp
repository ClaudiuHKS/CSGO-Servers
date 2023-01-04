#include "stub_mm.h"

SH_DECL_HOOK0(IServerGameDLL, GetTickInterval, const, 0, float);

static ICvar* g_pICvar_{ };

static IVEngineServer* g_pIVEngineServer_{ };
static IFileSystem* g_pIFileSystem_{ };
static IGameEventManager2* g_pIGameEventManager2_{ };
static IServerPluginHelpers* g_pIServerPluginHelpers_{ };

static IPlayerInfoManager* g_pIPlayerInfoManager_{ };
static IServerGameClients* g_pIServerGameClients_{ };
static IServerGameDLL* g_pIServerGameDLL_{ };

static CGlobalVars* g_pCGlobalVars_{ };

static IServerPluginCallbacks* g_pIServerPluginCallbacks_{ };

CustomTickRate g_CustomTickRate{ };

static ::std::string g_strBaseGameDir{ };

static bool g_bIsHooked{ };

PLUGIN_EXPOSE(CustomTickRate, g_CustomTickRate);

bool CustomTickRate::Load(PluginId id, ISmmAPI* ismm, char* error, unsigned int maxlen, bool)
{
    PLUGIN_SAVEVARS();

    GET_V_IFACE_CURRENT(GetEngineFactory, g_pICvar_, ICvar, CVAR_INTERFACE_VERSION);
    {
        g_pCVar = g_pICvar_;
    }

    GET_V_IFACE_CURRENT(GetEngineFactory, g_pIVEngineServer_, IVEngineServer, INTERFACEVERSION_VENGINESERVER);
    GET_V_IFACE_CURRENT(GetEngineFactory, g_pIGameEventManager2_, IGameEventManager2, INTERFACEVERSION_GAMEEVENTSMANAGER2);
    GET_V_IFACE_CURRENT(GetEngineFactory, g_pIServerPluginHelpers_, IServerPluginHelpers, INTERFACEVERSION_ISERVERPLUGINHELPERS);

    GET_V_IFACE_CURRENT(GetServerFactory, g_pIPlayerInfoManager_, IPlayerInfoManager, INTERFACEVERSION_PLAYERINFOMANAGER);
    GET_V_IFACE_CURRENT(GetServerFactory, g_pIServerGameClients_, IServerGameClients, INTERFACEVERSION_SERVERGAMECLIENTS);
    GET_V_IFACE_CURRENT(GetServerFactory, g_pIServerGameDLL_, IServerGameDLL, INTERFACEVERSION_SERVERGAMEDLL);

    GET_V_IFACE_CURRENT(GetFileSystemFactory, g_pIFileSystem_, IFileSystem, FILESYSTEM_INTERFACE_VERSION);

    g_pCGlobalVars_ = ismm->GetCGlobals();

    if (!(g_pIServerPluginCallbacks_ = ismm->GetVSPInfo(nullptr)))
    {
        ismm->AddListener(this, this);

        ismm->EnableVSPListener();
    }

    g_strBaseGameDir.assign(ismm->GetBaseDir());

    if (g_strBaseGameDir.empty())
    {
        ::std::snprintf(error, maxlen, "Failed To Find The Game Base Directory");

        META_CONPRINT("\n***********************************\n");
        META_CONPRINT("Failed To Find The Game Base Directory\n");
        META_CONPRINT("***********************************\n\n");

        return false;
    }

    if (!g_bIsHooked)
    {
        SH_ADD_HOOK_MEMFUNC(IServerGameDLL, GetTickInterval, g_pIServerGameDLL_, this, &CustomTickRate::Hook_GetTickInterval, false);

        SH_ADD_HOOK_MEMFUNC(IServerGameDLL, GetTickInterval, g_pIServerGameDLL_, this, &CustomTickRate::Hook_GetTickInterval, true);

        g_bIsHooked = true;
    }

    return true;
}

void CustomTickRate::OnVSPListening(IServerPluginCallbacks* pIServerPluginCallbacks)
{
    g_pIServerPluginCallbacks_ = pIServerPluginCallbacks;
}

bool CustomTickRate::Unload(char*, unsigned int)
{
    if (g_bIsHooked)
    {
        SH_REMOVE_HOOK_MEMFUNC(IServerGameDLL, GetTickInterval, g_pIServerGameDLL_, this, &CustomTickRate::Hook_GetTickInterval, false);

        SH_REMOVE_HOOK_MEMFUNC(IServerGameDLL, GetTickInterval, g_pIServerGameDLL_, this, &CustomTickRate::Hook_GetTickInterval, true);

        g_bIsHooked = { };
    }

    return true;
}

float CustomTickRate::Hook_GetTickInterval() const noexcept
{
    static ::std::string strConfigFilePath{ };
    static ::std::ifstream inConfigFile{ };
    static ::nlohmann::json jsonTree{ };
    static float fTickInterval{ };
    static int nProcessPriorityClass{ };

#if defined WIN32

    static bool bDisableProcessPriorityBoost{ };

#endif

    fTickInterval = fDefaultIntervalPerTick;

    strConfigFilePath.assign(g_strBaseGameDir + "/addons/custom_tickrate/settings.cfg");

    if (!g_pIFileSystem_->FileExists(strConfigFilePath.c_str()))
    {
        META_CONPRINT("\n***********************************\n");
        META_CONPRINTF("Failed To Find The '%s' File\n\n", strConfigFilePath.c_str());
        ::std::cout << "Defaulting To '" << nDefaultTickRate << "' Tick Rate" << ::std::endl;
        ::std::cout << "'" << ::std::setprecision(maxRealPrecision) << fTickInterval << "' Tick Interval" << ::std::endl;
        META_CONPRINT("***********************************\n\n");

        RETURN_META_VALUE(MRES_SUPERCEDE, fTickInterval);
    }

    inConfigFile.open(strConfigFilePath);

    if (!inConfigFile.is_open())
    {
        META_CONPRINT("\n***********************************\n");
        META_CONPRINTF("Failed To Open The '%s' File\n\n", strConfigFilePath.c_str());
        ::std::cout << "Defaulting To '" << nDefaultTickRate << "' Tick Rate" << ::std::endl;
        ::std::cout << "'" << ::std::setprecision(maxRealPrecision) << fTickInterval << "' Tick Interval" << ::std::endl;
        META_CONPRINT("***********************************\n\n");

        inConfigFile.clear();

        RETURN_META_VALUE(MRES_SUPERCEDE, fTickInterval);
    }

    jsonTree = ::nlohmann::json::parse(inConfigFile, nullptr, false, true);

    inConfigFile.close();

    inConfigFile.clear();

    if (jsonTree.is_discarded())
    {
        META_CONPRINT("\n***********************************\n");
        META_CONPRINTF("The File '%s' Has Invalid 'Json' Content\n\n", strConfigFilePath.c_str());
        ::std::cout << "Defaulting To '" << nDefaultTickRate << "' Tick Rate" << ::std::endl;
        ::std::cout << "'" << ::std::setprecision(maxRealPrecision) << fTickInterval << "' Tick Interval" << ::std::endl;
        META_CONPRINT("***********************************\n\n");

        jsonTree.clear();

        RETURN_META_VALUE(MRES_SUPERCEDE, fTickInterval);
    }

    if (jsonTree.empty())
    {
        META_CONPRINT("\n***********************************\n");
        META_CONPRINTF("The File '%s' Has No 'Json' Content\n\n", strConfigFilePath.c_str());
        ::std::cout << "Defaulting To '" << nDefaultTickRate << "' Tick Rate" << ::std::endl;
        ::std::cout << "'" << ::std::setprecision(maxRealPrecision) << fTickInterval << "' Tick Interval" << ::std::endl;
        META_CONPRINT("***********************************\n\n");

        jsonTree.clear();

        RETURN_META_VALUE(MRES_SUPERCEDE, fTickInterval);
    }

#if defined WIN32

    if (jsonTree["Windows Disable Process Priority Boost"].empty())
    {
        META_CONPRINT("\n***********************************\n");
        META_CONPRINTF("Failed To Find The 'Windows Disable Process Priority Boost' Setting Into The '%s' File\n\n", strConfigFilePath.c_str());
        META_CONPRINT("The 'Disable Process Priority Boost' Of This Process Will Not Change\n");
        META_CONPRINT("***********************************\n\n");
    }

    else
    {
        bDisableProcessPriorityBoost = jsonTree["Windows Disable Process Priority Boost"].get < bool >();

        META_CONPRINT("\n***********************************\n");
        META_CONPRINTF("The 'Disable Process Priority Boost' Of This Process Changed To '%s'\n", bDisableProcessPriorityBoost ? "TRUE" : "FALSE");
        META_CONPRINT("***********************************\n\n");

        ::SetProcessPriorityBoost(::GetCurrentProcess(), xTo(bDisableProcessPriorityBoost, int));
    }

#endif

#if defined WIN32

    if (jsonTree["Windows Process Priority Class"].empty())

#else

    if (jsonTree["Linux Process Priority Class"].empty())

#endif

    {
        META_CONPRINT("\n***********************************\n");

#if defined WIN32

        META_CONPRINTF("Failed To Find The 'Windows Process Priority Class' Setting Into The '%s' File\n\n", strConfigFilePath.c_str());
        META_CONPRINT("The 'Windows Process Priority Class' Of This Process Will Not Change\n");

#else

        META_CONPRINTF("Failed To Find The 'Linux Process Priority Class' Setting Into The '%s' File\n\n", strConfigFilePath.c_str());
        META_CONPRINT("The 'Linux Process Priority Class' Of This Process Will Not Change\n");

#endif

        META_CONPRINT("***********************************\n\n");
    }

    else
    {

#if defined WIN32

        nProcessPriorityClass = jsonTree["Windows Process Priority Class"].get < int >();

#else

        nProcessPriorityClass = jsonTree["Linux Process Priority Class"].get < int >();

#endif

        META_CONPRINT("\n***********************************\n");

#if defined WIN32

        META_CONPRINTF("The 'Windows Process Priority Class' Of This Process Changed To '%d'\n", nProcessPriorityClass);

#else

        META_CONPRINTF("The 'Linux Process Priority Class' Of This Process Changed To '%d'\n", nProcessPriorityClass);

#endif

        META_CONPRINT("***********************************\n\n");

#if defined WIN32

        ::SetPriorityClass(::GetCurrentProcess(), xTo(nProcessPriorityClass, unsigned long));

#else

        setpriority(PRIO_PROCESS, getpid(), nProcessPriorityClass);

#endif

    }

    if (jsonTree["Interval Per Tick"].empty())
    {
        META_CONPRINT("\n***********************************\n");
        META_CONPRINTF("Failed To Find The 'Interval Per Tick' Setting Into The '%s' File\n\n", strConfigFilePath.c_str());
        ::std::cout << "Defaulting To '" << nDefaultTickRate << "' Tick Rate" << ::std::endl;
        ::std::cout << "'" << ::std::setprecision(maxRealPrecision) << fTickInterval << "' Tick Interval" << ::std::endl;
        META_CONPRINT("***********************************\n\n");

        jsonTree.clear();

        RETURN_META_VALUE(MRES_SUPERCEDE, fTickInterval);
    }

    fTickInterval = jsonTree["Interval Per Tick"].get < float >();

    jsonTree.clear();

    META_CONPRINT("\n***********************************\n");
    ::std::cout << "Successfully Set The 'Interval Per Tick' Setting To '" << ::std::setprecision(maxRealPrecision) << fTickInterval << "'" << ::std::endl;
    ::std::cout << "It Means That The Tick Rate Is Now '" << ::std::setprecision(maxRealPrecision) << (1.0f / fTickInterval) << "'" << ::std::endl;
    META_CONPRINT("***********************************\n\n");

    RETURN_META_VALUE(MRES_SUPERCEDE, fTickInterval);
}

void CustomTickRate::AllPluginsLoaded()
{

}

bool CustomTickRate::Pause(char*, unsigned int)
{
    if (g_bIsHooked)
    {
        SH_REMOVE_HOOK_MEMFUNC(IServerGameDLL, GetTickInterval, g_pIServerGameDLL_, this, &CustomTickRate::Hook_GetTickInterval, false);

        SH_REMOVE_HOOK_MEMFUNC(IServerGameDLL, GetTickInterval, g_pIServerGameDLL_, this, &CustomTickRate::Hook_GetTickInterval, true);

        g_bIsHooked = { };
    }

    return true;
}

bool CustomTickRate::Unpause(char*, unsigned int)
{
    if (!g_bIsHooked)
    {
        SH_ADD_HOOK_MEMFUNC(IServerGameDLL, GetTickInterval, g_pIServerGameDLL_, this, &CustomTickRate::Hook_GetTickInterval, false);

        SH_ADD_HOOK_MEMFUNC(IServerGameDLL, GetTickInterval, g_pIServerGameDLL_, this, &CustomTickRate::Hook_GetTickInterval, true);

        g_bIsHooked = true;
    }

    return true;
}

const char* CustomTickRate::GetLicense()
{
    return "MIT";
}

const char* CustomTickRate::GetVersion()
{
    return __DATE__;
}

const char* CustomTickRate::GetDate()
{
    return __DATE__;
}

const char* CustomTickRate::GetLogTag()
{
    return "CTR";
}

const char* CustomTickRate::GetAuthor()
{
    return "Hattrick HKS";
}

const char* CustomTickRate::GetDescription()
{
    return "Helps Owners Set A Custom Tick Rate";
}

const char* CustomTickRate::GetName()
{
    return "Custom Tick Rate";
}

const char* CustomTickRate::GetURL()
{
    return "https://hattrick.go.ro/";
}

#if !defined WIN32

extern "C" void __cxa_pure_virtual(void)
{
}

void* operator new(size_t uiMem)
{
    return malloc(uiMem);
}

void* operator new[](size_t uiMem)
{
    return malloc(uiMem);
}

void operator delete(void* pMem)
{
    free(pMem);
}

void operator delete[](void* pMem)
{
    free(pMem);
}

#endif
