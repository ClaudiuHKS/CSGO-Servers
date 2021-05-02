#include "extension.h"

GeoResolver g_GeoResolver;  SMEXT_LINK(&g_GeoResolver);

static MMDB_s g_City2Lite;  static bool g_bCity2Lite = false;   // GeoLite2-City.mmdb
static MMDB_s g_City2Paid;  static bool g_bCity2Paid = false;   // GeoIP2-City.mmdb

static GeoIP* g_pCityLite;  static bool g_bCityLite = false;    // GeoLiteCity.dat
static GeoIP* g_pCityPaid;  static bool g_bCityPaid = false;    // GeoIPCity.dat

static GeoIP* g_pIspLite;   static bool g_bIspLite = false;     // GeoLiteISP.dat
static GeoIP* g_pIspPaid;   static bool g_bIspPaid = false;     // GeoIPISP.dat

static unsigned int g_uiDb = GR_GEO_DB_NONE;
static unsigned int g_uiOrder = GR_GEO_ORDER_LITE_FIRST;

static const float g_fPi = xTo(M_PI, float);
static const float g_fPi180 = g_fPi / 180.0f;

static const unsigned int g_uiZero = xTo(0, unsigned int);
static const unsigned int g_uiCountryCodes = sizeof(GeoIP_country_code) / sizeof(GeoIP_country_code[0]);

static const char* g_pszcInvalid = grInvalid;
static const char* g_pszcLibrary = grLibrary;

static bool GR_RetrieveContinentNameByContinentCode(const SourceHook::String Code, SourceHook::String& Name)
{
    static const char* ppszcCodes[] =
    {
        "EU",       "AS",   "SA",               "NA",               "AF",       "AN",           "OC",
    };

    static const char* ppszcNames[] =
    {
        "Europe",   "Asia", "South America",    "North America",    "Africa",   "Antarctica",   "Australia & Oceania",
    };

    static const unsigned int uiContinents = sizeof(ppszcCodes) / sizeof(ppszcCodes[0]);

    static unsigned int uiIter;

    if (Code.empty() == false)
    {
        for (uiIter = g_uiZero; uiIter < uiContinents; uiIter++)
        {
            if (Code.compare(ppszcCodes[uiIter]) == 0)
            {
                Name.assign(ppszcNames[uiIter]);

                return true;
            }
        }
    }

    Name.assign(g_pszcInvalid);

    return false;
}

static bool GR_StripIpAddrPort(SourceHook::String& Ip)
{
    static unsigned int uiPos;

    if (Ip.empty() == false)
    {
        uiPos = Ip.find(':');

        if (uiPos != SourceHook::String::npos)
        {
            Ip.at(uiPos, '\0');

            return true;
        }
    }

    return false;
}

static float GR_RetrieveGeoDistance
(
    const float fLa1,
    const float fLo1,

    const float fLa2,
    const float fLo2,

    const bool bImp = false,
    const bool bRad = false
)
{
    static float fEarthRadius;

    static float fLa1Rad;
    static float fLo1Rad;

    static float fLa2Rad;
    static float fLo2Rad;

    if (fLa1 == 0.0f && fLo1 == 0.0f && fLa2 == 0.0f && fLo2 == 0.0f)
    {
        return 0.0f;
    }

    if (bImp == true)
    {
        fEarthRadius = grEarthRadiusMi;
    }

    else
    {
        fEarthRadius = grEarthRadiusKm;
    }

    if (bRad == false)
    {
        fLa1Rad = fLa1 * g_fPi180;
        fLo1Rad = fLo1 * g_fPi180;

        fLa2Rad = fLa2 * g_fPi180;
        fLo2Rad = fLo2 * g_fPi180;
    }

    else
    {
        fLa1Rad = fLa1;
        fLo1Rad = fLo1;

        fLa2Rad = fLa2;
        fLo2Rad = fLo2;
    }

    return fEarthRadius * acosf(sinf(fLa1Rad) * sinf(fLa2Rad) + cosf(fLa1Rad) * cosf(fLa2Rad) * cosf(fLo2Rad - fLo1Rad));
}

