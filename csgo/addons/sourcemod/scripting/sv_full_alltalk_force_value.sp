
/**
 * MAIN REQUIREMENTS
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


/**
 * CUSTOM DEFINITIONS TO BE EDITED
 */

#define _SV_FULL_ALLTALK_           (1) // sv_full_alltalk


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "'sv_full_alltalk' Force Value",
    author =        "CARAMEL® HACK",
    description =   "Forces A 'sv_full_alltalk' Value",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * GLOBAL VARIABLES
 */

Handle g_hSvFullAllTalk =           INVALID_HANDLE;

bool g_bAllTalkConVarChangeHooked = false;


/**
 * CUSTOM PUBLIC FORWARDS
 */

public void OnPluginStart()
{
    OnMapStart();
}

public void OnMapStart()
{
    static char szBuffer[PLATFORM_MAX_PATH] =       { 0, ... };

    if (g_hSvFullAllTalk == INVALID_HANDLE)
    {
        g_hSvFullAllTalk =                          FindConVar("sv_full_alltalk");
    }

    if (g_hSvFullAllTalk != INVALID_HANDLE)
    {
        if (GetConVarInt(g_hSvFullAllTalk) !=       _SV_FULL_ALLTALK_)
        {
            IntToString(_SV_FULL_ALLTALK_,          szBuffer, sizeof (szBuffer));

            SetConVarString(g_hSvFullAllTalk,       szBuffer, true);
        }

        if (!g_bAllTalkConVarChangeHooked)
        {
            HookConVarChange(g_hSvFullAllTalk,      _Con_Var_Change_);

            g_bAllTalkConVarChangeHooked =          true;
        }

        if (GetConVarInt(g_hSvFullAllTalk) !=       _SV_FULL_ALLTALK_)
        {
            IntToString(_SV_FULL_ALLTALK_,          szBuffer, sizeof (szBuffer));

            SetConVarString(g_hSvFullAllTalk,       szBuffer, true);
        }
    }
}

public void OnMapEnd()
{
    if (g_hSvFullAllTalk != INVALID_HANDLE)
    {
        if (g_bAllTalkConVarChangeHooked)
        {
            UnhookConVarChange(g_hSvFullAllTalk,    _Con_Var_Change_);

            g_bAllTalkConVarChangeHooked =          false;
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
    static char szBuffer[PLATFORM_MAX_PATH] = { 0, ... };

    if (hConVar == g_hSvFullAllTalk)
    {
        if (StringToInt(szNew) !=           _SV_FULL_ALLTALK_)
        {
            IntToString(_SV_FULL_ALLTALK_,  szBuffer, sizeof (szBuffer));

            SetConVarString(hConVar,        szBuffer, true);
        }
    }
}
