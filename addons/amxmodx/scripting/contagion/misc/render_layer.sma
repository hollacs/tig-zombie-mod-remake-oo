#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <render_layer_const>

#define MAX_LAYERS 16
#define MIN_INT -9999999

new g_Current[MAX_PLAYERS + 1] = {-1, ...};
new g_Rendering[MAX_PLAYERS + 1][MAX_LAYERS][RenderingData];
new Float:g_NextUpdate[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("Player Rendering Layer", "0.1", "holla");

	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", 1);
}

public plugin_natives()
{
	register_library("render_layer");

	register_native("render_push", "native_push");
	register_native("render_pop", "native_pop");
	register_native("render_clear", "native_clear");
	register_native("render_current", "native_current");
	register_native("render_get_data", "native_get_data");
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

	new color[3];
	get_array(3, color, sizeof color);

	new mode = get_param(4);
	new amount = get_param(5);
	new Float:duration = get_param_f(6);

	new class[32];
	get_string(7, class, charsmax(class));

	new zindex = get_param(8);

	return PushRendering(id, fx, color, mode, amount, duration, class, zindex);
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

	ClearRenderingLayers(id);
}

public native_current()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return -1;
	}

	return g_Current[id];
}

public native_get_data()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return;
	}

	new index = get_param(2);
	if (index < 0 || index >= MAX_LAYERS)
	{
		log_error(AMX_ERR_NATIVE, "Index (%d) out of bounds", index);
		return;
	}

	set_array(3, g_Rendering[id][index], RenderingData);
}

public OnPlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return;
	
	ClearRenderingLayers(id);
}

public client_PreThink(id)
{
	// performance improve
	new Float:gametime = get_gametime();
	if (gametime < g_NextUpdate[id])
		return;

	for (new i = 0; i < MAX_LAYERS; i++)
	{
		// filter empty layer and permanent duration
		if (!g_Rendering[id][i][render_index] || g_Rendering[id][i][render_until] == 0.0)
			continue;
		
		// time's up
		if (gametime >= g_Rendering[id][i][render_until])
			PopRendering(id, i); // pop this layer
	}
	
	g_NextUpdate[id] = gametime + 0.1;
}

public client_disconnected(id)
{
	ClearRenderingLayers(id)
}

PushRendering(id, fx=kRenderFxNone, color[3]={0, 0, 0}, mode=kRenderNormal, amount=0, Float:duration=0.0, const class[]="", zindex=0)
{
	new ii = -1;
	new index = -1;

	// class is not empty
	if (class[0])
	{
		for (new i = 0; i < MAX_LAYERS; i++)
		{
			// find the layer index of this class name
			if (equal(g_Rendering[id][i][render_class], class))
			{
				ii = i;
				index = g_Rendering[id][i][render_index];
				break; // found
			}
		}
	}

	if (ii == -1)
	{
		for (new i = 0; i < MAX_LAYERS; i++)
		{
			// find a empty layer slot to insert
			if (!g_Rendering[id][i][render_index])
			{
				ii = i;
				for (new j = 0; j < MAX_LAYERS; j++)
				{
					// find a suitable layer index
					if (g_Rendering[id][j][render_index] > index)
						index = g_Rendering[id][j][render_index];
				}
				index++; // increase by 1
				break; // found
			}
		}

		if (ii == -1)
			return -1;
	}

	// set rendering data
	g_Rendering[id][ii][render_fx] = fx;
	g_Rendering[id][ii][render_mode] = mode;
	g_Rendering[id][ii][render_color] = color;
	g_Rendering[id][ii][render_amount] = amount;

	// set duration
	if (duration > 0.0)
		g_Rendering[id][ii][render_until] = get_gametime() + duration;
	else
		g_Rendering[id][ii][render_until] = 0.0

	// set class name
	copy(g_Rendering[id][ii][render_class], charsmax(g_Rendering[][][render_class]), class);

	// set index and zindex
	g_Rendering[id][ii][render_index] = index;
	g_Rendering[id][ii][render_zindex] = zindex;

	new max_zindex = MIN_INT;

	// find the max zindex
	for (new i = 0; i < MAX_LAYERS; i++)
	{
		if (i != ii &&
			g_Rendering[id][i][render_index] && 
			g_Rendering[id][i][render_zindex] >= max_zindex)
		{
			max_zindex = g_Rendering[id][i][render_zindex];
		}
	}

	// stop here if current zindex is lower than max zindex
	if (zindex < max_zindex)
		return ii;

	g_Current[id] = ii;
	SetRendering(id, ii);

	return ii;
}

PopRendering(id, pop_index=-1, const class[]="")
{
	// class is not empty
	if (class[0])
	{
		pop_index = -1;

		// find the layer index of this class name
		for (new i = 0; i < MAX_LAYERS; i++)
		{
			if (equal(class, g_Rendering[id][i][render_class]))
			{
				pop_index = i;
				break; // found
			}
		}

		// not found
		if (pop_index == -1)
			return;
	}

	// the layer is empty
	if (!g_Rendering[id][pop_index][render_index])
		return;
	
	// clear this layer data
	g_Rendering[id][pop_index][render_index] = 0;
	g_Rendering[id][pop_index][render_class][0] = 0;

	new max_zindex = MIN_INT;
	new ii = -1;

	// find max zindex
	for (new i = 0; i < MAX_LAYERS; i++)
	{
		if (g_Rendering[id][i][render_index] && g_Rendering[id][i][render_zindex] > max_zindex)
		{
			max_zindex = g_Rendering[id][i][render_zindex];
			ii = i;
		}
	}

	// not found, which means all layers have been cleared.
	if (ii == -1)
	{
		g_Current[id] = -1;
		ResetRendering(id);
		return;
	}
	
	new index = 0;
	for (new i = 0; i < MAX_LAYERS; i++)
	{
		// check if there is some layer having the same zindex
		if (g_Rendering[id][i][render_index] && g_Rendering[id][i][render_zindex] == max_zindex)
		{
			if (g_Rendering[id][i][render_index] > index)
			{
				// if there is more than 2 occurs
				if (index)
					ii = i; // change the ii to this

				index = g_Rendering[id][i][render_index];
			}
		}
	}

	g_Current[id] = ii;
	SetRendering(id, ii);
}

ClearRenderingLayers(id)
{
	g_Current[id] = -1;

	for (new i = 0; i < MAX_LAYERS; i++)
	{
		g_Rendering[id][i][render_index] = 0;
		g_Rendering[id][i][render_class][0] = 0;
	}

	ResetRendering(id);
}

ResetRendering(id)
{
	entity_set_int(id, EV_INT_renderfx, kRenderFxNone);
	entity_set_int(id, EV_INT_rendermode, kRenderNormal);
	entity_set_vector(id, EV_VEC_rendercolor, Float:{0.0, 0.0, 0.0});
	entity_set_float(id, EV_FL_renderamt, 0.0);
}

SetRendering(id, index)
{
	static Float:color[3];
	IVecFVec(g_Rendering[id][index][render_color], color);

	entity_set_int(id, EV_INT_renderfx, g_Rendering[id][index][render_fx]);
	entity_set_int(id, EV_INT_rendermode, g_Rendering[id][index][render_mode]);
	entity_set_vector(id, EV_VEC_rendercolor, color);
	entity_set_float(id, EV_FL_renderamt, float(g_Rendering[id][index][render_amount]));
}