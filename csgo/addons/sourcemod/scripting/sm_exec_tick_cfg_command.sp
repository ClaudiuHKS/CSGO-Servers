
/**
 * MAIN REQUIREMENTS
 */

#include <sourcemod>


/**
 * CUSTOM DEFINITIONS TO BE EDITED
 */

#define _DESC_SM_EXEC_TICK_CFG_     "sm_exec_tick_cfg - Executes The Tick Based Config File"
#define _DESC_SM_EXEC_TICK_CFG_COL_ " \x01sm_exec_tick_cfg\x09 -\x05 Executes The Tick Based Config File"


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "SM Exec Tick CFG Command",
    author =        "CARAMEL® HACK",
    description =   "Provides The 'sm_exec_tick_cfg' Command",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * CUSTOM PRIVATE FUNCTIONS
 */

static int _Get_Sv_Tick_Rate_()
{
    return RoundToNearest(1.0 / GetTickInterval());
}


/**
 * CUSTOM PUBLIC FORWARDS
 */

public void OnPluginStart()
{
    RegAdminCmd("sm_exec_tick_cfg",     _SM_Exec_Tick_Cfg_,     ADMFLAG_CONFIG,     _DESC_SM_EXEC_TICK_CFG_);
}


/**
 * CUSTOM PUBLIC HANDLERS
 */

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
