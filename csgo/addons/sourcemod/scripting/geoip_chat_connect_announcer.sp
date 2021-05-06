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
 * PRINTS   " \x01Player\x04 HATTRİCK CARAMEL® HACK CS.MONEY\x01 joined."
 *
 * IF THE   GEOGRAPHICAL    INFORMATION HAS NOT BEEN DETECTED
 *
 * UNCOMMENT    - '//'      IF YES
 * COMMENT      + '//'      IF NO
 */

#define     SHOW_EVEN_IF_NOT_DETECTED

#define     SHOW_PLAYER_DISCONNECT_CHAT     /// Show?
#define     SHOW_PLAYER_TEAM_CHAT           /// Show?

/**
 * PRINTS   ONLY A MESSAGE EACH # SECONDS
 */

#define     CHAT_SPAM_DELAY     4.000000

static float g_fStamp = 0.000000;

public void OnPluginStart()
{
    HookEventEx("player_disconnect",            OnPlrDisconnect_Pre,        EventHookMode_Pre);
    HookEventEx("player_disconnect_client",     OnPlrDisconnect_Pre,        EventHookMode_Pre);
    HookEventEx("player_client_disconnect",     OnPlrDisconnect_Pre,        EventHookMode_Pre);

    HookEventEx("player_connect",               OnPlrConnect_Pre,           EventHookMode_Pre);
    HookEventEx("player_connect_client",        OnPlrConnect_Pre,           EventHookMode_Pre);
    HookEventEx("player_client_connect",        OnPlrConnect_Pre,           EventHookMode_Pre);

    HookEventEx("player_team",                  OnPlrTeam_Pre,              EventHookMode_Pre);

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
    if (nClient >= 1 && nClient <= MaxClients)
    {
        CreateTimer(GetRandomFloat(2.250000, 4.500000)  , \
                    displayJoinInfo                     , \
                    GetClientUserId(nClient)            , \
                    TIMER_FLAG_NO_MAPCHANGE             );
    }
}

public Action displayJoinInfo(Handle hTimer, any nClientUserId)
{
    static int      nClient                                 =                       0;

    static float    fEngTime                                =                       0.000000;

    static bool     bIsp                                    =                       false, \
                    bCountry                                =                       false, \
                    bCity                                   =                       false;

    static char     szCountry   [PLATFORM_MAX_PATH]         =                       "", \
                    szCity      [PLATFORM_MAX_PATH]         =                       "", \
                    szIsp       [PLATFORM_MAX_PATH]         =                       "", \
                    szIpAddr    [PLATFORM_MAX_PATH]         =                       "";

    fEngTime                                                =                       GetEngineTime();

    nClient                                                 =                       GetClientOfUserId(nClientUserId);

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
            PrintToChatAll(" \x01Player\x04 %N\x01 joined from\x05 %s\x01,\x05 %s\x01.",        nClient,    szCity,     szCountry);
        }

        else if (bCountry   &&      bCity)
        {
            PrintToChatAll(" \x01Player\x04 %N\x01 joined from\x05 %s\x01,\x05 %s\x01.",        nClient,    szCity,     szCountry);
        }

        else if (bCountry   &&      bIsp)
        {
            PrintToChatAll(" \x01Player\x04 %N\x01 joined from\x05 %s\x01 [\x05 %s\x01 ].",     nClient,    szCountry,  szIsp);
        }

        else if (bCity      &&      bIsp)
        {
            PrintToChatAll(" \x01Player\x04 %N\x01 joined from\x05 %s\x01 [\x05 %s\x01 ].",     nClient,    szCity,     szIsp);
        }

        else if (bCountry)
        {
            PrintToChatAll(" \x01Player\x04 %N\x01 joined from\x05 %s\x01.",                    nClient,    szCountry);
        }

        else if (bCity)
        {
            PrintToChatAll(" \x01Player\x04 %N\x01 joined from\x05 %s\x01.",                    nClient,    szCity);
        }

        else if (bIsp)
        {
            PrintToChatAll(" \x01Player\x04 %N\x01 joined [\x05 %s\x01 ].",                     nClient,    szIsp);
        }

#if     defined     SHOW_EVEN_IF_NOT_DETECTED

        else
        {
            PrintToChatAll(" \x01Player\x04 %N\x01 joined.",                                    nClient);
        }

#endif

        g_fStamp    =       fEngTime        +               CHAT_SPAM_DELAY;
    }
}

public void OnPlrConnect_Pre(Handle hEv,    const char[]    szEvName,   bool bEvNoBC)
{
    if (hEv         !=              INVALID_HANDLE)
    {
        if (bEvNoBC ==              false)
        {
            SetEventBroadcast(hEv,  true);
        }
    }
}

