
/**
 * MAIN REQUIREMENTS
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


/**
 * CUSTOM DEFINITIONS TO BE EDITED
 */

#define _DESC_SM_CVAR_              "sm_cvar REQ:CVar OPT:Value - Reveals Or Changes A CVar Value"
#define _DESC_SM_CVAR_COL_          " \x01sm_cvar\x07 REQ:CVar\x0B OPT:Value\x09 -\x05 Reveals Or Changes A CVar Value"


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "SM CVar Command",
    author =        "CARAMEL® HACK",
    description =   "Provides The 'sm_cvar' Command",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


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

            ReplaceStringEx(szStr, nMaxLen, ", $", "", 3, 0, true);
        }
    }
}


/**
 * CUSTOM PUBLIC FORWARDS
 */

public void OnPluginStart()
{
    RegAdminCmd("sm_cvar", _SM_CVar_, ADMFLAG_CONVARS, _DESC_SM_CVAR_);
}


/**
 * CUSTOM PUBLIC HANDLERS
 */

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
