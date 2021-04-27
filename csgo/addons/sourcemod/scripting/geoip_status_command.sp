#include        <sourcemod>
#include        <GeoResolver>

#define         SM_STATUS_IS_FOR_EVERYONE                           // COMMENT THIS LINE OUT, IF YOU WANT (WITH A '//' AT THE BEGINNING)

#if !defined    SM_STATUS_IS_FOR_EVERYONE

    #define     SM_STATUS_COMMAND_ACCESS        ADMFLAG_GENERIC     // REQUIRED ADMIN ACCESS FLAG, FOR THE COMMAND

#endif

public Plugin myinfo =
{
    name            =   "GeoResolver: 'sm_status' Command"                      , \
    author          =   "Hattrick HKS (claudiuhks)"                             , \
    description     =   "Prints Players' Geographical Information"              , \
    version         =   __DATE__                                                , \
    url             =   "https://forums.alliedmods.net/showthread.php?t=267805" ,
};

public void OnPluginStart()
{

#if !defined SM_STATUS_IS_FOR_EVERYONE

    RegAdminCmd("sm_status",        CmdStatus,  SM_STATUS_COMMAND_ACCESS,   "sm_status - Prints Players' Geographical Information",     "status"    );
    RegAdminCmd("sm_countries",     CmdStatus,  SM_STATUS_COMMAND_ACCESS,   "sm_countries - Prints Players' Geographical Information",  "status"    );
    RegAdminCmd("sm_cities",        CmdStatus,  SM_STATUS_COMMAND_ACCESS,   "sm_cities - Prints Players' Geographical Information",     "status"    );
    RegAdminCmd("sm_locations",     CmdStatus,  SM_STATUS_COMMAND_ACCESS,   "sm_locations - Prints Players' Geographical Information",  "status"    );

#else

    RegConsoleCmd("sm_status",      CmdStatus,                              "sm_status - Prints Players' Geographical Information"                  );
    RegConsoleCmd("sm_countries",   CmdStatus,                              "sm_countries - Prints Players' Geographical Information"               );
    RegConsoleCmd("sm_cities",      CmdStatus,                              "sm_cities - Prints Players' Geographical Information"                  );
    RegConsoleCmd("sm_locations",   CmdStatus,                              "sm_locations - Prints Players' Geographical Information"               );

#endif

}

