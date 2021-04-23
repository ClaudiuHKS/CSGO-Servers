
/**
 * MAIN REQUIREMENTS
 */

#include < sourcemod >
#include < cstrike >
#include < sdktools >
#include < sdkhooks >


/**
 * CUSTOM DEFINITIONS TO BE EDITED
 */

#define _SUICIDE_SCORE_             (0) // contributionscore_suicide


/**
 * CUSTOM DEFINITIONS
 */

#define         _PREP_OFFS_(%0,%1,%2)       if (%1 < 1) %1 = _Get_Offs_(%0, %2)


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "Suicide Game Score",
    author =        "CARAMEL® HACK",
    description =   "Alters The Score Of The Players Committing Suicide",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * GLOBAL VARIABLES
 */

Handle g_hSuicideScore =                INVALID_HANDLE;

bool g_bPlayerDeathHooked =             false;

bool g_bSScoreConVarChangeHooked =      false;


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
    static char szBuffer[PLATFORM_MAX_PATH] =       { 0, ... };

    if (!g_bPlayerDeathHooked)
    {
        HookEventEx("player_death",                 _Player_Death_);

        g_bPlayerDeathHooked =                      true;
    }

    if (g_hSuicideScore == INVALID_HANDLE)
    {
        g_hSuicideScore =                           FindConVar("contributionscore_suicide");
    }

    if (g_hSuicideScore != INVALID_HANDLE)
    {
        if (GetConVarInt(g_hSuicideScore) !=        _SUICIDE_SCORE_)
        {
            IntToString(_SUICIDE_SCORE_,            szBuffer, sizeof (szBuffer));

            SetConVarString(g_hSuicideScore,        szBuffer, true);
        }

        if (!g_bSScoreConVarChangeHooked)
        {
            HookConVarChange(g_hSuicideScore,       _Con_Var_Change_);

            g_bSScoreConVarChangeHooked =           true;
        }

        if (GetConVarInt(g_hSuicideScore) !=        _SUICIDE_SCORE_)
        {
            IntToString(_SUICIDE_SCORE_,            szBuffer, sizeof (szBuffer));

            SetConVarString(g_hSuicideScore,        szBuffer, true);
        }
    }
}

public void OnMapEnd()
{
    if (g_bPlayerDeathHooked)
    {
        UnhookEvent("player_death",                 _Player_Death_);

        g_bPlayerDeathHooked =                      false;
    }

    if (g_hSuicideScore != INVALID_HANDLE)
    {
        if (g_bSScoreConVarChangeHooked)
        {
            UnhookConVarChange(g_hSuicideScore,     _Con_Var_Change_);

            g_bSScoreConVarChangeHooked =           false;
        }
    }
}

public void OnPluginEnd()
{
    OnMapEnd();
}


/**
 * CUSTOM PUBLIC HANDLERS
 */

public void _Player_Death_(Event hEv, const char[] szName, bool bNoBC)
{
    static int nKiller = 0, nEntity = 0, nVictim = 0, m_bIsControllingBot = 0, m_iControlledBotEntIndex = 0;

    if
    (
        (
            (
                (nKiller = hEv.GetInt("attacker"))
                    ==
                (nVictim = hEv.GetInt("userid"))
            )
            ||
            (
                (nKiller)
                    <
                (1)
            )
        )
        &&
        (
            ((nEntity = GetClientOfUserId(nVictim)))
                >
            (0)
        )
        &&
        (
            (IsClientConnected(nEntity))
                ==
            (true)
        )
        &&
        (
            (IsClientInGame(nEntity))
                ==
            (true)
        )
    )
    {
        _PREP_OFFS_(nEntity,        m_bIsControllingBot,        "m_bIsControllingBot");

        if (GetEntData(nEntity,     m_bIsControllingBot,        1) > 0)
        {
            _PREP_OFFS_(nEntity,    m_iControlledBotEntIndex,   "m_iControlledBotEntIndex");

            CreateTimer(0.000001,   _Timer_Decrease_Deaths_,    GetClientUserId(GetEntData(nEntity, m_iControlledBotEntIndex)), TIMER_FLAG_NO_MAPCHANGE);
        }

        else
        {
            CreateTimer(0.000001,   _Timer_Decrease_Deaths_,    GetClientUserId(nEntity),                                       TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action _Timer_Decrease_Deaths_(Handle hTimer, any nId)
{
    static int m_iDeaths = 0, nEntity = 0, nDeaths = 0;

    if ((nEntity = GetClientOfUserId(nId)) > 0 &&   IsClientConnected(nEntity) &&           IsClientInGame(nEntity))
    {
        _PREP_OFFS_(nEntity,    m_iDeaths,          "m_iDeaths");

        nDeaths =               GetEntData(nEntity, m_iDeaths);

        if (nDeaths > 0)
        {
            SetEntData(nEntity, m_iDeaths,          nDeaths - 1);
        }
    }
}

public void _Con_Var_Change_(Handle hConVar, const char[] szOld, const char[] szNew)
{
    static char szBuffer[PLATFORM_MAX_PATH] = { 0, ... };

    if (hConVar == g_hSuicideScore)
    {
        if (StringToInt(szNew) !=           _SUICIDE_SCORE_)
        {
            IntToString(_SUICIDE_SCORE_,    szBuffer, sizeof (szBuffer));

            SetConVarString(hConVar,        szBuffer, true);
        }
    }
}
