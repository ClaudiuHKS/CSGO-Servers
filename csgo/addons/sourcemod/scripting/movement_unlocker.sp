
/**
 * MAIN REQUIREMENTS
 */

#include < sourcemod >
#include < cstrike >
#include < regex >
#include < sdktools >
#include < sdkhooks >


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "Movement Unlocker",
    author =        "CARAMEL® HACK",
    description =   "Unlocks the game players movement.",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * GLOBAL VARIABLES
 */

int g_nPatchSize =                  -1;
int g_nPatchOffs =                  -1;
int g_nPatchOrigBytes[512] =        { 0, ... };

Address g_hPatchAddr =              Address_Null;

bool g_bPatchStatus =               false;


/**
 * CUSTOM PUBLIC FORWARDS
 */

public void OnPluginStart()
{
    OnMapStart();
}

public void OnMapStart()
{
    static Handle hData = INVALID_HANDLE;
    static int nIter = 0;

    if
    (
        (
            (hData = LoadGameConfigFile("movement_unlocker.games"))
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

public void OnMapEnd()
{
    static int nIter = 0;

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
