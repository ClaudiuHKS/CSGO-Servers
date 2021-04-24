#pragma once

#if !defined WIN32 && !defined WINDOWS

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

class CustomTickRate : public ISmmPlugin, public IMetamodListener
{

public:

	bool Load(PluginId, ISmmAPI*, char*, size_t, bool);
	bool Unload(char*, size_t);

	bool Pause(char*, size_t);
	bool Unpause(char*, size_t);

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

	static constexpr auto fDefaultTickRate_{ 0.0078125f, };

};

extern CustomTickRate g_CustomTickRate;

PLUGIN_GLOBALVARS();
