
/**
 * MAIN REQUIREMENTS
 */

#include <sourcemod>
#include <sdktools>


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "Vote Restart Command",
    author =        "CARAMEL® HACK",
    description =   "Provides Custom Command To Vote To Restart The Game In Progress",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * CUSTOM PUBLIC FORWARDS
 */

public void OnClientSayCommand_Post(int nEntity, const char[] szCmd, const char[] szArgs)
{
    if (!IsClientConnected(nEntity) || !IsClientInGame(nEntity))
    {
        return;
    }

    if
    (
        strcmp(szArgs, "rr", false) == 0
            ||
        strcmp(szArgs, "voterr", false) == 0
            ||
        strcmp(szArgs, "voterestart", false) == 0
            ||
        strcmp(szArgs, "votereset", false) == 0
            ||
        strcmp(szArgs, "rgame", false) == 0
            ||
        strcmp(szArgs, "restartgame", false) == 0
            ||
        strcmp(szArgs, "!rr", false) == 0
            ||
        strcmp(szArgs, "!voterr", false) == 0
            ||
        strcmp(szArgs, "!voterestart", false) == 0
            ||
        strcmp(szArgs, "!votereset", false) == 0
            ||
        strcmp(szArgs, "!rgame", false) == 0
            ||
        strcmp(szArgs, "!restartgame", false) == 0
            ||
        strcmp(szArgs, "/rr", false) == 0
            ||
        strcmp(szArgs, "/voterr", false) == 0
            ||
        strcmp(szArgs, "/voterestart", false) == 0
            ||
        strcmp(szArgs, "/votereset", false) == 0
            ||
        strcmp(szArgs, "/rgame", false) == 0
            ||
        strcmp(szArgs, "/restartgame", false) == 0
    )
    {
        CreateTimer(0.000001, _Timer_Vote_Restart_Game_, GetClientUserId(nEntity), TIMER_FLAG_NO_MAPCHANGE);
    }
}


/**
 * CUSTOM PUBLIC HANDLERS
 */

public Action _Timer_Vote_Restart_Game_(Handle hTimer, any nId)
{
    static int nEntity = 0;

    if ((nEntity = GetClientOfUserId(nId)) > 0 &&   IsClientConnected(nEntity) &&           IsClientInGame(nEntity))
    {
        if (GameRules_GetProp("m_bWarmupPeriod"))
        {
            PrintToChat(nEntity,                    " \x01Try again\x0B later\x01.");
        }

        else
        {
            FakeClientCommandEx(nEntity,            "callvote RestartGame");

            PrintToChat(nEntity,                    " \x01Done.");
        }
    }

    return Plugin_Continue;
}
