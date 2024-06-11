#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <xs>

#define DEBUG
#define MAX_SPAWNS 256

new sprite_beam;

new Float:g_NodeOrigin[MAX_SPAWNS][3];
new Float:g_NodeAngle[MAX_SPAWNS][3];
new bool:g_NodeDucking[MAX_SPAWNS];
new g_NodeCount;

new Float:g_Origin[MAX_PLAYERS + 1][3];
new Float:g_Angle[MAX_PLAYERS + 1][3];
new Float:g_NextUpdate[MAX_PLAYERS + 1];
new g_NodeIndex[MAX_PLAYERS + 1] = {-1, ...};

new Float:cvar_distance;

public plugin_precache()
{
	sprite_beam = precache_model("sprites/laserbeam.spr");
}

public plugin_init()
{
	register_plugin("Walk Node", "0.1", "holla");

	LoadNodes();

	bind_pcvar_float(create_cvar("walknode_distance", "100"), cvar_distance);

#if defined DEBUG
	set_task(1.0, "ShowNodes", 0, _, _, "b");
#endif
}

public plugin_natives()
{
	register_library("walknode");

	register_native("walknode_get_origin", "native_get_origin");
	register_native("walknode_get_angle", "native_get_angle");
	register_native("walknode_get_ducking", "native_get_ducking");
	register_native("walknode_count", "native_count");
}

public native_get_origin()
{
	new index = get_param(1);
	if (index < 0 || index >= g_NodeCount)
	{
		log_error(AMX_ERR_NATIVE, "index (%d) out of bounds", index);
		return;
	}

	static Float:origin[3];
	origin[0] = g_NodeOrigin[index][0];
	origin[1] = g_NodeOrigin[index][1];
	origin[2] = g_NodeOrigin[index][2];

	set_array_f(2, origin, 3);
}

public native_get_angle()
{
	new index = get_param(1);
	if (index < 0 || index >= g_NodeCount)
	{
		log_error(AMX_ERR_NATIVE, "index (%d) out of bounds", index);
		return;
	}

	static Float:angle[3];
	angle[0] = g_NodeAngle[index][0];
	angle[1] = g_NodeAngle[index][1];
	angle[2] = g_NodeAngle[index][2];

	set_array_f(2, angle, 3);
}

public bool:native_get_ducking()
{
	new index = get_param(1);
	if (index < 0 || index >= g_NodeCount)
	{
		log_error(AMX_ERR_NATIVE, "index (%d) out of bounds", index);
		return false;
	}

	return g_NodeDucking[index];
}

public native_count()
{
	return g_NodeCount;
}

public plugin_end()
{
	SaveNodes();
}

public client_disconnected(id)
{
	g_NodeIndex[id] = -1;
	g_NextUpdate[id] = 0.0;
}

public client_PreThink(id)
{	
	if (g_NodeCount >= MAX_SPAWNS)
		return;

	if (g_NodeIndex[id] == -1)
	{
		new Float:current_time = get_gametime();
		if (current_time >= g_NextUpdate[id])
		{
			if (IsPlayerOnGround(id))
			{
				static Float:origin[3];
				entity_get_vector(id, EV_VEC_origin, origin);

				if (get_distance_f(origin, g_Origin[id]) > cvar_distance)
				{
					entity_get_vector(id, EV_VEC_angles, g_Angle[id]);

					g_Origin[id] = origin;
					g_NodeIndex[id] = 0;
					g_NextUpdate[id] = current_time + 1.0;
				}
			}
		}
	}
	else
	{
		new count = 0;
		while (count < 5)
		{
			if (get_distance_f(g_Origin[id], g_NodeOrigin[g_NodeIndex[id]]) <= cvar_distance)
			{
				g_NodeIndex[id] = -1;
				break;
			}
			else
			{
				g_NodeIndex[id]++;
				count++;

				if (g_NodeIndex[id] >= g_NodeCount)
				{
					g_NodeOrigin[g_NodeCount] = g_Origin[id];
					g_NodeAngle[g_NodeCount] = g_Angle[id];
					g_NodeDucking[g_NodeCount] = CheckOriginIsDucking(g_Origin[id]);
					g_NodeCount++
					g_NodeIndex[id] = -1;
					break;
				}
			}
		}
	}
}

