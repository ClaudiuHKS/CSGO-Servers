#pragma once

#include "smsdk_ext.h"

#define castValTo_( Value, Type )           ( ( Type ) ( Value ) )

#define grStrInvalid_                       ( "N/ A" )                      // (const char*) Yes, can be edited.
#define grStrLibrary_                       ( "GeoResolver" )

#define grGood                              ( MMDB_SUCCESS )

#define grHasData                           ( Entry.has_data == true )
#define grFoundEntry                        ( Res.found_entry == true )

#define grMeanEarthRadiusKm_                ( 6371.0f )                     // (float) The mean earth radius [Km].
#define grMeanEarthRadiusMi_                ( 3958.8f )                     // (float) The mean earth radius [Mi].

#define GR_GEO_DB_NONE                      ( 0 )

#define GR_GEO_DB_GEOIP2_CITY_LITE          ( 1 << 0 )                      // GeoLite2-City.mmdb
#define GR_GEO_DB_GEOIP2_CITY_PAID          ( 1 << 1 )                      // GeoIP2-City.mmdb

#define GR_GEO_DB_GEOIP_CITY_LITE           ( 1 << 2 )                      // GeoLiteCity.dat
#define GR_GEO_DB_GEOIP_CITY_PAID           ( 1 << 3 )                      // GeoIPCity.dat

#define GR_GEO_DB_GEOIP_ISP_LITE            ( 1 << 4 )                      // GeoLiteISP.dat
#define GR_GEO_DB_GEOIP_ISP_PAID            ( 1 << 5 )                      // GeoIPISP.dat

#define GR_GEO_ORDER_LITE_FIRST             ( 0 )
#define GR_GEO_ORDER_PAID_FIRST             ( 1 )

class GeoResolver : public SDKExtension
{

public:

    virtual bool SDK_OnLoad(char*, unsigned int, bool);

    virtual void SDK_OnUnload();

};
