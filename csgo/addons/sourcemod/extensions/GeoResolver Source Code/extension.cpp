#include "extension.h"
#include "maxminddb.h"
#include "GeoIPCity.h"
#include "sh_string.h"

#if !defined WIN32

#	include <math.h>

#endif

GeoResolver g_GeoResolver; SMEXT_LINK(&g_GeoResolver);

static MMDB_s g_City2Lite; static bool g_bCity2Lite = false;			// GeoLite2-City.mmdb
static MMDB_s g_City2Paid; static bool g_bCity2Paid = false;			// GeoIP2-City.mmdb

static GeoIP* g_pCityLite = NULL; static bool g_bCityLite = false;		// GeoLiteCity.dat
static GeoIP* g_pCityPaid = NULL; static bool g_bCityPaid = false;		// GeoIPCity.dat

static GeoIP* g_pIspLite = NULL; static bool g_bIspLite = false;		// GeoLiteISP.dat
static GeoIP* g_pIspPaid = NULL; static bool g_bIspPaid = false;		// GeoIPISP.dat

static unsigned int g_uiDb = GR_GEO_DB_NONE, g_uiOrder = GR_GEO_ORDER_LITE_FIRST;
static const float g_fPi = castValTo_(M_PI, float); static const float g_fPi90 = g_fPi / 90.0f, g_fPi180 = g_fPi / 180.0f;
static const float g_fMeanEarthRadiusKm2 = grMeanEarthRadiusKm_ * 2.0f, g_fMeanEarthRadiusMi2 = grMeanEarthRadiusMi_ * 2.0f;
static const unsigned int g_uiZero = castValTo_(0, unsigned int), g_uiLocalCountryCodesNum = sizeof(GeoIP_country_code) / sizeof(GeoIP_country_code[0]);
static const char* g_pszcNone = grInvalidStr_;

static bool GR_RetrieveContinNameByContinCode(const SourceHook::String Code, SourceHook::String& Name)
{
	static const char* ppszcCodes[] = { "EU", "AS", "SA", "NA", "AF", "AN", "OC", },
		* ppszcNames[] = { "Europe", "Asia", "South America", "North America", "Africa", "Antarctica", "Australia & Oceania", };

	static const unsigned int uiContin = sizeof(ppszcCodes) / sizeof(ppszcCodes[0]); static unsigned int uiIter;

	if (Code.empty() == false) {
		for (uiIter = g_uiZero; uiIter < uiContin; uiIter++) {
			if (Code.compare(ppszcCodes[uiIter]) == 0) {
				Name.assign(ppszcNames[uiIter]); return true;
			}
		}
	}

	Name.assign(g_pszcNone); return false;
}

static bool GR_StripIpAddrPort(SourceHook::String& Ip)
{
	static unsigned int uiPos;

	if (Ip.empty() == false) {
		uiPos = Ip.find(':');

		if (uiPos != SourceHook::String::npos) {
			Ip.at(uiPos, '\0'); return true;
		}
	}

	return false;
}

static float GR_ComputeGeoDistance(const float fLa1, const float fLa2, const float fLo1, const float fLo2, const bool bImp = false)
{
	if (fLa1 == 0.0f && fLa2 == 0.0f && fLo1 == 0.0f && fLo2 == 0.0f) {
		return 0.0f;
	}

	return (bImp ? g_fMeanEarthRadiusMi2 : g_fMeanEarthRadiusKm2) * asinf(sqrtf(powf(sinf((fLa2 - fLa1) * g_fPi90), 2.0f) +
		powf(sinf((fLo2 - fLo1) * g_fPi90), 2.0f) * cosf(fLa1 * g_fPi180) * cosf(fLa2 * g_fPi180)));
};

