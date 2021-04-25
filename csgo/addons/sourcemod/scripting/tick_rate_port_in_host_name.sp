
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
    name =          "Tick Rate & Port In 'hostname'",
    author =        "CARAMEL® HACK",
    description =   "Adds Tick Rate & Port In 'hostname'",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * GLOBAL VARIABLES
 */

Handle g_hHostName =                    INVALID_HANDLE;

bool g_bHostNameConVarChangeHooked =    false;


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
    if (g_hHostName == INVALID_HANDLE)
    {
        g_hHostName =                               FindConVar("hostname");
    }

    if (g_hHostName != INVALID_HANDLE)
    {
        if (!g_bHostNameConVarChangeHooked)
        {
            HookConVarChange(g_hHostName,           _Con_Var_Change_);

            g_bHostNameConVarChangeHooked =         true;
        }
    }
}

public void OnConfigsExecuted()
{
    static char szHostName[PLATFORM_MAX_PATH] = { 0, ... }, szHostPort[PLATFORM_MAX_PATH] = { 0, ... }, szTickRate[PLATFORM_MAX_PATH] = { 0, ... };

    static ConVar hHostName = null, hHostPort = null;
    static int nTickRate = 0;

    nTickRate = _Get_Sv_Tick_Rate_();

    IntToString(nTickRate, szTickRate, sizeof (szTickRate));

    ServerCommand("exec %d_tickrate.cfg", nTickRate);

    if (hHostName == null)
    {
        hHostName = FindConVar("hostname");
    }

    if (hHostPort == null)
    {
        hHostPort = FindConVar("hostport");
    }

    if (hHostName != null)
    {
        hHostName.GetString(szHostName, sizeof (szHostName));
    }

    if (hHostPort != null)
    {
        hHostPort.GetString(szHostPort, sizeof (szHostPort));
    }

    ReplaceString(szHostName,           sizeof (szHostName),    "<TICK>", szTickRate, false);
    ReplaceString(szHostName,           sizeof (szHostName),    "<PORT>", szHostPort, false);

    if (hHostName != null)
    {
        hHostName.SetString(szHostName, true);
    }
}

public void OnMapEnd()
{
    if (g_hHostName != INVALID_HANDLE)
    {
        if (g_bHostNameConVarChangeHooked)
        {
            UnhookConVarChange(g_hHostName,         _Con_Var_Change_);

            g_bHostNameConVarChangeHooked =         false;
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

    if (hConVar == g_hHostName)
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
