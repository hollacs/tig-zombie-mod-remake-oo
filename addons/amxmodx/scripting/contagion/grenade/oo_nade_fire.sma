#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <oo_player_class>
#include <oo_player_status>
#include <oo_assets>

new GrenadeInfo:g_oGrenadeInfo;
new sprite_trail, sprite_ring, sprite_gibs;

new Float:cvar_radius;
new Float:cvar_min;
new Float:cvar_max;
new Float:cvar_interval;
new Float:cvar_damage;
new cvar_traceline;

public oo_init()
{
	oo_class("FireNadeInfo", "GrenadeInfo")
	{
		new cl[] = "FireNadeInfo";
		oo_mthd(cl, "Condition", @int(ent), @str(class));
	}

	oo_class("FireNade", "Grenade")
	{
		new cl[] = "FireNade";
		oo_dtor(cl, "Dtor");
		oo_mthd(cl, "Ignite", @int(victim), @int(times));
		oo_mthd(cl, "Detonate");
		oo_mthd(cl, "DetonateEffect");
		oo_mthd(cl, "GetInfo");
		oo_mthd(cl, "SetWorldModel");
	}
}

public plugin_precache()
{
	g_oGrenadeInfo = oo_new("FireNadeInfo", "FireNade");
	oo_call(g_oGrenadeInfo, "LoadJson", "fire.json");

	sprite_trail = AssetsGetSprite(g_oGrenadeInfo, "trail");
	sprite_ring  = AssetsGetSprite(g_oGrenadeInfo, "ring");
	sprite_gibs = AssetsGetSprite(g_oGrenadeInfo, "gibs");
}

public plugin_init()
{
	register_plugin("[OO] Nade: Fire", "0.1", "holla");

	new pcvar = create_cvar("firenade_radius", "230");
	bind_pcvar_float(pcvar, cvar_radius);

	pcvar = create_cvar("firenade_flame_min", "20");
	bind_pcvar_float(pcvar, cvar_min);

	pcvar = create_cvar("firenade_flame_max", "60");
	bind_pcvar_float(pcvar, cvar_max);

	pcvar = create_cvar("firenade_flame_interval", "0.25");
	bind_pcvar_float(pcvar, cvar_interval);

	pcvar = create_cvar("firenade_damage", "20");
	bind_pcvar_float(pcvar, cvar_damage);

	pcvar = create_cvar("firenade_check_traceline", "1");
	bind_pcvar_num(pcvar, cvar_traceline);
}

public FireNadeInfo@Condition(id, const class[])
{
	if (equal(class, "hegrenade"))
	{
		if (is_user_connected(id) && oo_playerclass_isa(id, "Human"))
			return true;
	}

	return false;
}

public GrenadeInfo:FireNade@GetInfo()
{
	return g_oGrenadeInfo;
}

public FireNade@Dtor()
{
}

public FireNade@SetWorldModel()
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
		write_byte(200); // r
		write_byte(25); // g
		write_byte(0); // b
		write_byte(200); // brightness
		message_end();
	}
}

public FireNade@Detonate()
{
	new this = oo_this();
	new ent = oo_get(this, "ent");

	static Float:origin[3];
	get_entvar(ent, var_origin, origin);

	new victim = -1;
	new times;

	while ((victim = find_ent_in_sphere(victim, origin, cvar_radius)))
	{
		if (!is_user_alive(victim) || !oo_playerclass_isa(victim, "Zombie"))
			continue;

		if (cvar_traceline && !CheckTraceLine(ent, victim))
			continue;

		times = floatround(floatmax((1.0 - entity_range(victim, ent) / cvar_radius) * cvar_max, cvar_min));
		oo_call(this, "Ignite", victim, times);
	}

	oo_call(this, "Grenade@Detonate");
	return true;
}

public FireNade@Ignite(victim, times)
{
	new this = oo_this();
	new ent = oo_get(this, "ent");
	new attacker = get_entvar(ent, var_owner);
	
	oo_call(0, "BurnStatus@Add", victim, attacker, cvar_interval, cvar_damage, times);
}

public FireNade@DetonateEffect()
{
	new this = oo_this();
	new ent = oo_get(this, "ent");

	new Float:origin[3];
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
		write_byte(200); // red
		write_byte(50); // green
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
		write_short(sprite_ring); // sprite
		write_byte(0); // startframe
		write_byte(0); // framerate
		write_byte(4); // life
		write_byte(30); // width
		write_byte(0); // noise
		write_byte(200); // red
		write_byte(50); // green
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
		write_short(sprite_ring); // sprite
		write_byte(0); // startframe
		write_byte(0); // framerate
		write_byte(4); // life
		write_byte(30); // width
		write_byte(0); // noise
		write_byte(200); // red
		write_byte(50); // green
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
	write_byte(200); // red
	write_byte(50); // green
	write_byte(0); // blue
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