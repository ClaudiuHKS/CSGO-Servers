
/**
 * MAIN REQUIREMENTS
 */

#include < sourcemod >
#include < cstrike >
#include < regex >
#include < sdktools >
#include < sdkhooks >


/**
 * CUSTOM DEFINITIONS TO BE EDITED
 */

#define _WELCOME_MSG_1_             " \x01\x0BWelcome\x01. Committing\x09 suicide\x01 will not alter your\x04 score\x01. Unlimited\x09 team changes\x01 are\x04 allowed\x01. The\x09 voting system\x01 is\x04 enabled\x01."
#define _WELCOME_MSG_2_             " \x01You may\x05 /rs\x01,\x05 /map\x01,\x05 /votemap\x01,\x05 /voterr\x01 or\x05 /voterestart\x01."

#define _BOT_QUOTA_                 (2)
#define _SV_FULL_ALLTALK_           (1)

#define _DESC_SM_CVAR_              "sm_cvar REQ:CVar OPT:Value - Reveals Or Changes A CVar Value"
#define _DESC_SM_CVAR_COL_          " \x01sm_cvar\x07 REQ:CVar\x0B OPT:Value\x09 -\x05 Reveals Or Changes A CVar Value"


/**
 * CUSTOM DEFINITIONS
 */

#define         _PREP_OFFS_(%0,%1,%2)       if (%1 < 1) %1 = _Get_Offs_(%0, %2)

#if !defined    CS_TEAM_T
#define         CS_TEAM_T                   (2)
#endif

#if !defined    CS_TEAM_CT
#define         CS_TEAM_CT                  (3)
#endif


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "Hattrick",
    author =        "CARAMEL® HACK",
    description =   "Provides custom stuff.",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * GLOBAL VARIABLES
 */

bool g_bMsgShown[MAXPLAYERS] =      { false, ... };

Handle g_hBotQuota =                INVALID_HANDLE;
Handle g_hSvFullAllTalk =           INVALID_HANDLE;

int g_nPatchSize =                  -1;
int g_nPatchOffs =                  -1;
int g_nPatchOrigBytes[512] =        { 0, ... };

Address g_hPatchAddr =              Address_Null;

bool g_bPatchStatus =               false;

bool g_bPlayerDeathHooked =         false;
bool g_bPlayerTeamHooked =          false;

bool g_bQuotaConVarChangeHooked =   false;
bool g_bAllTalkConVarChangeHooked = false;


/**
 * CUSTOM PRIVATE FUNCTIONS
 */

static int _CVar_Flags_Str_(ConVar& hConVar, char[] szStr, int nMaxLen)
{
    static const char szDesc[][] =
    {
        "gamedll",          "clientdll",        "hidden",       "protected",        "sponly",       "notify",       "unlogged",
        "replicated",       "cheat",
    };

    static const int nFlags[] =
    {
        FCVAR_GAMEDLL,      FCVAR_CLIENTDLL,    FCVAR_HIDDEN,   FCVAR_PROTECTED,    FCVAR_SPONLY,   FCVAR_NOTIFY,   FCVAR_UNLOGGED,
        FCVAR_REPLICATED,   FCVAR_CHEAT,
    };

    static int nConVarFlags = 0, nIter = 0, nFlagsNum = 0;

    if (hConVar != null)
    {
        for (nIter = 0, nFlagsNum = 0, nConVarFlags = hConVar.Flags; nIter < sizeof (nFlags); nIter++)
        {
            if (nConVarFlags & nFlags[nIter])
            {
                switch (nFlagsNum)
                {
                    case 0:
                    {
                        FormatEx(szStr, nMaxLen, "%s, ", szDesc[nIter]);

                        nFlagsNum++;

                        break;
                    }

                    default:
                    {
                        Format(szStr, nMaxLen, "%s%s, ", szStr, szDesc[nIter]);

                        nFlagsNum++;

                        break;
                    }
                }
            }
        }

        if (nFlagsNum > 0)
        {
            Format(szStr, nMaxLen, "%s$", szStr);

            ReplaceStringEx(szStr, nMaxLen, ", $", "");
        }
    }
}

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
    RegAdminCmd("sm_cvar", _SM_CVar_, ADMFLAG_CONVARS, _DESC_SM_CVAR_);

    OnMapStart();
}

