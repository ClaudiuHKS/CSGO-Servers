
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
    name =          "Extra Gore",
    author =        "CARAMEL® HACK",
    description =   "Provides Extra Gore",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * GLOBAL VARIABLES
 */

static const char g_szGoreEffects[][] =
{
    "blood_impact_headshot_01b", \
    "blood_impact_headshot_01d", \
    "blood_impact_red_01_chunk",
};

static const char g_szIPS[] = "info_particle_system";

static bool g_bPlayerDmgHooked = false;
static bool g_bMapStartedToLoad = false;
static bool g_bLateLoaded = false;


/**
 * CUSTOM PRIVATE FUNCTIONS
 */

static void _Precache_Gore_Effect_(const char[] szName)
{
    static int nEnty = 0;

    if (g_bMapStartedToLoad)
    {
        nEnty = CreateEntityByName(g_szIPS);

        if (nEnty > 0)
        {
            if (IsValidEntity(nEnty))
            {
                if (DispatchKeyValue(nEnty, "effect_name", szName))
                {
                    if (DispatchSpawn(nEnty))
                    {
                        ActivateEntity(nEnty);

                        AcceptEntityInput(nEnty, "START");
                    }
                }

                CreateTimer(1.0, _Timer_Remove_Gore_Effect_, nEnty, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
}

static void _Create_Random_Gore_Effect_(int nVictim, const char[] szName)
{
    static float fEyePos[3] = { 0.0, ... }, fEyeAng[3] = { 0.0, ... };
    static char szEyeAng[128] = { 0, ... };
    static int nEnty = 0;

    if (GetRandomInt(1, 2) == 1)
    {
        nEnty = CreateEntityByName(g_szIPS);

        if (nEnty > 0)
        {
            if (IsValidEntity(nEnty))
            {
                GetClientEyePosition(nVictim, fEyePos);

                if (GetClientEyeAngles(nVictim, fEyeAng))
                {
                    TeleportEntity(nEnty, fEyePos, fEyeAng, NULL_VECTOR);

                    if (DispatchKeyValue(nEnty, "effect_name", szName))
                    {
                        FormatEx(szEyeAng, sizeof (szEyeAng), "%f %f %f", fEyeAng[0], fEyeAng[1], fEyeAng[2]);

                        if (DispatchKeyValue(nEnty, "angles", szEyeAng))
                        {
                            if (DispatchSpawn(nEnty))
                            {
                                ActivateEntity(nEnty);

                                AcceptEntityInput(nEnty, "START");
                            }
                        }
                    }
                }

                CreateTimer(1.0, _Timer_Remove_Gore_Effect_, nEnty, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
}


/**
 * CUSTOM PUBLIC FORWARDS
 */

public APLRes AskPluginLoad2(Handle hSelf, bool bLateLoaded, char[] szError, int nErrorMaxLen)
{
    g_bLateLoaded = bLateLoaded;

    return APLRes_Success;
}

public void OnPluginStart()
{
    if (g_bLateLoaded)
    {
        g_bMapStartedToLoad = true;
    }

    OnMapStart();
}

public void OnMapStart()
{
    if (!g_bPlayerDmgHooked)
    {
        HookEventEx("player_hurt", _Player_Damage_Ev_, EventHookMode_Post);

        g_bPlayerDmgHooked = true;
    }

    if (g_bMapStartedToLoad)
    {
        for (int nGoreEffect = 0; nGoreEffect < sizeof (g_szGoreEffects); nGoreEffect++)
        {
            _Precache_Gore_Effect_(g_szGoreEffects[nGoreEffect]);
        }
    }
}

public void OnMapEnd()
{
    if (g_bPlayerDmgHooked)
    {
        UnhookEvent("player_hurt", _Player_Damage_Ev_, EventHookMode_Post);

        g_bPlayerDmgHooked = false;
    }

    g_bMapStartedToLoad = false;
}

public void OnPluginEnd()
{
    OnMapEnd();
}

public void OnMapInit(const char[] szMap)
{
    g_bMapStartedToLoad = true;
}


/**
 * CUSTOM PUBLIC HANDLERS
 */

public void _Player_Damage_Ev_(Handle hEv, const char[] szEvName, bool bEvNoBC)
{
    static int nVictimUserId = 0, nVictim = 0, nGoreEffect = 0;

    if (hEv != INVALID_HANDLE)
    {
        if (GetEventInt(hEv, "hitgroup", 0) == 1)
        {
            nVictimUserId = GetEventInt(hEv, "userid", 0);

            if (nVictimUserId > 0)
            {
                nVictim = GetClientOfUserId(nVictimUserId);

                if (nVictim > 0)
                {
                    if (IsClientConnected(nVictim) && IsClientInGame(nVictim))
                    {
                        for (nGoreEffect = 0; nGoreEffect < sizeof (g_szGoreEffects); nGoreEffect++)
                        {
                            _Create_Random_Gore_Effect_(nVictim, g_szGoreEffects[nGoreEffect]);
                        }
                    }
                }
            }
        }
    }
}

public Action _Timer_Remove_Gore_Effect_(Handle hTimer, any nEnty)
{
    static char szClass[64] = { 0, ... };

    if (nEnty > 0)
    {
        if (IsValidEntity(nEnty))
        {
            if (GetEntityClassname(nEnty, szClass, sizeof (szClass)))
            {
                if (strcmp(szClass, g_szIPS, false) == 0)
                {
                    AcceptEntityInput(nEnty, "KILLHIERARCHY");
                }
            }
        }
    }

    return Plugin_Continue;
}