static bool GR_RetrieveIpGeoInfo
(
    const SourceHook::String Ip,

    SourceHook::String& Code,
    SourceHook::String& Code3,
    SourceHook::String& Country,
    SourceHook::String& City,
    SourceHook::String& RegionCode,
    SourceHook::String& Region,
    SourceHook::String& TimeZone,
    SourceHook::String& PostalCode,
    SourceHook::String& ContinCode,
    SourceHook::String& Contin,
    SourceHook::String& AutoSysOrg,
    SourceHook::String& Isp,

    float& fLa,
    float& fLo
)
{
    static MMDB_lookup_result_s Res;

    static MMDB_entry_data_s Entry;

    static GeoIPRecord* pRecord;

    static SourceHook::String RawIp;

    static char* pszBuffer;

    static const char* pszcBuffer;

    static int nErr[2];

    static unsigned int uiIter;

    Code.assign(g_pszcInvalid);
    Code3.assign(g_pszcInvalid);
    Country.assign(g_pszcInvalid);
    City.assign(g_pszcInvalid);
    RegionCode.assign(g_pszcInvalid);
    Region.assign(g_pszcInvalid);
    TimeZone.assign(g_pszcInvalid);
    PostalCode.assign(g_pszcInvalid);
    ContinCode.assign(g_pszcInvalid);
    Contin.assign(g_pszcInvalid);
    AutoSysOrg.assign(g_pszcInvalid);
    Isp.assign(g_pszcInvalid);

    fLa = 0.0f;
    fLo = 0.0f;

    if (Ip.empty() == true)
    {
        return false;
    }

    RawIp.assign(Ip);

    GR_StripIpAddrPort(RawIp);

    if (g_uiOrder == GR_GEO_ORDER_LITE_FIRST)
    {
        if (g_bCity2Lite)
        {
            Res = MMDB_lookup_string(&g_City2Lite, RawIp.c_str(), &nErr[0], &nErr[1]);

            if (nErr[0] == grGood && nErr[1] == grGood && grFoundEntry)
            {
                if (Code.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "country", "iso_code", NULL) == grGood && grHasData) {
                    Code.assign(Entry.utf8_string); Code.at(Entry.data_size, '\0');
                }

                if (Code3.compare(g_pszcInvalid) == 0 && Code.compare(g_pszcInvalid))
                {
                    for (uiIter = g_uiZero; uiIter < g_uiCountryCodes; uiIter++)
                    {
                        if (Code.compare(GeoIP_country_code[uiIter]) == 0)
                        {
                            Code3.assign(GeoIP_country_code3[uiIter]);

                            break;
                        }
                    }
                }

                if (Country.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "country", "names", "en", NULL) == grGood && grHasData) {
                    Country.assign(Entry.utf8_string); Country.at(Entry.data_size, '\0');
                }

                if (City.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "city", "names", "en", NULL) == grGood && grHasData) {
                    City.assign(Entry.utf8_string); City.at(Entry.data_size, '\0');
                }

                if (RegionCode.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "subdivisions", "0", "iso_code", NULL) == grGood && grHasData) {
                    RegionCode.assign(Entry.utf8_string); RegionCode.at(Entry.data_size, '\0');
                }

                if (Region.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "subdivisions", "0", "names", "en", NULL) == grGood && grHasData) {
                    Region.assign(Entry.utf8_string); Region.at(Entry.data_size, '\0');
                }

                if (TimeZone.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "location", "time_zone", NULL) == grGood && grHasData) {
                    TimeZone.assign(Entry.utf8_string); TimeZone.at(Entry.data_size, '\0');
                }

                if (PostalCode.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "postal", "code", NULL) == grGood && grHasData) {
                    PostalCode.assign(Entry.utf8_string); PostalCode.at(Entry.data_size, '\0');
                }

                if (ContinCode.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "continent", "code", NULL) == grGood && grHasData) {
                    ContinCode.assign(Entry.utf8_string); ContinCode.at(Entry.data_size, '\0');
                }

                if (Contin.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "continent", "names", "en", NULL) == grGood && grHasData) {
                    Contin.assign(Entry.utf8_string); Contin.at(Entry.data_size, '\0');
                }

                if (AutoSysOrg.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "traits", "autonomous_system_organization", NULL) == grGood && grHasData) {
                    AutoSysOrg.assign(Entry.utf8_string); AutoSysOrg.at(Entry.data_size, '\0');
                }

                if (Isp.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "traits", "isp", NULL) == grGood && grHasData) {
                    Isp.assign(Entry.utf8_string); Isp.at(Entry.data_size, '\0');
                }

                if (fLa == 0.0f && MMDB_get_value(&Res.entry, &Entry, "location", "latitude", NULL) == grGood && grHasData && Entry.float_value != 0.0f) {
                    fLa = Entry.float_value;
                }

                if (fLo == 0.0f && MMDB_get_value(&Res.entry, &Entry, "location", "longitude", NULL) == grGood && grHasData && Entry.float_value != 0.0f) {
                    fLo = Entry.float_value;
                }
            }
        }

        if (g_bCity2Paid)
        {
            Res = MMDB_lookup_string(&g_City2Paid, RawIp.c_str(), &nErr[0], &nErr[1]);

            if (nErr[0] == grGood && nErr[1] == grGood && grFoundEntry)
            {
                if (Code.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "country", "iso_code", NULL) == grGood && grHasData) {
                    Code.assign(Entry.utf8_string); Code.at(Entry.data_size, '\0');
                }

                if (Code3.compare(g_pszcInvalid) == 0 && Code.compare(g_pszcInvalid))
                {
                    for (uiIter = g_uiZero; uiIter < g_uiCountryCodes; uiIter++)
                    {
                        if (Code.compare(GeoIP_country_code[uiIter]) == 0)
                        {
                            Code3.assign(GeoIP_country_code3[uiIter]);

                            break;
                        }
                    }
                }

                if (Country.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "country", "names", "en", NULL) == grGood && grHasData) {
                    Country.assign(Entry.utf8_string); Country.at(Entry.data_size, '\0');
                }

                if (City.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "city", "names", "en", NULL) == grGood && grHasData) {
                    City.assign(Entry.utf8_string); City.at(Entry.data_size, '\0');
                }

                if (RegionCode.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "subdivisions", "0", "iso_code", NULL) == grGood && grHasData) {
                    RegionCode.assign(Entry.utf8_string); RegionCode.at(Entry.data_size, '\0');
                }

                if (Region.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "subdivisions", "0", "names", "en", NULL) == grGood && grHasData) {
                    Region.assign(Entry.utf8_string); Region.at(Entry.data_size, '\0');
                }

                if (TimeZone.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "location", "time_zone", NULL) == grGood && grHasData) {
                    TimeZone.assign(Entry.utf8_string); TimeZone.at(Entry.data_size, '\0');
                }

                if (PostalCode.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "postal", "code", NULL) == grGood && grHasData) {
                    PostalCode.assign(Entry.utf8_string); PostalCode.at(Entry.data_size, '\0');
                }

                if (ContinCode.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "continent", "code", NULL) == grGood && grHasData) {
                    ContinCode.assign(Entry.utf8_string); ContinCode.at(Entry.data_size, '\0');
                }

                if (Contin.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "continent", "names", "en", NULL) == grGood && grHasData) {
                    Contin.assign(Entry.utf8_string); Contin.at(Entry.data_size, '\0');
                }

                if (AutoSysOrg.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "traits", "autonomous_system_organization", NULL) == grGood && grHasData) {
                    AutoSysOrg.assign(Entry.utf8_string); AutoSysOrg.at(Entry.data_size, '\0');
                }

                if (Isp.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "traits", "isp", NULL) == grGood && grHasData) {
                    Isp.assign(Entry.utf8_string); Isp.at(Entry.data_size, '\0');
                }

                if (fLa == 0.0f && MMDB_get_value(&Res.entry, &Entry, "location", "latitude", NULL) == grGood && grHasData && Entry.float_value != 0.0f) {
                    fLa = Entry.float_value;
                }

                if (fLo == 0.0f && MMDB_get_value(&Res.entry, &Entry, "location", "longitude", NULL) == grGood && grHasData && Entry.float_value != 0.0f) {
                    fLo = Entry.float_value;
                }
            }
        }
    }

    else
    {
        if (g_bCity2Paid)
        {
            Res = MMDB_lookup_string(&g_City2Paid, RawIp.c_str(), &nErr[0], &nErr[1]);

            if (nErr[0] == grGood && nErr[1] == grGood && grFoundEntry)
            {
                if (Code.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "country", "iso_code", NULL) == grGood && grHasData) {
                    Code.assign(Entry.utf8_string); Code.at(Entry.data_size, '\0');
                }

                if (Code3.compare(g_pszcInvalid) == 0 && Code.compare(g_pszcInvalid))
                {
                    for (uiIter = g_uiZero; uiIter < g_uiCountryCodes; uiIter++)
                    {
                        if (Code.compare(GeoIP_country_code[uiIter]) == 0)
                        {
                            Code3.assign(GeoIP_country_code3[uiIter]);

                            break;
                        }
                    }
                }

                if (Country.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "country", "names", "en", NULL) == grGood && grHasData) {
                    Country.assign(Entry.utf8_string); Country.at(Entry.data_size, '\0');
                }

                if (City.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "city", "names", "en", NULL) == grGood && grHasData) {
                    City.assign(Entry.utf8_string); City.at(Entry.data_size, '\0');
                }

                if (RegionCode.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "subdivisions", "0", "iso_code", NULL) == grGood && grHasData) {
                    RegionCode.assign(Entry.utf8_string); RegionCode.at(Entry.data_size, '\0');
                }

                if (Region.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "subdivisions", "0", "names", "en", NULL) == grGood && grHasData) {
                    Region.assign(Entry.utf8_string); Region.at(Entry.data_size, '\0');
                }

                if (TimeZone.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "location", "time_zone", NULL) == grGood && grHasData) {
                    TimeZone.assign(Entry.utf8_string); TimeZone.at(Entry.data_size, '\0');
                }

                if (PostalCode.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "postal", "code", NULL) == grGood && grHasData) {
                    PostalCode.assign(Entry.utf8_string); PostalCode.at(Entry.data_size, '\0');
                }

                if (ContinCode.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "continent", "code", NULL) == grGood && grHasData) {
                    ContinCode.assign(Entry.utf8_string); ContinCode.at(Entry.data_size, '\0');
                }

                if (Contin.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "continent", "names", "en", NULL) == grGood && grHasData) {
                    Contin.assign(Entry.utf8_string); Contin.at(Entry.data_size, '\0');
                }

                if (AutoSysOrg.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "traits", "autonomous_system_organization", NULL) == grGood && grHasData) {
                    AutoSysOrg.assign(Entry.utf8_string); AutoSysOrg.at(Entry.data_size, '\0');
                }

                if (Isp.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "traits", "isp", NULL) == grGood && grHasData) {
                    Isp.assign(Entry.utf8_string); Isp.at(Entry.data_size, '\0');
                }

                if (fLa == 0.0f && MMDB_get_value(&Res.entry, &Entry, "location", "latitude", NULL) == grGood && grHasData && Entry.float_value != 0.0f) {
                    fLa = Entry.float_value;
                }

                if (fLo == 0.0f && MMDB_get_value(&Res.entry, &Entry, "location", "longitude", NULL) == grGood && grHasData && Entry.float_value != 0.0f) {
                    fLo = Entry.float_value;
                }
            }
        }

        if (g_bCity2Lite)
        {
            Res = MMDB_lookup_string(&g_City2Lite, RawIp.c_str(), &nErr[0], &nErr[1]);

            if (nErr[0] == grGood && nErr[1] == grGood && grFoundEntry)
            {
                if (Code.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "country", "iso_code", NULL) == grGood && grHasData) {
                    Code.assign(Entry.utf8_string); Code.at(Entry.data_size, '\0');
                }

                if (Code3.compare(g_pszcInvalid) == 0 && Code.compare(g_pszcInvalid))
                {
                    for (uiIter = g_uiZero; uiIter < g_uiCountryCodes; uiIter++)
                    {
                        if (Code.compare(GeoIP_country_code[uiIter]) == 0)
                        {
                            Code3.assign(GeoIP_country_code3[uiIter]);

                            break;
                        }
                    }
                }

                if (Country.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "country", "names", "en", NULL) == grGood && grHasData) {
                    Country.assign(Entry.utf8_string); Country.at(Entry.data_size, '\0');
                }

                if (City.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "city", "names", "en", NULL) == grGood && grHasData) {
                    City.assign(Entry.utf8_string); City.at(Entry.data_size, '\0');
                }

                if (RegionCode.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "subdivisions", "0", "iso_code", NULL) == grGood && grHasData) {
                    RegionCode.assign(Entry.utf8_string); RegionCode.at(Entry.data_size, '\0');
                }

                if (Region.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "subdivisions", "0", "names", "en", NULL) == grGood && grHasData) {
                    Region.assign(Entry.utf8_string); Region.at(Entry.data_size, '\0');
                }

                if (TimeZone.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "location", "time_zone", NULL) == grGood && grHasData) {
                    TimeZone.assign(Entry.utf8_string); TimeZone.at(Entry.data_size, '\0');
                }

                if (PostalCode.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "postal", "code", NULL) == grGood && grHasData) {
                    PostalCode.assign(Entry.utf8_string); PostalCode.at(Entry.data_size, '\0');
                }

                if (ContinCode.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "continent", "code", NULL) == grGood && grHasData) {
                    ContinCode.assign(Entry.utf8_string); ContinCode.at(Entry.data_size, '\0');
                }

                if (Contin.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "continent", "names", "en", NULL) == grGood && grHasData) {
                    Contin.assign(Entry.utf8_string); Contin.at(Entry.data_size, '\0');
                }

                if (AutoSysOrg.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "traits", "autonomous_system_organization", NULL) == grGood && grHasData) {
                    AutoSysOrg.assign(Entry.utf8_string); AutoSysOrg.at(Entry.data_size, '\0');
                }

                if (Isp.compare(g_pszcInvalid) == 0 && MMDB_get_value(&Res.entry, &Entry, "traits", "isp", NULL) == grGood && grHasData) {
                    Isp.assign(Entry.utf8_string); Isp.at(Entry.data_size, '\0');
                }

                if (fLa == 0.0f && MMDB_get_value(&Res.entry, &Entry, "location", "latitude", NULL) == grGood && grHasData && Entry.float_value != 0.0f) {
                    fLa = Entry.float_value;
                }

                if (fLo == 0.0f && MMDB_get_value(&Res.entry, &Entry, "location", "longitude", NULL) == grGood && grHasData && Entry.float_value != 0.0f) {
                    fLo = Entry.float_value;
                }
            }
        }
    }

    if (g_uiOrder == GR_GEO_ORDER_LITE_FIRST)
    {
        if (g_bCityLite)
        {
            pRecord = GeoIP_record_by_addr(g_pCityLite, RawIp.c_str());

            if (pRecord)
            {
                if (Code.compare(g_pszcInvalid) == 0 && pRecord->country_code && *pRecord->country_code != '\0') {
                    Code.assign(pRecord->country_code);
                }

                if (Code3.compare(g_pszcInvalid) == 0 && pRecord->country_code3 && *pRecord->country_code3 != '\0') {
                    Code3.assign(pRecord->country_code3);
                }

                if (Country.compare(g_pszcInvalid) == 0 && pRecord->country_name && *pRecord->country_name != '\0') {
                    Country.assign(pRecord->country_name);
                }

                if (City.compare(g_pszcInvalid) == 0 && pRecord->city && *pRecord->city != '\0') {
                    City.assign(pRecord->city);
                }

                if (RegionCode.compare(g_pszcInvalid) == 0 && pRecord->region && *pRecord->region != '\0') {
                    RegionCode.assign(pRecord->region);
                }

                if (Region.compare(g_pszcInvalid) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
                    pszcBuffer = GeoIP_region_name_by_code(pRecord->country_code, pRecord->region);

                    Region.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcInvalid);
                }

                if (TimeZone.compare(g_pszcInvalid) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
                    pszcBuffer = GeoIP_time_zone_by_country_and_region(pRecord->country_code, pRecord->region);

                    TimeZone.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcInvalid);
                }

                if (PostalCode.compare(g_pszcInvalid) == 0 && pRecord->postal_code && *pRecord->postal_code != '\0') {
                    PostalCode.assign(pRecord->postal_code);
                }

                if (ContinCode.compare(g_pszcInvalid) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
                    ContinCode.assign(pRecord->continent_code);
                }

                if (Contin.compare(g_pszcInvalid) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
                    GR_RetrieveContinentNameByContinentCode(pRecord->continent_code, Contin);
                }

                if (fLa == 0.0f && pRecord->latitude != 0.0f) {
                    fLa = pRecord->latitude;
                }

                if (fLo == 0.0f && pRecord->longitude != 0.0f) {
                    fLo = pRecord->longitude;
                }

                GeoIPRecord_delete(pRecord);
            }
        }

        if (g_bCityPaid)
        {
            pRecord = GeoIP_record_by_addr(g_pCityPaid, RawIp.c_str());

            if (pRecord)
            {
                if (Code.compare(g_pszcInvalid) == 0 && pRecord->country_code && *pRecord->country_code != '\0') {
                    Code.assign(pRecord->country_code);
                }

                if (Code3.compare(g_pszcInvalid) == 0 && pRecord->country_code3 && *pRecord->country_code3 != '\0') {
                    Code3.assign(pRecord->country_code3);
                }

                if (Country.compare(g_pszcInvalid) == 0 && pRecord->country_name && *pRecord->country_name != '\0') {
                    Country.assign(pRecord->country_name);
                }

                if (City.compare(g_pszcInvalid) == 0 && pRecord->city && *pRecord->city != '\0') {
                    City.assign(pRecord->city);
                }

                if (RegionCode.compare(g_pszcInvalid) == 0 && pRecord->region && *pRecord->region != '\0') {
                    RegionCode.assign(pRecord->region);
                }

                if (Region.compare(g_pszcInvalid) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
                    pszcBuffer = GeoIP_region_name_by_code(pRecord->country_code, pRecord->region);

                    Region.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcInvalid);
                }

                if (TimeZone.compare(g_pszcInvalid) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
                    pszcBuffer = GeoIP_time_zone_by_country_and_region(pRecord->country_code, pRecord->region);

                    TimeZone.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcInvalid);
                }

                if (PostalCode.compare(g_pszcInvalid) == 0 && pRecord->postal_code && *pRecord->postal_code != '\0') {
                    PostalCode.assign(pRecord->postal_code);
                }

                if (ContinCode.compare(g_pszcInvalid) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
                    ContinCode.assign(pRecord->continent_code);
                }

                if (Contin.compare(g_pszcInvalid) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
                    GR_RetrieveContinentNameByContinentCode(pRecord->continent_code, Contin);
                }

                if (fLa == 0.0f && pRecord->latitude != 0.0f) {
                    fLa = pRecord->latitude;
                }

                if (fLo == 0.0f && pRecord->longitude != 0.0f) {
                    fLo = pRecord->longitude;
                }

                GeoIPRecord_delete(pRecord);
            }
        }
    }

    else
    {
        if (g_bCityPaid)
        {
            pRecord = GeoIP_record_by_addr(g_pCityPaid, RawIp.c_str());

            if (pRecord)
            {
                if (Code.compare(g_pszcInvalid) == 0 && pRecord->country_code && *pRecord->country_code != '\0') {
                    Code.assign(pRecord->country_code);
                }

                if (Code3.compare(g_pszcInvalid) == 0 && pRecord->country_code3 && *pRecord->country_code3 != '\0') {
                    Code3.assign(pRecord->country_code3);
                }

                if (Country.compare(g_pszcInvalid) == 0 && pRecord->country_name && *pRecord->country_name != '\0') {
                    Country.assign(pRecord->country_name);
                }

                if (City.compare(g_pszcInvalid) == 0 && pRecord->city && *pRecord->city != '\0') {
                    City.assign(pRecord->city);
                }

                if (RegionCode.compare(g_pszcInvalid) == 0 && pRecord->region && *pRecord->region != '\0') {
                    RegionCode.assign(pRecord->region);
                }

                if (Region.compare(g_pszcInvalid) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
                    pszcBuffer = GeoIP_region_name_by_code(pRecord->country_code, pRecord->region);

                    Region.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcInvalid);
                }

                if (TimeZone.compare(g_pszcInvalid) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
                    pszcBuffer = GeoIP_time_zone_by_country_and_region(pRecord->country_code, pRecord->region);

                    TimeZone.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcInvalid);
                }

                if (PostalCode.compare(g_pszcInvalid) == 0 && pRecord->postal_code && *pRecord->postal_code != '\0') {
                    PostalCode.assign(pRecord->postal_code);
                }

                if (ContinCode.compare(g_pszcInvalid) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
                    ContinCode.assign(pRecord->continent_code);
                }

                if (Contin.compare(g_pszcInvalid) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
                    GR_RetrieveContinentNameByContinentCode(pRecord->continent_code, Contin);
                }

                if (fLa == 0.0f && pRecord->latitude != 0.0f) {
                    fLa = pRecord->latitude;
                }

                if (fLo == 0.0f && pRecord->longitude != 0.0f) {
                    fLo = pRecord->longitude;
                }

                GeoIPRecord_delete(pRecord);
            }
        }

        if (g_bCityLite)
        {
            pRecord = GeoIP_record_by_addr(g_pCityLite, RawIp.c_str());

            if (pRecord)
            {
                if (Code.compare(g_pszcInvalid) == 0 && pRecord->country_code && *pRecord->country_code != '\0') {
                    Code.assign(pRecord->country_code);
                }

                if (Code3.compare(g_pszcInvalid) == 0 && pRecord->country_code3 && *pRecord->country_code3 != '\0') {
                    Code3.assign(pRecord->country_code3);
                }

                if (Country.compare(g_pszcInvalid) == 0 && pRecord->country_name && *pRecord->country_name != '\0') {
                    Country.assign(pRecord->country_name);
                }

                if (City.compare(g_pszcInvalid) == 0 && pRecord->city && *pRecord->city != '\0') {
                    City.assign(pRecord->city);
                }

                if (RegionCode.compare(g_pszcInvalid) == 0 && pRecord->region && *pRecord->region != '\0') {
                    RegionCode.assign(pRecord->region);
                }

                if (Region.compare(g_pszcInvalid) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
                    pszcBuffer = GeoIP_region_name_by_code(pRecord->country_code, pRecord->region);

                    Region.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcInvalid);
                }

                if (TimeZone.compare(g_pszcInvalid) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
                    pszcBuffer = GeoIP_time_zone_by_country_and_region(pRecord->country_code, pRecord->region);

                    TimeZone.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcInvalid);
                }

                if (PostalCode.compare(g_pszcInvalid) == 0 && pRecord->postal_code && *pRecord->postal_code != '\0') {
                    PostalCode.assign(pRecord->postal_code);
                }

                if (ContinCode.compare(g_pszcInvalid) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
                    ContinCode.assign(pRecord->continent_code);
                }

                if (Contin.compare(g_pszcInvalid) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
                    GR_RetrieveContinentNameByContinentCode(pRecord->continent_code, Contin);
                }

                if (fLa == 0.0f && pRecord->latitude != 0.0f) {
                    fLa = pRecord->latitude;
                }

                if (fLo == 0.0f && pRecord->longitude != 0.0f) {
                    fLo = pRecord->longitude;
                }

                GeoIPRecord_delete(pRecord);
            }
        }
    }

    if (g_uiOrder == GR_GEO_ORDER_LITE_FIRST)
    {
        if (g_bIspLite)
        {
            if (Isp.compare(g_pszcInvalid) == 0)
            {
                pszBuffer = GeoIP_org_by_addr(g_pIspLite, RawIp.c_str());

                if (pszBuffer)
                {
                    if (*pszBuffer != '\0')
                    {
                        Isp.assign(pszBuffer);
                    }

                    free(pszBuffer);
                }
            }
        }

        if (g_bIspPaid)
        {
            if (Isp.compare(g_pszcInvalid) == 0)
            {
                pszBuffer = GeoIP_org_by_addr(g_pIspPaid, RawIp.c_str());

                if (pszBuffer)
                {
                    if (*pszBuffer != '\0')
                    {
                        Isp.assign(pszBuffer);
                    }

                    free(pszBuffer);
                }
            }
        }
    }

    else
    {
        if (g_bIspPaid)
        {
            if (Isp.compare(g_pszcInvalid) == 0)
            {
                pszBuffer = GeoIP_org_by_addr(g_pIspPaid, RawIp.c_str());

                if (pszBuffer)
                {
                    if (*pszBuffer != '\0')
                    {
                        Isp.assign(pszBuffer);
                    }

                    free(pszBuffer);
                }
            }
        }

        if (g_bIspLite)
        {
            if (Isp.compare(g_pszcInvalid) == 0)
            {
                pszBuffer = GeoIP_org_by_addr(g_pIspLite, RawIp.c_str());

                if (pszBuffer)
                {
                    if (*pszBuffer != '\0')
                    {
                        Isp.assign(pszBuffer);
                    }

                    free(pszBuffer);
                }
            }
        }
    }

    return true;
}