#if defined DEBUG
public ShowNodes()
{
	static Float:origin[3];
	for (new i = 1; i < MaxClients; i++)
	{
		if (!is_user_connected(i) || is_user_bot(i))
			continue;

		entity_get_vector(i, EV_VEC_origin, origin);
		
		for (new j = 0; j < g_NodeCount; j++)
		{
			if (get_distance_f(origin, g_NodeOrigin[j]) > 500.0)
				continue;

			CreateBeamPoints(i, MSG_ONE_UNRELIABLE, g_NodeOrigin[j], 
				g_NodeOrigin[j][0], g_NodeOrigin[j][1], g_NodeOrigin[j][2] - 36.0,
				g_NodeOrigin[j][0], g_NodeOrigin[j][1], g_NodeOrigin[j][2] + 36.0,
				sprite_beam, 0, 0, 10, 20, 0, {0, 255, 0}, 255, 0);
		}
	}
}
#endif

LoadNodes()
{
	static filepath[100], mapname[32];
	get_configsdir(filepath, charsmax(filepath));
	get_mapname(mapname, charsmax(mapname));

	format(filepath, charsmax(filepath), "%s/walknode/%s.node", filepath, mapname);

	new file = fopen(filepath, "r");
	if (!file)
		return;

	g_NodeCount = 0;

	static linedata[96], data_o[3][16], data_a[3][16], data_d[2], i;
	while (!feof(file))
	{
		fgets(file, linedata, charsmax(linedata));
		trim(linedata);

		if (!linedata[0])
			continue;

		parse(linedata, 
			data_o[0], 15, data_o[1], 15, data_o[2], 15,
			data_a[0], 15, data_a[1], 15, data_a[2], 15, 
			data_d, 1);

		for (i = 0; i < 3; i++)
		{
			g_NodeOrigin[g_NodeCount][i] = str_to_float(data_o[i]);
			g_NodeAngle[g_NodeCount][i] = str_to_float(data_a[i]);
		}
		g_NodeDucking[g_NodeCount] = bool:str_to_num(data_d);

		g_NodeCount++;
	}

	fclose(file);
}

SaveNodes()
{
	static filepath[100], mapname[32];
	get_configsdir(filepath, charsmax(filepath));
	get_mapname(mapname, charsmax(mapname));

	format(filepath, charsmax(filepath), "%s/walknode/%s.node", filepath, mapname);

	new file = fopen(filepath, "w");
	if (!file)
		return;

	for (new i = 0; i < g_NodeCount; i++)
	{
		fprintf(file, "%f %f %f %f %f %f %d^n",
			g_NodeOrigin[i][0], g_NodeOrigin[i][1], g_NodeOrigin[i][2],
			g_NodeAngle[i][0], g_NodeAngle[i][1], g_NodeAngle[i][2],
			g_NodeDucking[i]);
	}
	
	fclose(file);
}

bool:IsPlayerOnGround(id)
{
	new flags = entity_get_int(id, EV_INT_flags);
	if (~flags & FL_ONGROUND)
		return false;

	static Float:v1[3], Float:v2[3];
	entity_get_vector(id, EV_VEC_origin, v1);
	v2 = v1;
	v2[2] -= 16.0;

	engfunc(EngFunc_TraceHull, v1, v2, IGNORE_MONSTERS, 
		(flags & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN,
		id, 0);

	static Float:fraction;
	get_tr2(0, TR_flFraction, fraction);

	return (fraction == 0.0)
}

bool:CheckOriginIsDucking(Float:origin[3])
{
	static Float:v1[3], Float:v2[3];
	v1 = origin;
	v2 = v1;
	v2[2] -= 36.0;

	engfunc(EngFunc_TraceHull, v1, v2, IGNORE_MONSTERS, HULL_HEAD, 0, 0);
	get_tr2(0, TR_vecEndPos, v1);

	v1[2] += 18.0
	engfunc(EngFunc_TraceHull, v1, v1, IGNORE_MONSTERS, HULL_HUMAN, 0, 0);

	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return false;

	return true;
}

CreateBeamPoints(id, dest, Float:origin[3], 
	Float:start_x, Float:start_y, Float:start_z, 
	Float:end_x, Float:end_y, Float:end_z, 
	sprite, startframe, framerate, life, width, noise, color[3], brightness, scroll)
{
	message_begin_f(dest, SVC_TEMPENTITY, origin, id);
	write_byte(TE_BEAMPOINTS);
	write_coord_f(start_x); // startposition.x
	write_coord_f(start_y); // startposition.y
	write_coord_f(start_z); // startposition.z
	write_coord_f(end_x); // endposition.x
	write_coord_f(end_y); // endposition.y
	write_coord_f(end_z); // endposition.z
	write_short(sprite); // sprite index
	write_byte(startframe); // starting frame
	write_byte(framerate); // frame rate in 0.1's
	write_byte(life); // life in 0.1's
	write_byte(width); // line width in 0.1's
	write_byte(noise); // noise amplitude in 0.01's
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
	write_byte(brightness); // brightness
	write_byte(scroll); // scroll speed in 0.1's
	message_end();
}