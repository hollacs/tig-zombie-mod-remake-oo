/* AMX Mod X
*   No Objectives
*
* (c) Copyright 2007 by VEN
*
* This file is provided as is (no warranties)
*
*	DESCRIPTION
*		Plugin allow to remove all map objectives or objectives of certain type.
*		Round timer will be disbled for maps that doesn't contain any objectives.
*
*	CVARS
*		no_objectives (flags: acde, default: acde, "": disable the plugin)
*			a - remove "as" (vip assasination) objectives
*			c - remove "cs" (hostage rescue) objectives
*			d - remove "de" (bomb defuse) objectives
*			e - remove "es" (T escape) objectives
*		Note: map change on CVar change required.
*
*	VERSIONS
*		0.3
*			- added support for all objective entities
*			- fixed: timer wasn't shown on multi objective maps if objectives wasn't completely removed
*			- improvements in objective modes routine
*		0.2
*			- disabled round timer
*			- added no_objectives CVar
*		0.1
*			- initial version
*/

// plugin's main information
#define PLUGIN_NAME "No Objectives"
#define PLUGIN_VERSION "0.3"
#define PLUGIN_AUTHOR "VEN"

#include <amxmodx>
#include <fakemeta>

new const g_objective_ents[][] = {
	"func_bomb_target",
	"info_bomb_target",
	"hostage_entity",
	"monster_scientist",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone"
}

#define OBJTYPE_AS (1<<0)
#define OBJTYPE_CS (1<<2)
#define OBJTYPE_DE (1<<3)
#define OBJTYPE_ES (1<<4)
#define OBJTYPE_ALL (OBJTYPE_AS | OBJTYPE_CS | OBJTYPE_DE | OBJTYPE_ES)

#define CVAR_NAME "no_objectives"
#define CVAR_DEFAULT OBJTYPE_ALL

new const g_objective_type[] = {
	OBJTYPE_DE,
	OBJTYPE_DE,
	OBJTYPE_CS,
	OBJTYPE_CS,
	OBJTYPE_CS,
	OBJTYPE_CS,
	OBJTYPE_AS,
	OBJTYPE_AS,
	OBJTYPE_ES
}

new const bool:g_objective_prim[] = {
	true,
	true,
	true,
	false,
	false,
	false,
	false,
	true,
	true
}

#define HIDE_ROUND_TIMER (1<<4)

new g_msgid_hideweapon

new g_pcvar_no_objectives

new g_no_objectives = CVAR_DEFAULT & OBJTYPE_ALL

public plugin_precache() {
	if ((g_pcvar_no_objectives = get_cvar_pointer(CVAR_NAME))) {
		new cvar_val[8]
		get_pcvar_string(g_pcvar_no_objectives, cvar_val, sizeof cvar_val - 1)
		g_no_objectives = read_flags(cvar_val) & OBJTYPE_ALL
	}

	if (g_no_objectives)
		register_forward(FM_Spawn, "forward_spawn")
}

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	if (!g_pcvar_no_objectives) {
		new cvar_defval[8]
		get_flags(CVAR_DEFAULT, cvar_defval, sizeof cvar_defval - 1)
		register_cvar(CVAR_NAME, cvar_defval)
	}

	if (is_objective_map())
		return

	g_msgid_hideweapon = get_user_msgid("HideWeapon")
	register_message(g_msgid_hideweapon, "message_hide_weapon")
	register_event("ResetHUD", "event_hud_reset", "b")
	set_msg_block(get_user_msgid("RoundTime"), BLOCK_SET)
}

public forward_spawn(ent) {
	if (!pev_valid(ent))
		return FMRES_IGNORED

	static classname[32], i
	pev(ent, pev_classname, classname, sizeof classname - 1)
	for (i = 0; i < sizeof g_objective_ents; ++i) {
		if (equal(classname, g_objective_ents[i])) {
			if (!(g_no_objectives & g_objective_type[i]))
				return FMRES_IGNORED

			engfunc(EngFunc_RemoveEntity, ent)
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}

public message_hide_weapon() {
	set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | HIDE_ROUND_TIMER)
}

public event_hud_reset(id) {
	message_begin(MSG_ONE, g_msgid_hideweapon, _, id)
	write_byte(HIDE_ROUND_TIMER)
	message_end()
}

bool:is_objective_map() {
	new const classname[] = "classname"
	for (new i = 0; i < sizeof g_objective_ents; ++i) {
		if (g_objective_prim[i] && engfunc(EngFunc_FindEntityByString, FM_NULLENT, classname, g_objective_ents[i]))
			return true
	}

	return false
}