static bool GR_DirExists(const char* pszcDirPath)
{

#if !defined WIN32

    static DIR* pDir;

#else

    static unsigned long ulAttr;

#endif

    if (!pszcDirPath || *pszcDirPath == '\0')
    {
        return false;
    }

#if !defined WIN32

    pDir = opendir(pszcDirPath);

    if (pDir)
    {
        closedir(pDir);

        return true;
    }

    return false;

#else

    ulAttr = GetFileAttributesA(pszcDirPath);

    if (ulAttr == INVALID_FILE_ATTRIBUTES)
    {
        return false;
    }

    if (!(ulAttr & FILE_ATTRIBUTE_DIRECTORY))
    {
        return false;
    }

    return true;

#endif

}

static bool GR_FileExists(const char* pszcFilePath)
{
    static FILE* pFile;

    if (!pszcFilePath || *pszcFilePath == '\0')
    {
        return false;
    }

    pFile = fopen(pszcFilePath, "r");

    if (pFile)
    {
        fclose(pFile);

        return true;
    }

    return false;
}

static bool GR_Startup()
{
    static char szPath[256];
    static char szTime[256];

    static char* pszBuffer;

    static time_t Stamp;

    g_pSM->BuildPath(Path_SM, szPath, sizeof(szPath), "data/GeoResolver/GeoLite2-City.mmdb");

    if (MMDB_open(szPath, MMDB_MODE_MMAP, &g_City2Lite) == grGood)
    {
        Stamp = xTo(g_City2Lite.metadata.build_epoch, time_t);

        strftime(szTime, sizeof(szTime), "%F %T UTC", gmtime(&Stamp));

        g_pSM->LogMessage(myself, "Loaded GeoLite2-City.mmdb, %s.", szTime);

        g_bCity2Lite = true;

        g_uiDb |= GR_GEO_DB_CITY2_LITE;
    }

    else
    {
        g_pSM->LogMessage(myself, "GeoLite2-City.mmdb unavailable.");

        g_bCity2Lite = false;

        g_uiDb &= ~GR_GEO_DB_CITY2_LITE;
    }

    g_pSM->BuildPath(Path_SM, szPath, sizeof(szPath), "data/GeoResolver/GeoIP2-City.mmdb");

    if (MMDB_open(szPath, MMDB_MODE_MMAP, &g_City2Paid) == grGood)
    {
        Stamp = xTo(g_City2Paid.metadata.build_epoch, time_t);

        strftime(szTime, sizeof(szTime), "%F %T UTC", gmtime(&Stamp));

        g_pSM->LogMessage(myself, "Loaded GeoIP2-City.mmdb, %s.", szTime);

        g_bCity2Paid = true;

        g_uiDb |= GR_GEO_DB_CITY2_PAID;
    }

    else
    {
        g_pSM->LogMessage(myself, "GeoIP2-City.mmdb unavailable.");

        g_bCity2Paid = false;

        g_uiDb &= ~GR_GEO_DB_CITY2_PAID;
    }

    g_pSM->BuildPath(Path_SM, szPath, sizeof(szPath), "data/GeoResolver/GeoLiteCity.dat");

    if ((g_pCityLite = GeoIP_open(szPath, GEOIP_INDEX_CACHE)))
    {
        pszBuffer = GeoIP_database_info(g_pCityLite);

        if (pszBuffer)
        {
            if (*pszBuffer != '\0')
            {
                g_pSM->LogMessage(myself, "Loaded GeoLiteCity.dat, %s.", pszBuffer);
            }

            else
            {
                g_pSM->LogMessage(myself, "Loaded GeoLiteCity.dat, unknown information.");
            }

            free(pszBuffer);
        }

        else
        {
            g_pSM->LogMessage(myself, "Loaded GeoLiteCity.dat, unknown information.");
        }

        GeoIP_set_charset(g_pCityLite, GEOIP_CHARSET_UTF8);

        g_bCityLite = true;

        g_uiDb |= GR_GEO_DB_CITY_LITE;
    }

    else
    {
        g_pSM->LogMessage(myself, "GeoLiteCity.dat unavailable.");

        g_bCityLite = false;

        g_uiDb &= ~GR_GEO_DB_CITY_LITE;
    }

    g_pSM->BuildPath(Path_SM, szPath, sizeof(szPath), "data/GeoResolver/GeoIPCity.dat");

    if ((g_pCityPaid = GeoIP_open(szPath, GEOIP_INDEX_CACHE)))
    {
        pszBuffer = GeoIP_database_info(g_pCityPaid);

        if (pszBuffer)
        {
            if (*pszBuffer != '\0')
            {
                g_pSM->LogMessage(myself, "Loaded GeoIPCity.dat, %s.", pszBuffer);
            }

            else
            {
                g_pSM->LogMessage(myself, "Loaded GeoIPCity.dat, unknown information.");
            }

            free(pszBuffer);
        }

        else
        {
            g_pSM->LogMessage(myself, "Loaded GeoIPCity.dat, unknown information.");
        }

        GeoIP_set_charset(g_pCityPaid, GEOIP_CHARSET_UTF8);

        g_bCityPaid = true;

        g_uiDb |= GR_GEO_DB_CITY_PAID;
    }

    else
    {
        g_pSM->LogMessage(myself, "GeoIPCity.dat unavailable.");

        g_bCityPaid = false;

        g_uiDb &= ~GR_GEO_DB_CITY_PAID;
    }

    g_pSM->BuildPath(Path_SM, szPath, sizeof(szPath), "data/GeoResolver/GeoLiteISP.dat");

    if ((g_pIspLite = GeoIP_open(szPath, GEOIP_INDEX_CACHE)))
    {
        pszBuffer = GeoIP_database_info(g_pIspLite);

        if (pszBuffer)
        {
            if (*pszBuffer != '\0')
            {
                g_pSM->LogMessage(myself, "Loaded GeoLiteISP.dat, %s.", pszBuffer);
            }

            else
            {
                g_pSM->LogMessage(myself, "Loaded GeoLiteISP.dat, unknown information.");
            }

            free(pszBuffer);
        }

        else
        {
            g_pSM->LogMessage(myself, "Loaded GeoLiteISP.dat, unknown information.");
        }

        GeoIP_set_charset(g_pIspLite, GEOIP_CHARSET_UTF8);

        g_bIspLite = true;

        g_uiDb |= GR_GEO_DB_ISP_LITE;
    }

    else
    {
        g_pSM->LogMessage(myself, "GeoLiteISP.dat unavailable.");

        g_bIspLite = false;

        g_uiDb &= ~GR_GEO_DB_ISP_LITE;
    }

    g_pSM->BuildPath(Path_SM, szPath, sizeof(szPath), "data/GeoResolver/GeoIPISP.dat");

    if ((g_pIspPaid = GeoIP_open(szPath, GEOIP_INDEX_CACHE)))
    {
        pszBuffer = GeoIP_database_info(g_pIspPaid);

        if (pszBuffer)
        {
            if (*pszBuffer != '\0')
            {
                g_pSM->LogMessage(myself, "Loaded GeoIPISP.dat, %s.", pszBuffer);
            }

            else
            {
                g_pSM->LogMessage(myself, "Loaded GeoIPISP.dat, unknown information.");
            }

            free(pszBuffer);
        }

        else
        {
            g_pSM->LogMessage(myself, "Loaded GeoIPISP.dat, unknown information.");
        }

        GeoIP_set_charset(g_pIspPaid, GEOIP_CHARSET_UTF8);

        g_bIspPaid = true;

        g_uiDb |= GR_GEO_DB_ISP_PAID;
    }

    else
    {
        g_pSM->LogMessage(myself, "GeoIPISP.dat unavailable.");

        g_bIspPaid = false;

        g_uiDb &= ~GR_GEO_DB_ISP_PAID;
    }

    return true;
}