public void OnMapStart()
{
    static Handle hData = INVALID_HANDLE;
    static int nIter = 0;

    if (!g_bPlayerDeathHooked)
    {
        HookEventEx("player_death",                 _Player_Death_);

        g_bPlayerDeathHooked =                      true;
    }

    if (!g_bPlayerTeamHooked)
    {
        HookEventEx("player_team",                  _Player_Team_);

        g_bPlayerTeamHooked =                       true;
    }

    if (g_hBotQuota == INVALID_HANDLE)
    {
        g_hBotQuota =                               FindConVar("bot_quota");
    }

    if (g_hSvFullAllTalk == INVALID_HANDLE)
    {
        g_hSvFullAllTalk =                          FindConVar("sv_full_alltalk");
    }

    if (g_hBotQuota != INVALID_HANDLE)
    {
        if (GetConVarInt(g_hBotQuota) !=            _BOT_QUOTA_)
        {
            SetConVarInt(g_hBotQuota,               _BOT_QUOTA_);
        }

        if (!g_bQuotaConVarChangeHooked)
        {
            HookConVarChange(g_hBotQuota,           _Con_Var_Change_);

            g_bQuotaConVarChangeHooked =            true;
        }

        if (GetConVarInt(g_hBotQuota) !=            _BOT_QUOTA_)
        {
            SetConVarInt(g_hBotQuota,               _BOT_QUOTA_);
        }
    }

    if (g_hSvFullAllTalk != INVALID_HANDLE)
    {
        if (GetConVarInt(g_hSvFullAllTalk) !=       _SV_FULL_ALLTALK_)
        {
            SetConVarInt(g_hSvFullAllTalk,          _SV_FULL_ALLTALK_);
        }

        if (!g_bAllTalkConVarChangeHooked)
        {
            HookConVarChange(g_hSvFullAllTalk,      _Con_Var_Change_);

            g_bAllTalkConVarChangeHooked =          true;
        }

        if (GetConVarInt(g_hSvFullAllTalk) !=       _SV_FULL_ALLTALK_)
        {
            SetConVarInt(g_hSvFullAllTalk,          _SV_FULL_ALLTALK_);
        }
    }

    if
    (
        (
            (hData = LoadGameConfigFile("hattrick.games"))
                !=
            (INVALID_HANDLE)
        )
        &&
        (
            (g_hPatchAddr = GameConfGetAddress(hData,       "WalkMoveMaxSpeed"))
                !=
            (Address_Null)
        )
        &&
        (
            (g_nPatchOffs = GameConfGetOffset(hData,        "CappingOffset"))
                !=
            (-1)
        )
        &&
        (
            (g_nPatchSize = GameConfGetOffset(hData,        "PatchBytes"))
                !=
            (-1)
        )
    )
    {
        if (!g_bPatchStatus)
        {
            for (nIter = 0; nIter < g_nPatchSize; nIter++)
            {
                g_nPatchOrigBytes[nIter] = LoadFromAddress(g_hPatchAddr + view_as<Address>(g_nPatchOffs) + view_as<Address>(nIter), NumberType_Int8);

                StoreToAddress(g_hPatchAddr + view_as<Address>(g_nPatchOffs) + view_as<Address>(nIter), 0x90, NumberType_Int8);
            }

            g_bPatchStatus = true;
        }
    }

    if (hData != INVALID_HANDLE)
    {
        CloseHandle(hData);

        hData = INVALID_HANDLE;
    }
}

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

