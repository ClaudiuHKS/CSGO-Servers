
/**
 * MAIN REQUIREMENTS
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>


/**
 * CUSTOM DEFINITIONS TO BE EDITED
 */

#define _WELCOME_CON_MSG_1_         "Welcome. Committing suicide will not alter your score. Unlimited team changes are allowed. The voting system is enabled."
#define _WELCOME_CON_MSG_2_         "You may /rs, /map, /votemap, /voterr or /voterestart."

#define _WELCOME_MSG_1_             " \x01\x0BWelcome\x01. Committing\x09 suicide\x01 will not alter your\x04 score\x01. Unlimited\x09 team changes\x01 are\x04 allowed\x01. The\x09 voting system\x01 is\x04 enabled\x01."
#define _WELCOME_MSG_2_             " \x01You may\x05 /rs\x01,\x05 /map\x01,\x05 /votemap\x01,\x05 /voterr\x01 or\x05 /voterestart\x01."

#define _SV_MAX_RATE_               (786432) // Maximum INT Value That 'sv_maxrate' Can Have In CS:GO

#define _RATE_CON_MSG_1_            "You are using rate %s. We recommend the maximum, rate %s."
#define _RATE_CON_MSG_2_            "You can type it in your console. You will also need a strong internet connection."

#define _RATE_MSG_1_                " \x01You are using\x05 rate %s\x01. We recommend the maximum,\x09 rate %s\x01."
#define _RATE_MSG_2_                " \x01You can type it in your\x0B console\x01. You will also need a\x04 strong internet connection\x01."

#define _BOT_QUOTA_                 (2) // bot_quota
#define _SV_FULL_ALLTALK_           (1) // sv_full_alltalk
#define _SUICIDE_SCORE_             (0) // contributionscore_suicide
#define _SUICIDE_PENALTY_           (0) // mp_suicide_penalty

#define _STEAM_SV_KEYS_KV_FILE_     "SteamSvKeys.TXT"
#define _STEAM_SV_KEYS_KV_TITLE_    "SteamSvKeys"

#define _SV_TICK_RATE_KV_FILE_      "SvTickRate.TXT"
#define _SV_TICK_RATE_KV_TITLE_     "SvTickRate"

#define _DESC_SM_CVAR_              "sm_cvar REQ:CVar OPT:Value - Reveals Or Changes A CVar Value"
#define _DESC_SM_CVAR_COL_          " \x01sm_cvar\x07 REQ:CVar\x0B OPT:Value\x09 -\x05 Reveals Or Changes A CVar Value"

#define _DESC_SM_EXEC_TICK_CFG_     "sm_exec_tick_cfg - Executes The Tick Based Config File"
#define _DESC_SM_EXEC_TICK_CFG_COL_ " \x01sm_exec_tick_cfg\x09 -\x05 Executes The Tick Based Config File"


/**
 * CUSTOM DEFINITIONS
 */

#define         _PREP_OFFS_(%0,%1,%2)       if (%1 < 1) %1 = _Get_Offs_(%0, %2)


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "Hattrick",
    author =        "CARAMEL® HACK",
    description =   "Provides Custom Stuff",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * GLOBAL VARIABLES
 */

static bool g_bMsgShown[MAXPLAYERS] =           { false, ... };
static bool g_bRateMsgShown[MAXPLAYERS] =       { false, ... };

static Handle g_hBotQuota =                     INVALID_HANDLE;
static Handle g_hSvFullAllTalk =                INVALID_HANDLE;
static Handle g_hHostName =                     INVALID_HANDLE;
static Handle g_hSvTags =                       INVALID_HANDLE;
static Handle g_hSuicideScore =                 INVALID_HANDLE;
static Handle g_hSuicidePenalty =               INVALID_HANDLE;

static int g_nPatchSize =                       -1;
static int g_nPatchOffs =                       -1;
static int g_nPatchOrigBytes[512] =             { 0, ... };

