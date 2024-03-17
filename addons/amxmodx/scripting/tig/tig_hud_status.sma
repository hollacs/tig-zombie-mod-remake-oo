#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <oo>
#include <oo_player_class>

new g_HudSyncObj;

public plugin_init()
{
	register_plugin("[TiG] HUD Status", "0.1", "holla");

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

	set_hudmessage(0, 255, 0, 0.015, 0.93, 0, 0.0, 0.3, 0.0, 0.0, 4);
	ShowSyncHudMsg(id, g_HudSyncObj, "HP: %d | AP: %d | Class: %s", 
		get_user_health(id),
		get_user_armor(id),
		classname);
}