static bool GR_RetrieveIpGeoInfo(const SourceHook::String Ip, SourceHook::String& Code, SourceHook::String& Code3, SourceHook::String& Country,
	SourceHook::String& City, SourceHook::String& RegionCode, SourceHook::String& Region, SourceHook::String& TimeZone, SourceHook::String& PostalCode,
	SourceHook::String& ContinCode, SourceHook::String& Contin, SourceHook::String& AutoSysOrg, SourceHook::String& Isp, float& fLa, float& fLo)
{
	static MMDB_lookup_result_s MmdbRes; static MMDB_entry_data_s MmdbData; static GeoIPRecord* pRecord;
	static SourceHook::String RawIp; static char* pszBuffer; static const char* pszcBuffer;
	static int nErr[2]; static unsigned int uiIter;

	Code.assign(g_pszcNone); Code3.assign(g_pszcNone); Country.assign(g_pszcNone); City.assign(g_pszcNone); RegionCode.assign(g_pszcNone);
	Region.assign(g_pszcNone); TimeZone.assign(g_pszcNone); PostalCode.assign(g_pszcNone); ContinCode.assign(g_pszcNone);
	Contin.assign(g_pszcNone); AutoSysOrg.assign(g_pszcNone); Isp.assign(g_pszcNone); fLa = 0.0f; fLo = 0.0f;

	if (Ip.empty() == true) {
		return false;
	}

	RawIp.assign(Ip); GR_StripIpAddrPort(RawIp);

	if (g_uiOrder == GR_GEO_ORDER_LITE_FIRST)
	{
		if (g_bCity2Lite)
		{
			MmdbRes = MMDB_lookup_string(&g_City2Lite, RawIp.c_str(), &nErr[0], &nErr[1]);

			if (nErr[0] == MMDB_SUCCESS && nErr[1] == MMDB_SUCCESS && MmdbRes.found_entry == true)
			{
				if (Code.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "country", "iso_code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Code.assign(MmdbData.utf8_string); Code.at(MmdbData.data_size, '\0');
				}

				if (Code3.compare(g_pszcNone) == 0 && Code.compare(g_pszcNone)) {
					for (uiIter = g_uiZero; uiIter < g_uiLocalCountryCodesNum; uiIter++) {
						if (Code.compare(GeoIP_country_code[uiIter]) == 0) {
							Code3.assign(GeoIP_country_code3[uiIter]); break;
						}
					}
				}

				if (Country.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "country", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Country.assign(MmdbData.utf8_string); Country.at(MmdbData.data_size, '\0');
				}

				if (City.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "city", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					City.assign(MmdbData.utf8_string); City.at(MmdbData.data_size, '\0');
				}

				if (RegionCode.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "subdivisions", "0", "iso_code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					RegionCode.assign(MmdbData.utf8_string); RegionCode.at(MmdbData.data_size, '\0');
				}

				if (Region.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "subdivisions", "0", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Region.assign(MmdbData.utf8_string); Region.at(MmdbData.data_size, '\0');
				}

				if (TimeZone.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "location", "time_zone", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					TimeZone.assign(MmdbData.utf8_string); TimeZone.at(MmdbData.data_size, '\0');
				}

				if (PostalCode.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "postal", "code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					PostalCode.assign(MmdbData.utf8_string); PostalCode.at(MmdbData.data_size, '\0');
				}

				if (ContinCode.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "continent", "code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					ContinCode.assign(MmdbData.utf8_string); ContinCode.at(MmdbData.data_size, '\0');
				}

				if (Contin.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "continent", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Contin.assign(MmdbData.utf8_string); Contin.at(MmdbData.data_size, '\0');
				}

				if (AutoSysOrg.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "traits", "autonomous_system_organization", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					AutoSysOrg.assign(MmdbData.utf8_string); AutoSysOrg.at(MmdbData.data_size, '\0');
				}

				if (Isp.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "traits", "isp", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Isp.assign(MmdbData.utf8_string); Isp.at(MmdbData.data_size, '\0');
				}

				if (fLa == 0.0f && MMDB_get_value(&MmdbRes.entry, &MmdbData, "location", "latitude", NULL) == MMDB_SUCCESS && MmdbData.has_data == true && MmdbData.float_value != 0.0f) {
					fLa = MmdbData.float_value;
				}

				if (fLo == 0.0f && MMDB_get_value(&MmdbRes.entry, &MmdbData, "location", "longitude", NULL) == MMDB_SUCCESS && MmdbData.has_data == true && MmdbData.float_value != 0.0f) {
					fLo = MmdbData.float_value;
				}
			}
		}

		if (g_bCity2Paid)
		{
			MmdbRes = MMDB_lookup_string(&g_City2Paid, RawIp.c_str(), &nErr[0], &nErr[1]);

			if (nErr[0] == MMDB_SUCCESS && nErr[1] == MMDB_SUCCESS && MmdbRes.found_entry == true)
			{
				if (Code.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "country", "iso_code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Code.assign(MmdbData.utf8_string); Code.at(MmdbData.data_size, '\0');
				}

				if (Code3.compare(g_pszcNone) == 0 && Code.compare(g_pszcNone)) {
					for (uiIter = g_uiZero; uiIter < g_uiLocalCountryCodesNum; uiIter++) {
						if (Code.compare(GeoIP_country_code[uiIter]) == 0) {
							Code3.assign(GeoIP_country_code3[uiIter]); break;
						}
					}
				}

				if (Country.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "country", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Country.assign(MmdbData.utf8_string); Country.at(MmdbData.data_size, '\0');
				}

				if (City.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "city", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					City.assign(MmdbData.utf8_string); City.at(MmdbData.data_size, '\0');
				}

				if (RegionCode.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "subdivisions", "0", "iso_code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					RegionCode.assign(MmdbData.utf8_string); RegionCode.at(MmdbData.data_size, '\0');
				}

				if (Region.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "subdivisions", "0", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Region.assign(MmdbData.utf8_string); Region.at(MmdbData.data_size, '\0');
				}

				if (TimeZone.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "location", "time_zone", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					TimeZone.assign(MmdbData.utf8_string); TimeZone.at(MmdbData.data_size, '\0');
				}

				if (PostalCode.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "postal", "code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					PostalCode.assign(MmdbData.utf8_string); PostalCode.at(MmdbData.data_size, '\0');
				}

				if (ContinCode.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "continent", "code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					ContinCode.assign(MmdbData.utf8_string); ContinCode.at(MmdbData.data_size, '\0');
				}

				if (Contin.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "continent", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Contin.assign(MmdbData.utf8_string); Contin.at(MmdbData.data_size, '\0');
				}

				if (AutoSysOrg.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "traits", "autonomous_system_organization", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					AutoSysOrg.assign(MmdbData.utf8_string); AutoSysOrg.at(MmdbData.data_size, '\0');
				}

				if (Isp.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "traits", "isp", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Isp.assign(MmdbData.utf8_string); Isp.at(MmdbData.data_size, '\0');
				}

				if (fLa == 0.0f && MMDB_get_value(&MmdbRes.entry, &MmdbData, "location", "latitude", NULL) == MMDB_SUCCESS && MmdbData.has_data == true && MmdbData.float_value != 0.0f) {
					fLa = MmdbData.float_value;
				}

				if (fLo == 0.0f && MMDB_get_value(&MmdbRes.entry, &MmdbData, "location", "longitude", NULL) == MMDB_SUCCESS && MmdbData.has_data == true && MmdbData.float_value != 0.0f) {
					fLo = MmdbData.float_value;
				}
			}
		}
	}

	else
	{
		if (g_bCity2Paid)
		{
			MmdbRes = MMDB_lookup_string(&g_City2Paid, RawIp.c_str(), &nErr[0], &nErr[1]);

			if (nErr[0] == MMDB_SUCCESS && nErr[1] == MMDB_SUCCESS && MmdbRes.found_entry == true)
			{
				if (Code.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "country", "iso_code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Code.assign(MmdbData.utf8_string); Code.at(MmdbData.data_size, '\0');
				}

				if (Code3.compare(g_pszcNone) == 0 && Code.compare(g_pszcNone)) {
					for (uiIter = g_uiZero; uiIter < g_uiLocalCountryCodesNum; uiIter++) {
						if (Code.compare(GeoIP_country_code[uiIter]) == 0) {
							Code3.assign(GeoIP_country_code3[uiIter]); break;
						}
					}
				}

				if (Country.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "country", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Country.assign(MmdbData.utf8_string); Country.at(MmdbData.data_size, '\0');
				}

				if (City.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "city", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					City.assign(MmdbData.utf8_string); City.at(MmdbData.data_size, '\0');
				}

				if (RegionCode.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "subdivisions", "0", "iso_code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					RegionCode.assign(MmdbData.utf8_string); RegionCode.at(MmdbData.data_size, '\0');
				}

				if (Region.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "subdivisions", "0", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Region.assign(MmdbData.utf8_string); Region.at(MmdbData.data_size, '\0');
				}

				if (TimeZone.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "location", "time_zone", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					TimeZone.assign(MmdbData.utf8_string); TimeZone.at(MmdbData.data_size, '\0');
				}

				if (PostalCode.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "postal", "code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					PostalCode.assign(MmdbData.utf8_string); PostalCode.at(MmdbData.data_size, '\0');
				}

				if (ContinCode.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "continent", "code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					ContinCode.assign(MmdbData.utf8_string); ContinCode.at(MmdbData.data_size, '\0');
				}

				if (Contin.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "continent", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Contin.assign(MmdbData.utf8_string); Contin.at(MmdbData.data_size, '\0');
				}

				if (AutoSysOrg.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "traits", "autonomous_system_organization", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					AutoSysOrg.assign(MmdbData.utf8_string); AutoSysOrg.at(MmdbData.data_size, '\0');
				}

				if (Isp.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "traits", "isp", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Isp.assign(MmdbData.utf8_string); Isp.at(MmdbData.data_size, '\0');
				}

				if (fLa == 0.0f && MMDB_get_value(&MmdbRes.entry, &MmdbData, "location", "latitude", NULL) == MMDB_SUCCESS && MmdbData.has_data == true && MmdbData.float_value != 0.0f) {
					fLa = MmdbData.float_value;
				}

				if (fLo == 0.0f && MMDB_get_value(&MmdbRes.entry, &MmdbData, "location", "longitude", NULL) == MMDB_SUCCESS && MmdbData.has_data == true && MmdbData.float_value != 0.0f) {
					fLo = MmdbData.float_value;
				}
			}
		}

		if (g_bCity2Lite)
		{
			MmdbRes = MMDB_lookup_string(&g_City2Lite, RawIp.c_str(), &nErr[0], &nErr[1]);

			if (nErr[0] == MMDB_SUCCESS && nErr[1] == MMDB_SUCCESS && MmdbRes.found_entry == true)
			{
				if (Code.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "country", "iso_code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Code.assign(MmdbData.utf8_string); Code.at(MmdbData.data_size, '\0');
				}

				if (Code3.compare(g_pszcNone) == 0 && Code.compare(g_pszcNone)) {
					for (uiIter = g_uiZero; uiIter < g_uiLocalCountryCodesNum; uiIter++) {
						if (Code.compare(GeoIP_country_code[uiIter]) == 0) {
							Code3.assign(GeoIP_country_code3[uiIter]); break;
						}
					}
				}

				if (Country.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "country", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Country.assign(MmdbData.utf8_string); Country.at(MmdbData.data_size, '\0');
				}

				if (City.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "city", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					City.assign(MmdbData.utf8_string); City.at(MmdbData.data_size, '\0');
				}

				if (RegionCode.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "subdivisions", "0", "iso_code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					RegionCode.assign(MmdbData.utf8_string); RegionCode.at(MmdbData.data_size, '\0');
				}

				if (Region.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "subdivisions", "0", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Region.assign(MmdbData.utf8_string); Region.at(MmdbData.data_size, '\0');
				}

				if (TimeZone.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "location", "time_zone", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					TimeZone.assign(MmdbData.utf8_string); TimeZone.at(MmdbData.data_size, '\0');
				}

				if (PostalCode.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "postal", "code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					PostalCode.assign(MmdbData.utf8_string); PostalCode.at(MmdbData.data_size, '\0');
				}

				if (ContinCode.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "continent", "code", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					ContinCode.assign(MmdbData.utf8_string); ContinCode.at(MmdbData.data_size, '\0');
				}

				if (Contin.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "continent", "names", "en", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Contin.assign(MmdbData.utf8_string); Contin.at(MmdbData.data_size, '\0');
				}

				if (AutoSysOrg.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "traits", "autonomous_system_organization", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					AutoSysOrg.assign(MmdbData.utf8_string); AutoSysOrg.at(MmdbData.data_size, '\0');
				}

				if (Isp.compare(g_pszcNone) == 0 && MMDB_get_value(&MmdbRes.entry, &MmdbData, "traits", "isp", NULL) == MMDB_SUCCESS && MmdbData.has_data == true) {
					Isp.assign(MmdbData.utf8_string); Isp.at(MmdbData.data_size, '\0');
				}

				if (fLa == 0.0f && MMDB_get_value(&MmdbRes.entry, &MmdbData, "location", "latitude", NULL) == MMDB_SUCCESS && MmdbData.has_data == true && MmdbData.float_value != 0.0f) {
					fLa = MmdbData.float_value;
				}

				if (fLo == 0.0f && MMDB_get_value(&MmdbRes.entry, &MmdbData, "location", "longitude", NULL) == MMDB_SUCCESS && MmdbData.has_data == true && MmdbData.float_value != 0.0f) {
					fLo = MmdbData.float_value;
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
				if (Code.compare(g_pszcNone) == 0 && pRecord->country_code && *pRecord->country_code != '\0') {
					Code.assign(pRecord->country_code);
				}

				if (Code3.compare(g_pszcNone) == 0 && pRecord->country_code3 && *pRecord->country_code3 != '\0') {
					Code3.assign(pRecord->country_code3);
				}

				if (Country.compare(g_pszcNone) == 0 && pRecord->country_name && *pRecord->country_name != '\0') {
					Country.assign(pRecord->country_name);
				}

				if (City.compare(g_pszcNone) == 0 && pRecord->city && *pRecord->city != '\0') {
					City.assign(pRecord->city);
				}

				if (RegionCode.compare(g_pszcNone) == 0 && pRecord->region && *pRecord->region != '\0') {
					RegionCode.assign(pRecord->region);
				}

				if (Region.compare(g_pszcNone) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
					pszcBuffer = GeoIP_region_name_by_code(pRecord->country_code, pRecord->region);
					Region.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcNone);
				}

				if (TimeZone.compare(g_pszcNone) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
					pszcBuffer = GeoIP_time_zone_by_country_and_region(pRecord->country_code, pRecord->region);
					TimeZone.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcNone);
				}

				if (PostalCode.compare(g_pszcNone) == 0 && pRecord->postal_code && *pRecord->postal_code != '\0') {
					PostalCode.assign(pRecord->postal_code);
				}

				if (ContinCode.compare(g_pszcNone) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
					ContinCode.assign(pRecord->continent_code);
				}

				if (Contin.compare(g_pszcNone) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
					GR_RetrieveContinNameByContinCode(pRecord->continent_code, Contin);
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
				if (Code.compare(g_pszcNone) == 0 && pRecord->country_code && *pRecord->country_code != '\0') {
					Code.assign(pRecord->country_code);
				}

				if (Code3.compare(g_pszcNone) == 0 && pRecord->country_code3 && *pRecord->country_code3 != '\0') {
					Code3.assign(pRecord->country_code3);
				}

				if (Country.compare(g_pszcNone) == 0 && pRecord->country_name && *pRecord->country_name != '\0') {
					Country.assign(pRecord->country_name);
				}

				if (City.compare(g_pszcNone) == 0 && pRecord->city && *pRecord->city != '\0') {
					City.assign(pRecord->city);
				}

				if (RegionCode.compare(g_pszcNone) == 0 && pRecord->region && *pRecord->region != '\0') {
					RegionCode.assign(pRecord->region);
				}

				if (Region.compare(g_pszcNone) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
					pszcBuffer = GeoIP_region_name_by_code(pRecord->country_code, pRecord->region);
					Region.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcNone);
				}

				if (TimeZone.compare(g_pszcNone) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
					pszcBuffer = GeoIP_time_zone_by_country_and_region(pRecord->country_code, pRecord->region);
					TimeZone.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcNone);
				}

				if (PostalCode.compare(g_pszcNone) == 0 && pRecord->postal_code && *pRecord->postal_code != '\0') {
					PostalCode.assign(pRecord->postal_code);
				}

				if (ContinCode.compare(g_pszcNone) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
					ContinCode.assign(pRecord->continent_code);
				}

				if (Contin.compare(g_pszcNone) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
					GR_RetrieveContinNameByContinCode(pRecord->continent_code, Contin);
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
				if (Code.compare(g_pszcNone) == 0 && pRecord->country_code && *pRecord->country_code != '\0') {
					Code.assign(pRecord->country_code);
				}

				if (Code3.compare(g_pszcNone) == 0 && pRecord->country_code3 && *pRecord->country_code3 != '\0') {
					Code3.assign(pRecord->country_code3);
				}

				if (Country.compare(g_pszcNone) == 0 && pRecord->country_name && *pRecord->country_name != '\0') {
					Country.assign(pRecord->country_name);
				}

				if (City.compare(g_pszcNone) == 0 && pRecord->city && *pRecord->city != '\0') {
					City.assign(pRecord->city);
				}

				if (RegionCode.compare(g_pszcNone) == 0 && pRecord->region && *pRecord->region != '\0') {
					RegionCode.assign(pRecord->region);
				}

				if (Region.compare(g_pszcNone) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
					pszcBuffer = GeoIP_region_name_by_code(pRecord->country_code, pRecord->region);
					Region.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcNone);
				}

				if (TimeZone.compare(g_pszcNone) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
					pszcBuffer = GeoIP_time_zone_by_country_and_region(pRecord->country_code, pRecord->region);
					TimeZone.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcNone);
				}

				if (PostalCode.compare(g_pszcNone) == 0 && pRecord->postal_code && *pRecord->postal_code != '\0') {
					PostalCode.assign(pRecord->postal_code);
				}

				if (ContinCode.compare(g_pszcNone) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
					ContinCode.assign(pRecord->continent_code);
				}

				if (Contin.compare(g_pszcNone) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
					GR_RetrieveContinNameByContinCode(pRecord->continent_code, Contin);
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
				if (Code.compare(g_pszcNone) == 0 && pRecord->country_code && *pRecord->country_code != '\0') {
					Code.assign(pRecord->country_code);
				}

				if (Code3.compare(g_pszcNone) == 0 && pRecord->country_code3 && *pRecord->country_code3 != '\0') {
					Code3.assign(pRecord->country_code3);
				}

				if (Country.compare(g_pszcNone) == 0 && pRecord->country_name && *pRecord->country_name != '\0') {
					Country.assign(pRecord->country_name);
				}

				if (City.compare(g_pszcNone) == 0 && pRecord->city && *pRecord->city != '\0') {
					City.assign(pRecord->city);
				}

				if (RegionCode.compare(g_pszcNone) == 0 && pRecord->region && *pRecord->region != '\0') {
					RegionCode.assign(pRecord->region);
				}

				if (Region.compare(g_pszcNone) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
					pszcBuffer = GeoIP_region_name_by_code(pRecord->country_code, pRecord->region);
					Region.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcNone);
				}

				if (TimeZone.compare(g_pszcNone) == 0 && pRecord->country_code && *pRecord->country_code != '\0' && pRecord->region && *pRecord->region != '\0') {
					pszcBuffer = GeoIP_time_zone_by_country_and_region(pRecord->country_code, pRecord->region);
					TimeZone.assign((pszcBuffer && *pszcBuffer != '\0') ? pszcBuffer : g_pszcNone);
				}

				if (PostalCode.compare(g_pszcNone) == 0 && pRecord->postal_code && *pRecord->postal_code != '\0') {
					PostalCode.assign(pRecord->postal_code);
				}

				if (ContinCode.compare(g_pszcNone) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
					ContinCode.assign(pRecord->continent_code);
				}

				if (Contin.compare(g_pszcNone) == 0 && pRecord->continent_code && *pRecord->continent_code != '\0') {
					GR_RetrieveContinNameByContinCode(pRecord->continent_code, Contin);
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
		if (g_bIspLite) {
			if (Isp.compare(g_pszcNone) == 0) {
				pszBuffer = GeoIP_org_by_addr(g_pIspLite, RawIp.c_str());

				if (pszBuffer) {
					if (*pszBuffer != '\0') {
						Isp.assign(pszBuffer);
					}

					free(pszBuffer);
				}
			}
		}

		if (g_bIspPaid) {
			if (Isp.compare(g_pszcNone) == 0) {
				pszBuffer = GeoIP_org_by_addr(g_pIspPaid, RawIp.c_str());

				if (pszBuffer) {
					if (*pszBuffer != '\0') {
						Isp.assign(pszBuffer);
					}

					free(pszBuffer);
				}
			}
		}
	}

	else
	{
		if (g_bIspPaid) {
			if (Isp.compare(g_pszcNone) == 0) {
				pszBuffer = GeoIP_org_by_addr(g_pIspPaid, RawIp.c_str());

				if (pszBuffer) {
					if (*pszBuffer != '\0') {
						Isp.assign(pszBuffer);
					}

					free(pszBuffer);
				}
			}
		}

		if (g_bIspLite) {
			if (Isp.compare(g_pszcNone) == 0) {
				pszBuffer = GeoIP_org_by_addr(g_pIspLite, RawIp.c_str());

				if (pszBuffer) {
					if (*pszBuffer != '\0') {
						Isp.assign(pszBuffer);
					}

					free(pszBuffer);
				}
			}
		}
	}

	return true;
}

