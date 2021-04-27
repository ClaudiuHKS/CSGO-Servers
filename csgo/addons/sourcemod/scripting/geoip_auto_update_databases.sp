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
    GeoR_Reload();
}
