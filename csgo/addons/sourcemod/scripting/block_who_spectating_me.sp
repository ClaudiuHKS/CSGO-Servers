#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public  Plugin  myinfo  =
{
    name                =   "Any Game AC: Hidden Spectators"                            , \
    author              =   "Hattrick HKS (claudiuhks)"                                 , \
    description         =   "Blocks Any Kind Of Spectators' Resolvers"                  , \
    version             =   __DATE__                                                    , \
    url                 =   "https://forums.alliedmods.net/showthread.php?t=324601"     ,
};

bool g_bAlive               [MAXPLAYERS]                    =       { false, ... };
bool g_bInGame              [MAXPLAYERS]                    =       { false, ... };

public void OnClientPutInServer(int nClient)
{
    SDKHookEx(nClient, SDKHook_SetTransmit, Hook_SetTransmit);

    g_bInGame   [nClient]   =   true;
}

public void OnClientDisconnect(int nClient)
{
    SDKUnhook(nClient, SDKHook_SetTransmit, Hook_SetTransmit);

    g_bAlive    [nClient]   =   false;
    g_bInGame   [nClient]   =   false;
}

public void OnClientDisconnect_Post(int nClient)
{
    SDKUnhook(nClient, SDKHook_SetTransmit, Hook_SetTransmit);

    g_bAlive    [nClient]   =   false;
    g_bInGame   [nClient]   =   false;
}

public void OnPluginEnd()
{
    for (int nClient = 1; nClient <= MaxClients; nClient++)
    {
        if (g_bInGame[nClient])
        {
            SDKUnhook(nClient, SDKHook_SetTransmit, Hook_SetTransmit);

            g_bAlive    [nClient]   =   false;
            g_bInGame   [nClient]   =   false;
        }
    }

    UnhookEvent("player_spawn", OnPlayerStateChanged_Pre, EventHookMode_Pre);
    UnhookEvent("player_death", OnPlayerStateChanged_Pre, EventHookMode_Pre);
    UnhookEvent("player_team",  OnPlayerStateChanged_Pre, EventHookMode_Pre);

    UnhookEvent("player_spawn", OnPlayerStateChanged, EventHookMode_Post);
    UnhookEvent("player_death", OnPlayerStateChanged, EventHookMode_Post);
    UnhookEvent("player_team",  OnPlayerStateChanged, EventHookMode_Post);
}

public void OnPluginStart()
{
    HookEventEx("player_spawn", OnPlayerStateChanged_Pre, EventHookMode_Pre);
    HookEventEx("player_death", OnPlayerStateChanged_Pre, EventHookMode_Pre);
    HookEventEx("player_team",  OnPlayerStateChanged_Pre, EventHookMode_Pre);

    HookEventEx("player_spawn", OnPlayerStateChanged, EventHookMode_Post);
    HookEventEx("player_death", OnPlayerStateChanged, EventHookMode_Post);
    HookEventEx("player_team",  OnPlayerStateChanged, EventHookMode_Post);

    for (int nClient = 1; nClient <= MaxClients; nClient++)
    {
        if (IsClientConnected(nClient) && IsClientInGame(nClient))
        {
            OnClientPutInServer(nClient);

            CreateTimer(0.000001, Timer_PlayerStateChanged, GetClientUserId(nClient), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public void OnPlayerStateChanged_Pre(Event hEv, const char[] szEvName, bool bEvNoBC)
{
    static int nUserId = 0;

    if (hEv != null)
    {
        nUserId = hEv.GetInt("userid", 0);

        if (nUserId > 0)
        {
            CreateTimer(0.000001, Timer_PlayerStateChanged, nUserId, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public void OnPlayerStateChanged(Event hEv, const char[] szEvName, bool bEvNoBC)
{
    static int nUserId = 0;

    if (hEv != null)
    {
        nUserId = hEv.GetInt("userid", 0);

        if (nUserId > 0)
        {
            CreateTimer(0.000001, Timer_PlayerStateChanged, nUserId, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action Timer_PlayerStateChanged(Handle hTimer, any nUserId)
{
    static int nClient = 0;

    if ((nClient = GetClientOfUserId(nUserId)) > 0 && g_bInGame[nClient])
    {
        g_bAlive[nClient] = IsPlayerAlive(nClient);
    }
}

public Action Hook_SetTransmit(int nEntity, int nClient)
{
    if (g_bAlive[nClient] &&    !g_bAlive[nEntity])
    {
        return Plugin_Handled;  // If I'm alive, the game server shouldn't transmit through the Internet any dead players to me!
    }

    return Plugin_Continue;
}