static bool GR_Shutdown()
{
    g_uiDb = GR_GEO_DB_NONE;

    if (g_bCity2Lite)
    {
        MMDB_close(&g_City2Lite);

        g_bCity2Lite = false;
    }

    if (g_bCity2Paid)
    {
        MMDB_close(&g_City2Paid);

        g_bCity2Paid = false;
    }

    if (g_bCityLite)
    {
        GeoIP_delete(g_pCityLite);

        g_bCityLite = false;
    }

    if (g_bCityPaid)
    {
        GeoIP_delete(g_pCityPaid);

        g_bCityPaid = false;
    }

    if (g_bIspLite)
    {
        GeoIP_delete(g_pIspLite);

        g_bIspLite = false;
    }

    if (g_bIspPaid)
    {
        GeoIP_delete(g_pIspPaid);

        g_bIspPaid = false;
    }

    return true;
}

static int GeoR_Record(IPluginContext* pCtx, const int* pParams)
{
    static char* pszIp;

    static float fLa;
    static float fLo;

    static int* pLa;
    static int* pLo;

    static SourceHook::String Ip, Code, Code3, Country, City, RegionCode, Region, TimeZone, PostalCode, ContinCode, Contin, AutoSysOrg, Isp;

    Code.assign(g_pszcInvalid);
    Code3.assign(g_pszcInvalid);
    Country.assign(g_pszcInvalid);
    City.assign(g_pszcInvalid);
    RegionCode.assign(g_pszcInvalid);
    Region.assign(g_pszcInvalid);
    TimeZone.assign(g_pszcInvalid);
    PostalCode.assign(g_pszcInvalid);
    ContinCode.assign(g_pszcInvalid);
    Contin.assign(g_pszcInvalid);
    AutoSysOrg.assign(g_pszcInvalid);
    Isp.assign(g_pszcInvalid);

    fLa = 0.0f;
    fLo = 0.0f;

    pCtx->LocalToString(pParams[1], &pszIp);

    if (!pszIp || *pszIp == '\0')
    {
        Ip.clear();
    }

    else
    {
        Ip.assign(pszIp);

        GR_StripIpAddrPort(Ip);
    }

    GR_RetrieveIpGeoInfo(Ip, Code, Code3, Country, City, RegionCode, Region, TimeZone, PostalCode, ContinCode, Contin, AutoSysOrg, Isp, fLa, fLo);

    pCtx->StringToLocalUTF8(pParams[2], pParams[3], Code.c_str(), NULL);
    pCtx->StringToLocalUTF8(pParams[4], pParams[5], Code3.c_str(), NULL);
    pCtx->StringToLocalUTF8(pParams[6], pParams[7], Country.c_str(), NULL);
    pCtx->StringToLocalUTF8(pParams[8], pParams[9], City.c_str(), NULL);
    pCtx->StringToLocalUTF8(pParams[10], pParams[11], RegionCode.c_str(), NULL);
    pCtx->StringToLocalUTF8(pParams[12], pParams[13], Region.c_str(), NULL);
    pCtx->StringToLocalUTF8(pParams[14], pParams[15], TimeZone.c_str(), NULL);
    pCtx->StringToLocalUTF8(pParams[16], pParams[17], PostalCode.c_str(), NULL);
    pCtx->StringToLocalUTF8(pParams[18], pParams[19], ContinCode.c_str(), NULL);
    pCtx->StringToLocalUTF8(pParams[20], pParams[21], Contin.c_str(), NULL);
    pCtx->StringToLocalUTF8(pParams[22], pParams[23], AutoSysOrg.c_str(), NULL);
    pCtx->StringToLocalUTF8(pParams[24], pParams[25], Isp.c_str(), NULL);

    pCtx->LocalToPhysAddr(pParams[26], &pLa);

    if (pLa)
    {
        *pLa = sp_ftoc(fLa);
    }

    pCtx->LocalToPhysAddr(pParams[27], &pLo);

    if (pLo)
    {
        *pLo = sp_ftoc(fLo);
    }

    return 1;
}

