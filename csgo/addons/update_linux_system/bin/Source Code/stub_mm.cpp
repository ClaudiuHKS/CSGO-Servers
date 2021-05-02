#include "stub_mm.h"

UpdateLinuxSystem g_UpdateLinuxSystem;

PLUGIN_EXPOSE(UpdateLinuxSystem, g_UpdateLinuxSystem);

bool UpdateLinuxSystem::Load(PluginId id, ISmmAPI* ismm, char* pszError, unsigned int uiErrorSize, bool)
{
    const char* pszcGameBaseDir;

    char szBuffer[2048], szTrimmed[2048];

    char szCfgFile[256], szLogFile[256];

#if !defined WIN32

    char szCpuFile[256], szMemFile[256];

#endif

    FILE* pICfgFile, * pOLogFile;

#if !defined WIN32

    FILE* pICpuFile, * pOCpuFile;

    FILE* pIMemFile, * pOMemFile;

#endif

    int nIter, nLen;

    PLUGIN_SAVEVARS();

    if (!(pszcGameBaseDir = ismm->GetBaseDir()) || *pszcGameBaseDir == '\0')
    {
        snprintf(pszError, uiErrorSize, "Failed To Retrieve The Game Base Directory");

        return false;
    }

    snprintf(szCfgFile, sizeof(szCfgFile), "%s/addons/update_linux_system/packages.cfg", pszcGameBaseDir);
    snprintf(szLogFile, sizeof(szLogFile), "%s/addons/update_linux_system/status.log", pszcGameBaseDir);

#if !defined WIN32

    snprintf(szCpuFile, sizeof(szCpuFile), "%s/addons/update_linux_system/cpuinfo.txt", pszcGameBaseDir);
    snprintf(szMemFile, sizeof(szMemFile), "%s/addons/update_linux_system/meminfo.txt", pszcGameBaseDir);

#endif

    if ((pICfgFile = fopen(szCfgFile, "r")))
    {
        while (!feof(pICfgFile))
        {
            szBuffer[0] = '\0';
            szTrimmed[0] = '\0';

            nLen = 0;

            fgets(szBuffer, sizeof(szBuffer), pICfgFile);

            for (nIter = 0; nIter < xTo(strlen(szBuffer), int); nIter++)
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

#if !defined WIN32

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
                fputs(szBuffer, pOCpuFile);

                fclose(pOCpuFile);
            }
        }

        fclose(pICpuFile);
    }

#endif

#if !defined WIN32

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
                fputs(szBuffer, pOMemFile);

                fclose(pOMemFile);
            }
        }

        fclose(pIMemFile);
    }

#endif

    return true;
}

bool UpdateLinuxSystem::Unload(char*, unsigned int)
{
    return true;
}

void UpdateLinuxSystem::AllPluginsLoaded()
{

}

bool UpdateLinuxSystem::Pause(char*, unsigned int)
{
    return true;
}

bool UpdateLinuxSystem::Unpause(char*, unsigned int)
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

#if !defined WIN32

extern "C" void __cxa_pure_virtual(void)
{
}

void* operator new(size_t uiMem)
{
    return malloc(uiMem);
}

void* operator new[](size_t uiMem)
{
    return malloc(uiMem);
}

void operator delete(void* pMem)
{
    free(pMem);
}

void operator delete[](void* pMem)
{
    free(pMem);
}

#endif
