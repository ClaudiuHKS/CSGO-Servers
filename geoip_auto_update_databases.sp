#include <sourcemod>
#include <GeoResolver>

public Plugin myinfo =
{
    name            =   "GeoResolver: Auto Database Updater"                    , \
    author          =   "Hattrick HKS (claudiuhks)"                             , \
    description     =   "Reloads The MaxMind® Databases During Map Change"      , \
    version         =   __DATE__                                                , \
    url             =   "https://forums.alliedmods.net/showthread.php?t=267805" ,
};

public void OnMapEnd()
{
    static const char szcDbFileNames[][] =
    {
        "GeoLite2-City.mmdb",           "GeoIP2-City.mmdb",
        "GeoLiteCity.dat",              "GeoIPCity.dat",
        "GeoLiteISP.dat",               "GeoIPISP.dat",
    };

    static char szDataGeoResolverUpdateDirPath[PLATFORM_MAX_PATH] = { 0, ... }, szFileName[PLATFORM_MAX_PATH] = { 0, ... };
    static DirectoryListing hDir = null;
    static FileType nFileType = FileType_Unknown;
    static int nIter = 0;

    BuildPath(Path_SM, szDataGeoResolverUpdateDirPath, sizeof (szDataGeoResolverUpdateDirPath), "data/GeoResolver/Update");

    if (DirExists(szDataGeoResolverUpdateDirPath))
    {
        hDir = OpenDirectory(szDataGeoResolverUpdateDirPath);

        if (hDir)
        {
            while (ReadDirEntry(hDir, szFileName, sizeof (szFileName), nFileType))
            {
                if (nFileType == FileType_File)
                {
                    for (nIter = 0; nIter < sizeof (szcDbFileNames); nIter++)
                    {
                        if (0 == strcmp(szFileName, szcDbFileNames[nIter], true))
                        {
                            CloseHandle(hDir);

                            GeoR_Reload();

                            return;
                        }
                    }
                }
            }

            CloseHandle(hDir);
        }
    }
}
