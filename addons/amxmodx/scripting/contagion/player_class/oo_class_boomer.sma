#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <oo_player_class>
#include <oo_assets>
#include <cs_painshock>
#include <csdm_spawn>
#include <walknode>
#include <xs>

new PlayerClassInfo:g_oClassInfo;

new Float:cvar_radius, Float:cvar_mindmg, Float:cvar_maxdmg, cvar_traceline, Float:cvar_spawntime;
new sprite_shockwave;

public oo_init()
{
	oo_class("Boomer", "SpecialInfected");
	{
		new const cl[] = "Boomer";
		oo_var(cl, "start_hold_time", 1);

		oo_mthd(cl, "GetClassInfo");
		oo_mthd(cl, "OnCmdStart", @int(uc), @int(seed));
		oo_mthd(cl, "OnKilledBy", @int(attacker), @int(shouldgibs));
		oo_mthd(cl, "Boom", @bool(kill));
		oo_mthd(cl, "CreateSpawnEnt");
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "Boomer");
	oo_call(g_oClassInfo, "Clone", oo_call(0, "SpecialInfected@ClassInfo"));
	oo_call(g_oClassInfo, "LoadJson", "boomer.json");
}

public plugin_init()
{
	register_plugin("[OO] Class: Boomer", "0.1", "holla");

	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRestartRound");

	register_think("boomer_spawn", "OnBoomerSpawn");

	bind_pcvar_float(create_cvar("ctg_boomer_explo_radius", "240"), cvar_radius);
	bind_pcvar_float(create_cvar("ctg_boomer_explo_min_dmg", "1"), cvar_mindmg);
	bind_pcvar_float(create_cvar("ctg_boomer_explo_max_dmg", "50"), cvar_maxdmg);
	bind_pcvar_num(create_cvar("ctg_boomer_explo_traceline", "1"), cvar_traceline);
	bind_pcvar_float(create_cvar("ctg_boomer_explo_spawn_time", "30"), cvar_spawntime);

	oo_call(g_oClassInfo, "CreateCvars");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_boomer", "health", "3000");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_boomer", "health2", "100");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_boomer", "gravity", "1.0");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_boomer", "speed", "0.95");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_boomer", "dmg", "1.15");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_boomer", "knockback", "0.8");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_boomer", "painshock", "0.9");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_boomer", "swing_speed", "1.75");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_boomer", "stab_speed", "1.25");

	sprite_shockwave = AssetsGetSprite(g_oClassInfo, "shockwave");
}

public PlayerClassInfo:Boomer@GetClassInfo()
{
	return g_oClassInfo;
}

public Boomer@OnCmdStart(uc, seed)
{
	new this = oo_this();
	new id = oo_get(this, "player_id");

	if (!is_user_alive(id))
		return;

	new Float:gametime = get_gametime();
	if (!is_user_bot(id))
	{
		new buttons = get_uc(uc, UC_Buttons);
		new oldbuttons = get_entvar(id, var_oldbuttons);

		new Float:start_hold_time = Float:oo_get(this, "start_hold_time");
		if (start_hold_time == 0.0 && (buttons & IN_RELOAD) && !(oldbuttons & IN_RELOAD))
		{
			cs_painshock_set(id, 0.0);
			oo_set(this, "start_hold_time", gametime);
			SendBarTime(id, 1);
		}

		if (start_hold_time > 0.0)
		{
			if (!(buttons & IN_RELOAD) && (oldbuttons & IN_RELOAD))
			{
				oo_set(this, "start_hold_time", 0.0);
				SendBarTime(id, 0);
			}
			else if (gametime - start_hold_time >= 1.0)
			{
				oo_set(this, "start_hold_time", 0.0);

				set_uc(uc, UC_Buttons, buttons & ~IN_RELOAD);
				set_entvar(id, var_oldbuttons, oldbuttons | IN_RELOAD);

				oo_call(this, "Boom", true);
			}
		}
	}
	else
	{
		new Float:start_hold_time = Float:oo_get(this, "start_hold_time");
		if (start_hold_time == 0.0)
		{
			new near_count = 0;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (!is_user_alive(i) || !oo_playerclass_isa(i, "Human"))
					continue;
				
				if (entity_range(id, i) <= cvar_radius * 0.75)
					near_count++;
			}

			if (near_count >= 3)
			{
				cs_painshock_set(id, 0.0);
				oo_set(this, "start_hold_time", gametime);
			}
		}

		if (start_hold_time > 0.0 && gametime - start_hold_time >= 1.0)
		{
			oo_set(this, "start_hold_time", 0.0);
			oo_call(this, "Boom", true);
		}
	}
}

