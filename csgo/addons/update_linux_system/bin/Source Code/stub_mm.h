#pragma once

#include <ISmmPlugin.h>

class UpdateLinuxSystem : public ISmmPlugin
{

public:

	bool Load(PluginId, ISmmAPI*, char*, size_t, bool);
	bool Unload(char*, size_t);

	bool Pause(char*, size_t);
	bool Unpause(char*, size_t);

	void AllPluginsLoaded();

public:

	const char* GetAuthor();
	const char* GetName();
	const char* GetDescription();
	const char* GetURL();
	const char* GetLicense();
	const char* GetVersion();
	const char* GetDate();
	const char* GetLogTag();

};

extern UpdateLinuxSystem g_UpdateLinuxSystem;

PLUGIN_GLOBALVARS();
