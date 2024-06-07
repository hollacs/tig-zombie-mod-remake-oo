#include <amxmodx>
#include <engine>
#include <fakemeta>

new g_GlobalLights[2];
new g_PlayerLights[MAX_PLAYERS + 1][2];

public plugin_init()
{
	register_plugin("[CS] Light Style", "0.1", "holla");

	register_forward(FM_LightStyle, "OnLightStyle_Post", 1);

	new pcvar = create_cvar("cs_lightstyle", "");
	hook_cvar_change(pcvar, "CvarLightStyleCallback");
}

public plugin_natives()
{
	register_library("cs_lightstyle");

	register_native("cs_set_player_lights", "native_set_player_lights");
	register_native("cs_set_lights", "native_set_player_lights");
}

public native_set_player_lights()
{
	new player = get_param(1);
	if (!is_user_connected(player))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", player);
		return;
	}

	static lights[2];
	get_string(2, lights, charsmax(lights));

	SetPlayerLights(player, lights);
}

public native_set_lights()
{
	static lights[2];
	get_string(1, lights, charsmax(lights));

	SetGlobalLights(lights);
}

public client_disconnected(id)
{
	g_PlayerLights[id][0] = 0;
}

public OnLightStyle_Post(style, const pattern[])
{
	if (!style)
	{
		SetGlobalLights(pattern);
	}
}

public CvarLightStyleCallback(pcvar, const old_value[], const new_value[])
{
	SetGlobalLights(new_value);
}

SetPlayerLights(id, const lights[])
{
	g_PlayerLights[id][0] = lights[0];

	message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, _, id);
	write_byte(0);
	write_string(lights[0] ? g_PlayerLights[id] : g_GlobalLights);
	message_end();
}

SetGlobalLights(const lights[])
{
	g_GlobalLights[0] = lights[0];

	set_lights(g_GlobalLights);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (is_user_connected(i) && g_PlayerLights[i][0])
		{
			message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, _, i);
			write_byte(0);
			write_string(g_PlayerLights[i]);
			message_end();
		}
	}
}