public Action CmdStatus(int nClient,                    int nArgs)
{
    static int          nPlayer                         =   0, \
                        nRow                            =   0;

    static GR_Db        nDb                             =   GEOIP_NONE;

    static ReplySource  nSrc                            =   SM_REPLY_TO_CONSOLE;

    static char         szIpAddr    [PLATFORM_MAX_PATH] =   "", \
                        szName      [PLATFORM_MAX_PATH] =   "", \
                        szCountry   [PLATFORM_MAX_PATH] =   "", \
                        szCity      [PLATFORM_MAX_PATH] =   "", \
                        szIsp       [PLATFORM_MAX_PATH] =   "";

    if (nClient > 0 &&  (!IsClientConnected(nClient)    ||  !IsClientInGame(nClient)))
    {
        return          Plugin_Handled;
    }

    nDb                                                 =   GeoR_Databases();
    nSrc                                                =   GetCmdReplySource();

    if (nDb ==  GEOIP_NONE)
    {
        switch  (nClient)
        {
            case 0:
            {
                PrintToServer       (           "\nNo MaxMind® Databases Are Actually In Use\n"             );
            }

            default:
            {
                if (nSrc ==         SM_REPLY_TO_CHAT)
                {
                    PrintToChat     (nClient,   " \x01No\x04 MaxMind® Databases\x01 Are Actually In Use"    );
                }

                else
                {
                    PrintToConsole  (nClient,   "\nNo MaxMind® Databases Are Actually In Use\n"             );
                }
            }
        }

        return                      Plugin_Handled;
    }

    if (nDb &       GEOIP_ISP_PAID  ||      nDb &                               GEOIP_ISP_LITE)
    {
        if (nSrc == SM_REPLY_TO_CONSOLE)
        {
            if      (nClient == 0)
            {
                PrintToServer   (           "\n%-2s %-48s %-48s %-48s %s\n",    "#", "Name", "Country", "City", "ISP");
            }

            else
            {
                PrintToConsole  (nClient,   "\n%-2s %-48s %-48s %-48s %s\n",    "#", "Name", "Country", "City", "ISP");
            }
        }

        else
        {
            PrintToConsole      (nClient,   "\n%-2s %-48s %-48s %-48s %s\n",    "#", "Name", "Country", "City", "ISP");
        }
    }

    else
    {
        if (nSrc == SM_REPLY_TO_CONSOLE)
        {
            if      (nClient == 0)
            {
                PrintToServer   (           "\n%-2s %-48s %-48s %s\n",          "#", "Name", "Country", "City");
            }

            else
            {
                PrintToConsole  (nClient,   "\n%-2s %-48s %-48s %s\n",          "#", "Name", "Country", "City");
            }
        }

        else
        {
            PrintToConsole      (nClient,   "\n%-2s %-48s %-48s %s\n",          "#", "Name", "Country", "City");
        }
    }

    nRow =          0;

    for (nPlayer =  1; nPlayer <= MaxClients; nPlayer++)
    {
        if (IsClientConnected(nPlayer)      && \
            IsClientInGame(nPlayer)         && \
            !IsFakeClient(nPlayer)          && \
            !IsClientSourceTV(nPlayer)      && \
            !IsClientReplay(nPlayer)        && \
            !IsClientTimingOut(nPlayer)     && \
            !IsClientInKickQueue(nPlayer)   )
        {
            if (!GetClientIP(nPlayer,       szIpAddr,   sizeof(szIpAddr),   true))
            {
                continue;
            }

            GetClientName   (nPlayer,       szName,     sizeof(szName));

            GeoR_Country    (szIpAddr,      szCountry,  sizeof(szCountry));
            GeoR_City       (szIpAddr,      szCity,     sizeof(szCity));

            if (nDb &       GEOIP_ISP_PAID  ||          nDb &               GEOIP_ISP_LITE)
            {
                GeoR_ISP    (szIpAddr,      szIsp,      sizeof(szIsp));

                if          (nClient == 0)
                {
                    PrintToServer(          "%-2d %-48s %-48s %-48s %s",    ++nRow, szName, szCountry, szCity, szIsp);
                }

                else
                {
                    PrintToConsole(nClient, "%-2d %-48s %-48s %-48s %s",    ++nRow, szName, szCountry, szCity, szIsp);
                }
            }

            else
            {
                if          (nClient == 0)
                {
                    PrintToServer(          "%-2d %-48s %-48s %s",          ++nRow, szName, szCountry, szCity);
                }

                else
                {
                    PrintToConsole(nClient, "%-2d %-48s %-48s %s",          ++nRow, szName, szCountry, szCity);
                }
            }
        }
    }

    if      (nRow >     0)
    {
        if  (nClient == 0)
        {
            PrintToServer(              "\nListed %d %s\n", nRow, nRow == 1 ? "Row" : "Rows");
        }

        else
        {
            PrintToConsole(nClient,     "\nListed %d %s\n", nRow, nRow == 1 ? "Row" : "Rows");

            if (nSrc ==                 SM_REPLY_TO_CHAT)
            {
                PrintToChat(nClient,    " \x01Listed\x04 %d\x01 %s In Your\x05 CONSOLE", nRow, nRow == 1 ? "Row" : "Rows");
            }
        }
    }

    else
    {
        if  (nClient == 0)
        {
            PrintToServer(              "Listed %d %s\n", nRow, nRow == 1 ? "Row" : "Rows");
        }

        else
        {
            PrintToConsole(nClient,     "Listed %d %s\n", nRow, nRow == 1 ? "Row" : "Rows");

            if (nSrc ==                 SM_REPLY_TO_CHAT)
            {
                PrintToChat(nClient,    " \x01Listed\x04 %d\x01 %s In Your\x05 CONSOLE", nRow, nRow == 1 ? "Row" : "Rows");
            }
        }
    }

    return  Plugin_Handled;
}
