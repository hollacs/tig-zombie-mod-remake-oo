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
#include <cs_painshock>

new GrenadeInfo:g_oGrenadeInfo;
new sprite_trail, sprite_ring, sprite_explo;

new Float:cvar_radius, Float:cvar_damage_min, Float:cvar_damage_max, Float:cvar_knockback, cvar_traceline;
new Float:cvar_ampl, Float:cvar_freq, Float:cvar_dur, Float:cvar_punch[2];

public oo_init()
{
	oo_class("ShockNadeInfo", "GrenadeInfo")
	{
		new cl[] = "ShockNadeInfo";
		oo_mthd(cl, "Condition", @int(ent), @str(class));
	}

	oo_class("ShockNade", "Grenade")
	{
		new cl[] = "ShockNade";
		oo_dtor(cl, "Dtor");
		oo_mthd(cl, "Detonate");
		oo_mthd(cl, "DetonateEffect");
		oo_mthd(cl, "GetInfo");
		oo_mthd(cl, "SetWorldModel");
	}
}

public plugin_precache()
{
	g_oGrenadeInfo = oo_new("ShockNadeInfo", "ShockNade");
	oo_call(g_oGrenadeInfo, "LoadJson", "shock.json");

	sprite_trail = AssetsGetSprite(g_oGrenadeInfo, "trail");
	sprite_ring  = AssetsGetSprite(g_oGrenadeInfo, "ring");
	sprite_explo = AssetsGetSprite(g_oGrenadeInfo, "explo");
}

public plugin_init()
{
	register_plugin("[OO] Nade: Shock", "0.1", "holla");

	new pcvar = create_cvar("shock_nade_radius", "240");
	bind_pcvar_float(pcvar, cvar_radius);

	pcvar = create_cvar("shock_nade_damage_min", "1");
	bind_pcvar_float(pcvar, cvar_damage_min);

	pcvar = create_cvar("shock_nade_damage_max", "25");
	bind_pcvar_float(pcvar, cvar_damage_max);

	pcvar = create_cvar("shock_nade_knockback", "300");
	bind_pcvar_float(pcvar, cvar_knockback);

	pcvar = create_cvar("shock_nade_punch_x", "10");
	bind_pcvar_float(pcvar, cvar_punch[0]);

	pcvar = create_cvar("shock_nade_punch_y", "10");
	bind_pcvar_float(pcvar, cvar_punch[1]);

	pcvar = create_cvar("shock_nade_ampl", "1.0");
	bind_pcvar_float(pcvar, cvar_ampl);

	pcvar = create_cvar("shock_nade_freq", "1.0");
	bind_pcvar_float(pcvar, cvar_freq);

	pcvar = create_cvar("shock_nade_dur", "3.0");
	bind_pcvar_float(pcvar, cvar_dur);

	pcvar = create_cvar("shock_nade_check_traceline", "1");
	bind_pcvar_num(pcvar, cvar_traceline);
}

public ShockNadeInfo@Condition(id, const class[])
{
	if (equal(class, "flashbang"))
	{
		if (is_user_connected(id) && oo_playerclass_isa(id, "Zombie"))
			return true;
	}

	return false;
}

public GrenadeInfo:ShockNade@GetInfo()
{
	return g_oGrenadeInfo;
}

public ShockNade@Dtor()
{
}

public ShockNade@SetWorldModel()
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
		write_byte(200); // g
		write_byte(0); // b
		write_byte(200); // brightness
		message_end();
	}
}	

public ShockNade@Detonate()
{
	new this = oo_this();
	new ent = oo_get(this, "ent");
	new attacker = get_entvar(ent, var_owner);

	static Float:origin[3], Float:origin2[3], Float:vec[3], Float:velocity[3], Float:punchangle[3];
	get_entvar(ent, var_origin, origin);

	new victim = -1;
	new Float:damage, Float:ratio, Float:power;

	while ((victim = find_ent_in_sphere(victim, origin, cvar_radius)))
	{
		if (!is_user_alive(victim) || !oo_playerclass_isa(victim, "Human"))
			continue;

		if (cvar_traceline && !CheckTraceLine(ent, victim))
			continue;

		ratio = 1.0 - entity_range(victim, ent) / cvar_radius;
		damage = floatmax(ratio * cvar_damage_max, cvar_damage_min);
		power = cvar_knockback * ratio;

		get_entvar(victim, var_origin, origin2);
		xs_vec_sub(origin2, origin, vec);
		xs_vec_normalize(vec, vec);
		xs_vec_mul_scalar(vec, power, vec);
		get_entvar(victim, var_velocity, velocity);
		xs_vec_add(velocity, vec, velocity);
		set_entvar(victim, var_velocity, velocity);

		get_entvar(victim, var_punchangle, punchangle);
		punchangle[0] += cvar_punch[0] * ratio;
		punchangle[1] += cvar_punch[1] * ratio;
		punchangle[1] *= random_num(0, 1) ? 1.0 : -1.0;
		set_entvar(victim, var_punchangle, punchangle);

		SendScreenShake(victim, cvar_ampl, cvar_freq, 1.0 + cvar_dur * ratio);

		cs_painshock_set(victim, 1.0 - ratio);
		
		ExecuteHamB(Ham_TakeDamage, victim, ent, attacker, damage, DMG_GRENADE);
	}

	oo_call(this, "Grenade@Detonate");
	return true;
}

public ShockNade@DetonateEffect()
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
		write_byte(200); // red
		write_byte(200); // green
		write_byte(0); // blue
		write_byte(200); // brightness
		write_byte(0); // speed
		message_end();
	}

	if (sprite_explo)
	{
		message_begin_f(MSG_PAS, SVC_TEMPENTITY, origin);
		write_byte(TE_EXPLOSION);	// This makes a dynamic light and the explosion sprites/sound
		write_coord_f(origin[0]);		// Send to PAS because of the sound
		write_coord_f(origin[1]);
		write_coord_f(origin[2] + 20.0);
		write_short(sprite_explo);
		write_byte(25);			// scale * 10
		write_byte(30);		// framerate
		write_byte(TE_EXPLFLAG_NOSOUND);	// flags
		message_end();
	}

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

stock SendScreenShake(id, Float:amplitude, Float:frequency, Float:duration)
{
	static msgScreenShake;
	msgScreenShake || (msgScreenShake = get_user_msgid("ScreenShake"));

	message_begin(MSG_ONE_UNRELIABLE, msgScreenShake, _, id);
	write_short(FixedUnsigned16(amplitude, 1 << 12));  // --| Shake amount.
	write_short(FixedUnsigned16(duration, 1 << 12));   // --| Shake lasts this long.
	write_short(FixedUnsigned16(frequency, 1 << 8));  // --| Shake noise frequency.
	message_end();
}

FixedUnsigned16( const Float:value, const scale )
{
    return clamp( floatround( value * scale ), 0, 0xFFFF );
}