#include <amxmodx>
#include <reapi>

#define MAX_LAYERS 16

enum Rendering
{
	render_fx,
	render_mode,
	Float:render_color[3],
	Float:render_amount,
	Float:render_until,
	render_class[32],
	render_zindex
};

new g_Rendering[MAX_PLAYERS + 1][MAX_LAYERS][Rendering];
new Float:g_NextUpdate[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("Player Rendering Layer", "0.1", "holla");

	RegisterHookChain(RG_CBasePlayer_PreThink, "OnPlayerPreThink");
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn_Post", 1);
}

public plugin_natives()
{
	register_library("player_rendering_layer");

	register_native("render_push", "native_push");
	register_native("render_pop", "native_pop");
	register_native("render_clear", "native_clear");
}

public native_push()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return -1;
	}

	new fx = get_param(2);

	new Float:color[3];
	get_array_f(3, color, sizeof color);

	new mode = get_param(4);
	new Float:amount = get_param_f(5);
	new Float:duration = get_param_f(6);

	new class[32];
	get_string(7, class, charsmax(class));

	return PushRendering(id, fx, color, mode, amount, duration, class);
}

public native_pop()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return;
	}

	new pop_index = get_param(2);

	new class[32];
	get_string(3, class, charsmax(class));

	PopRendering(id, pop_index, class);
}

public native_clear()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return;
	}

	ClearRendering(id);
}

public OnPlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return;
	
	ClearRendering(id);
}

public OnPlayerPreThink(id)
{
	new Float:gametime = get_gametime();
	if (gametime < g_NextUpdate[id])
		return;

	for (new i = 0; i < MAX_LAYERS; i++)
	{
		if (!g_Rendering[id][i][render_zindex] || g_Rendering[id][i][render_until] == 0.0)
			continue;
		
		if (gametime >= g_Rendering[id][i][render_until])
			PopRendering(id, i, "");
	}
	
	g_NextUpdate[id] = gametime + 0.1;
}

public client_disconnected(id)
{
	ClearRendering(id);
}

PushRendering(id, fx, Float:color[3], mode, Float:amount, Float:duration, const class[])
{
	new zindex = 0;
	new index2 = -1;
	new index = -1;
	for (new i = 0; i < MAX_LAYERS; i++)
	{
		if (g_Rendering[id][i][render_zindex] > zindex)
		{
			zindex = g_Rendering[id][i][render_zindex];

			if (!index2 && equal(class, g_Rendering[id][index][render_class]))
				index2 = i;
		}
		else if (index == -1)
		{
			index = i;
		}
	}

	if (index2 != -1)
		index = index2;

	if (index == -1)
		return -1;

	g_Rendering[id][index][render_fx] = fx;
	g_Rendering[id][index][render_mode] = mode;
	g_Rendering[id][index][render_color] = color;
	g_Rendering[id][index][render_amount] = amount;
	g_Rendering[id][index][render_until] = (duration == 0.0) ? duration : get_gametime() + duration;
	
	if (index2 == -1)
	{
		g_Rendering[id][index][render_zindex] = zindex + 1;
		copy(g_Rendering[id][index][render_class], 31, class);
	}

	if (index2 == -1 || g_Rendering[id][index2][render_zindex] >= zindex)
	{
		set_entvar(id, var_renderfx, fx);
		set_entvar(id, var_rendermode, mode);
		set_entvar(id, var_rendercolor, color);
		set_entvar(id, var_renderamt, amount);
	}

	return index;
}

PopRendering(id, pop_index, const class[])
{
	if (class[0])
	{
		pop_index = -1;
		for (new i = 0; i < MAX_LAYERS; i++)
		{
			if (equal(class, g_Rendering[id][i][render_class]))
			{
				pop_index = i;
				break;
			}
		}

		if (pop_index == -1)
			return;
	}

	new index = -1;
	new zindex = 0;
	for (new i = 0; i < MAX_LAYERS; i++)
	{
		if (g_Rendering[id][i][render_zindex] > zindex)
		{
			if (g_Rendering[id][i][render_zindex] < g_Rendering[id][pop_index][render_zindex])
				index = i;

			zindex = g_Rendering[id][i][render_zindex];
		}
	}

	new pop_zindex = g_Rendering[id][pop_index][render_zindex];
	g_Rendering[id][pop_index][render_zindex] = 0;
	g_Rendering[id][pop_index][render_class][0] = 0;

	if (zindex > pop_zindex)
		return;

	if (index == -1)
	{
		set_entvar(id, var_renderfx, kRenderFxNone);
		set_entvar(id, var_rendermode, kRenderNormal);
		set_entvar(id, var_rendercolor, Float:{0.0, 0.0, 0.0});
		set_entvar(id, var_renderamt, 0.0);
		return;
	}

	set_entvar(id, var_renderfx, g_Rendering[id][index][render_fx]);
	set_entvar(id, var_rendermode, g_Rendering[id][index][render_mode]);
	set_entvar(id, var_rendercolor, g_Rendering[id][index][render_color]);
	set_entvar(id, var_renderamt, g_Rendering[id][index][render_amount]);
}

ClearRendering(id)
{
	for (new i = 0; i < MAX_LAYERS; i++)
	{
		g_Rendering[id][i][render_zindex] = 0;
	}

	set_entvar(id, var_renderfx, kRenderFxNone);
	set_entvar(id, var_rendermode, kRenderNormal);
	set_entvar(id, var_rendercolor, Float:{0.0, 0.0, 0.0});
	set_entvar(id, var_renderamt, 0.0);
}