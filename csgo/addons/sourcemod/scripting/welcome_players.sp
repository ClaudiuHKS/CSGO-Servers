
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

#define _WELCOME_MSG_1_             " \x01\x0BWelcome\x01. Committing\x09 suicide\x01 will not alter your\x04 score\x01. Unlimited\x09 team changes\x01 are\x04 allowed\x01. The\x09 voting system\x01 is\x04 enabled\x01."
#define _WELCOME_MSG_2_             " \x01You may\x05 /rs\x01,\x05 /map\x01,\x05 /votemap\x01,\x05 /voterr\x01 or\x05 /voterestart\x01."


/**
 * CUSTOM DEFINITIONS
 */

#define         _PREP_OFFS_(%0,%1,%2)       if (%1 < 1) %1 = _Get_Offs_(%0, %2)

#if !defined    CS_TEAM_T
#define         CS_TEAM_T                   (2)
#endif

#if !defined    CS_TEAM_CT
#define         CS_TEAM_CT                  (3)
#endif


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "Welcome Players",
    author =        "CARAMEL® HACK",
    description =   "Welcome all players after joining the game server.",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * GLOBAL VARIABLES
 */

bool g_bMsgShown[MAXPLAYERS] =      { false, ... };

bool g_bPlayerTeamHooked =          false;


/**
 * CUSTOM PUBLIC FORWARDS
 */

public void OnPluginStart()
{
    OnMapStart();
}

public void OnMapStart()
{
    if (!g_bPlayerTeamHooked)
    {
        HookEventEx("player_team",                  _Player_Team_);

        g_bPlayerTeamHooked =                       true;
    }
}

public void OnMapEnd()
{
    if (g_bPlayerTeamHooked)
    {
        UnhookEvent("player_team",                  _Player_Team_);

        g_bPlayerTeamHooked =                       false;
    }
}

public void OnPluginEnd()
{
    OnMapEnd();
}

public bool OnClientConnect(int nEntity, char[] szError, int nMaxLen)
{
    g_bMsgShown[nEntity] = false;

    return true;
}


/**
 * CUSTOM PUBLIC HANDLERS
 */

public void _Player_Team_(Event hEv, const char[] szName, bool bNoBC)
{
    static int nTeam = 0, nEntity = 0;

    if
    (
        (
            (
                (nTeam = hEv.GetInt("team"))
                    ==
                (CS_TEAM_T)
            )
            ||
            (
                (nTeam)
                    ==
                (CS_TEAM_CT)
            )
        )
        &&
        (
            (nEntity = GetClientOfUserId(hEv.GetInt("userid")))
                >
            (0)
        )
        &&
        (
            (g_bMsgShown[nEntity])
                ==
            (false)
        )
        &&
        (
            (IsClientConnected(nEntity))
                ==
            (true)
        )
        &&
        (
            (IsClientInGame(nEntity))
                ==
            (true)
        )
    )
    {
        g_bMsgShown[nEntity] = true;

        PrintToChat(nEntity, _WELCOME_MSG_1_);
        PrintToChat(nEntity, _WELCOME_MSG_2_);
    }
}