static Address g_hPatchAddr =                   Address_Null;

static bool g_bPatchStatus =                    false;

static bool g_bPlayerDeathHooked =              false;
static bool g_bPlayerTeamHooked =               false;

static bool g_bQuotaConVarChangeHooked =        false;
static bool g_bAllTalkConVarChangeHooked =      false;
static bool g_bHostNameConVarChangeHooked =     false;
static bool g_bSvTagsConVarChangeHooked =       false;
static bool g_bSScoreConVarChangeHooked =       false;
static bool g_bSPenConVarChangeHooked =         false;

static float g_fRateMsgTimeStamp =              0.0;


/**
 * CUSTOM PRIVATE FUNCTIONS
 */

static bool _Create_Dir_(const char[] szDirPath, const int nCombinations = 8192)
{
    static int nIter = 0;

    for (nIter = 0; nIter < nCombinations; nIter++)
    {
        if (CreateDirectory(szDirPath, nIter))
        {
            return true;
        }
    }

    return false;
}

static void _Get_Sv_Full_Ip_(char[] szFullIpAddr, const int nLen)
{
    static char net_public_adr[PLATFORM_MAX_PATH] = { 0, ... }, hostip[PLATFORM_MAX_PATH] = { 0, ... },
        ip[PLATFORM_MAX_PATH] = { 0, ... }, hostport[PLATFORM_MAX_PATH] = { 0, ... };

    static ConVar net_public_adr_h = null, hostip_h = null, ip_h = null, hostport_h = null;
    static int hostip_n = 0;

    if (net_public_adr_h == null)
    {
        net_public_adr_h = FindConVar("net_public_adr");
    }

    if (hostip_h == null)
    {
        hostip_h = FindConVar("hostip");
    }

    if (ip_h == null)
    {
        ip_h = FindConVar("ip");
    }

    if (hostport_h == null)
    {
        hostport_h = FindConVar("hostport");
    }

    if (net_public_adr_h != null)
    {
        net_public_adr_h.GetString(net_public_adr, sizeof (net_public_adr));

        ReplaceStringEx(net_public_adr, sizeof (net_public_adr), "::", ":", 2, 1, true);
    }

    if (hostip_h != null)
    {
        hostip_n = hostip_h.IntValue;

        FormatEx(hostip, sizeof (hostip), "%d.%d.%d.%d", (hostip_n >> 24) & 0xFF, (hostip_n >> 16) & 0xFF, (hostip_n >> 8) & 0xFF, hostip_n & 0xFF);
    }

    if (ip_h != null)
    {
        ip_h.GetString(ip, sizeof (ip));

        ReplaceStringEx(ip, sizeof (ip), "::", ":", 2, 1, true);
    }

    if (hostport_h != null)
    {
        hostport_h.GetString(hostport, sizeof (hostport));
    }

    if (IsCharNumeric(net_public_adr[0]))
    {
        if (FindCharInString(net_public_adr, ':') == -1)
        {
            FormatEx(szFullIpAddr, nLen, "%s:%s", net_public_adr, hostport);
        }

        else
        {
            strcopy(szFullIpAddr, nLen, net_public_adr);
        }
    }

    else if (IsCharNumeric(hostip[0]))
    {
        if (FindCharInString(hostip, ':') == -1)
        {
            FormatEx(szFullIpAddr, nLen, "%s:%s", hostip, hostport);
        }

        else
        {
            strcopy(szFullIpAddr, nLen, hostip);
        }
    }

    else if (IsCharNumeric(ip[0]))
    {
        if (FindCharInString(ip, ':') == -1)
        {
            FormatEx(szFullIpAddr, nLen, "%s:%s", ip, hostport);
        }

        else
        {
            strcopy(szFullIpAddr, nLen, ip);
        }
    }

    else if (strlen(net_public_adr) > 0)
    {
        if (FindCharInString(net_public_adr, ':') == -1)
        {
            FormatEx(szFullIpAddr, nLen, "%s:%s", net_public_adr, hostport);
        }

        else
        {
            strcopy(szFullIpAddr, nLen, net_public_adr);
        }
    }

    else if (strlen(hostip) > 0)
    {
        if (FindCharInString(hostip, ':') == -1)
        {
            FormatEx(szFullIpAddr, nLen, "%s:%s", hostip, hostport);
        }

        else
        {
            strcopy(szFullIpAddr, nLen, hostip);
        }
    }

    else if (strlen(ip) > 0)
    {
        if (FindCharInString(ip, ':') == -1)
        {
            FormatEx(szFullIpAddr, nLen, "%s:%s", ip, hostport);
        }

        else
        {
            strcopy(szFullIpAddr, nLen, ip);
        }
    }

    else
    {
        FormatEx(szFullIpAddr, nLen, ":%s", hostport);
    }
}

