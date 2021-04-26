#include "stub_mm.h"

UpdateLinuxSystem g_UpdateLinuxSystem;

PLUGIN_EXPOSE(UpdateLinuxSystem, g_UpdateLinuxSystem);

bool UpdateLinuxSystem::Load(PluginId id, ISmmAPI* ismm, char* error, size_t maxlen, bool bIsLateLoaded_)
{
    const char* pszGameBaseDir;

    char szBuffer[2048], szTrimmed[2048];

    char szCfgFile[256], szLogFile[256];

#if !defined WIN32 && !defined WINDOWS

    char szCpuFile[256], szMemFile[256];

#endif

    FILE* pICfgFile, * pOLogFile;

#if !defined WIN32 && !defined WINDOWS

    FILE* pICpuFile, * pOCpuFile;

    FILE* pIMemFile, * pOMemFile;

#endif

    int nIter, nLen;

    PLUGIN_SAVEVARS();

    if (!(pszGameBaseDir = ismm->GetBaseDir()) || *pszGameBaseDir == '\0')
    {
        snprintf(error, maxlen, "Failed To Retrieve The Game Base Directory");

        return false;
    }

    snprintf(szCfgFile, sizeof(szCfgFile), "%s/addons/update_linux_system/packages.cfg", pszGameBaseDir);
    snprintf(szLogFile, sizeof(szLogFile), "%s/addons/update_linux_system/status.log", pszGameBaseDir);

#if !defined WIN32 && !defined WINDOWS

    snprintf(szCpuFile, sizeof(szCpuFile), "%s/addons/update_linux_system/cpuinfo.txt", pszGameBaseDir);
    snprintf(szMemFile, sizeof(szMemFile), "%s/addons/update_linux_system/meminfo.txt", pszGameBaseDir);

#endif

    if ((pICfgFile = fopen(szCfgFile, "r")))
    {
        while (!feof(pICfgFile))
        {
            szBuffer[0] = '\0';
            szTrimmed[0] = '\0';

            nLen = 0;

            fgets(szBuffer, sizeof(szBuffer), pICfgFile);

            for (nIter = 0; nIter < strlen(szBuffer); nIter++)
            {
                if (szBuffer[nIter] != '\n' && szBuffer[nIter] != '\r')
                {
                    if (szBuffer[nIter] == '\t')
                    {
                        szTrimmed[nLen] = ' ';
                    }

                    else
                    {
                        szTrimmed[nLen] = szBuffer[nIter];
                    }

                    nLen++;
                }
            }

            szTrimmed[nLen] = '\0';

            if (szTrimmed[0] == '\0' || szTrimmed[0] == ';' || szTrimmed[0] == '#' || szTrimmed[0] == '/')
            {
                continue;
            }

            META_CONPRINTF("EXECUTING [ %s ]\n", szTrimmed);

            pOLogFile = fopen(szLogFile, "a");

            if (pOLogFile)
            {
                fprintf(pOLogFile, "EXECUTING [ %s ]\n", szTrimmed);

                fclose(pOLogFile);
            }

            system(szTrimmed);
        }

        fclose(pICfgFile);
    }

#if !defined WIN32 && !defined WINDOWS

    if ((pICpuFile = fopen("/proc/cpuinfo", "r")))
    {
        unlink(szCpuFile);

        while (!feof(pICpuFile))
        {
            szBuffer[0] = '\0';

            fgets(szBuffer, sizeof(szBuffer), pICpuFile);

            pOCpuFile = fopen(szCpuFile, "a");

            if (pOCpuFile)
            {
                fprintf(pOCpuFile, szBuffer);

                fclose(pOCpuFile);
            }
        }

        fclose(pICpuFile);
    }

#endif

#if !defined WIN32 && !defined WINDOWS

    if ((pIMemFile = fopen("/proc/meminfo", "r")))
    {
        unlink(szMemFile);

        while (!feof(pIMemFile))
        {
            szBuffer[0] = '\0';

            fgets(szBuffer, sizeof(szBuffer), pIMemFile);

            pOMemFile = fopen(szMemFile, "a");

            if (pOMemFile)
            {
                fprintf(pOMemFile, szBuffer);

                fclose(pOMemFile);
            }
        }

        fclose(pIMemFile);
    }

#endif

    return true;
}

bool UpdateLinuxSystem::Unload(char* pszError, size_t uErrorMaxLen)
{
    return true;
}

void UpdateLinuxSystem::AllPluginsLoaded()
{

}

bool UpdateLinuxSystem::Pause(char* pszError_, size_t uErrorMaxLen_)
{
    return true;
}

bool UpdateLinuxSystem::Unpause(char* pszError_, size_t uErrorMaxLen_)
{
    return true;
}

const char* UpdateLinuxSystem::GetLicense()
{
    return "MIT";
}

const char* UpdateLinuxSystem::GetVersion()
{
    return __DATE__;
}

const char* UpdateLinuxSystem::GetDate()
{
    return __DATE__;
}

const char* UpdateLinuxSystem::GetLogTag()
{
    return "ULS";
}

const char* UpdateLinuxSystem::GetAuthor()
{
    return "Hattrick HKS";
}

const char* UpdateLinuxSystem::GetDescription()
{
    return "Helps Owners Update Their Linux System";
}

const char* UpdateLinuxSystem::GetName()
{
    return "Update Linux System";
}

const char* UpdateLinuxSystem::GetURL()
{
    return "https://hattrick.go.ro/";
}