static bool GR_DirExists(const char* pszcDirPath) {

#if !defined WIN32

	static DIR* pDir;

#else

	static unsigned long ulAttr;

#endif

	if (!pszcDirPath || *pszcDirPath == '\0') {
		return false;
	}

#if !defined WIN32

	pDir = opendir(pszcDirPath);

	if (pDir) {
		closedir(pDir); return true;
	}

	return false;

#else

	ulAttr = GetFileAttributes(pszcDirPath);

	if (ulAttr == INVALID_FILE_ATTRIBUTES || !(ulAttr & FILE_ATTRIBUTE_DIRECTORY)) {
		return false;
	}

	return true;

#endif

};

static bool GR_FileExists(const char* pszcFilePath) {
	static FILE* pFile;

	if (!pszcFilePath || *pszcFilePath == '\0') {
		return false;
	}

	pFile = fopen(pszcFilePath, "r");

	if (pFile) {
		fclose(pFile); return true;
	}

	return false;
}

static bool GR_Startup() {
	static char szPath[256], szDateTime[256], * pszBuffer;
	static time_t UnixDateTime;

	g_pSM->BuildPath(Path_SM, szPath, sizeof(szPath), "data/GeoResolver/GeoLite2-City.mmdb");

	if (MMDB_open(szPath, MMDB_MODE_MMAP, &g_City2Lite) == MMDB_SUCCESS) {
		UnixDateTime = castValTo_(g_City2Lite.metadata.build_epoch, time_t);
		strftime(szDateTime, sizeof(szDateTime), "%F %T UTC", gmtime(&UnixDateTime));
		g_pSM->LogMessage(myself, "Loaded GeoLite2-City.mmdb, %s.", szDateTime);
		g_bCity2Lite = true; g_uiDb |= GR_GEO_DB_GEOIP2_CITY_LITE;
	}

	else {
		g_pSM->LogMessage(myself, "GeoLite2-City.mmdb unavailable."); g_bCity2Lite = false; g_uiDb &= ~GR_GEO_DB_GEOIP2_CITY_LITE;
	}

	g_pSM->BuildPath(Path_SM, szPath, sizeof(szPath), "data/GeoResolver/GeoIP2-City.mmdb");

	if (MMDB_open(szPath, MMDB_MODE_MMAP, &g_City2Paid) == MMDB_SUCCESS) {
		UnixDateTime = castValTo_(g_City2Paid.metadata.build_epoch, time_t);
		strftime(szDateTime, sizeof(szDateTime), "%F %T UTC", gmtime(&UnixDateTime));
		g_pSM->LogMessage(myself, "Loaded GeoIP2-City.mmdb, %s.", szDateTime);
		g_bCity2Paid = true; g_uiDb |= GR_GEO_DB_GEOIP2_CITY_PAID;
	}

	else {
		g_pSM->LogMessage(myself, "GeoIP2-City.mmdb unavailable."); g_bCity2Paid = false; g_uiDb &= ~GR_GEO_DB_GEOIP2_CITY_PAID;
	}

	g_pSM->BuildPath(Path_SM, szPath, sizeof(szPath), "data/GeoResolver/GeoLiteCity.dat");

	if ((g_pCityLite = GeoIP_open(szPath, GEOIP_INDEX_CACHE))) {
		pszBuffer = GeoIP_database_info(g_pCityLite);

		if (pszBuffer) {
			if (*pszBuffer != '\0') {
				g_pSM->LogMessage(myself, "Loaded GeoLiteCity.dat, %s.", pszBuffer);
			}

			else {
				g_pSM->LogMessage(myself, "Loaded GeoLiteCity.dat, unknown information.");
			}

			free(pszBuffer);
		}

		else {
			g_pSM->LogMessage(myself, "Loaded GeoLiteCity.dat, unknown information.");
		}

		GeoIP_set_charset(g_pCityLite, GEOIP_CHARSET_UTF8); g_bCityLite = true; g_uiDb |= GR_GEO_DB_GEOIP_CITY_LITE;
	}

	else {
		g_pSM->LogMessage(myself, "GeoLiteCity.dat unavailable."); g_bCityLite = false; g_uiDb &= ~GR_GEO_DB_GEOIP_CITY_LITE;
	}

	g_pSM->BuildPath(Path_SM, szPath, sizeof(szPath), "data/GeoResolver/GeoIPCity.dat");

	if ((g_pCityPaid = GeoIP_open(szPath, GEOIP_INDEX_CACHE))) {
		pszBuffer = GeoIP_database_info(g_pCityPaid);

		if (pszBuffer) {
			if (*pszBuffer != '\0') {
				g_pSM->LogMessage(myself, "Loaded GeoIPCity.dat, %s.", pszBuffer);
			}

			else {
				g_pSM->LogMessage(myself, "Loaded GeoIPCity.dat, unknown information.");
			}

			free(pszBuffer);
		}

		else {
			g_pSM->LogMessage(myself, "Loaded GeoIPCity.dat, unknown information.");
		}

		GeoIP_set_charset(g_pCityPaid, GEOIP_CHARSET_UTF8); g_bCityPaid = true; g_uiDb |= GR_GEO_DB_GEOIP_CITY_PAID;
	}

	else {
		g_pSM->LogMessage(myself, "GeoIPCity.dat unavailable."); g_bCityPaid = false; g_uiDb &= ~GR_GEO_DB_GEOIP_CITY_PAID;
	}

	g_pSM->BuildPath(Path_SM, szPath, sizeof(szPath), "data/GeoResolver/GeoLiteISP.dat");

	if ((g_pIspLite = GeoIP_open(szPath, GEOIP_INDEX_CACHE))) {
		pszBuffer = GeoIP_database_info(g_pIspLite);

		if (pszBuffer) {
			if (*pszBuffer != '\0') {
				g_pSM->LogMessage(myself, "Loaded GeoLiteISP.dat, %s.", pszBuffer);
			}

			else {
				g_pSM->LogMessage(myself, "Loaded GeoLiteISP.dat, unknown information.");
			}

			free(pszBuffer);
		}

		else {
			g_pSM->LogMessage(myself, "Loaded GeoLiteISP.dat, unknown information.");
		}

		GeoIP_set_charset(g_pIspLite, GEOIP_CHARSET_UTF8); g_bIspLite = true; g_uiDb |= GR_GEO_DB_GEOIP_ISP_LITE;
	}

	else {
		g_pSM->LogMessage(myself, "GeoLiteISP.dat unavailable."); g_bIspLite = false; g_uiDb &= ~GR_GEO_DB_GEOIP_ISP_LITE;
	}

	g_pSM->BuildPath(Path_SM, szPath, sizeof(szPath), "data/GeoResolver/GeoIPISP.dat");

	if ((g_pIspPaid = GeoIP_open(szPath, GEOIP_INDEX_CACHE))) {
		pszBuffer = GeoIP_database_info(g_pIspPaid);

		if (pszBuffer) {
			if (*pszBuffer != '\0') {
				g_pSM->LogMessage(myself, "Loaded GeoIPISP.dat, %s.", pszBuffer);
			}

			else {
				g_pSM->LogMessage(myself, "Loaded GeoIPISP.dat, unknown information.");
			}

			free(pszBuffer);
		}

		else {
			g_pSM->LogMessage(myself, "Loaded GeoIPISP.dat, unknown information.");
		}

		GeoIP_set_charset(g_pIspPaid, GEOIP_CHARSET_UTF8); g_bIspPaid = true; g_uiDb |= GR_GEO_DB_GEOIP_ISP_PAID;
	}

	else {
		g_pSM->LogMessage(myself, "GeoIPISP.dat unavailable."); g_bIspPaid = false; g_uiDb &= ~GR_GEO_DB_GEOIP_ISP_PAID;
	}

	return true;
}