static int GeoR_Db(IPluginContext*, const int*)
{
    return xTo(g_uiDb, int);
}

static int GeoR_Distance(IPluginContext*, const int* pParams)
{
    return sp_ftoc(GR_RetrieveGeoDistance(sp_ctof(pParams[1]), sp_ctof(pParams[2]), sp_ctof(pParams[3]), sp_ctof(pParams[4]), xTo(pParams[5], bool)));
}

static int GeoR_Reload(IPluginContext*, const int*)
{
    static const char* ppszcOldFiles[] =
    {
        "data/GeoResolver/GeoLite2-City.mmdb",          "data/GeoResolver/GeoIP2-City.mmdb",
        "data/GeoResolver/GeoLiteCity.dat",             "data/GeoResolver/GeoIPCity.dat",
        "data/GeoResolver/GeoLiteISP.dat",              "data/GeoResolver/GeoIPISP.dat",
    };

    static const char* ppszcNewFiles[] =
    {
        "data/GeoResolver/Update/GeoLite2-City.mmdb",   "data/GeoResolver/Update/GeoIP2-City.mmdb",
        "data/GeoResolver/Update/GeoLiteCity.dat",      "data/GeoResolver/Update/GeoIPCity.dat",
        "data/GeoResolver/Update/GeoLiteISP.dat",       "data/GeoResolver/Update/GeoIPISP.dat",
    };

    static const unsigned int uiFiles = sizeof(ppszcOldFiles) / sizeof(ppszcOldFiles[0]);

    static char szPath[256];

    static char szOldPath[256];
    static char szNewPath[256];

    static unsigned int uiIter;

    GR_Shutdown();

    g_pSM->BuildPath(Path_SM, szPath, sizeof(szPath), "data/GeoResolver/Update");

    if (GR_DirExists(szPath))
    {
        for (uiIter = g_uiZero; uiIter < uiFiles; uiIter++)
        {
            g_pSM->BuildPath(Path_SM, szNewPath, sizeof(szNewPath), ppszcNewFiles[uiIter]);

            if (GR_FileExists(szNewPath))
            {
                g_pSM->BuildPath(Path_SM, szOldPath, sizeof(szOldPath), ppszcOldFiles[uiIter]);

                if (GR_FileExists(szOldPath))
                {
                    remove(szOldPath);
                }

                rename(szNewPath, szOldPath);
            }
        }
    }

    GR_Startup();

    return 1;
}

