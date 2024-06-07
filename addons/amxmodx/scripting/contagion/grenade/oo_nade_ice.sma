#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <oo_player_class>
#include <oo_player_status>
#include <xs>
#include <oo_assets>

new GrenadeInfo:g_oGrenadeInfo;
new sprite_trail, sprite_ring, sprite_gibs;

new Float:cvar_radius, Float:cvar_duration_min, Float:cvar_duration_max, cvar_traceline, Float:cvar_chill_duration, Float:cvar_chill_speed;
new g_fwFrozen, g_fwRet;

public oo_init()
{
	oo_class("IceNadeInfo", "GrenadeInfo")
	{
		new cl[] = "IceNadeInfo";
		oo_mthd(cl, "Condition", @int(ent), @str(class));
	}

	oo_class("IceNade", "Grenade")
	{
		new cl[] = "IceNade";
		oo_dtor(cl, "Dtor");
		oo_mthd(cl, "Detonate");
		oo_mthd(cl, "DetonateEffect");
		oo_mthd(cl, "GetInfo");
		oo_mthd(cl, "SetWorldModel");
		oo_mthd(cl, "Frozen", @int(player), @int(attacker), @fl(duration));
	}
}

public plugin_precache()
{
	g_oGrenadeInfo = oo_new("IceNadeInfo", "IceNade");
	oo_call(g_oGrenadeInfo, "LoadJson", "ice.json");

	sprite_trail = AssetsGetSprite(g_oGrenadeInfo, "trail");
	sprite_ring  = AssetsGetSprite(g_oGrenadeInfo, "ring");
	sprite_gibs = AssetsGetSprite(g_oGrenadeInfo, "gibs");
}

public plugin_init()
{
	register_plugin("[OO] Nade: Ice", "0.1", "holla");

	g_fwFrozen = CreateMultiForward("OO_OnIceNadeFrozen", ET_CONTINUE, FP_CELL, FP_CELL, FP_VAL_BYREF);

	new pcvar = create_cvar("icenade_radius", "240");
	bind_pcvar_float(pcvar, cvar_radius);

	pcvar = create_cvar("icenade_duration_min", "2");
	bind_pcvar_float(pcvar, cvar_duration_min);

	pcvar = create_cvar("icenade_duration_max", "4");
	bind_pcvar_float(pcvar, cvar_duration_max);

	pcvar = create_cvar("icenade_chill_duration", "3");
	bind_pcvar_float(pcvar, cvar_chill_duration);

	pcvar = create_cvar("icenade_chill_speed", "0.75");
	bind_pcvar_float(pcvar, cvar_chill_speed);

	pcvar = create_cvar("icenade_check_traceline", "1");
	bind_pcvar_num(pcvar, cvar_traceline);
}

public IceNadeInfo@Condition(id, const class[])
{
	if (equal(class, "flashbang"))
	{
		if (is_user_connected(id) && oo_playerclass_isa(id, "Human"))
			return true;
	}

	return false;
}

public GrenadeInfo:IceNade@GetInfo()
{
	return g_oGrenadeInfo;
}

public IceNade@Dtor()
{
}

public IceNade@SetWorldModel()
{
	new this = oo_this();
	oo_call(this, "Grenade@SetWorldModel");

	new ent = oo_get(this, "ent");
	if (sprite_trail)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW); // TE id
		write_short(ent); // entity
		write_short(sprite_trail); // sprite
		write_byte(10); // life
		write_byte(5); // width
		write_byte(0); // r
		write_byte(150); // g
		write_byte(200); // b
		write_byte(200); // brightness
		message_end();
	}
}	

public IceNade@Detonate()
{
	new this = oo_this();
	new ent = oo_get(this, "ent");

	static Float:origin[3];
	get_entvar(ent, var_origin, origin);

	new attacker = get_entvar(ent, var_owner);
	new victim = -1;
	new Float:duration;

	while ((victim = find_ent_in_sphere(victim, origin, cvar_radius)))
	{
		if (!is_user_alive(victim) || !oo_playerclass_isa(victim, "Zombie"))
			continue;

		if (cvar_traceline && !CheckTraceLine(ent, victim))
			continue;

		duration = floatmax((1.0 - entity_range(victim, ent) / cvar_radius) * cvar_duration_max, cvar_duration_min);
		oo_call(this, "Frozen", victim, attacker, duration);
	}

	oo_call(this, "Grenade@Detonate");
	return true;
}

public IceNade@Frozen(victim, attacker, Float:duration)
{
	ExecuteForward(g_fwFrozen, g_fwRet, victim, attacker, duration);
	if (g_fwRet == PLUGIN_HANDLED)
		return;
	
	oo_call(0, "FrozenStatus@Add", victim, duration)
}

public IceNade@DetonateEffect()
{
	new this = oo_this();
	new ent = oo_get(this, "ent");

	static Float:origin[3];
	get_entvar(ent, var_origin, origin);

	if (sprite_gibs)
	{	
		message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
		write_byte(TE_SPRITETRAIL) // Throws a shower of sprites or models
		write_coord_f(origin[0]) // start pos
		write_coord_f(origin[1])
		write_coord_f(origin[2])
		write_coord_f(origin[0]) // velocity
		write_coord_f(origin[1])
		write_coord_f(origin[2] + 50.0)
		write_short(sprite_gibs) // spr
		write_byte(30) // (count)
		write_byte(random_num(10,20)) // (life in 0.1's)
		write_byte(1) // byte (scale in 0.1's)
		write_byte(50) // (velocity along vector in 10's)
		write_byte(10) // (randomness of velocity in 10's)
		message_end()
	}

	if (sprite_ring)
	{
		message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
		write_byte(TE_BEAMCYLINDER); // TE id
		write_coord_f(origin[0]); // x
		write_coord_f(origin[1]); // y
		write_coord_f(origin[2] + 16.0); // z
		write_coord_f(origin[0]); // x axis
		write_coord_f(origin[1]); // y axis
		write_coord_f(origin[2] + 385.0); // z axis
		write_short(sprite_ring); // sprite
		write_byte(0); // startframe
		write_byte(0); // framerate
		write_byte(4); // life
		write_byte(30); // width
		write_byte(0); // noise
		write_byte(0); // red
		write_byte(150); // green
		write_byte(200); // blue
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
		write_short(sprite_ring); // sprite
		write_byte(0); // startframe
		write_byte(0); // framerate
		write_byte(4); // life
		write_byte(30); // width
		write_byte(0); // noise
		write_byte(0); // red
		write_byte(150); // green
		write_byte(200); // blue
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
		write_short(sprite_ring); // sprite
		write_byte(0); // startframe
		write_byte(0); // framerate
		write_byte(4); // life
		write_byte(30); // width
		write_byte(0); // noise
		write_byte(0); // red
		write_byte(150); // green
		write_byte(200); // blue
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
	write_byte(0); // red
	write_byte(150); // green
	write_byte(200); // blue
	write_byte(6); // life in 0.1's
	write_byte(40) // decay rate in 0.1's
	message_end();

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_WORLDDECAL);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_byte(random_num(46, 48));
	message_end();
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
