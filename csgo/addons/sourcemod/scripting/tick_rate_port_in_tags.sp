
/**
 * MAIN REQUIREMENTS
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "Tick Rate & Port In 'sv_tags'",
    author =        "CARAMEL® HACK",
    description =   "Adds Tick Rate & Port In 'sv_tags'",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * GLOBAL VARIABLES
 */

static Handle g_hSvTags =                       INVALID_HANDLE;

static bool g_bSvTagsConVarChangeHooked =       false;


/**
 * CUSTOM PRIVATE FUNCTIONS
 */

static int _Get_Sv_Tick_Rate_()
{
    return RoundToNearest(1.0 / GetTickInterval());
}


/**
 * CUSTOM PUBLIC FORWARDS
 */

public void OnPluginStart()
{
    OnMapStart();

    OnConfigsExecuted();
}

public void OnMapStart()
{
    if (g_hSvTags == INVALID_HANDLE)
    {
        g_hSvTags =                                 FindConVar("sv_tags");
    }

    if (g_hSvTags != INVALID_HANDLE)
    {
        if (!g_bSvTagsConVarChangeHooked)
        {
            HookConVarChange(g_hSvTags,             _Con_Var_Change_);

            g_bSvTagsConVarChangeHooked =           true;
        }
    }
}

public void OnConfigsExecuted()
{
    static char szHostPort[PLATFORM_MAX_PATH] = { 0, ... }, szTags[PLATFORM_MAX_PATH] = { 0, ... }, szTickRate[PLATFORM_MAX_PATH] = { 0, ... };

    static ConVar hHostPort = null, hTags = null;
    static int nTickRate = 0;

    nTickRate = _Get_Sv_Tick_Rate_();

    IntToString(nTickRate, szTickRate, sizeof (szTickRate));

    ServerCommand("exec %d_tickrate.cfg", nTickRate);

    if (hHostPort == null)
    {
        hHostPort = FindConVar("hostport");
    }

    if (hTags == null)
    {
        hTags =     FindConVar("sv_tags");
    }

    if (hHostPort != null)
    {
        hHostPort.GetString(szHostPort, sizeof (szHostPort));
    }

    if (hTags != null)
    {
        hTags.GetString(szTags,         sizeof (szTags));
    }

    ReplaceString(szTags,               sizeof (szTags),        "<TICK>", szTickRate, false);
    ReplaceString(szTags,               sizeof (szTags),        "<PORT>", szHostPort, false);

    if (hTags != null)
    {
        hTags.SetString(szTags,         true);
    }
}

public void OnMapEnd()
{
    if (g_hSvTags != INVALID_HANDLE)
    {
        if (g_bSvTagsConVarChangeHooked)
        {
            UnhookConVarChange(g_hSvTags,           _Con_Var_Change_);

            g_bSvTagsConVarChangeHooked =           false;
        }
    }
}

public void OnPluginEnd()
{
    OnMapEnd();
}


/**
 * CUSTOM PUBLIC HANDLERS
 */

public void _Con_Var_Change_(Handle hConVar, const char[] szOld, const char[] szNew)
{
    static char szBuffer[PLATFORM_MAX_PATH] = { 0, ... }, szHostPort[PLATFORM_MAX_PATH] = { 0, ... }, szTickRate[PLATFORM_MAX_PATH] = { 0, ... };
    static ConVar hHostPort = null;
    static int nTickRate = 0;

    if (hHostPort == null)
    {
        hHostPort = FindConVar("hostport");
    }

    if (hConVar == g_hSvTags)
    {
        if (hHostPort != null)
        {
            hHostPort.GetString(szHostPort, sizeof (szHostPort));

            nTickRate = _Get_Sv_Tick_Rate_();

            IntToString(nTickRate, szTickRate, sizeof (szTickRate));

            strcopy(szBuffer, sizeof (szBuffer), szNew);

            ReplaceString(szBuffer, sizeof (szBuffer), "<TICK>", szTickRate, false);
            ReplaceString(szBuffer, sizeof (szBuffer), "<PORT>", szHostPort, false);

            if (strcmp(szNew, szBuffer))
            {
                SetConVarString(hConVar, szBuffer, true);
            }
        }
    }
}