public void OnPlrDisconnect_Pre(Handle hEv, const char[]    szEvName,   bool bEvNoBC)
{

#if defined SHOW_PLAYER_DISCONNECT_CHAT

    static Handle hPack                         =   INVALID_HANDLE;

    static char szName[PLATFORM_MAX_PATH]       =   { 0, ... };
    static char szReason[PLATFORM_MAX_PATH]     =   { 0, ... };
    static char szRandom[PLATFORM_MAX_PATH]     =   { 0, ... };

    static bool bGenerated                      =   false;

    if (bGenerated == false)
    {
        bGenerated = true;

        const int nRandomStringLen = 16;

        for (int nIter = 0; nIter < nRandomStringLen; nIter++)
        {
            switch (GetRandomInt(0, 2))
            {
                case 0:
                {
                    Format(szRandom, sizeof (szRandom), "%s%c", szRandom, GetRandomInt('a', 'z'));
                }

                case 1:
                {
                    Format(szRandom, sizeof (szRandom), "%s%c", szRandom, GetRandomInt('A', 'Z'));
                }

                case 2:
                {
                    Format(szRandom, sizeof (szRandom), "%s%c", szRandom, GetRandomInt('0', '9'));
                }
            }
        }

        szRandom[nRandomStringLen] = '\0';
    }

#endif

    if (hEv         !=                  INVALID_HANDLE)
    {
        if (bEvNoBC ==                  false)
        {
            SetEventBroadcast(hEv,      true);
        }

#if defined SHOW_PLAYER_DISCONNECT_CHAT

        GetEventString(hEv, "name", szName, sizeof (szName), szRandom);

        if (strcmp(szName, szRandom, true))
        {
            GetEventString(hEv, "reason", szReason, sizeof (szReason), szRandom);

            if (strcmp(szReason, szRandom, true))
            {
                hPack       =   CreateDataPack();

                if (hPack   !=  INVALID_HANDLE)
                {
                    WritePackString(hPack, szName);
                    WritePackString(hPack, szReason);

                    CreateTimer(GetRandomFloat(0.100000, 1.500000), Timer_Left, hPack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
                }
            }
        }

#endif

    }
}

public void OnPlrTeam_Pre(Handle hEv, const char[]    szEvName,   bool bEvNoBC)
{

#if defined SHOW_PLAYER_TEAM_CHAT

    static Handle hPack         =   INVALID_HANDLE;

    static int nClientUserId    =   0;
    static int nTeam            =   0;

#endif

    if (hEv                     !=  INVALID_HANDLE)
    {
        if (bEvNoBC             ==  false)
        {
            SetEventBroadcast(hEv,  true);
        }

#if defined SHOW_PLAYER_TEAM_CHAT

        nClientUserId = GetEventInt(hEv, "userid", -8192);

        if (nClientUserId != -8192)
        {
            nTeam = GetEventInt(hEv, "team", 0);

            if (nTeam > 0)
            {
                hPack       =   CreateDataPack();

                if (hPack   !=  INVALID_HANDLE)
                {
                    WritePackCell(hPack, nClientUserId);
                    WritePackCell(hPack, nTeam);

                    CreateTimer(GetRandomFloat(0.100000, 1.500000), Timer_TeamJoin, hPack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
                }
            }
        }

#endif

    }
}

#if defined SHOW_PLAYER_TEAM_CHAT

public Action Timer_TeamJoin(Handle hTimer, any hPack)
{
    static int nClientUserId    =   0;
    static int nClient          =   0;
    static int nTeam            =   0;

    static float fEngTime       =   0.0;

    fEngTime                    =   GetEngineTime();

    if (fEngTime > g_fStamp)
    {
        if (hPack != INVALID_HANDLE)
        {
            ResetPack(hPack);

            nClientUserId = ReadPackCell(hPack);

            nClient = GetClientOfUserId(nClientUserId);

            if (nClient >= 1 && nClient <= MaxClients)
            {
                if (IsClientConnected(nClient) && IsClientInGame(nClient))
                {
                    nTeam = ReadPackCell(hPack);

                    switch (nTeam)
                    {
                        case 1:
                        {
                            PrintToChatAll(" \x01Player\x05 %N\x01 became a\x08 spectator\x01.",            nClient);

                            g_fStamp = fEngTime + CHAT_SPAM_DELAY;
                        }

                        case 2:
                        {
                            PrintToChatAll(" \x01Player\x05 %N\x01 became a\x07 terrorist\x01.",            nClient);

                            g_fStamp = fEngTime + CHAT_SPAM_DELAY;
                        }

                        case 3:
                        {
                            PrintToChatAll(" \x01Player\x05 %N\x01 became a\x0B counter terrorist\x01.",    nClient);

                            g_fStamp = fEngTime + CHAT_SPAM_DELAY;
                        }
                    }
                }
            }
        }
    }
}

#endif

#if defined SHOW_PLAYER_DISCONNECT_CHAT

public Action Timer_Left(Handle hTimer,         any hPack)
{
    static char szName[PLATFORM_MAX_PATH]       =   { 0, ... };
    static char szReason[PLATFORM_MAX_PATH]     =   { 0, ... };
    static char szNewReason[PLATFORM_MAX_PATH]  =   { 0, ... };

    static float fEngTime                       =   0.0;

    static int nIter                            =   0;
    static int nNewReasonLen                    =   0;

    fEngTime                                    =   GetEngineTime();

    if (fEngTime > g_fStamp)
    {
        if (hPack != INVALID_HANDLE)
        {
            ResetPack(hPack);

            ReadPackString(hPack, szName,   sizeof (szName));
            ReadPackString(hPack, szReason, sizeof (szReason));

            nNewReasonLen = 0;

            for (nIter = 0; nIter < strlen(szReason); nIter++)
            {
                if (szReason[nIter] == ' ' || IsCharAlpha(szReason[nIter]) || IsCharNumeric(szReason[nIter]))
                {
                    szNewReason[nNewReasonLen] = CharToLower(szReason[nIter]);

                    nNewReasonLen++;
                }
            }

            szNewReason[nNewReasonLen] = '\0';

            ReplaceString(szNewReason, sizeof (szNewReason), "  ", " ", true);

            TrimString(szNewReason);

            PrintToChatAll(" \x01Player\x05 %s\x01 left,\x09 %s\x01.", szName, szNewReason);

            g_fStamp = fEngTime + CHAT_SPAM_DELAY;
        }
    }
}

#endif
