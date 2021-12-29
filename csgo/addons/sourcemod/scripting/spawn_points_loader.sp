
/**
 * MAIN REQUIREMENTS
 */

#include <sourcemod>
#include <sdktools>

#if !defined CS_TEAM_NONE
    #define CS_TEAM_NONE (0)
#endif

#if !defined CS_TEAM_T
    #define CS_TEAM_T (2)
#endif

#if !defined CS_TEAM_CT
    #define CS_TEAM_CT (3)
#endif


/**
 * CUSTOM DEFINITIONS TO BE EDITED
 */

#define _MIN_DIST_SPAWN_POINTS_ 56.000000


/**
 * CUSTOM DEFINITIONS
 */

#define _PREP_OFFS_(%0,%1,%2) if (%1 < 1) %1 = _Get_Offs_(%0, %2)


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name = "Spawn Points Loader", \
    author = "CARAMEL® HACK", \
    description = "Loads The Custom Spawn Points", \
    version = __DATE__, \
    url = "https://hattrick.go.ro/",
};


/**
 * GLOBAL VARIABLES
 */

static bool g_bLate = false;


/**
 * CUSTOM PRIVATE FUNCTIONS
 */

static float _Vec_Dis_2D_(const float fPosA[3], const float fPosB[3])
{
    static float fTmpPosA[3] = { 0.000000, ... }, fTmpPosB[3] = { 0.000000, ... };

    fTmpPosA[0] = fPosA[0];
    fTmpPosA[1] = fPosA[1];
    fTmpPosA[2] = 0.0;

    fTmpPosB[0] = fPosB[0];
    fTmpPosB[1] = fPosB[1];
    fTmpPosB[2] = 0.0;

    return GetVectorDistance(fTmpPosA, fTmpPosB, false);
}

static int _Get_Offs_(int nEnty, const char[] szPrp)
{
    static const char szTbl[][] =
    {
        "CBaseEntity",                  "CBaseCSEntity",
        "CBasePlayer",                  "CBaseCSPlayer",
        "CBaseGrenade",                 "CBaseCSGrenade",
        "CBaseGrenadeProjectile",       "CBaseCSGrenadeProjectile",
        "CBasePlayerResource",          "CBaseCSPlayerResource",
        "CBaseViewModel",               "CBaseCSViewModel",
        "CBaseC4",                      "CBaseCSC4",
        "CBaseAnimating",               "CBaseCSAnimating",
        "CBaseCombatCharacter",         "CBaseCSCombatCharacter",
        "CBaseCombatWeapon",            "CBaseCSCombatWeapon",
        "CBaseWeaponWorldModel",        "CBaseCSWeaponWorldModel",
        "CBaseRagdoll",                 "CBaseCSRagdoll",

        "CEntity",                      "CSEntity",                             "CCSEntity",
        "CPlayer",                      "CSPlayer",                             "CCSPlayer",
        "CGrenade",                     "CSGrenade",                            "CCSGrenade",
        "CGrenadeProjectile",           "CSGrenadeProjectile",                  "CCSGrenadeProjectile",
        "CPlayerResource",              "CSPlayerResource",                     "CCSPlayerResource",
        "CViewModel",                   "CSViewModel",                          "CCSViewModel",
        "CC4",                          "CSC4",                                 "CCSC4",
        "CAnimating",                   "CSAnimating",                          "CCSAnimating",
        "CCombatCharacter",             "CSCombatCharacter",                    "CCSCombatCharacter",
        "CCombatWeapon",                "CSCombatWeapon",                       "CCSCombatWeapon",
        "CWeaponWorldModel",            "CSWeaponWorldModel",                   "CCSWeaponWorldModel",
        "CRagdoll",                     "CSRagdoll",                            "CCSRagdoll",
    };

    static int nOff = 0, nTbl = 0;

    if ((nOff = FindDataMapInfo(nEnty, szPrp)) > 0)
    {
        return nOff;
    }

    for (nTbl = 0; nTbl < sizeof (szTbl); nTbl++)
    {
        if ((nOff = FindSendPropInfo(szTbl[nTbl], szPrp)) > 0)
        {
            return nOff;
        }
    }

    return nOff;
}


