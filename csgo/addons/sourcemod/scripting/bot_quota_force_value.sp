
/**
 * MAIN REQUIREMENTS
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


/**
 * CUSTOM DEFINITIONS TO BE EDITED
 */

#define _BOT_QUOTA_                 (2) // bot_quota


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "'bot_quota' Force Value",
    author =        "CARAMEL® HACK",
    description =   "Forces A 'bot_quota' Value",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * GLOBAL VARIABLES
 */

static Handle g_hBotQuota =                 INVALID_HANDLE;

static bool g_bQuotaConVarChangeHooked =    false;


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

    if (g_hBotQuota == INVALID_HANDLE)
    {
        g_hBotQuota =                               FindConVar("bot_quota");
    }

    if (g_hBotQuota != INVALID_HANDLE)
    {
        if (GetConVarInt(g_hBotQuota) !=            _BOT_QUOTA_)
        {
            IntToString(_BOT_QUOTA_,                szBuffer, sizeof (szBuffer));

            SetConVarString(g_hBotQuota,            szBuffer, true, true);
        }

        if (!g_bQuotaConVarChangeHooked)
        {
            HookConVarChange(g_hBotQuota,           _Con_Var_Change_);

            g_bQuotaConVarChangeHooked =            true;
        }

        if (GetConVarInt(g_hBotQuota) !=            _BOT_QUOTA_)
        {
            IntToString(_BOT_QUOTA_,                szBuffer, sizeof (szBuffer));

            SetConVarString(g_hBotQuota,            szBuffer, true, true);
        }
    }
}

public void OnMapEnd()
{
    if (g_hBotQuota != INVALID_HANDLE)
    {
        if (g_bQuotaConVarChangeHooked)
        {
            UnhookConVarChange(g_hBotQuota,         _Con_Var_Change_);

            g_bQuotaConVarChangeHooked =            false;
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

    if (hConVar == g_hBotQuota)
    {
        if (StringToInt(szNew) !=           _BOT_QUOTA_)
        {
            IntToString(_BOT_QUOTA_,        szBuffer, sizeof (szBuffer));

            SetConVarString(hConVar,        szBuffer, true, true);
        }
    }
}