public Boomer@OnKilledBy(attacker, shouldgibs)
{
	new this = oo_this();
	oo_call(this, "Boom", false);
}

public Boomer@Boom(bool:kill)
{
	new this = oo_this();
	new id = oo_get(this, "player_id");

	static Float:origin[3];
	get_entvar(id, var_origin, origin);

	if (sprite_shockwave)
	{
		message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
		write_byte(TE_BEAMCYLINDER); // TE id
		write_coord_f(origin[0]); // x
		write_coord_f(origin[1]); // y
		write_coord_f(origin[2] + 16.0); // z
		write_coord_f(origin[0]); // x axis
		write_coord_f(origin[1]); // y axis
		write_coord_f(origin[2] + 385.0); // z axis
		write_short(sprite_shockwave); // sprite
		write_byte(0); // startframe
		write_byte(0); // framerate
		write_byte(4); // life
		write_byte(30); // width
		write_byte(0); // noise
		write_byte(50); // red
		write_byte(255); // green
		write_byte(0); // blue
		write_byte(200); // brightness
		write_byte(0); // speed
		message_end();
		
		message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
		write_byte(TE_BEAMCYLINDER); // TE id
		write_coord_f(origin[0]); // x
		write_coord_f(origin[1]); // y
		write_coord_f(origin[2] + 16.0); // z
		write_coord_f(origin[0]); // x axis
		write_coord_f(origin[1]); // y axis
		write_coord_f(origin[2] + 470.0); // z axis
		write_short(sprite_shockwave); // sprite
		write_byte(0); // startframe
		write_byte(0); // framerate
		write_byte(4); // life
		write_byte(30); // width
		write_byte(0); // noise
		write_byte(50); // red
		write_byte(255); // green
		write_byte(0); // blue
		write_byte(200); // brightness
		write_byte(0); // speed
		message_end();

		message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
		write_byte(TE_BEAMCYLINDER); // TE id
		write_coord_f(origin[0]); // x
		write_coord_f(origin[1]); // y
		write_coord_f(origin[2] + 16.0); // z
		write_coord_f(origin[0]); // x axis
		write_coord_f(origin[1]); // y axis
		write_coord_f(origin[2] + 555.0); // z axis
		write_short(sprite_shockwave); // sprite
		write_byte(0); // startframe
		write_byte(0); // framerate
		write_byte(4); // life
		write_byte(30); // width
		write_byte(0); // noise
		write_byte(50); // red
		write_byte(255); // green
		write_byte(0); // blue
		write_byte(200); // brightness
		write_byte(0); // speed
		message_end();
	}
	
	message_begin_f(MSG_PAS, SVC_TEMPENTITY, origin);
	write_byte(TE_DLIGHT);
	write_coord_f(origin[0]); // position.x
	write_coord_f(origin[1]); // position.y
	write_coord_f(origin[2]); // position.z
	write_byte(30); // radius in 10's
	write_byte(50); // red
	write_byte(255); // green
	write_byte(0); // blue
	write_byte(6); // life in 0.1's
	write_byte(40) // decay rate in 0.1's
	message_end();

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_PARTICLEBURST); // TE id
	write_coord_f(origin[0]); // position.x
	write_coord_f(origin[1]); // position.y
	write_coord_f(origin[2]); // position.z
	write_short(100) // radius
	write_byte(72) // color
	write_byte(6) // duration (will be randomized a bit)
	message_end()

	static sound[100];
	if (AssetsGetRandomSound(g_oClassInfo, "explosion", sound, charsmax(sound)))
		emit_sound(id, CHAN_BODY, sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	new attacker = id;
	new victim = -1;
	new Float:damage

	while ((victim = find_ent_in_sphere(victim, origin, cvar_radius)))
	{
		if (!is_user_alive(victim) || !oo_playerclass_isa(victim, "Human"))
			continue;

		if (cvar_traceline && !CheckTraceLine(attacker, victim))
			continue;

		damage = floatmax((1.0 - entity_range(victim, attacker) / cvar_radius) * cvar_maxdmg, cvar_mindmg);
		ExecuteHamB(Ham_TakeDamage, victim, attacker, attacker, damage, DMG_GRENADE);
	}

	if (kill)
		user_kill(id);

	oo_call(this, "CreateSpawnEnt");
}

