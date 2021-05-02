#pragma once

#include "smsdk_ext.h"

#include <math.h>

#include "maxminddb.h"
#include "GeoIPCity.h"
#include "sh_string.h"

#define xTo(Var, Type)              ((Type)(Var))

#define grInvalid                   ("N/ A")
#define grLibrary                   ("GeoResolver")

#define grGood                      (MMDB_SUCCESS)

#define grHasData                   (Entry.has_data == true)
#define grFoundEntry                (Res.found_entry == true)

#define grEarthRadiusKm             (6371.0f)
#define grEarthRadiusMi             (3958.8f)

#define GR_GEO_DB_NONE              (0)

#define GR_GEO_DB_CITY2_LITE        (1 << 0)    // GeoLite2-City.mmdb
#define GR_GEO_DB_CITY2_PAID        (1 << 1)    // GeoIP2-City.mmdb

#define GR_GEO_DB_CITY_LITE         (1 << 2)    // GeoLiteCity.dat
#define GR_GEO_DB_CITY_PAID         (1 << 3)    // GeoIPCity.dat

#define GR_GEO_DB_ISP_LITE          (1 << 4)    // GeoLiteISP.dat
#define GR_GEO_DB_ISP_PAID          (1 << 5)    // GeoIPISP.dat

#define GR_GEO_ORDER_LITE_FIRST     (0)
#define GR_GEO_ORDER_PAID_FIRST     (1)

class GeoResolver : public SDKExtension
{
public:

    virtual bool SDK_OnLoad(char*, unsigned int, bool);

    virtual void SDK_OnUnload();
};