/**
 * CUSTOM PUBLIC FORWARDS
 */

public APLRes AskPluginLoad2(Handle hSelf, bool bLate, char[] szErr, int nErrMaxLen)
{
    g_bLate = bLate;

    return APLRes_Success;
}

public void OnPluginStart()
{
    if (g_bLate)
    {
        OnMapStart();
    }
}

public void OnMapStart()
{
    static bool bSpawn = false;
    static Handle hKV = INVALID_HANDLE;
    static int nIndex = 0, nTeam = 0, nEnty = 0, m_vecOrigin = 0;
    static char szBuffer[256] = { 0, ... }, szCfg[256] = { 0, ... };
    static float fPos[3] = { 0.000000, ... }, fAng[3] = { 0.000000, ... }, fExPos[3] = { 0.000000, ... };

    GetCurrentMap(szBuffer, sizeof (szBuffer));

    for (nIndex = 0; nIndex < strlen(szBuffer); nIndex++)
    {
        szBuffer[nIndex] = CharToLower(szBuffer[nIndex]);
    }

    hKV = CreateKeyValues(szBuffer);

    if (hKV != INVALID_HANDLE)
    {
        BuildPath(Path_SM, szCfg, sizeof (szCfg), "configs/spawns_%s.cfg", szBuffer);

        if (FileToKeyValues(hKV, szCfg))
        {
            nIndex = 0;

            FormatEx(szBuffer, sizeof (szBuffer), "spawn_%d_origin", nIndex);
            KvGetVector(hKV, szBuffer, fPos);

            while (fPos[0] != 0.000000)
            {
                FormatEx(szBuffer, sizeof (szBuffer), "spawn_%d_angles", nIndex);
                KvGetVector(hKV, szBuffer, fAng);

                fAng[0] = 0.000000;
                fAng[2] = 0.000000;

                FormatEx(szBuffer, sizeof (szBuffer), "spawn_%d_team", nIndex);
                nTeam = KvGetNum(hKV, szBuffer);

                nEnty = INVALID_ENT_REFERENCE;
                bSpawn = true;

                if (nTeam == CS_TEAM_T)
                {
                    while ((nEnty = FindEntityByClassname(nEnty, "info_player_terrorist")) != INVALID_ENT_REFERENCE)
                    {
                        _PREP_OFFS_(nEnty, m_vecOrigin, "m_vecOrigin");
                        GetEntDataVector(nEnty, m_vecOrigin, fExPos);

                        if (_Vec_Dis_2D_(fExPos, fPos) < _MIN_DIST_SPAWN_POINTS_)
                        {
                            bSpawn = false;
                            break;
                        }
                    }
                }

                else
                {
                    while ((nEnty = FindEntityByClassname(nEnty, "info_player_counterterrorist")) != INVALID_ENT_REFERENCE)
                    {
                        _PREP_OFFS_(nEnty, m_vecOrigin, "m_vecOrigin");
                        GetEntDataVector(nEnty, m_vecOrigin, fExPos);

                        if (_Vec_Dis_2D_(fExPos, fPos) < _MIN_DIST_SPAWN_POINTS_)
                        {
                            bSpawn = false;
                            break;
                        }
                    }
                }

                if (bSpawn)
                {
                    nEnty = CreateEntityByName(nTeam == CS_TEAM_T ? "info_player_terrorist" : "info_player_counterterrorist");

                    if (nEnty > 0)
                    {
                        if (IsValidEntity(nEnty))
                        {
                            if (DispatchSpawn(nEnty))
                            {
                                TeleportEntity(nEnty, fPos, fAng, NULL_VECTOR);
                            }
                        }
                    }
                }

                FormatEx(szBuffer, sizeof (szBuffer), "spawn_%d_origin", ++nIndex);
                KvGetVector(hKV, szBuffer, fPos);
            }
        }

        CloseHandle(hKV);
    }
}
