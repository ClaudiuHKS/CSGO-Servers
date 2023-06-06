
/**
 * MAIN REQUIREMENTS
 */

#include <sourcemod>
#include <sdktools>


/**
 * CUSTOM DEFINITIONS TO BE EDITED
 */

#define _STEAM_SV_KEYS_KV_FILE_     "SteamSvKeys.TXT"
#define _STEAM_SV_KEYS_KV_TITLE_    "SteamSvKeys"


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "Set Steam Account From File",
    author =        "CARAMEL® HACK",
    description =   "Executes 'sv_setsteamaccount' By Reading A TXT File",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * CUSTOM PRIVATE FUNCTIONS
 */

static bool _Create_Dir_(const char[] szDirPath, const int nFlags = \
    ((FPERM_U_READ | FPERM_U_WRITE | FPERM_U_EXEC) | \
    (FPERM_G_READ | FPERM_G_WRITE | FPERM_G_EXEC) | \
    (FPERM_O_READ | FPERM_O_WRITE | FPERM_O_EXEC)))
{
    static int nIter = 0;

    for (nIter = nFlags; nIter != -1; nIter--)
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


/**
 * CUSTOM PUBLIC FORWARDS
 */

public void OnPluginStart()
{
    OnMapStart();
}

public void OnMapStart()
{
    static char szFullIpAddr[PLATFORM_MAX_PATH] = { 0, ... }, szDataPath[PLATFORM_MAX_PATH] = { 0, ... }, szSteamKeysKvFile[PLATFORM_MAX_PATH] = { 0, ... },
        szSteamKey[PLATFORM_MAX_PATH] = { 0, ... };

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
}
