
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

#define         _PREP_OFFS_(%0,%1,%2)       if (%1 < 1) %1 = _Get_Offs_(%0, %2)


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "Exagerate Ragdolls",
    author =        "CARAMEL® HACK",
    description =   "Exagerates Ragdolls",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * CUSTOM PRIVATE FUNCTIONS
 */

static int _Get_Offs_(int nEntity, const char[] szProp)
{
    static const char szTables[][] =
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

    static int nOffs = 0, nTable = 0;

    if ((nOffs = FindDataMapInfo(nEntity, szProp)) > 0)
    {
        return nOffs;
    }

    for (nTable = 0; nTable < sizeof (szTables); nTable++)
    {
        if ((nOffs = FindSendPropInfo(szTables[nTable], szProp)) > 0)
        {
            return nOffs;
        }
    }

    return nOffs;
}


/**
 * CUSTOM PUBLIC FORWARDS
 */

public void OnEntityCreated(int nEntity, const char[] szClass)
{
    if (StrContains(szClass, "RagDoll", false) != -1)
    {
        CreateTimer(0.000001, _Timer_Ragdoll_Velocity_, nEntity, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public void OnEntitySpawned(int nEntity, const char[] szClass)
{
    if (StrContains(szClass, "RagDoll", false) != -1)
    {
        CreateTimer(0.000001, _Timer_Ragdoll_Velocity_, nEntity, TIMER_FLAG_NO_MAPCHANGE);
    }
}


/**
 * CUSTOM PUBLIC HANDLERS
 */

public Action _Timer_Ragdoll_Velocity_(Handle hTimer, any nEntity)
{
    static int m_vecVelocity = 0, m_vecAbsVelocity = 0, m_vecForce = 0, m_vecRagdollVelocity = 0;
    static float fVelocity[3] = { 0.0, ... }, fAbsVelocity[3] = { 0.0, ... }, fForce[3] = { 0.0, ... }, fRagdollVelocity[3] = { 0.0, ... };

    if (IsValidEdict(nEntity) || IsValidEntity(nEntity))
    {
        _PREP_OFFS_(nEntity, m_vecVelocity,             "m_vecVelocity");
        _PREP_OFFS_(nEntity, m_vecAbsVelocity,          "m_vecAbsVelocity");
        _PREP_OFFS_(nEntity, m_vecForce,                "m_vecForce");
        _PREP_OFFS_(nEntity, m_vecRagdollVelocity,      "m_vecRagdollVelocity");

        GetEntDataVector(nEntity, m_vecVelocity,        fVelocity);
        GetEntDataVector(nEntity, m_vecAbsVelocity,     fAbsVelocity);
        GetEntDataVector(nEntity, m_vecForce,           fForce);
        GetEntDataVector(nEntity, m_vecRagdollVelocity, fRagdollVelocity);

        ScaleVector(fVelocity,                          2048.0);
        ScaleVector(fAbsVelocity,                       2048.0);
        ScaleVector(fForce,                             2048.0);
        ScaleVector(fRagdollVelocity,                   2048.0);

        SetEntDataVector(nEntity, m_vecVelocity,        fVelocity, true);
        SetEntDataVector(nEntity, m_vecAbsVelocity,     fAbsVelocity, true);
        SetEntDataVector(nEntity, m_vecForce, fForce,   true);
        SetEntDataVector(nEntity, m_vecRagdollVelocity, fRagdollVelocity, true);
    }
}
