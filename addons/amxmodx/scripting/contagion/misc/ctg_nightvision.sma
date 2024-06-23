#include <amxmodx>
#include <reapi>
#include <oo_player_class>

new const SOUND_NVGON[] = "items/nvg_on.wav";
new const SOUND_NVGOFF[] = "items/nvg_off.wav";

new bool:g_HasNightVision[MAX_PLAYERS + 1];
new g_NightVisionOn[MAX_PLAYERS + 1];
new Float:g_NextUpdateTime[MAX_PLAYERS + 1];

public plugin_precache()
{
	precache_sound(SOUND_NVGON);
	precache_sound(SOUND_NVGOFF);
}

public plugin_init()
{
	register_plugin("[CTG] Night Vision", "0.1", "holla");

	oo_hook_mthd("PlayerClass", "SetProps", "OnPlayerClassSetProps");

	register_clcmd("nightvision", "CmdNightVision");

	oo_hook_mthd("Player", "OnKilled", "OnPlayerKilled");
	oo_hook_mthd("Player", "OnSpawn", "OnPlayerSpawn");
	oo_hook_mthd("Player", "OnPreThink", "OnPlayerPreThink");
}

public plugin_natives()
{
	register_library("ctg_nightvision");

	register_native("ctg_nightvision_set", "native_nightvision_set");
	register_native("ctg_nightvision_get", "native_nightvision_get");
	register_native("ctg_nightvision_toggle", "native_nightvision_toggle");
}

public native_nightvision_set()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return;
	}

	g_HasNightVision[id] = bool:get_param(2);
}

public bool:native_nightvision_get()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return false;
	}

	return g_HasNightVision[id];
}

public native_nightvision_toggle()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return;
	}

	NightVisionToggle(id, bool:get_param(2));
}

public OnPlayerKilled()
{
	new id = oo_get(@this, "player_id");
	g_NightVisionOn[id] = false;
	g_HasNightVision[id] = false;
	g_NextUpdateTime[id] = 0.0;
}

public OnPlayerSpawn()
{
	new id = oo_get(@this, "player_id");
	g_NightVisionOn[id] = false;
}

public OnPlayerClassSetProps(bool:set_team)
{
	new id = oo_get(@this, "player_id");
	if (oo_playerclass_isa(id, "Human"))
		g_HasNightVision[id] = false;
	else if (oo_playerclass_isa(id, "Zombie"))
		g_HasNightVision[id] = true;
}

public OnPlayerPreThink()
{
	new id = oo_get(@this, "player_id");
	if (is_user_alive(id) && !g_HasNightVision[id])
		return;

	if (!g_NightVisionOn[id])
		return;

	new Float:gametime = get_gametime();
	if (gametime < g_NextUpdateTime[id])
		return;

	static Float:origin[3];
	get_entvar(id, var_origin, origin);

	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	write_byte(TE_DLIGHT);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_byte(80);

	if (!is_user_alive(id))
	{
		write_byte(0);
		write_byte(60);
		write_byte(90);
	}
	else if (oo_playerclass_isa(id, "Zombie"))
	{
		write_byte(90);
		write_byte(60);
		write_byte(0);
	}
	else
	{
		write_byte(45);
		write_byte(60);
		write_byte(45);
	}

	new ping, loss;
	get_user_ping(id, ping, loss);

	new Float:interval = gametime - (g_NextUpdateTime[id] - 0.1);
	new life = max(floatround((interval + ping * 0.001 + loss * 0.001) * 10.0, floatround_ceil), 3);
	//server_print("life = %d, ping = %d, loss = %d, interval = %f", life, ping, loss, interval);

	write_byte(life);
	write_byte(0);
	message_end();

	g_NextUpdateTime[id] = gametime + 0.1;
}

public CmdNightVision(id)
{
	if (is_user_alive(id) && !g_HasNightVision[id])
		return PLUGIN_HANDLED;

	NightVisionToggle(id, !g_NightVisionOn[id]);
	return PLUGIN_HANDLED;
}

NightVisionToggle(id, bool:toggle)
{
	g_NightVisionOn[id] = toggle;
	g_NextUpdateTime[id] = get_gametime();

	if (oo_playerclass_isa(id, "Zombie"))
		client_cmd(id, "spk %s", toggle ? SOUND_NVGON : SOUND_NVGOFF);
	else
		emit_sound(id, CHAN_ITEM, toggle ? SOUND_NVGON : SOUND_NVGOFF, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}