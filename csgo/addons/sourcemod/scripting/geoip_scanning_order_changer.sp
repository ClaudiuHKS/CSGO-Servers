#include <sourcemod>
#include <GeoResolver>

public Plugin myinfo =
{
    name            =   "GeoResolver: Scanning Order Changer"                   , \
    author          =   "Hattrick HKS (claudiuhks)"                             , \
    description     =   "Changes The Order Of Scanning"                         , \
    version         =   __DATE__                                                , \
    url             =   "https://forums.alliedmods.net/showthread.php?t=267805" ,
};

public void OnPluginStart()
{
    GeoR_Order(GEOIP_PAID_FIRST);
}
