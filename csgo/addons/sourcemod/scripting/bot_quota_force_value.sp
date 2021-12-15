
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
static Handle g_hMpRestartGame =            INVALID_HANDLE;

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

    if (g_hMpRestartGame == INVALID_HANDLE)
    {
        g_hMpRestartGame =                          FindConVar("mp_restartgame");
    }

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

public void OnConfigsExecuted()
{
    if (g_hMpRestartGame != INVALID_HANDLE)
    {
        if (g_hBotQuota != INVALID_HANDLE)
        {
            CreateTimer(1.000000, _Timer_FakePlayers_Status_, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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

public Action _Timer_FakePlayers_Status_(Handle hTimer, any hData)
{
    static int nQuota = 0, nPlayer = 0, nHumans = 0, nFakePlayers = 0;

    nQuota = GetConVarInt(g_hBotQuota);

    if (nQuota > 0)
    {
        if (GetConVarInt(g_hMpRestartGame) == 0)
        {
            for (nPlayer = 1, nHumans = 0, nFakePlayers = 0; nPlayer <= MaxClients; nPlayer++)
            {
                if (IsClientConnected(nPlayer) && IsClientInGame(nPlayer))
                {
                    if (IsClientSourceTV(nPlayer) || IsClientReplay(nPlayer))
                    {
                        continue;
                    }

                    if (IsClientInKickQueue(nPlayer))
                    {
                        continue;
                    }

                    switch (IsFakeClient(nPlayer))
                    {
                        case false:
                        {
                            if (!IsClientTimingOut(nPlayer))
                            {
                                nHumans++;
                            }
                        }

                        default:
                        {
                            nFakePlayers++;
                        }
                    }
                }
            }

            if (nHumans < nQuota)
            {
                if (nFakePlayers < nQuota)
                {
                    SetConVarInt(g_hMpRestartGame, 1, true, true);
                }
            }
        }
    }
}