public void OnMapEnd()
{
    static int nIter = 0;

    if (g_bPlayerDeathHooked)
    {
        UnhookEvent("player_death",                 _Player_Death_);

        g_bPlayerDeathHooked =                      false;
    }

    if (g_bPlayerTeamHooked)
    {
        UnhookEvent("player_team",                  _Player_Team_);

        g_bPlayerTeamHooked =                       false;
    }

    if (g_hBotQuota != INVALID_HANDLE)
    {
        if (g_bQuotaConVarChangeHooked)
        {
            UnhookConVarChange(g_hBotQuota,         _Con_Var_Change_);

            g_bQuotaConVarChangeHooked =            false;
        }
    }

    if (g_hSvFullAllTalk != INVALID_HANDLE)
    {
        if (g_bAllTalkConVarChangeHooked)
        {
            UnhookConVarChange(g_hSvFullAllTalk,    _Con_Var_Change_);

            g_bAllTalkConVarChangeHooked =          false;
        }
    }

    if (g_hPatchAddr != Address_Null)
    {
        if (g_nPatchSize != -1)
        {
            if (g_nPatchOffs != -1)
            {
                if (g_bPatchStatus)
                {
                    for (nIter = 0; nIter < g_nPatchSize; nIter++)
                    {
                        StoreToAddress(g_hPatchAddr + view_as<Address>(g_nPatchOffs) + view_as<Address>(nIter), g_nPatchOrigBytes[nIter], NumberType_Int8);
                    }

                    g_bPatchStatus = false;
                }
            }
        }
    }
}

public void OnPluginEnd()
{
    OnMapEnd();
}

