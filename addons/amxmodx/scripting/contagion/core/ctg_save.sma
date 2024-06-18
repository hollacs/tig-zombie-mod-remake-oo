#include <amxmodx>
#include <ctg_database>

new Float:g_NextSave[MAX_PLAYERS + 1];
new Float:cvar_wait;

public plugin_init()
{
	register_plugin("[CTG] Save", "0.1", "holla");

	register_clcmd("say /save", "CmdSave");

	bind_pcvar_float(create_cvar("ctg_save_wait", "10"), cvar_wait);
}

public CmdSave(id)
{
	new Float:gametime = get_gametime();
	if (gametime < g_NextSave[id])
	{
		client_print_color(id, print_team_red, "^4[Save] ^3請等候 ^1%d ^3秒後再使用", floatround(g_NextSave[id] - gametime, floatround_ceil));
		return PLUGIN_HANDLED;
	}

	ctg_db_save_player_data(id, true);
	g_NextSave[id] = get_gametime() + cvar_wait;
	return PLUGIN_CONTINUE;
}