public Boomer@CreateSpawnEnt()
{
	new this = oo_this();
	new id = oo_get(this, "player_id");

	static Float:origin[3];
	get_entvar(id, var_origin, origin);

	new ent = rg_create_entity("info_target");
	entity_set_origin(ent, origin);
	set_entvar(ent, var_classname, "boomer_spawn");
	set_entvar(ent, var_nextthink, get_gametime() + cvar_spawntime);
}

public OnBoomerSpawn(ent)
{
	if (!is_entity(ent))
		return;
	
	rg_remove_entity(ent);
}

public OnRestartRound()
{
	remove_entity_name("boomer_spawn");
}

public CSDM_OnGetPlayerSpawnSpot(id)
{
	if (!oo_playerclass_isa(id, "CommonInfected"))
		return PLUGIN_CONTINUE;
		
	new spawn_ent[3], spawn_ent_num = 0;

	new ent = -1;
	while ((ent = find_ent_by_class(ent, "boomer_spawn")) && spawn_ent_num < sizeof spawn_ent)
	{
		if (is_entity(ent))
			spawn_ent[spawn_ent_num++] = ent;
	}

	if (spawn_ent_num < 1)
		return PLUGIN_CONTINUE;
	
	ent = spawn_ent[random(spawn_ent_num)];

	static Float:origin[3], Float:pos[3];
	get_entvar(ent, var_origin, origin);

	new node_id = -1;
	new node_count = walknode_count();
	new Float:max_dist = 4096.0, Float:dist;

	for (new i = 0; i < node_count; i++)
	{
		walknode_get_origin(i, pos);

		if (!IsVisible(pos, origin) || !IsHullVacant(pos) || IsNearHuman(pos, 300.0))
			continue;
		
		dist = get_distance_f(pos, origin);
		if (dist < max_dist)
		{
			node_id = i;
			max_dist = dist;
		}
	}

	if (node_id == -1)
		return PLUGIN_CONTINUE;

	static Float:angle[3];
	walknode_get_origin(node_id, origin);
	walknode_get_angle(node_id, angle);

	SetPlayerOrigin(id, origin, angle);
	client_print(0, print_chat, "chose walknode index (%d)", node_id);

	return PLUGIN_HANDLED;
}

bool:IsVisible(Float:src[3], Float:dest[3], no_monsters=IGNORE_MONSTERS, skip_ent=0)
{
	engfunc(EngFunc_TraceLine, src, dest, no_monsters, skip_ent, 0);

	new Float:fr;
	get_tr2(0, TR_flFraction, fr);

	return (fr == 1.0);
}

bool:IsHullVacant(Float:origin[3], no_monsters=IGNORE_MONSTERS, hull=HULL_HEAD, skipent=0)
{
	engfunc(EngFunc_TraceHull, origin, origin, no_monsters, hull, skipent, 0);

	return bool:(!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen));
}

