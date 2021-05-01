
/**
 * MAIN REQUIREMENTS
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>


/**
 * CUSTOM DEFINITIONS TO BE EDITED
 */

#define _SV_MAX_RATE_               (786432) // Maximum INT Value That 'sv_maxrate' Can Have In CS:GO

#define _RATE_CON_MSG_1_            "You are using rate %s. We recommend the maximum, rate %s."
#define _RATE_CON_MSG_2_            "You can type it in your console. You will also need a strong internet connection."

#define _RATE_MSG_1_                " \x01You are using\x05 rate %s\x01. We recommend the maximum,\x09 rate %s\x01."
#define _RATE_MSG_2_                " \x01You can type it in your\x0B console\x01. You will also need a\x04 strong internet connection\x01."


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "Notify Small 'rate' ConVar Setting",
    author =        "CARAMEL® HACK",
    description =   "Tells Players They Have Too Small 'rate' ConVar Value",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * GLOBAL VARIABLES
 */

static bool g_bRateMsgShown[MAXPLAYERS] =       { false, ... };

static float g_fRateMsgTimeStamp =              0.0;


/**
 * CUSTOM PUBLIC FORWARDS
 */

public void OnPluginStart()
{
    OnMapStart();
}

public void OnMapStart()
{
    g_fRateMsgTimeStamp = 0.0;
}

public void OnMapEnd()
{
    g_fRateMsgTimeStamp = 0.0;
}

public void OnPluginEnd()
{
    OnMapStart();
}

public bool OnClientConnect(int nEntity, char[] szError, int nMaxLen)
{
    g_bRateMsgShown[nEntity] =          false;

    return true;
}

public Action CS_OnTerminateRound(float& fDelay, CSRoundEndReason& nReason)
{
    static float fTimeNow = 0.0;
    static int nPlayer = 0, nTeam = 0;

    if (((fTimeNow = GetEngineTime()) - g_fRateMsgTimeStamp) > 16.0 || g_fRateMsgTimeStamp == 0.0)
    {
        g_fRateMsgTimeStamp = fTimeNow;

        for (nPlayer = 1; nPlayer <= MaxClients; nPlayer++)
        {
            if (g_bRateMsgShown[nPlayer])
            {
                continue;
            }

            if (!IsClientConnected(nPlayer)     ||      !IsClientInGame(nPlayer))
            {
                continue;
            }

            if (IsFakeClient(nPlayer)           ||      IsClientSourceTV(nPlayer)       ||      IsClientReplay(nPlayer))
            {
                continue;
            }

            if (IsClientInKickQueue(nPlayer)    ||      IsClientTimingOut(nPlayer))
            {
                continue;
            }

            nTeam = GetClientTeam(nPlayer);

            if (nTeam != CS_TEAM_T              &&      nTeam != CS_TEAM_CT)
            {
                continue;
            }

            QueryClientConVar(nPlayer, "rate", _Rate_Con_Var_Check_);
        }
    }
}


/**
 * CUSTOM PUBLIC HANDLERS
 */

public void _Rate_Con_Var_Check_(QueryCookie nCookie, int nPlayer, ConVarQueryResult nRes, const char[] szConVarName, const char[] szConVarValue)
{
    static char szSvMaxRate[PLATFORM_MAX_PATH] = { 0, ... };
    static int nPlayerRate = 0, nSvMaxRate = 0;
    static ConVar hSvMaxRate = null;

    if (nRes == ConVarQuery_Okay)
    {
        if (IsClientConnected(nPlayer) && IsClientInGame(nPlayer))
        {
            g_bRateMsgShown[nPlayer] = true;

            if (hSvMaxRate == null)
            {
                hSvMaxRate =    FindConVar("sv_maxrate");
            }

            if (hSvMaxRate != null)
            {
                hSvMaxRate.GetString(szSvMaxRate,           sizeof (szSvMaxRate));

                nSvMaxRate =    hSvMaxRate.IntValue;

                if (nSvMaxRate  < 1)
                {
                    nSvMaxRate  = _SV_MAX_RATE_;

                    IntToString(nSvMaxRate, szSvMaxRate,    sizeof (szSvMaxRate));
                }

                nPlayerRate =   StringToInt(szConVarValue);

                if (nPlayerRate < nSvMaxRate)
                {
                    PrintToConsole(nPlayer, _RATE_CON_MSG_1_,   szConVarValue,  szSvMaxRate);
                    PrintToConsole(nPlayer, _RATE_CON_MSG_2_);

                    PrintToChat(nPlayer,    _RATE_MSG_1_,       szConVarValue,  szSvMaxRate);
                    PrintToChat(nPlayer,    _RATE_MSG_2_);
                }
            }
        }
    }
}
