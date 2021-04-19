
/**
 * MAIN REQUIREMENTS
 */

#include < sourcemod >
#include < cstrike >
#include < regex >
#include < sdktools >
#include < sdkhooks >


/**
 * CUSTOM DEFINITIONS TO BE EDITED
 */

#define _SV_FULL_ALLTALK_           (1)


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "'sv_full_alltalk' Force Value",
    author =        "CARAMEL® HACK",
    description =   "Forces a 'sv_full_alltalk' value.",
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
    if (g_hSvFullAllTalk == INVALID_HANDLE)
    {
        g_hSvFullAllTalk =                          FindConVar("sv_full_alltalk");
    }

    if (g_hSvFullAllTalk != INVALID_HANDLE)
    {
        if (GetConVarInt(g_hSvFullAllTalk) !=       _SV_FULL_ALLTALK_)
        {
            SetConVarInt(g_hSvFullAllTalk,          _SV_FULL_ALLTALK_);
        }

        if (!g_bAllTalkConVarChangeHooked)
        {
            HookConVarChange(g_hSvFullAllTalk,      _Con_Var_Change_);

            g_bAllTalkConVarChangeHooked =          true;
        }

        if (GetConVarInt(g_hSvFullAllTalk) !=       _SV_FULL_ALLTALK_)
        {
            SetConVarInt(g_hSvFullAllTalk,          _SV_FULL_ALLTALK_);
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
    if (hConVar == g_hSvFullAllTalk)
    {
        if (StringToInt(szNew) !=           _SV_FULL_ALLTALK_)
        {
            SetConVarInt(hConVar,           _SV_FULL_ALLTALK_);
        }
    }
}
