#ifndef _plugin_sox_h_
#define _plugin_sox_h_

#include "CoronaLua.h"
#include "CoronaMacros.h"
#include "sox.h"

#define PLUGIN_NAME "plugin.sox"

CORONA_EXPORT int luaopen_plugin_sox(lua_State *L);

#endif
