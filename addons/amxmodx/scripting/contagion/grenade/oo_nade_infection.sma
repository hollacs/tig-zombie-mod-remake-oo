#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <oo_player_class>
#include <oo_player_status>
#include <oo_zombie_mode>
#include <xs>
#include <oo_assets>

new GrenadeInfo:g_oGrenadeInfo;
new sprite_trail, sprite_ring;

new Float:cvar_radius, Float:cvar_damage_min, Float:cvar_damage_max, cvar_traceline;

public oo_init()
{
	oo_class("InfectionNadeInfo", "GrenadeInfo")
	{
		new cl[] = "InfectionNadeInfo";
		oo_mthd(cl, "Condition", @int(ent), @str(class));
	}

	oo_class("InfectionNade", "Grenade")
	{
		new cl[] = "InfectionNade";
		oo_dtor(cl, "Dtor");
		oo_mthd(cl, "Detonate");
		oo_mthd(cl, "DetonateEffect");
		oo_mthd(cl, "GetInfo");
		oo_mthd(cl, "SetWorldModel");
	}
}

public plugin_precache()
{
	g_oGrenadeInfo = oo_new("InfectionNadeInfo", "InfectionNade");
	oo_call(g_oGrenadeInfo, "LoadJson", "infection.json");

	sprite_trail = AssetsGetSprite(g_oGrenadeInfo, "trail");
	sprite_ring  = AssetsGetSprite(g_oGrenadeInfo, "ring");
}

public plugin_init()
{
	register_plugin("[OO] Nade: Infection", "0.1", "holla");

	new pcvar = create_cvar("infection_nade_radius", "240");
	bind_pcvar_float(pcvar, cvar_radius);

	pcvar = create_cvar("infection_nade_damage_min", "1");
	bind_pcvar_float(pcvar, cvar_damage_min);

	pcvar = create_cvar("infection_nade_damage_max", "100");
	bind_pcvar_float(pcvar, cvar_damage_max);

	pcvar = create_cvar("infection_nade_check_traceline", "1");
	bind_pcvar_num(pcvar, cvar_traceline);
}

public InfectionNadeInfo@Condition(id, const class[])
{
	if (equal(class, "hegrenade"))
	{
		if (is_user_connected(id) && oo_playerclass_isa(id, "Zombie"))
			return true;
	}

	return false;
}

public GrenadeInfo:InfectionNade@GetInfo()
{
	return g_oGrenadeInfo;
}

public InfectionNade@Dtor()
{
}

public InfectionNade@SetWorldModel()
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
		write_byte(255); // g
		write_byte(0); // b
		write_byte(200); // brightness
		message_end();
	}
}	

public InfectionNade@Detonate()
{
	new this = oo_this();
	new ent = oo_get(this, "ent");
	new attacker = get_entvar(ent, var_owner);

	static Float:origin[3];
	get_entvar(ent, var_origin, origin);

	new victim = -1;
	new Float:damage, Float:armor;

	while ((victim = find_ent_in_sphere(victim, origin, cvar_radius)))
	{
		if (!is_user_alive(victim) || !oo_playerclass_isa(victim, "Human"))
			continue;

		if (cvar_traceline && !CheckTraceLine(ent, victim))
			continue;

		damage = floatmax((1.0 - entity_range(victim, ent) / cvar_radius) * cvar_damage_max, cvar_damage_min);
		armor = Float:get_entvar(victim, var_armorvalue);
		if (damage >= armor)
		{
			oo_infect_player(victim, attacker)
		}
		else
		{
			set_entvar(victim, var_armorvalue, armor - damage);
			oo_call(0, "PoisonStatus@Add", victim, attacker, 1.0, 1.0, 20);
		}
	}

	oo_call(this, "Grenade@Detonate");
	return true;
}

public InfectionNade@DetonateEffect()
{
	new this = oo_this();
	new ent = oo_get(this, "ent");

	static Float:origin[3];
	get_entvar(ent, var_origin, origin);

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
		write_short(sprite_ring); // sprite
		write_byte(0); // startframe
		write_byte(0); // framerate
		write_byte(4); // life
		write_byte(30); // width
		write_byte(0); // noise
		write_byte(0); // red
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
		write_short(sprite_ring); // sprite
		write_byte(0); // startframe
		write_byte(0); // framerate
		write_byte(4); // life
		write_byte(30); // width
		write_byte(0); // noise
		write_byte(0); // red
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
	write_byte(0); // red
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
