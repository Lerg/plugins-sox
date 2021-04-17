#include "CoronaAssert.h"
#include "CoronaLibrary.h"
#include <stdlib.h>

#include "plugin_sox.h"
#include "utils.h"

static bool is_initialized = false;
static char *tmp_path = NULL;

static void lua_print(lua_State *L, const char *message) {
	lua_getglobal(L, "print");
	lua_pushstring(L, message);
	lua_call(L, 1, 0);
}

static unsigned int verbosity_to_int(const char *verbosity) {
	if (strcmp(verbosity, "none")) {
		return 0;
	} else if (strcmp(verbosity, "fail")) {
		return 1;
	} else if (strcmp(verbosity, "warn")) {
		return 2;
	} else if (strcmp(verbosity, "report")) {
		return 3;
	} else if (strcmp(verbosity, "debug")) {
		return 4;
	} else if (strcmp(verbosity, "debug_more")) {
		return 5;
	} else if (strcmp(verbosity, "debug_most")) {
		return 6;
	}
	return 2;
}

static int plugin_init(lua_State *L) {
	utils::check_arg_count(L, 0, 1);
	char *verbosity = NULL;
	int *buffer_size = NULL;
	int *input_buffer_size = NULL;
	bool *use_threads = NULL;

	if (lua_istable(L, 1)) {
		utils::get_table(L, 1); // params.
		utils::table_get_string(L, "verbosity", &verbosity, "warn");
		utils::table_get_string(L, "temporary_directory", &tmp_path);
		utils::table_get_integer(L, "buffer_size", &buffer_size);
		utils::table_get_integer(L, "input_buffer_size", &input_buffer_size);
		utils::table_get_boolean(L, "use_threads", &use_threads);
		lua_pop(L, 1); // params table.
	}

	if (!is_initialized) {
		is_initialized = sox_init() == SOX_SUCCESS;
		if (is_initialized) {
			sox_globals_t *config = sox_get_globals();
			if (tmp_path != NULL) {
				config->tmp_path = tmp_path;
			}
			if (verbosity != NULL) {
				config->verbosity = verbosity_to_int(verbosity);
			}
			if (buffer_size != NULL) {
				config->bufsiz = *buffer_size;
			}
			if (input_buffer_size != NULL) {
				config->input_bufsiz = *input_buffer_size;
			}
			if (use_threads != NULL) {
				config->use_threads = *use_threads == true ? sox_true : sox_false;
			}
		}
	}
	lua_pushboolean(L, is_initialized);
	return 1;
}

static int plugin_quit(lua_State *L) {
	utils::check_arg_count(L, 0);
	if (is_initialized) {
		is_initialized = false;
		sox_quit();
	}
	return 0;
}

