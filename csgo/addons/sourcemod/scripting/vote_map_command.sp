
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
    name =          "Vote Map Command",
    author =        "CARAMEL® HACK",
    description =   "Provides Custom Command To Vote To Change The Map",
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
        strcmp(szArgs, "map", false) == 0
            ||
        strcmp(szArgs, "votemap", false) == 0
            ||
        strcmp(szArgs, "changemap", false) == 0
            ||
        strcmp(szArgs, "level", false) == 0
            ||
        strcmp(szArgs, "vote", false) == 0
            ||
        strcmp(szArgs, "votelevel", false) == 0
            ||
        strcmp(szArgs, "changelevel", false) == 0
            ||
        strcmp(szArgs, "!map", false) == 0
            ||
        strcmp(szArgs, "!votemap", false) == 0
            ||
        strcmp(szArgs, "!changemap", false) == 0
            ||
        strcmp(szArgs, "!level", false) == 0
            ||
        strcmp(szArgs, "!vote", false) == 0
            ||
        strcmp(szArgs, "!votelevel", false) == 0
            ||
        strcmp(szArgs, "!changelevel", false) == 0
            ||
        strcmp(szArgs, "/map", false) == 0
            ||
        strcmp(szArgs, "/votemap", false) == 0
            ||
        strcmp(szArgs, "/changemap", false) == 0
            ||
        strcmp(szArgs, "/level", false) == 0
            ||
        strcmp(szArgs, "/vote", false) == 0
            ||
        strcmp(szArgs, "/votelevel", false) == 0
            ||
        strcmp(szArgs, "/changelevel", false) == 0
    )
    {
        CreateTimer(0.000001, _Timer_Vote_Change_Map_, GetClientUserId(nEntity), TIMER_FLAG_NO_MAPCHANGE);
    }
}


/**
 * CUSTOM PUBLIC HANDLERS
 */

public Action _Timer_Vote_Change_Map_(Handle hTimer, any nId)
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
            FakeClientCommandEx(nEntity,            "callvote");

            PrintToChat(nEntity,                    " \x01Done.");
        }
    }
}
