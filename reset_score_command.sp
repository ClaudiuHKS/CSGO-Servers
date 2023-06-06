
/**
 * MAIN REQUIREMENTS
 */

#include <sourcemod>
#include <sdktools>
#include <cstrike>


/**
 * CUSTOM DEFINITIONS
 */

#define         _PREP_OFFS_(%0,%1,%2)       if (%1 < 1) %1 = _Get_Offs_(%0, %2)


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "Reset Score Command",
    author =        "CARAMEL® HACK",
    description =   "Provides Commands To Reset The Score",
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

public void OnClientSayCommand_Post(int nEntity, const char[] szCmd, const char[] szArgs)
{
    if (!IsClientConnected(nEntity) || !IsClientInGame(nEntity))
    {
        return;
    }

    if
    (
        strcmp(szArgs, "rs", false) == 0
            ||
        strcmp(szArgs, "reset", false) == 0
            ||
        strcmp(szArgs, "restart", false) == 0
            ||
        strcmp(szArgs, "rscore", false) == 0
            ||
        strcmp(szArgs, "resetscore", false) == 0
            ||
        strcmp(szArgs, "restartscore", false) == 0
            ||
        strcmp(szArgs, "!rs", false) == 0
            ||
        strcmp(szArgs, "!reset", false) == 0
            ||
        strcmp(szArgs, "!restart", false) == 0
            ||
        strcmp(szArgs, "!rscore", false) == 0
            ||
        strcmp(szArgs, "!resetscore", false) == 0
            ||
        strcmp(szArgs, "!restartscore", false) == 0
            ||
        strcmp(szArgs, "/rs", false) == 0
            ||
        strcmp(szArgs, "/reset", false) == 0
            ||
        strcmp(szArgs, "/restart", false) == 0
            ||
        strcmp(szArgs, "/rscore", false) == 0
            ||
        strcmp(szArgs, "/resetscore", false) == 0
            ||
        strcmp(szArgs, "/restartscore", false) == 0
    )
    {
        CreateTimer(0.000001, _Timer_Zero_Score_, GetClientUserId(nEntity), TIMER_FLAG_NO_MAPCHANGE);
    }
}


/**
 * CUSTOM PUBLIC HANDLERS
 */

public Action _Timer_Zero_Score_(Handle hTimer, any nId)
{
    static int m_iDeaths = 0, m_iFrags = 0, nEntity = 0;

    if ((nEntity = GetClientOfUserId(nId)) > 0 &&   IsClientConnected(nEntity) &&           IsClientInGame(nEntity))
    {
        _PREP_OFFS_(nEntity,    m_iDeaths,          "m_iDeaths");
        _PREP_OFFS_(nEntity,    m_iFrags,           "m_iFrags");

        SetEntData(nEntity,     m_iDeaths,          0);
        SetEntData(nEntity,     m_iFrags,           0);

        CS_SetMVPCount(nEntity,                     0);
        CS_SetClientContributionScore(nEntity,      0);
        CS_SetClientAssists(nEntity,                0);

        PrintToChat(nEntity,    " \x01Done.");
    }

    return Plugin_Continue;
}
