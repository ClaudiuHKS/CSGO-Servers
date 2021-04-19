
/**
 * MAIN REQUIREMENTS
 */

#include < sourcemod >
#include < cstrike >
#include < sdktools >
#include < sdkhooks >


/**
 * CUSTOM INFORMATION
 */

public Plugin myinfo =
{
    name =          "Fast Duck",
    author =        "CARAMEL® HACK",
    description =   "Provides fast players ducking.",
    version =       __DATE__,
    url =           "https://hattrick.go.ro/",
};


/**
 * CUSTOM PUBLIC FORWARDS
 */

public Action OnPlayerRunCmd(int nEntity, int& nButtons, int& nImpulse, float fVelocity[3], float fAngles[3], int& nWeapon, int& nSubType, int& nCmdNum, int& nTickCount, int& nSeed, int nMouseDir[2])
{
    nButtons |= (1 << 22);
}
