#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <reapi>

new Array:g_SpawnOrigin;
new Array:g_SpawnAngle;
new Array:g_SpawnViewAngle;
new g_SpawnCount;

new g_fwGetPlayerSpawnSpot;

public plugin_init()
{
	register_plugin("[CTG] CSDM Spawn", "0.1", "holla");

	RegisterHookChain(RG_CSGameRules_GetPlayerSpawnSpot, "OnGetPlayerSpawnSpot_Post", 1);

	g_SpawnOrigin = ArrayCreate(3);
	g_SpawnAngle = ArrayCreate(3);
	g_SpawnViewAngle = ArrayCreate(3);

	g_fwGetPlayerSpawnSpot = CreateMultiForward("ctg_OnGetPlayerSpawnSpot", ET_CONTINUE, FP_CELL);

	LoadSpawns();
}

public OnGetPlayerSpawnSpot_Post(id)
{
	if (!(TEAM_TERRORIST <= get_member(id, m_iTeam) <= TEAM_CT))
		return;

	new ret;
	ExecuteForward(g_fwGetPlayerSpawnSpot, ret, id);
	if (ret == PLUGIN_HANDLED)
		return;
	
	new spawn_index = random(g_SpawnCount);
	static Float:v[3];

	for (new i = spawn_index + 1; ; i++)
	{
		if (i >= g_SpawnCount) i = 0;

		ArrayGetArray(g_SpawnOrigin, i, v);

		if (IsHullVacant(v, HULL_HUMAN))
		{
			entity_set_origin(id, v);

			ArrayGetArray(g_SpawnAngle, i, v);
			set_entvar(id, var_angles, v);

			ArrayGetArray(g_SpawnViewAngle, i, v);
			set_entvar(id, var_v_angle, v);

			break;
		}

		if (i == spawn_index) break;
	}
}

LoadSpawns()
{
	static cfgdir[32], mapname[32], filepath[100];
	get_configsdir(cfgdir, charsmax(cfgdir));
	get_mapname(mapname, charsmax(mapname));
	formatex(filepath, charsmax(filepath), "%s/csdm/%s.spawns.cfg", cfgdir, mapname);

	if (file_exists(filepath))
	{
		static csdmdata[10][6];

		new fp = fopen(filepath, "rt");
		if (fp)
		{
			static linedata[64], Float:v[3];

			while (!feof(fp))
			{
				fgets(fp, linedata, charsmax(linedata));

				if(!linedata[0] || str_count(linedata,' ') < 2) continue;

				parse(linedata, 
					csdmdata[0], 5, csdmdata[1], 5, csdmdata[2], 5, 
					csdmdata[3], 5, csdmdata[4], 5, csdmdata[5], 5,
					csdmdata[6], 5, csdmdata[7], 5, csdmdata[8], 5,
					csdmdata[9], 5);
				
				v[0] = str_to_float(csdmdata[0]);
				v[1] = str_to_float(csdmdata[1]);
				v[2] = str_to_float(csdmdata[2]);
				ArrayPushArray(g_SpawnOrigin, v);

				v[0] = str_to_float(csdmdata[3]);
				v[1] = str_to_float(csdmdata[4]);
				v[2] = str_to_float(csdmdata[5]);
				ArrayPushArray(g_SpawnAngle, v);

				v[0] = str_to_float(csdmdata[6]);
				v[1] = str_to_float(csdmdata[7]);
				v[2] = str_to_float(csdmdata[8]);
				ArrayPushArray(g_SpawnViewAngle, v);

				g_SpawnCount++;
			}

			fclose(fp);
		}
	}
	else
	{
		CollectSpawnEnt("info_player_start");
		CollectSpawnEnt("info_player_deathmatch");
	}
}

IsHullVacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

CollectSpawnEnt(const classname[])
{
	new Float:v[3];
	new ent = -1;
	while ((ent = rg_find_ent_by_class(ent, classname)) != 0)
	{
		get_entvar(ent, var_origin, v)
		ArrayPushArray(g_SpawnOrigin, v);
		
		get_entvar(ent, var_angles, v)
		ArrayPushArray(g_SpawnAngle, v);
		
		get_entvar(ent, var_v_angle, v)
		ArrayPushArray(g_SpawnViewAngle, v);
		
		g_SpawnCount++;
	}
}

stock str_count(const str[], searchchar)
{
	new count, i, len = strlen(str)
	
	for (i = 0; i <= len; i++)
	{
		if(str[i] == searchchar)
			count++
	}
	
	return count;
}