bool _Get_From_Kv_File_(const char[] szFileTitle, const char[] szFileName, const char[] szEntry, const char[] szKey, char[] szValue, const int nLen)
{
    static KeyValues hKv = null;
    static char szBuffer[PLATFORM_MAX_PATH] = { 0, ... };

    hKv = new KeyValues(szFileTitle);

    if (hKv == null)
    {
        return false;
    }

    hKv.ImportFromFile(szFileName);

    if (!hKv.GotoFirstSubKey())
    {
        delete hKv;

        hKv = null;

        return false;
    }

    do
    {
        hKv.GetSectionName(szBuffer, sizeof (szBuffer));

        if (strcmp(szBuffer, szEntry, false) == 0)
        {
            hKv.GetString(szKey, szValue, nLen);

            delete hKv;

            hKv = null;

            return true;
        }
    }

    while (hKv.GotoNextKey());

    delete hKv;

    hKv = null;

    return false;
}

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

            ReplaceStringEx(szStr, nMaxLen, ", $", "", 3, 0, true);
        }
    }
}

static int _Get_Sv_Tick_Rate_()
{
    return RoundToNearest(1.0 / GetTickInterval());
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

public APLRes AskPluginLoad2(Handle hSelf, bool bLateLoaded, char[] szError, int nErrorMaxLen)
{
    if (Engine_CSGO != GetEngineVersion())
    {
        FormatEx(szError, nErrorMaxLen, "This Plug-in Only Works On Counter-Strike: Global Offensive");

        return APLRes_Failure;
    }

    return APLRes_Success;
}

public void OnPluginStart()
{
    RegAdminCmd("sm_cvar",              _SM_CVar_,              ADMFLAG_CONVARS,    _DESC_SM_CVAR_,             "cvar");
    RegAdminCmd("sm_exec_tick_cfg",     _SM_Exec_Tick_Cfg_,     ADMFLAG_CONFIG,     _DESC_SM_EXEC_TICK_CFG_,    "exec");

    OnMapStart();

    OnConfigsExecuted();
}

public void OnMapStart()
{
    static char szFullIpAddr[PLATFORM_MAX_PATH] = { 0, ... }, szDataPath[PLATFORM_MAX_PATH] = { 0, ... }, szSteamKeysKvFile[PLATFORM_MAX_PATH] = { 0, ... },
        szSteamKey[PLATFORM_MAX_PATH] = { 0, ... }, szTickRateKvFile[PLATFORM_MAX_PATH] = { 0, ... }, szTickRate[PLATFORM_MAX_PATH] = { 0, ... },
        szDefaultTickRate[PLATFORM_MAX_PATH] = { 0, ... }, szHours[PLATFORM_MAX_PATH] = { 0, ... }, szCurrentHour[PLATFORM_MAX_PATH] = { 0, ... },
        szBuffer[PLATFORM_MAX_PATH] = { 0, ... };

    static Handle hData = INVALID_HANDLE;
    static int nIter = 0, nTickInterval = 0, nHostStateInterval = 0, nTickRate = 0, nDefaultTickRate = 0;
    static Address hStartSound = Address_Null, hSpawnServer = Address_Null, hTickInterval = Address_Null, hIntervalPerTick = Address_Null;
    static float fIntervalPerTick = 0.0, fDefaultIntervalPerTick = 0.0;

    BuildPath(Path_SM, szDataPath, sizeof (szDataPath), "data");

    if (!DirExists(szDataPath))
    {
        _Create_Dir_(szDataPath);
    }

    if (DirExists(szDataPath))
    {
        FormatEx(szSteamKeysKvFile, sizeof (szSteamKeysKvFile), "%s/%s", szDataPath, _STEAM_SV_KEYS_KV_FILE_);

        if (FileExists(szSteamKeysKvFile))
        {
            _Get_Sv_Full_Ip_(szFullIpAddr, sizeof (szFullIpAddr));

            if (_Get_From_Kv_File_(_STEAM_SV_KEYS_KV_TITLE_, szSteamKeysKvFile, szFullIpAddr, "sv_setsteamaccount", szSteamKey, sizeof (szSteamKey)))
            {
                if (strlen(szSteamKey) > 0)
                {
                    if (IsCharNumeric(szSteamKey[0]) || (IsCharAlpha(szSteamKey[0]) && IsCharUpper(szSteamKey[0])))
                    {
                        ServerCommand("sv_setsteamaccount %s", szSteamKey);
                    }
                }
            }
        }
    }

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

    if (g_hHostName == INVALID_HANDLE)
    {
        g_hHostName =                               FindConVar("hostname");
    }

    if (g_hSvTags == INVALID_HANDLE)
    {
        g_hSvTags =                                 FindConVar("sv_tags");
    }

    if (g_hSuicideScore == INVALID_HANDLE)
    {
        g_hSuicideScore =                           FindConVar("contributionscore_suicide");
    }

    if (g_hSuicidePenalty == INVALID_HANDLE)
    {
        g_hSuicidePenalty =                         FindConVar("mp_suicide_penalty");
    }

    if (g_hBotQuota != INVALID_HANDLE)
    {
        if (GetConVarInt(g_hBotQuota) !=            _BOT_QUOTA_)
        {
            IntToString(_BOT_QUOTA_,                szBuffer, sizeof (szBuffer));

            SetConVarString(g_hBotQuota,            szBuffer, true);
        }

        if (!g_bQuotaConVarChangeHooked)
        {
            HookConVarChange(g_hBotQuota,           _Con_Var_Change_);

            g_bQuotaConVarChangeHooked =            true;
        }

        if (GetConVarInt(g_hBotQuota) !=            _BOT_QUOTA_)
        {
            IntToString(_BOT_QUOTA_,                szBuffer, sizeof (szBuffer));

            SetConVarString(g_hBotQuota,            szBuffer, true);
        }
    }

    if (g_hSvFullAllTalk != INVALID_HANDLE)
    {
        if (GetConVarInt(g_hSvFullAllTalk) !=       _SV_FULL_ALLTALK_)
        {
            IntToString(_SV_FULL_ALLTALK_,          szBuffer, sizeof (szBuffer));

            SetConVarString(g_hSvFullAllTalk,       szBuffer, true);
        }

        if (!g_bAllTalkConVarChangeHooked)
        {
            HookConVarChange(g_hSvFullAllTalk,      _Con_Var_Change_);

            g_bAllTalkConVarChangeHooked =          true;
        }

        if (GetConVarInt(g_hSvFullAllTalk) !=       _SV_FULL_ALLTALK_)
        {
            IntToString(_SV_FULL_ALLTALK_,          szBuffer, sizeof (szBuffer));

            SetConVarString(g_hSvFullAllTalk,       szBuffer, true);
        }
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

    if (g_hSuicidePenalty != INVALID_HANDLE)
    {
        if (GetConVarInt(g_hSuicidePenalty) !=      _SUICIDE_PENALTY_)
        {
            IntToString(_SUICIDE_PENALTY_,          szBuffer, sizeof (szBuffer));

            SetConVarString(g_hSuicidePenalty,      szBuffer, true);
        }

        if (!g_bSPenConVarChangeHooked)
        {
            HookConVarChange(g_hSuicidePenalty,     _Con_Var_Change_);

            g_bSPenConVarChangeHooked =             true;
        }

        if (GetConVarInt(g_hSuicidePenalty) !=      _SUICIDE_PENALTY_)
        {
            IntToString(_SUICIDE_PENALTY_,          szBuffer, sizeof (szBuffer));

            SetConVarString(g_hSuicidePenalty,      szBuffer, true);
        }
    }

    if (g_hHostName != INVALID_HANDLE)
    {
        if (!g_bHostNameConVarChangeHooked)
        {
            HookConVarChange(g_hHostName,           _Con_Var_Change_);

            g_bHostNameConVarChangeHooked =         true;
        }
    }

    if (g_hSvTags != INVALID_HANDLE)
    {
        if (!g_bSvTagsConVarChangeHooked)
        {
            HookConVarChange(g_hSvTags,             _Con_Var_Change_);

            g_bSvTagsConVarChangeHooked =           true;
        }
    }

    if ((hData = LoadGameConfigFile("hattrick.games")) != INVALID_HANDLE)
    {
        if
        (
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

        if
        (
            (
                (hStartSound = GameConfGetAddress(hData,        "sv_startsound"))
                    !=
                (Address_Null)
            )
            &&
            (
                (hSpawnServer = GameConfGetAddress(hData,       "spawnserver"))
                    !=
                (Address_Null)
            )
            &&
            (
                (nTickInterval = GameConfGetOffset(hData,       "m_flTickInterval"))
                    !=
                (-1)
            )
            &&
            (
                (nHostStateInterval = GameConfGetOffset(hData,  "host_state_interval"))
                    !=
                (-1)
            )
        )
        {
            hTickInterval       = view_as<Address>(LoadFromAddress(hStartSound  + view_as<Address>(nTickInterval),      NumberType_Int32));
            hIntervalPerTick    = view_as<Address>(LoadFromAddress(hSpawnServer + view_as<Address>(nHostStateInterval), NumberType_Int32));

            if (hTickInterval   != Address_Null && hIntervalPerTick != Address_Null)
            {
                if (DirExists(szDataPath))
                {
                    FormatEx(szTickRateKvFile, sizeof (szTickRateKvFile), "%s/%s", szDataPath, _SV_TICK_RATE_KV_FILE_);

                    if (FileExists(szTickRateKvFile))
                    {
                        _Get_Sv_Full_Ip_(szFullIpAddr, sizeof (szFullIpAddr));

                        if (_Get_From_Kv_File_(_SV_TICK_RATE_KV_TITLE_, szTickRateKvFile, szFullIpAddr,         "tick_rate",                szTickRate,         sizeof (szTickRate)))
                        {
                            if (_Get_From_Kv_File_(_SV_TICK_RATE_KV_TITLE_, szTickRateKvFile, szFullIpAddr,     "default_tick_rate",        szDefaultTickRate,  sizeof (szDefaultTickRate)))
                            {
                                if (_Get_From_Kv_File_(_SV_TICK_RATE_KV_TITLE_, szTickRateKvFile, szFullIpAddr, "hours_for_not_default",    szHours,            sizeof (szHours)))
                                {
                                    if (strlen(szTickRate) > 0 && strlen(szDefaultTickRate) > 0 && strlen(szHours) > 0)
                                    {
                                        FormatTime(szCurrentHour, sizeof (szCurrentHour), "%H");

                                        nTickRate =                             StringToInt(szTickRate);
                                        nDefaultTickRate =                      StringToInt(szDefaultTickRate);

                                        fIntervalPerTick =                      1.0 / float(nTickRate);
                                        fDefaultIntervalPerTick =               1.0 / float(nDefaultTickRate);

                                        if (StrContains(szHours, szCurrentHour) != -1)
                                        {
                                            StoreToAddress(hTickInterval,       view_as<int>(fIntervalPerTick), NumberType_Int32);
                                            StoreToAddress(hIntervalPerTick,    view_as<int>(fIntervalPerTick), NumberType_Int32);
                                        }

                                        else
                                        {
                                            StoreToAddress(hTickInterval,       view_as<int>(fDefaultIntervalPerTick), NumberType_Int32);
                                            StoreToAddress(hIntervalPerTick,    view_as<int>(fDefaultIntervalPerTick), NumberType_Int32);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        CloseHandle(hData);

        hData = INVALID_HANDLE;
    }

    g_fRateMsgTimeStamp = 0.0;
}

public void OnConfigsExecuted()
{
    static char szHostName[PLATFORM_MAX_PATH] = { 0, ... }, szHostPort[PLATFORM_MAX_PATH] = { 0, ... }, szTags[PLATFORM_MAX_PATH] = { 0, ... },
        szTickRate[PLATFORM_MAX_PATH] = { 0, ... };

    static ConVar hHostName = null, hHostPort = null, hTags = null;
    static int nTickRate = 0;

    nTickRate = _Get_Sv_Tick_Rate_();

    IntToString(nTickRate, szTickRate, sizeof (szTickRate));

    ServerCommand("exec %d_tickrate.cfg", nTickRate);

    if (hHostName == null)
    {
        hHostName = FindConVar("hostname");
    }

    if (hHostPort == null)
    {
        hHostPort = FindConVar("hostport");
    }

    if (hTags == null)
    {
        hTags =     FindConVar("sv_tags");
    }

    if (hHostName != null)
    {
        hHostName.GetString(szHostName, sizeof (szHostName));
    }

    if (hHostPort != null)
    {
        hHostPort.GetString(szHostPort, sizeof (szHostPort));
    }

    if (hTags != null)
    {
        hTags.GetString(szTags,         sizeof (szTags));
    }

    ReplaceString(szHostName,           sizeof (szHostName),    "<TICK>", szTickRate, false);
    ReplaceString(szHostName,           sizeof (szHostName),    "<PORT>", szHostPort, false);

    ReplaceString(szTags,               sizeof (szTags),        "<TICK>", szTickRate, false);
    ReplaceString(szTags,               sizeof (szTags),        "<PORT>", szHostPort, false);

    if (hHostName != null)
    {
        hHostName.SetString(szHostName, true);
    }

    if (hTags != null)
    {
        hTags.SetString(szTags,         true);
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

    if (g_hHostName != INVALID_HANDLE)
    {
        if (g_bHostNameConVarChangeHooked)
        {
            UnhookConVarChange(g_hHostName,         _Con_Var_Change_);

            g_bHostNameConVarChangeHooked =         false;
        }
    }

    if (g_hSvTags != INVALID_HANDLE)
    {
        if (g_bSvTagsConVarChangeHooked)
        {
            UnhookConVarChange(g_hSvTags,           _Con_Var_Change_);

            g_bSvTagsConVarChangeHooked =           false;
        }
    }

    if (g_hSuicideScore != INVALID_HANDLE)
    {
        if (g_bSScoreConVarChangeHooked)
        {
            UnhookConVarChange(g_hSuicideScore,     _Con_Var_Change_);

            g_bSScoreConVarChangeHooked =           false;
        }
    }

    if (g_hSuicidePenalty != INVALID_HANDLE)
    {
        if (g_bSPenConVarChangeHooked)
        {
            UnhookConVarChange(g_hSuicidePenalty,   _Con_Var_Change_);

            g_bSPenConVarChangeHooked =             false;
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

    g_fRateMsgTimeStamp = 0.0;
}

public void OnPluginEnd()
{
    OnMapEnd();
}

public bool OnClientConnect(int nEntity, char[] szError, int nMaxLen)
{
    g_bMsgShown[nEntity] =              false;
    g_bRateMsgShown[nEntity] =          false;

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

public Action CS_OnTerminateRound(float& fDelay, CSRoundEndReason& nReason)
{
    static float fTimeNow = 0.0;
    static int nPlayer = 0, nTeam = 0;

    if (((fTimeNow = GetEngineTime()) - g_fRateMsgTimeStamp) > 16.0 || g_fRateMsgTimeStamp == 0.0)
    {
        g_fRateMsgTimeStamp = fTimeNow;

        for (nPlayer = 1; nPlayer < MAXPLAYERS; nPlayer++)
        {
            if (g_bRateMsgShown[nPlayer])
            {
                continue;
            }

            if (!IsClientConnected(nPlayer)     ||      !IsClientInGame(nPlayer))
            {
                continue;
            }

            if (IsFakeClient(nPlayer)           ||      IsClientSourceTV(nPlayer)       ||      IsClientReplay(nPlayer))
            {
                continue;
            }

            if (IsClientInKickQueue(nPlayer)    ||      IsClientTimingOut(nPlayer))
            {
                continue;
            }

            nTeam = GetClientTeam(nPlayer);

            if (nTeam != CS_TEAM_T              &&      nTeam != CS_TEAM_CT)
            {
                continue;
            }

            QueryClientConVar(nPlayer, "rate", _Rate_Con_Var_Check_);
        }
    }
}

public Action OnPlayerRunCmd(int nEntity, int& nButtons, int& nImpulse, float fVelocity[3], float fAngles[3], int& nWeapon, int& nSubType, int& nCmdNum, int& nTickCount, int& nSeed, int nMouseDir[2])
{
    nButtons |= IN_BULLRUSH;
}


/**
 * CUSTOM PUBLIC HANDLERS
 */

public void _Rate_Con_Var_Check_(QueryCookie nCookie, int nPlayer, ConVarQueryResult nRes, const char[] szConVarName, const char[] szConVarValue)
{
    static char szSvMaxRate[PLATFORM_MAX_PATH] = { 0, ... };
    static int nPlayerRate = 0, nSvMaxRate = 0;
    static ConVar hSvMaxRate = null;

    if (nRes == ConVarQuery_Okay)
    {
        if (IsClientConnected(nPlayer) && IsClientInGame(nPlayer))
        {
            g_bRateMsgShown[nPlayer] = true;

            if (hSvMaxRate == null)
            {
                hSvMaxRate =    FindConVar("sv_maxrate");
            }

            if (hSvMaxRate != null)
            {
                hSvMaxRate.GetString(szSvMaxRate,           sizeof (szSvMaxRate));

                nSvMaxRate =    hSvMaxRate.IntValue;

                if (nSvMaxRate  < 1)
                {
                    nSvMaxRate  = _SV_MAX_RATE_;

                    IntToString(nSvMaxRate, szSvMaxRate,    sizeof (szSvMaxRate));
                }

                nPlayerRate =   StringToInt(szConVarValue);

                if (nPlayerRate < nSvMaxRate)
                {
                    PrintToConsole(nPlayer, _RATE_CON_MSG_1_,   szConVarValue,  szSvMaxRate);
                    PrintToConsole(nPlayer, _RATE_CON_MSG_2_);

                    PrintToChat(nPlayer,    _RATE_MSG_1_,       szConVarValue,  szSvMaxRate);
                    PrintToChat(nPlayer,    _RATE_MSG_2_);
                }
            }
        }
    }
}

public void _Con_Var_Change_(Handle hConVar, const char[] szOld, const char[] szNew)
{
    static char szBuffer[PLATFORM_MAX_PATH] = { 0, ... }, szHostPort[PLATFORM_MAX_PATH] = { 0, ... }, szTickRate[PLATFORM_MAX_PATH] = { 0, ... };
    static ConVar hHostPort = null;
    static int nTickRate = 0;

    if (hHostPort == null)
    {
        hHostPort = FindConVar("hostport");
    }

    if (hConVar == g_hBotQuota)
    {
        if (StringToInt(szNew) !=           _BOT_QUOTA_)
        {
            IntToString(_BOT_QUOTA_,        szBuffer, sizeof (szBuffer));

            SetConVarString(hConVar,        szBuffer, true);
        }
    }

    else if (hConVar == g_hSvFullAllTalk)
    {
        if (StringToInt(szNew) !=           _SV_FULL_ALLTALK_)
        {
            IntToString(_SV_FULL_ALLTALK_,  szBuffer, sizeof (szBuffer));

            SetConVarString(hConVar,        szBuffer, true);
        }
    }

    else if (hConVar == g_hSuicideScore)
    {
        if (StringToInt(szNew) !=           _SUICIDE_SCORE_)
        {
            IntToString(_SUICIDE_SCORE_,    szBuffer, sizeof (szBuffer));

            SetConVarString(hConVar,        szBuffer, true);
        }
    }

    else if (hConVar == g_hSuicidePenalty)
    {
        if (StringToInt(szNew) !=           _SUICIDE_PENALTY_)
        {
            IntToString(_SUICIDE_PENALTY_,  szBuffer, sizeof (szBuffer));

            SetConVarString(hConVar,        szBuffer, true);
        }
    }

    else if (hConVar == g_hHostName)
    {
        if (hHostPort != null)
        {
            hHostPort.GetString(szHostPort, sizeof (szHostPort));

            nTickRate = _Get_Sv_Tick_Rate_();

            IntToString(nTickRate, szTickRate, sizeof (szTickRate));

            strcopy(szBuffer, sizeof (szBuffer), szNew);

            ReplaceString(szBuffer, sizeof (szBuffer), "<TICK>", szTickRate, false);
            ReplaceString(szBuffer, sizeof (szBuffer), "<PORT>", szHostPort, false);

            if (strcmp(szNew, szBuffer))
            {
                SetConVarString(hConVar, szBuffer, true);
            }
        }
    }

    else if (hConVar == g_hSvTags)
    {
        if (hHostPort != null)
        {
            hHostPort.GetString(szHostPort, sizeof (szHostPort));

            nTickRate = _Get_Sv_Tick_Rate_();

            IntToString(nTickRate, szTickRate, sizeof (szTickRate));

            strcopy(szBuffer, sizeof (szBuffer), szNew);

            ReplaceString(szBuffer, sizeof (szBuffer), "<TICK>", szTickRate, false);
            ReplaceString(szBuffer, sizeof (szBuffer), "<PORT>", szHostPort, false);

            if (strcmp(szNew, szBuffer))
            {
                SetConVarString(hConVar, szBuffer, true);
            }
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

        PrintToConsole(nEntity, _WELCOME_CON_MSG_1_);
        PrintToConsole(nEntity, _WELCOME_CON_MSG_2_);

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

    if (IsValidEntity(nEntity))
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

public Action _SM_Exec_Tick_Cfg_(int nClient, int nArgs)
{
    static char szConfigFileName[PLATFORM_MAX_PATH] = { 0, ... };

    if (nClient > 0 && (!IsClientConnected(nClient) || !IsClientInGame(nClient)))
    {
        return Plugin_Handled;
    }

    FormatEx(szConfigFileName, sizeof (szConfigFileName), "%d_tickrate.cfg", _Get_Sv_Tick_Rate_());

    ServerCommand("exec %s", szConfigFileName);

    switch (nClient)
    {
        case 0:
        {
            PrintToServer("Executed [ %s ]",                    szConfigFileName);
        }

        default:
        {
            PrintToConsole(nClient, "Executed [ %s ]",          szConfigFileName);

            PrintToChat(nClient,    " \x09Executed\x0B [ %s ]", szConfigFileName);
        }
    }

    return Plugin_Handled;
}