static int GeoR_Order(IPluginContext*, const int* pParams)
{
    g_uiOrder = xTo(pParams[1], unsigned int);

    return 1;
}

static const sp_nativeinfo_t g_GeoResolverFuncs[] =
{
    { "GeoR_CompleteRecord",    GeoR_Record,    },
    { "GeoR_FullRecord",        GeoR_Record,    },
    { "GeoR_Record",            GeoR_Record,    },

    { "GeoR_Databases",         GeoR_Db,        },
    { "GeoR_Db",                GeoR_Db,        },

    { "GeoR_Distance",          GeoR_Distance,  },
    { "GeoR_Length",            GeoR_Distance,  },
    { "GeoR_Len",               GeoR_Distance,  },

    { "GeoR_Reload",            GeoR_Reload,    },
    { "GeoR_Refresh",           GeoR_Reload,    },
    { "GeoR_Restart",           GeoR_Reload,    },

    { "GeoR_ChangeOrder",       GeoR_Order,     },
    { "GeoR_Order",             GeoR_Order,     },
    { "GeoR_SetOrder",          GeoR_Order,     },

    { NULL,                     NULL,           },
};

bool GeoResolver::SDK_OnLoad(char*, unsigned int, bool)
{
    GR_Startup();

    g_pShareSys->AddNatives(myself, g_GeoResolverFuncs);

    g_pShareSys->RegisterLibrary(myself, g_pszcLibrary);

    return true;
}

void GeoResolver::SDK_OnUnload()
{
    GR_Shutdown();
}