bool:IsNearHuman(Float:origin[3], Float:radius)
{
	static Float:origin2[3];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_alive(i) || !oo_playerclass_isa(i, "Human"))
			continue;
		
		get_entvar(i, var_origin, origin2);
		if (get_distance_f(origin, origin2) <= radius)
			return true;
	}

	return false;
}

SetPlayerOrigin(id, Float:origin[3], Float:angle[3])
{
	static const Float:VEC_DUCK_HULL_MIN[3] = {-16.0, -16.0, -18.0};
	static const Float:VEC_DUCK_HULL_MAX[3] = { 16.0,  16.0,  32.0};
	static const Float:VEC_DUCK_VIEW[3] 	= {  0.0,   0.0,  12.0};
	static const Float:VEC_NULL[3] = {0.0, 0.0, 0.0};

	angle[0] = 0.0;

	set_entvar(id, var_flags, get_entvar(id, var_flags) | FL_DUCKING);
	entity_set_size(id, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX);
	entity_set_origin(id, origin);

	set_entvar(id, var_view_ofs, VEC_DUCK_VIEW);
	set_entvar(id, var_v_angle, VEC_NULL);
	set_entvar(id, var_velocity, VEC_NULL);
	set_entvar(id, var_angles, angle);
	set_entvar(id, var_punchangle, VEC_NULL);
	set_entvar(id, var_fixangle, 1);

	//set_entvar(id, var_gravity, angle[2]);
	set_entvar(id, var_fuser2, 0.0);
}  

bool:CheckTraceLine(ent, victim)
{
	static Float:start_orig[3], Float:end_orig[3];
	get_entvar(ent, var_origin, start_orig);
	get_entvar(victim, var_origin, end_orig);

	static Float:start[3], Float:end[3], Float:fr;
	start = start_orig;
	end = end_orig;

	static Float:v[3], Float:a1[3], Float:a2[3];
	xs_vec_sub(end, start, a1);
	xs_vec_normalize(a1, a1);
	vector_to_angle(a1, a1);

	new a, b;
	for (a = 0; a <= 3; a++)
	{
		start[2] = start_orig[2] + a * 22.0;
		engfunc(EngFunc_TraceLine, start_orig, start, IGNORE_MONSTERS, ent, 0);
		get_tr2(0, TR_flFraction, fr);
		if (fr < 1.0)
			break;

		engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ent, 0);
		get_tr2(0, TR_flFraction, fr)
		if (fr == 1.0)
			return true;

		for (b = -1; b <= 1; b++)
		{
			a2[0] = a2[2] = 0.0;
			a2[1] = constrain_angle(a1[1] + b * 40.0);
			angle_vector(a2, ANGLEVECTOR_FORWARD, v);
			xs_vec_mul_scalar(v, 120.0, v);
			xs_vec_add(start, v, v);
			engfunc(EngFunc_TraceLine, start, v, IGNORE_MONSTERS, ent, 0);
			get_tr2(0, TR_vecEndPos, v);

			engfunc(EngFunc_TraceLine, v, end, IGNORE_MONSTERS, ent, 0);
			get_tr2(0, TR_flFraction, fr)
			if (fr == 1.0)
				return true;
		}
	}

	return false;
}

stock Float:fmod(Float:num, Float:denom)
{
    return num - denom * floatround(num / denom, floatround_floor);
}

stock Float:constrain_angle(Float:x)
{
	x = fmod(x + 180.0, 360.0);
	if (x < 0)
		x += 360.0;
	return x - 180.0;
}

stock SendBarTime(id, duration)
{
	static msgBarTime;
	msgBarTime || (msgBarTime = get_user_msgid("BarTime"));

	message_begin(MSG_ONE_UNRELIABLE, msgBarTime, _, id);
	write_short(duration);
	message_end();
}