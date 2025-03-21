#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <oo>
#include <oo_player_class>
#include <oo_player_status>
#include <ctg_player_level>

new g_HudSyncObj;

public plugin_init()
{
	register_plugin("[CTG] HUD Status", "0.1", "holla");

	set_task(0.25, "TaskUpdateHud", 0, _, _, "b");

	g_HudSyncObj = CreateHudSyncObj();
}

public TaskUpdateHud()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (is_user_alive(i) && !is_user_bot(i))
		{
			UpdateHud(i);
		}
	}
}

public UpdateHud(id)
{
	ClearSyncHud(id, g_HudSyncObj);

	new classname[32] = "---";

	new PlayerClass:class_o = oo_playerclass_get(id);
	if (class_o != @null)
		oo_call(class_o, "GetClassName", classname, charsmax(classname));

	static status[32];
	oo_playerstatus_str(id, status, charsmax(status));

	new color[3] = {0, 255, 0};
	if (status[0] == 'C' || status[0] == 'I' || status[0] == 'S' || status[0] == 'B')
		color = {255, 255, 0};
	else if (status[0] == 'D')
		color = {255, 10, 10};

	new level 	= ctg_get_player_level(id);
	new exp 	= ctg_get_player_exp(id);
	new required_exp = ctg_get_required_exp(level);

	set_hudmessage(color[0], color[1], color[2], -1.0, 0.89, 0, 0.0, 0.3, 0.0, 0.0, 4);
	ShowSyncHudMsg(id, g_HudSyncObj, "HP: %d | AP: %d | Class: %s | Status: %s^nLevel: %d | EXP: %d/%d (%.1f%%)", 
		get_user_health(id), get_user_armor(id), classname, status,
		level, exp, required_exp, exp / float(required_exp) * 100.0);
}