#include <sourcemod>

public Plugin myinfo =
{
    name            =   "Simple Ranking"                        , \
    author          =   "Hattrick HKS (claudiuhks)"             , \
    description     =   "Provides A Simple Ranking System"      , \
    version         =   __DATE__                                , \
    url             =   "https://hattrick.go.ro/"               ,
};

static Handle g_hDb = INVALID_HANDLE;

public void OnPluginEnd()
{
    if (g_hDb != INVALID_HANDLE)
    {
        CloseHandle(g_hDb);

        g_hDb = INVALID_HANDLE;
    }
}

public void OnPluginStart()
{
    OnMapStart();
}

public void OnMapStart()
{
    static int nStamp = 0;
    static int nTime = 0;

    if (g_hDb == INVALID_HANDLE)
    {
        nTime = GetTime();

        if ((nTime - nStamp) > 8)
        {
            SQL_TConnect(OnConnection);

            nStamp = nTime;
        }
    }
}

public void OnConnection(Handle hOwner, Handle hChild, const char[] szcError, any hUserData)
{
    static const char szcCreation[] = "CREATE TABLE IF NOT EXISTS `simple_ranking` \
                                        ( \
                                            `auth` int( 10 ) UNSIGNED NOT NULL DEFAULT 0 , \
                                            `name` varchar( 256 ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '' , \
                                            `kills` int( 10 ) UNSIGNED NOT NULL DEFAULT 0 , \
                                            `deaths` int( 10 ) UNSIGNED NOT NULL DEFAULT 0 , \
                                            `kdr` float UNSIGNED NOT NULL DEFAULT 0 , \
                                            UNIQUE ( `auth` ) \
                                        ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci;";

    static int nStamp = 0;
    static int nTime = 0;

    nTime = GetTime();

    if ((nTime - nStamp) > 8)
    {
        if (strlen(szcError) > 0)
        {
            LogMessage("Failed to connect to the MySQL database.");

            LogMessage(szcError);
        }

        else
        {
            g_hDb = hChild;

            LogMessage("The connection to the MySQL database succeeded.");

            SQL_SetCharset(g_hDb, "utf8mb4");

            SQL_TQuery(g_hDb, OnTableCreation, szcCreation, INVALID_HANDLE, DBPrio_High);
        }

        nStamp = nTime;
    }
}

public void OnTableCreation(Handle hOwner, Handle hChild, const char[] szcError, any hUserData)
{
    if (strlen(szcError) > 0)
    {
        LogMessage("Failed to create the `simple_ranking` MySQL table.")

        LogMessage(szcError);
    }

    else
    {
        LogMessage("The MySQL table called `simple_ranking` has been successfully created.");
    }
}