static int plugin_process(lua_State *L) {
	utils::check_arg_count(L, 1);
	if (!is_initialized) {
		return 0;
	}

	char *input_filename = NULL;
	char *output_filename = NULL;
	char *args[10];

	utils::get_table(L, 1); // params.
	utils::table_get_string_not_null(L, "input", &input_filename);
	utils::table_get_string_not_null(L, "output", &output_filename);

	sox_format_t *in = sox_open_read(input_filename, NULL, NULL, NULL);
	if (in == NULL) {
		luaL_error(L, PLUGIN_NAME ": failed to open the input file.");
	}
	sox_format_t *out = sox_open_write(output_filename, &in->signal, &in->encoding, NULL, NULL, NULL);
	if (out == NULL) {
		luaL_error(L, PLUGIN_NAME ": failed to open the output file.");
	}
	sox_effects_chain_t *chain = sox_create_effects_chain(&in->encoding, &out->encoding);

	sox_signalinfo_t interm_signal = in->signal; /* NB: deep copy */

	/* The first effect in the effect chain must be something that can source
	 * samples; in this case, we use the built-in handler that inputs
	 * data from an audio file */
	sox_effect_t *e = sox_create_effect(sox_find_effect("input"));
	args[0] = (char *)in;
	if (sox_effect_options(e, 1, args) != SOX_SUCCESS) {
		luaL_error(L, PLUGIN_NAME ": failed to create the input effect.");
	} else {
		if (sox_add_effect(chain, e, &interm_signal, &in->signal) != SOX_SUCCESS) {
			luaL_error(L, PLUGIN_NAME ": failed to add the input effect.");
		}
	}
	free(e);

	utils::table_get_table(L, "effects");

	lua_pushnil(L); // Key.
	while (lua_next(L, -2)) {
		if (lua_istable(L, -1)) {
			char *effect_name = NULL;
			char *effect_params = NULL;
			utils::table_get_string_not_null(L, "name", &effect_name);
			utils::table_get_string(L, "params", &effect_params);
			int parameter_count = 0;
			char *parameters[20];
			if (effect_params != NULL) {
				char *part = strtok(effect_params, " ");
				while (part != NULL && parameter_count < 20) {
					parameters[parameter_count++] = part;
					part = strtok(NULL, " ");
				}
			}
			const sox_effect_handler_t *effect_handler = sox_find_effect(effect_name);
			if (effect_handler != NULL) {
				sox_effect_t *effect = sox_create_effect(effect_handler);
				if (effect != NULL) {
					if (sox_effect_options(effect, parameter_count, parameters) != SOX_SUCCESS) {
						luaL_error(L, PLUGIN_NAME ": failed to set parameters for the %s effect.", effect_name);
					} else if (sox_add_effect(chain, effect, &interm_signal, &out->signal) != SOX_SUCCESS) {
						luaL_error(L, PLUGIN_NAME ": failed to add the %s effect.", effect_name);
					}
					free(effect);
				} else {
					luaL_error(L, PLUGIN_NAME ": failed to create the %s effect.", effect_name);
				}
			} else {
				luaL_error(L, PLUGIN_NAME ": failed to find the %s effect.", effect_name);
			}
		}
		lua_pop(L, 1);
	}

	lua_pop(L, 1); // effects table.
	lua_pop(L, 1); // params table.

	// Adjust sample rate and channels automatically in case of a mismatch.
	if (interm_signal.channels != out->signal.channels) {
		e = sox_create_effect(sox_find_effect("channels"));
		if (e != NULL) {
			if (sox_effect_options(e, 0, NULL) != SOX_SUCCESS || sox_add_effect(chain, e, &interm_signal, &out->signal) != SOX_SUCCESS) {
				luaL_error(L, PLUGIN_NAME ": failed to add the automatic channels effect.");
			}
			free(e);
		}
	}
	if (interm_signal.rate != out->signal.rate) {
		e = sox_create_effect(sox_find_effect("rate"));
		if (e != NULL) {
			if (sox_effect_options(e, 0, NULL) != SOX_SUCCESS || sox_add_effect(chain, e, &interm_signal, &out->signal) != SOX_SUCCESS) {
				luaL_error(L, PLUGIN_NAME ": failed to add the automatic rate effect.");
			}
			free(e);
		}
	}

	e = sox_create_effect(sox_find_effect("output"));
	args[0] = (char *)out;
	if (sox_effect_options(e, 1, args) != SOX_SUCCESS) {
		luaL_error(L, PLUGIN_NAME ": failed to create the output effect.");
	} else {
		if (sox_add_effect(chain, e, &interm_signal, &out->signal) != SOX_SUCCESS) {
			luaL_error(L, PLUGIN_NAME ": failed to add the output effect.");
		}
	}
	free(e);

	sox_flow_effects(chain, NULL, NULL);

	sox_delete_effects_chain(chain);
	sox_close(out);
	sox_close(in);

	return 0;
}

CORONA_EXPORT int luaopen_plugin_sox(lua_State *L) {
	static const luaL_Reg lua_functions[] = {
		{"init", plugin_init},
		{"quit", plugin_quit},
		{"process", plugin_process},
		{NULL, NULL}
	};

	luaL_openlib(L, PLUGIN_NAME, lua_functions, 0);

	is_initialized = false;

	return 1;
}
