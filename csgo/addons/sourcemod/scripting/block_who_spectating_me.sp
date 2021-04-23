#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
    name            =   "Any Game AC: Hidden Spectators"                            , \
    author          =   "Hattrick HKS (claudiuhks)"                                 , \
    description     =   "Blocks Any Kind Of Spectators' Resolvers"                  , \
    version         =   __DATE__                                                    , \
    url             =   "https://forums.alliedmods.net/showthread.php?t=324601"     ,
};

bool g_bAlive[MAXPLAYERS] = { false, ... };

public void OnClientPutInServer(int nClient)
{
    SDKHookEx(nClient, SDKHook_SetTransmit, Hook_SetTransmit);
}

public void OnClientDisconnect(int nClient)
{
    SDKUnhook(nClient, SDKHook_SetTransmit, Hook_SetTransmit);

    g_bAlive[nClient] = false;
}

public void OnPluginEnd()
{
    for (int nClient = 1; nClient < MAXPLAYERS; nClient++)
    {
        if (IsClientConnected(nClient) && IsClientInGame(nClient))
        {
            SDKUnhook(nClient, SDKHook_SetTransmit, Hook_SetTransmit);
        }

        g_bAlive[nClient] = false;
    }

    UnhookEvent("player_spawn", OnPlayerStateChanged, EventHookMode_Post);
    UnhookEvent("player_death", OnPlayerStateChanged, EventHookMode_Post);
    UnhookEvent("player_team",  OnPlayerStateChanged, EventHookMode_Post);

    UnhookEvent("player_spawn", OnPlayerStateChanged, EventHookMode_Pre);
    UnhookEvent("player_death", OnPlayerStateChanged, EventHookMode_Pre);
    UnhookEvent("player_team",  OnPlayerStateChanged, EventHookMode_Pre);
}

public void OnClientDisconnect_Post(int nClient)
{
    SDKUnhook(nClient, SDKHook_SetTransmit, Hook_SetTransmit);

    g_bAlive[nClient] = false;
}

public void OnPluginStart()
{
    HookEventEx("player_spawn", OnPlayerStateChanged, EventHookMode_Post);
    HookEventEx("player_death", OnPlayerStateChanged, EventHookMode_Post);
    HookEventEx("player_team",  OnPlayerStateChanged, EventHookMode_Post);

    HookEventEx("player_spawn", OnPlayerStateChanged, EventHookMode_Pre);
    HookEventEx("player_death", OnPlayerStateChanged, EventHookMode_Pre);
    HookEventEx("player_team",  OnPlayerStateChanged, EventHookMode_Pre);

    for (int nEntity = 1; nEntity < MAXPLAYERS; nEntity++)
    {
        if (IsClientConnected(nEntity) && IsClientInGame(nEntity))
        {
            OnClientPutInServer(nEntity);
        }
    }
}

public Action OnPlayerStateChanged(Event hEv, const char[] szEvName, bool bEvNoBC)
{
    if (hEv != null)
    {
        CreateTimer(0.000001, Timer_PlayerStateChanged, hEv.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_PlayerStateChanged(Handle hTimer, any nUserId)
{
    int nClient = GetClientOfUserId(nUserId);

    if (nClient > 0)
    {
        if (IsClientConnected(nClient) && IsClientInGame(nClient))
        {
            g_bAlive[nClient] = IsPlayerAlive(nClient);
        }

        else
        {
            g_bAlive[nClient] = false;
        }
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
