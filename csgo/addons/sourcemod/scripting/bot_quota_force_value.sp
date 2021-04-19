
/**
 * MAIN REQUIREMENTS
 */

#include < sourcemod >
#include < cstrike >
#include < sdktools >
#include < sdkhooks >


/**
 * CUSTOM DEFINITIONS TO BE EDITED
 */

#define _BOT_QUOTA_                 (2)


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "'bot_quota' Force Value",
    author =        "CARAMEL® HACK",
    description =   "Forces a 'bot_quota' value.",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * GLOBAL VARIABLES
 */

Handle g_hBotQuota =                INVALID_HANDLE;

bool g_bQuotaConVarChangeHooked =   false;


/**
 * CUSTOM PUBLIC FORWARDS
 */

public void OnPluginStart()
{
    OnMapStart();
}

public void OnMapStart()
{
    if (g_hBotQuota == INVALID_HANDLE)
    {
        g_hBotQuota =                               FindConVar("bot_quota");
    }

    if (g_hBotQuota != INVALID_HANDLE)
    {
        if (GetConVarInt(g_hBotQuota) !=            _BOT_QUOTA_)
        {
            SetConVarInt(g_hBotQuota,               _BOT_QUOTA_);
        }

        if (!g_bQuotaConVarChangeHooked)
        {
            HookConVarChange(g_hBotQuota,           _Con_Var_Change_);

            g_bQuotaConVarChangeHooked =            true;
        }

        if (GetConVarInt(g_hBotQuota) !=            _BOT_QUOTA_)
        {
            SetConVarInt(g_hBotQuota,               _BOT_QUOTA_);
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
    if (hConVar == g_hBotQuota)
    {
        if (StringToInt(szNew) !=           _BOT_QUOTA_)
        {
            SetConVarInt(hConVar,           _BOT_QUOTA_);
        }
    }
}