public bool OnClientConnect(int nEntity, char[] szError, int nMaxLen)
{
    g_bMsgShown[nEntity] = false;

    return true;
}

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

    else if
    (
        strcmp(szArgs, "rr", false) == 0
            ||
        strcmp(szArgs, "voterr", false) == 0
            ||
        strcmp(szArgs, "voterestart", false) == 0
            ||
        strcmp(szArgs, "votereset", false) == 0
            ||
        strcmp(szArgs, "rgame", false) == 0
            ||
        strcmp(szArgs, "restartgame", false) == 0
            ||
        strcmp(szArgs, "!rr", false) == 0
            ||
        strcmp(szArgs, "!voterr", false) == 0
            ||
        strcmp(szArgs, "!voterestart", false) == 0
            ||
        strcmp(szArgs, "!votereset", false) == 0
            ||
        strcmp(szArgs, "!rgame", false) == 0
            ||
        strcmp(szArgs, "!restartgame", false) == 0
            ||
        strcmp(szArgs, "/rr", false) == 0
            ||
        strcmp(szArgs, "/voterr", false) == 0
            ||
        strcmp(szArgs, "/voterestart", false) == 0
            ||
        strcmp(szArgs, "/votereset", false) == 0
            ||
        strcmp(szArgs, "/rgame", false) == 0
            ||
        strcmp(szArgs, "/restartgame", false) == 0
    )
    {
        CreateTimer(0.000001, _Timer_Vote_Restart_Game_, GetClientUserId(nEntity), TIMER_FLAG_NO_MAPCHANGE);
    }

    else if
    (
        strcmp(szArgs, "map", false) == 0
            ||
        strcmp(szArgs, "votemap", false) == 0
            ||
        strcmp(szArgs, "changemap", false) == 0
            ||
        strcmp(szArgs, "level", false) == 0
            ||
        strcmp(szArgs, "vote", false) == 0
            ||
        strcmp(szArgs, "votelevel", false) == 0
            ||
        strcmp(szArgs, "changelevel", false) == 0
            ||
        strcmp(szArgs, "!map", false) == 0
            ||
        strcmp(szArgs, "!votemap", false) == 0
            ||
        strcmp(szArgs, "!changemap", false) == 0
            ||
        strcmp(szArgs, "!level", false) == 0
            ||
        strcmp(szArgs, "!vote", false) == 0
            ||
        strcmp(szArgs, "!votelevel", false) == 0
            ||
        strcmp(szArgs, "!changelevel", false) == 0
            ||
        strcmp(szArgs, "/map", false) == 0
            ||
        strcmp(szArgs, "/votemap", false) == 0
            ||
        strcmp(szArgs, "/changemap", false) == 0
            ||
        strcmp(szArgs, "/level", false) == 0
            ||
        strcmp(szArgs, "/vote", false) == 0
            ||
        strcmp(szArgs, "/votelevel", false) == 0
            ||
        strcmp(szArgs, "/changelevel", false) == 0
    )
    {
        CreateTimer(0.000001, _Timer_Vote_Change_Map_, GetClientUserId(nEntity), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action OnPlayerRunCmd(int nEntity, int& nButtons, int& nImpulse, float fVelocity[3], float fAngles[3], int& nWeapon, int& nSubType, int& nCmdNum, int& nTickCount, int& nSeed, int nMouseDir[2])
{
    nButtons |= (1 << 22);
}


/**
 * CUSTOM PUBLIC HANDLERS
 */

public void _Con_Var_Change_(Handle hConVar, const char[] szOld, const char[] szNew)
{
    if (hConVar == g_hBotQuota)
    {
        if (StringToInt(szNew) !=           _BOT_QUOTA_)
        {
            SetConVarInt(hConVar,           _BOT_QUOTA_);
        }
    }

    else if (hConVar == g_hSvFullAllTalk)
    {
        if (StringToInt(szNew) !=           _SV_FULL_ALLTALK_)
        {
            SetConVarInt(hConVar,           _SV_FULL_ALLTALK_);
        }
    }
}

public void _Player_Team_(Event hEv, const char[] szName, bool bNoBC)
{
    static int nTeam = 0, nEntity = 0;

    if
    (
        (
            (
                (nTeam = hEv.GetInt("team"))
                    ==
                (CS_TEAM_T)
            )
            ||
            (
                (nTeam)
                    ==
                (CS_TEAM_CT)
            )
        )
        &&
        (
            (nEntity = GetClientOfUserId(hEv.GetInt("userid")))
                >
            (0)
        )
        &&
        (
            (g_bMsgShown[nEntity])
                ==
            (false)
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
        g_bMsgShown[nEntity] = true;

        PrintToChat(nEntity, _WELCOME_MSG_1_);
        PrintToChat(nEntity, _WELCOME_MSG_2_);
    }
}

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
}

public Action _Timer_Vote_Restart_Game_(Handle hTimer, any nId)
{
    static int nEntity = 0;

    if ((nEntity = GetClientOfUserId(nId)) > 0 &&   IsClientConnected(nEntity) &&           IsClientInGame(nEntity))
    {
        if (GameRules_GetProp("m_bWarmupPeriod"))
        {
            PrintToChat(nEntity,                    " \x01Try again\x0B later\x01.");
        }

        else
        {
            FakeClientCommandEx(nEntity,            "callvote RestartGame");

            PrintToChat(nEntity,                    " \x01Done.");
        }
    }
}

public Action _Timer_Vote_Change_Map_(Handle hTimer, any nId)
{
    static int nEntity = 0;

    if ((nEntity = GetClientOfUserId(nId)) > 0 &&   IsClientConnected(nEntity) &&           IsClientInGame(nEntity))
    {
        if (GameRules_GetProp("m_bWarmupPeriod"))
        {
            PrintToChat(nEntity,                    " \x01Try again\x0B later\x01.");
        }

        else
        {
            FakeClientCommandEx(nEntity,            "callvote");

            PrintToChat(nEntity,                    " \x01Done.");
        }
    }
}

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

public Action _SM_CVar_(int nClient, int nArgs)
{
    static char szConVarName[PLATFORM_MAX_PATH] = { 0, ... }, szConVarVal[PLATFORM_MAX_PATH] = { 0, ... }, szConVarDefVal[PLATFORM_MAX_PATH] = { 0, ... },
        szConVarDesc[PLATFORM_MAX_PATH] = { 0, ... }, szConVarFlags[PLATFORM_MAX_PATH] = { 0, ... };

    static float fMin = 0.0, fMax = 0.0;
    static ConVar hConVar = null;

    if (nClient > 0 && (!IsClientConnected(nClient) || !IsClientInGame(nClient)))
    {
        return Plugin_Handled;
    }

    if (nArgs < 1)
    {
        switch (nClient)
        {
            case 0:
            {
                PrintToServer(_DESC_SM_CVAR_);
            }

            default:
            {
                PrintToConsole(nClient, _DESC_SM_CVAR_);

                PrintToChat(nClient,    _DESC_SM_CVAR_COL_);
            }
        }

        return Plugin_Handled;
    }

    GetCmdArg(1, szConVarName, sizeof (szConVarName));

    hConVar = FindConVar(szConVarName);

    if (hConVar == null)
    {
        switch (nClient)
        {
            case 0:
            {
                PrintToServer("Invalid CVar [ %s ]",                        szConVarName);
            }

            default:
            {
                PrintToConsole(nClient, "Invalid CVar [ %s ]",              szConVarName);

                PrintToChat(nClient,    " \x07Invalid\x09 CVar\x0B [ %s ]", szConVarName);
            }
        }

        return Plugin_Handled;
    }

    if (nArgs < 2)
    {
        hConVar.GetBounds(ConVarBound_Lower,        fMin);
        hConVar.GetBounds(ConVarBound_Upper,        fMax);

        hConVar.GetString(szConVarVal,              sizeof (szConVarVal));
        hConVar.GetDescription(szConVarDesc,        sizeof (szConVarDesc));
        hConVar.GetDefault(szConVarDefVal,          sizeof (szConVarDefVal));

        _CVar_Flags_Str_(hConVar, szConVarFlags,    sizeof (szConVarFlags));

        switch (nClient)
        {
            case 0:
            {
                PrintToServer("DESC [ %s ]",                                        szConVarDesc);
                PrintToServer("VAL [ %s ] DEF [ %s ]",                              szConVarVal, szConVarDefVal);
                PrintToServer("MIN [ %f ] MAX [ %f ]",                              fMin, fMax);
                PrintToServer("FLAGS [ %s ]",                                       szConVarFlags);
            }

            default:
            {
                PrintToConsole(nClient, "DESC [ %s ]",                              szConVarDesc);
                PrintToConsole(nClient, "VAL [ %s ] DEF [ %s ]",                    szConVarVal, szConVarDefVal);
                PrintToConsole(nClient, "MIN [ %f ] MAX [ %f ]",                    fMin, fMax);
                PrintToConsole(nClient, "FLAGS [ %s ]",                             szConVarFlags);

                PrintToChat(nClient,    " \x09DESC\x0B [ %s ]",                     szConVarDesc);
                PrintToChat(nClient,    " \x09VAL\x0B [ %s ]\x09 DEF\x0B [ %s ]",   szConVarVal, szConVarDefVal);
                PrintToChat(nClient,    " \x09MIN\x0B [ %f ]\x09 MAX\x0B [ %f ]",   fMin, fMax);
                PrintToChat(nClient,    " \x09FLAGS\x0B [ %s ]",                    szConVarFlags);
            }
        }

        return Plugin_Handled;
    }

    GetCmdArg(2, szConVarVal, sizeof (szConVarVal));

    hConVar.SetString(szConVarVal, true);

    switch (nClient)
    {
        case 0:
        {
            PrintToServer("%s [ %s ]",                      szConVarName, szConVarVal);
        }

        default:
        {
            PrintToConsole(nClient, "%s [ %s ]",            szConVarName, szConVarVal);

            PrintToChat(nClient,    " \x09%s\x0B [ %s ]",   szConVarName, szConVarVal);
        }
    }

    return Plugin_Handled;
}