static bool GR_Shutdown() {
	g_uiDb = GR_GEO_DB_NONE;

	if (g_bCity2Lite) {
		MMDB_close(&g_City2Lite); g_bCity2Lite = false;
	}

	if (g_bCity2Paid) {
		MMDB_close(&g_City2Paid); g_bCity2Paid = false;
	}

	if (g_bCityLite) {
		GeoIP_delete(g_pCityLite); g_bCityLite = false;
	}

	if (g_bCityPaid) {
		GeoIP_delete(g_pCityPaid); g_bCityPaid = false;
	}

	if (g_bIspLite) {
		GeoIP_delete(g_pIspLite); g_bIspLite = false;
	}

	if (g_bIspPaid) {
		GeoIP_delete(g_pIspPaid); g_bIspPaid = false;
	}

	return true;
}

static int GeoR_Record(IPluginContext* pCtx, const int* pParams)
{
	static char* pszIp; static float fLa, fLo; static int* pLa, * pLo;
	static SourceHook::String Ip, Country, City, Region, Isp, Code, Code3, RegionCode, TimeZone, PostalCode, Contin, ContinCode, AutoSysOrg;

	Country.assign(g_pszcNone); City.assign(g_pszcNone); Region.assign(g_pszcNone); Isp.assign(g_pszcNone); Code.assign(g_pszcNone); Code3.assign(g_pszcNone);
	RegionCode.assign(g_pszcNone); TimeZone.assign(g_pszcNone); PostalCode.assign(g_pszcNone); Contin.assign(g_pszcNone); ContinCode.assign(g_pszcNone);
	AutoSysOrg.assign(g_pszcNone); fLa = 0.0f; fLo = 0.0f;

	pCtx->LocalToString(pParams[1], &pszIp);

	if (!pszIp || *pszIp == '\0') {
		Ip.clear();
	}

	else {
		Ip.assign(pszIp); GR_StripIpAddrPort(Ip);
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

	if (pLa) {
		*pLa = sp_ftoc(fLa);
	}

	pCtx->LocalToPhysAddr(pParams[27], &pLo);

	if (pLo) {
		*pLo = sp_ftoc(fLo);
	}

	return 1;
}

static int GeoR_Db(IPluginContext*, const int*) {
	return castValTo_(g_uiDb, int);
}

static int GeoR_Distance(IPluginContext*, const int* pParams) {
	return sp_ftoc(GR_ComputeGeoDistance(sp_ctof(pParams[1]), sp_ctof(pParams[3]), sp_ctof(pParams[2]), sp_ctof(pParams[4]), castValTo_(pParams[5], bool)));
}

static int GeoR_Reload(IPluginContext*, const int*)
{
	static const char* ppszcOldFiles[] = {
		"data/GeoResolver/GeoLite2-City.mmdb",				"data/GeoResolver/GeoIP2-City.mmdb",
		"data/GeoResolver/GeoLiteCity.dat",					"data/GeoResolver/GeoIPCity.dat",
		"data/GeoResolver/GeoLiteISP.dat",					"data/GeoResolver/GeoIPISP.dat",
	};

	static const char* ppszcNewFiles[] = {
		"data/GeoResolver/Update/GeoLite2-City.mmdb",		"data/GeoResolver/Update/GeoIP2-City.mmdb",
		"data/GeoResolver/Update/GeoLiteCity.dat",			"data/GeoResolver/Update/GeoIPCity.dat",
		"data/GeoResolver/Update/GeoLiteISP.dat",			"data/GeoResolver/Update/GeoIPISP.dat",
	};

	static const unsigned int uiFiles = sizeof(ppszcOldFiles) / sizeof(ppszcOldFiles[0]);
	static char szPath[256], szOldPath[256], szNewPath[256]; static unsigned int uiIter;

	GR_Shutdown(); g_pSM->BuildPath(Path_SM, szPath, sizeof(szPath), "data/GeoResolver/Update");

	if (GR_DirExists(szPath))
	{
		for (uiIter = g_uiZero; uiIter < uiFiles; uiIter++)
		{
			g_pSM->BuildPath(Path_SM, szNewPath, sizeof(szNewPath), ppszcNewFiles[uiIter]);

			if (GR_FileExists(szNewPath))
			{
				g_pSM->BuildPath(Path_SM, szOldPath, sizeof(szOldPath), ppszcOldFiles[uiIter]);

				if (GR_FileExists(szOldPath)) {
					remove(szOldPath);
				}

				rename(szNewPath, szOldPath);
			}
		}
	}

	GR_Startup(); return 1;
}

static int GeoR_Order(IPluginContext*, const int* pParams) {
	g_uiOrder = castValTo_(pParams[1], unsigned int); return 1;
}

static const sp_nativeinfo_t g_GeoResolverFuncs[] = {
	{ "GeoR_CompleteRecord",	GeoR_Record, },			{ "GeoR_FullRecord",	GeoR_Record, },			{ "GeoR_Record",	GeoR_Record, },
	{ "GeoR_Databases",			GeoR_Db, },				{ "GeoR_Db",			GeoR_Db, },
	{ "GeoR_Distance",			GeoR_Distance, },		{ "GeoR_Length",		GeoR_Distance, },		{ "GeoR_Len",		GeoR_Distance, },
	{ "GeoR_Reload",			GeoR_Reload, },			{ "GeoR_Refresh",		GeoR_Reload, },			{ "GeoR_Restart",	GeoR_Reload, },
	{ "GeoR_ChangeOrder",		GeoR_Order, },			{ "GeoR_Order",			GeoR_Order, },			{ "GeoR_SetOrder",	GeoR_Order, },

	{ NULL,						NULL, },
};

bool GeoResolver::SDK_OnLoad(char*, unsigned int, bool) {
	GR_Startup(); g_pShareSys->AddNatives(myself, g_GeoResolverFuncs); g_pShareSys->RegisterLibrary(myself, grLibNameStr_); return true;
}

void GeoResolver::SDK_OnUnload() {
	GR_Shutdown();
}
