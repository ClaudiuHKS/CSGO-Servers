#pragma once

#if !defined WIN32

#	include <sys/resource.h>

#else

#	include <WinSock2.h>
#	include <Windows.h>
#	include <Psapi.h>

#endif

#include "json.hpp"

#include <fstream>
#include <iostream>
#include <iomanip>
#include <limits>
#include <numbers>

#include <ISmmPlugin.h>

#include <filesystem.h>
#include <igameevents.h>
#include <iplayerinfo.h>

#define castValTo_( Value, Type )       ( ( Type ) ( Value ) )

#define maxRealPrecision_               ( ::std::numeric_limits < long double > ::max_digits10 )

class CustomTickRate : public ISmmPlugin /** Load, Unload */, public IMetamodListener /** OnVSPListening */
{

public:

	bool Load(PluginId, ISmmAPI*, char*, size_t, bool);
	bool Unload(char*, size_t);

public:

	bool Pause(char*, size_t);
	bool Unpause(char*, size_t);

public:

	void AllPluginsLoaded();

public:

	void OnVSPListening(IServerPluginCallbacks*);

public:

	float Hook_GetTickInterval() const noexcept;

public:

	const char* GetAuthor();
	const char* GetName();
	const char* GetDescription();
	const char* GetURL();
	const char* GetLicense();
	const char* GetVersion();
	const char* GetDate();
	const char* GetLogTag();

private:

	static constexpr auto nDefaultTickRate_{ 128, /** Yes, this value can be changed. */ };
	static constexpr auto fDefaultIntervalPerTick_{ 1.0f / castValTo_(nDefaultTickRate_, float), };

};

extern CustomTickRate g_CustomTickRate;

PLUGIN_GLOBALVARS();
