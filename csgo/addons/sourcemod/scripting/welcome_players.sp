
/**
 * MAIN REQUIREMENTS
 */

#include <sourcemod>
#include <sdktools>

#if !defined    CS_TEAM_NONE
    #define     CS_TEAM_NONE    (0)
#endif

#if !defined    CS_TEAM_T
    #define     CS_TEAM_T       (2)
#endif

#if !defined    CS_TEAM_CT
    #define     CS_TEAM_CT      (3)
#endif


/**
 * CUSTOM DEFINITIONS TO BE EDITED
 */

#define _WELCOME_CON_MSG_1_         "Welcome. Committing suicide will not alter your score. Unlimited team changes are allowed. The voting system is enabled."
#define _WELCOME_CON_MSG_2_         "You may /rs, /map, /votemap, /voterr or /voterestart."

#define _WELCOME_MSG_1_             " \x01\x0BWelcome\x01. Committing\x09 suicide\x01 will not alter your\x04 score\x01. Unlimited\x09 team changes\x01 are\x04 allowed\x01. The\x09 voting system\x01 is\x04 enabled\x01."
#define _WELCOME_MSG_2_             " \x01You may\x05 /rs\x01,\x05 /map\x01,\x05 /votemap\x01,\x05 /voterr\x01 or\x05 /voterestart\x01."


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "Welcome Players",
    author =        "CARAMEL® HACK",
    description =   "Welcomes All Players After Joining The Game Server",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * GLOBAL VARIABLES
 */

static bool g_bMsgShown[MAXPLAYERS] =       { false, ... };

static bool g_bPlayerTeamHooked =           false;


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
        HookEventEx("player_team",                  _Player_Team_,      EventHookMode_Post);

        g_bPlayerTeamHooked =                       true;
    }
}

public void OnMapEnd()
{
    if (g_bPlayerTeamHooked)
    {
        UnhookEvent("player_team",                  _Player_Team_,      EventHookMode_Post);

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
                (nTeam = hEv.GetInt("team", CS_TEAM_NONE))
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
            (nEntity = GetClientOfUserId(hEv.GetInt("userid", 0)))
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

        PrintToConsole(nEntity, _WELCOME_CON_MSG_1_);
        PrintToConsole(nEntity, _WELCOME_CON_MSG_2_);

        PrintToChat(nEntity, _WELCOME_MSG_1_);
        PrintToChat(nEntity, _WELCOME_MSG_2_);
    }
}
