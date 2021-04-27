#include <sourcemod>
#include <GeoResolver>

public Plugin myinfo =
{
    name            =   "GeoResolver: Connect Announcer"                            , \
    author          =   "Hattrick HKS (claudiuhks)"                                 , \
    description     =   "Prints Players' Geographical Information While Joining"    , \
    version         =   __DATE__                                                    , \
    url             =   "https://forums.alliedmods.net/showthread.php?t=267805"     ,
};

/**
 * PRINTS   " \x01Player\x04 HATTRİCK CARAMEL® HACK CS.MONEY\x01 Joined"
 *
 * IF THE   GEOGRAPHICAL    INFORMATION HAS NOT BEEN DETECTED
 *
 * UNCOMMENT    - '//'      IF YES
 * COMMENT      + '//'      IF NO
 */

// #define SHOW_EVEN_IF_NOT_DETECTED

/**
 * PRINTS ONLY A MESSAGE EACH # SECONDS
 */

#define CHAT_SPAM_DELAY 8.000000

static float g_fStamp = 0.000000;

public void OnPluginStart()
{
    HookEventEx("player_disconnect",            OnPlrDisconnect_Pre,        EventHookMode_Pre);
    HookEventEx("player_disconnect_client",     OnPlrDisconnect_Pre,        EventHookMode_Pre);
    HookEventEx("player_client_disconnect",     OnPlrDisconnect_Pre,        EventHookMode_Pre);

    HookEventEx("player_connect",               OnPlrConnect_Pre,           EventHookMode_Pre);
    HookEventEx("player_connect_client",        OnPlrConnect_Pre,           EventHookMode_Pre);
    HookEventEx("player_client_connect",        OnPlrConnect_Pre,           EventHookMode_Pre);

    g_fStamp = 0.000000;
}

public void OnMapStart()
{
    g_fStamp = 0.000000;
}

public void OnMapEnd()
{
    g_fStamp = 0.000000;
}

public void OnClientPutInServer(int nClient)
{
    CreateTimer(GetRandomFloat(2.250000, 4.500000)  , \
                displayJoinInfo                     , \
                nClient                             , \
                TIMER_FLAG_NO_MAPCHANGE             );
}

public Action displayJoinInfo(Handle hTimer, any nClient)
{
    static float    fEngTime                                =                       0.000000;

    static bool     bIsp                                    =                       false, \
                    bCountry                                =                       false, \
                    bCity                                   =                       false;

    static char     szCountry   [PLATFORM_MAX_PATH]         =                       "", \
                    szCity      [PLATFORM_MAX_PATH]         =                       "", \
                    szIsp       [PLATFORM_MAX_PATH]         =                       "", \
                    szIpAddr    [PLATFORM_MAX_PATH]         =                       "";

    fEngTime                                                =                       GetEngineTime();

    if (fEngTime            >   g_fStamp                                            && \
        nClient             >=  1                                                   && \
        nClient             <=  MaxClients                                          && \
        IsClientConnected       (nClient)                                           && \
        IsClientInGame          (nClient)                                           && \
        !IsFakeClient           (nClient)                                           && \
        !IsClientSourceTV       (nClient)                                           && \
        !IsClientReplay         (nClient)                                           && \
        !IsClientInKickQueue    (nClient)                                           && \
        !IsClientTimingOut      (nClient)                                           && \
        GetClientIP             (nClient,   szIpAddr,   sizeof(szIpAddr),   true)   )
    {
        GeoR_Country            (szIpAddr,  szCountry,  sizeof(szCountry));
        GeoR_City               (szIpAddr,  szCity,     sizeof(szCity));
        GeoR_ISP                (szIpAddr,  szIsp,      sizeof(szIsp));

        bIsp        =           (strcmp(szIsp,          "N/ A") == 0)       ? false :       true;
        bCountry    =           (strcmp(szCountry,      "N/ A") == 0)       ? false :       true;
        bCity       =           (strcmp(szCity,         "N/ A") == 0)       ? false :       true;

        if (bCountry        &&      bCity       &&      bIsp)
        {
            PrintToChatAll(" \x01Player\x04 %N\x01 Joined From\x05 %s\x01,\x05 %s",         nClient,    szCity,     szCountry);
        }

        else if (bCountry   &&      bCity)
        {
            PrintToChatAll(" \x01Player\x04 %N\x01 Joined From\x05 %s\x01,\x05 %s",         nClient,    szCity,     szCountry);
        }

        else if (bCountry   &&      bIsp)
        {
            PrintToChatAll(" \x01Player\x04 %N\x01 Joined From\x05 %s\x01 [\x05 %s\x01 ]",  nClient,    szCountry,  szIsp);
        }

        else if (bCity      &&      bIsp)
        {
            PrintToChatAll(" \x01Player\x04 %N\x01 Joined From\x05 %s\x01 [\x05 %s\x01 ]",  nClient,    szCity,     szIsp);
        }

        else if (bCountry)
        {
            PrintToChatAll(" \x01Player\x04 %N\x01 Joined From\x05 %s",                     nClient,    szCountry);
        }

        else if (bCity)
        {
            PrintToChatAll(" \x01Player\x04 %N\x01 Joined From\x05 %s",                     nClient,    szCity);
        }

        else if (bIsp)
        {
            PrintToChatAll(" \x01Player\x04 %N\x01 Joined [\x05 %s\x01 ]",                  nClient,    szIsp);
        }

#if     defined     SHOW_EVEN_IF_NOT_DETECTED

        else
        {
            PrintToChatAll(" \x01Player\x04 %N\x01 Joined",                                 nClient);
        }

#endif

        g_fStamp    =       fEngTime        +               CHAT_SPAM_DELAY;
    }
}

public void OnPlrConnect_Pre(Handle hEv,    const char[]    szEvName,   bool bEvNoBC)
{
    if (hEv !=              INVALID_HANDLE)
    {
        if (bEvNoBC ==      false)
        {
            SetEventBroadcast(hEv, true);
        }
    }
}

public void OnPlrDisconnect_Pre(Handle hEv, const char[]    szEvName,   bool bEvNoBC)
{
    if (hEv !=              INVALID_HANDLE)
    {
        if (bEvNoBC ==      false)
        {
            SetEventBroadcast(hEv, true);
        }
    }
}
