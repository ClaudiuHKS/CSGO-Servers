
/**
 * MAIN REQUIREMENTS
 */

#include < sourcemod >
#include < cstrike >
#include < sdktools >
#include < sdkhooks >


/**
 * CUSTOM DEFINITIONS
 */

#define _MINUTES_   1051000                 // MINUTES TO BAN   [ 0 = PERMANENT | 1051000 = 2 YEARS | .. ]
#define _REASON_    "INHUMAN REACTIONS"     // REASON OF BAN    [ CAN HAVE WHITE SPACES INSIDE ]


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "No Spin Hack",
    author =        "CARAMEL® HACK",
    description =   "Blocks any spin hacks.",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * GLOBAL VARIABLES
 */

static float g_fLen[MAXPLAYERS][3];
static float g_fAng[MAXPLAYERS][3];


/**
 * PUBLIC FORWARDS
 */

public void OnPluginStart()
{
    static int nIter = 0;

    for (nIter = 1; nIter < MAXPLAYERS; nIter++)
    {
        if (IsClientConnected(nIter) && IsClientInGame(nIter))
        {
            OnClientPutInServer(nIter);
        }
    }
}

public void OnPluginEnd()
{
    static int nIter = 0;

    for (nIter = 1; nIter < MAXPLAYERS; nIter++)
    {
        if (IsClientConnected(nIter) && IsClientInGame(nIter))
        {
            OnClientDisconnect(nIter);
        }
    }
}

public void OnClientPutInServer(int nEntity)
{
    SDKHookEx(nEntity, SDKHook_OnTakeDamageAlive,   _Take_Damage_Alive_);
}

public void OnClientDisconnect(int nEntity)
{
    SDKUnhook(nEntity, SDKHook_OnTakeDamageAlive,   _Take_Damage_Alive_);
}

public void OnClientDisconnect_Post(int nEntity)
{
    SDKUnhook(nEntity, SDKHook_OnTakeDamageAlive,   _Take_Damage_Alive_);
}

public Action OnPlayerRunCmd(int nEntity, int& nButtons, int& nImpulse, float fVelocity[3], float fAngles[3], int& nWeapon, int& nSubType, int& nCmdNum, int& nTickCount, int& nSeed, int nMouseDir[2])
{
    g_fLen[nEntity][0] = fAngles[0] - g_fAng[nEntity][0];
    g_fLen[nEntity][1] = fAngles[1] - g_fAng[nEntity][1];
    g_fLen[nEntity][2] = fAngles[2] - g_fAng[nEntity][2];

    g_fAng[nEntity][0] = fAngles[0];
    g_fAng[nEntity][1] = fAngles[1];
    g_fAng[nEntity][2] = fAngles[2];
}


/**
 * CUSTOM PUBLIC FORWARDS
 */

public Action _Take_Damage_Alive_(int nVictim, int& nAttacker, int& nInflictor, float& fDamage, int& nDamageType, int& nWeapon, float fDamageForce[3], float fDamagePosition[3], int nDamageCustom)
{
    if (nDamageType & DMG_BULLET)
    {
        if (nVictim != nAttacker)
        {
            if (nAttacker > 0)
            {
                if (FloatAbs(g_fLen[nAttacker][0]) >= 45.0 || FloatAbs(g_fLen[nAttacker][1]) >= 45.0 || FloatAbs(g_fLen[nAttacker][2]) >= 45.0)
                {
                    ServerCommand("sm_ban #%d %d \"%s\";", GetClientUserId(nAttacker), _MINUTES_, _REASON_);
                }
            }
        }
    }
}
