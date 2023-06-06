
/**
 * MAIN REQUIREMENTS
 */

#include <sourcemod>
#include <sdktools>


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
 * GLOBAL VARIABLES
 */

static bool g_bPlayerDeathHooked =              false;


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

public void OnPluginStart()
{
    OnMapStart();
}

public void OnMapStart()
{
    if (!g_bPlayerDeathHooked)
    {
        HookEventEx("player_death",     _Player_Death_Event_,       EventHookMode_Post);

        g_bPlayerDeathHooked =          true;
    }
}

public void OnMapEnd()
{
    if (g_bPlayerDeathHooked)
    {
        UnhookEvent("player_death",     _Player_Death_Event_,       EventHookMode_Post);

        g_bPlayerDeathHooked =          false;
    }
}

public void OnPluginEnd()
{
    OnMapEnd();
}


/**
 * CUSTOM PUBLIC HANDLERS
 */

public void _Player_Death_Event_(Event hEv, const char[] szName, bool bNoBC)
{
    static int nVictimUserId = 0, nVictim = 0, nCorpse = 0, m_hRagdoll = 0, m_vecVelocity = 0, m_vecAbsVelocity = 0, m_vecForce = 0, m_vecRagdollVelocity = 0;
    static float fVelocity[3] = { 0.0, ... }, fAbsVelocity[3] = { 0.0, ... }, fForce[3] = { 0.0, ... }, fRagdollVelocity[3] = { 0.0, ... };

    nVictimUserId = hEv.GetInt("userid", 0);

    if (nVictimUserId > 0)
    {
        nVictim = GetClientOfUserId(nVictimUserId);

        if (nVictim > 0)
        {
            if (IsClientConnected(nVictim) && IsClientInGame(nVictim))
            {
                if (!IsPlayerAlive(nVictim))
                {
                    _PREP_OFFS_(nVictim, m_hRagdoll,    "m_hRagdoll");

                    nCorpse = GetEntDataEnt2(nVictim,   m_hRagdoll);

                    if (nCorpse > 0)
                    {
                        if (IsValidEntity(nCorpse))
                        {
                            _PREP_OFFS_(nCorpse, m_vecVelocity,             "m_vecVelocity");
                            _PREP_OFFS_(nCorpse, m_vecAbsVelocity,          "m_vecAbsVelocity");
                            _PREP_OFFS_(nCorpse, m_vecForce,                "m_vecForce");
                            _PREP_OFFS_(nCorpse, m_vecRagdollVelocity,      "m_vecRagdollVelocity");

                            GetEntDataVector(nCorpse, m_vecVelocity,        fVelocity);
                            GetEntDataVector(nCorpse, m_vecAbsVelocity,     fAbsVelocity);
                            GetEntDataVector(nCorpse, m_vecForce,           fForce);
                            GetEntDataVector(nCorpse, m_vecRagdollVelocity, fRagdollVelocity);

                            ScaleVector(fVelocity,                          2.0);
                            ScaleVector(fAbsVelocity,                       2.0);
                            ScaleVector(fForce,                             2.0);
                            ScaleVector(fRagdollVelocity,                   2.0);

                            SetEntDataVector(nCorpse, m_vecVelocity,        fVelocity, true);
                            SetEntDataVector(nCorpse, m_vecAbsVelocity,     fAbsVelocity, true);
                            SetEntDataVector(nCorpse, m_vecForce, fForce,   true);
                            SetEntDataVector(nCorpse, m_vecRagdollVelocity, fRagdollVelocity, true);
                        }
                    }
                }
            }
        }
    }
}
