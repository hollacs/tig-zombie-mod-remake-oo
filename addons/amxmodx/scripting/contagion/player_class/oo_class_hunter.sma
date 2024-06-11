#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <oo_assets>
#include <oo_player_class>
#include <xs>
#include <cs_painshock>

new PlayerClassInfo:g_oClassInfo;

new Float:cvar_speed, Float:cvar_angle, Float:cvar_cooldown;
new Float:cvar_painshock, Float:cvar_time, Float:cvar_radius, Float:cvar_damage;

public oo_init()
{
	oo_class("Hunter", "SpecialInfected");
	{
		new const cl[] = "Hunter";
		oo_var(cl, "leap_time", 1);
		oo_var(cl, "land_time", 1);
		oo_var(cl, "land_pos", 3);
		oo_var(cl, "has_attack", 1);
		oo_var(cl, "notify", 1);

		oo_mthd(cl, "GetClassInfo");
		oo_mthd(cl, "OnCmdStart", @int(uc), @int(seed));
		oo_mthd(cl, "OnPainShock", @int(victim), @fl(damage), @ref(value));
		oo_mthd(cl, "OnTouchPlayer", @int(id2));
		oo_mthd(cl, "Leap");
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "Hunter");
	oo_call(g_oClassInfo, "LoadJson", "hunter.json");
}

public plugin_init()
{
	register_plugin("[OO] Class: Hunter", "0.1", "holla");

	register_touch("player", "player", "OnPlayerTouch");

	bind_pcvar_float(create_cvar("ctg_hunter_leap_cooldown", "5.0"), cvar_cooldown);
	bind_pcvar_float(create_cvar("ctg_hunter_leap_speed", "500"), cvar_speed);
	bind_pcvar_float(create_cvar("ctg_hunter_leap_angle", "-30"), cvar_angle);
	bind_pcvar_float(create_cvar("ctg_hunter_pounch_painshock", "0.0"), cvar_painshock);
	bind_pcvar_float(create_cvar("ctg_hunter_pounch_time", "1.0"), cvar_time);
	bind_pcvar_float(create_cvar("ctg_hunter_pounch_radius", "50.0"), cvar_radius);
	bind_pcvar_float(create_cvar("ctg_hunter_touch_damage", "50.0"), cvar_damage);

	oo_call(g_oClassInfo, "CreateCvars");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_hunter", "health", "2000");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_hunter", "health2", "80");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_hunter", "gravity", "0.5");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_hunter", "speed", "1.025");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_hunter", "dmg", "1.05");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_hunter", "knockback", "1.1");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_hunter", "painshock", "1.1");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_hunter", "swing_speed", "0.9");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_hunter", "swing_dist", "50.0");
}

public OnPlayerTouch(id, id2)
{
	new PlayerClass:class_o = oo_playerclass_get(id);
	if (class_o != @null && oo_isa(class_o, "Hunter"))
	{
		oo_call(class_o, "OnTouchPlayer", id2)
	}
}

public Hunter@OnTouchPlayer(id2)
{
	if (!oo_playerclass_isa(id2, "Human"))
		return PLUGIN_CONTINUE;

	new this = oo_this();
	new id = oo_get(this, "player_id");

	new Float:gametime = get_gametime()

	new Float:land_time = Float:oo_get(this, "land_time");
	new Float:leap_time = Float:oo_get(this, "leap_time");
	if (land_time == -1.0 && leap_time > 0.0 && gametime > leap_time + 5.0)
		return PLUGIN_CONTINUE;

	if (oo_get(this, "has_attack"))
		return PLUGIN_CONTINUE;

	ExecuteHamB(Ham_TakeDamage, id2, id, id, cvar_damage, DMG_BULLET|DMG_NEVERGIB);
	oo_set(this, "has_attack", true);
	client_print(0, print_chat, "hunter touch!!");
	return PLUGIN_CONTINUE;
}

public PlayerClassInfo:Hunter@GetClassInfo()
{
	return g_oClassInfo;
}

public Hunter@OnPainShock(victim, Float:damage, &Float:value)
{
	new this = oo_this();
	new id = oo_get(this, "player_id");
	oo_call(this, "SpecialInfected@OnPainShock", victim, damage, value);

	if (get_user_weapon(id) != CSW_KNIFE)
		return;

	new Float:gametime = get_gametime()

	new Float:land_time = Float:oo_get(this, "land_time");
	if (land_time > 0.0 && gametime > land_time + cvar_time)
		return;

	new Float:leap_time = Float:oo_get(this, "leap_time");
	if (land_time == -1.0 && leap_time > 0.0 && gametime > leap_time + 5.0)
		return

	if (oo_get(this, "has_attack"))
		return;
	
	if (land_time > 0.0)
	{
		static Float:pos1[3], Float:pos2[3];
		oo_get_arr(this, "land_pos", pos1);
		get_entvar(id, var_origin, pos2);

		if (get_distance_f(pos1, pos2) > cvar_radius)
			return;
	}
	
	value = cvar_painshock;
	oo_set(this, "has_attack", true);
	client_print(0, print_chat, "hunter pounch!!");
}

public Hunter@OnCmdStart(uc, seed)
{
	new this = oo_this();
	new id = oo_get(this, "player_id");

	if (!is_user_alive(id))
		return;

	new Float:gametime = get_gametime();

	if (Float:oo_get(this, "land_time") == -1.0)
	{
		if (get_entvar(id, var_flags) & FL_ONGROUND)
		{
			static Float:pos[3];
			get_entvar(id, var_origin, pos);
			oo_set_arr(this, "land_pos", pos)
			oo_set(this, "land_time", gametime);
		}
	}

	if (gametime >= Float:oo_get(this, "leap_time") + cvar_cooldown)
	{
		if (!is_user_bot(id))
		{
			new buttons = get_uc(uc, UC_Buttons);
			new oldbuttons = get_entvar(id, var_oldbuttons);
			if ((buttons & IN_RELOAD) && !(oldbuttons & IN_RELOAD))
			{
				oo_call(this, "Leap");
			}
		}
		else
		{
			new aimid;
			get_user_aiming(id, aimid, _, 1024);

			if (is_user_alive(aimid) && oo_playerclass_isa(aimid, "Human") && entity_range(id, aimid) > 128.0)
			{
				oo_call(this, "Leap");
			}
		}
	}
}

public Hunter@Leap()
{
	new this = oo_this();
	new id = oo_get(this, "player_id");

	static Float:angle[3], Float:velocity[3];
	get_entvar(id, var_v_angle, angle);
	get_entvar(id, var_velocity, velocity);

	if (angle[0] > cvar_angle)
		angle[0] = cvar_angle;
	
	static Float:vec[3];
	angle_vector(angle, ANGLEVECTOR_FORWARD, vec);

	xs_vec_mul_scalar(vec, cvar_speed, vec);
	xs_vec_add(velocity, vec, velocity);

	set_entvar(id, var_velocity, velocity);

	oo_set(this, "leap_time", get_gametime());
	oo_set(this, "land_time", -1.0);
	oo_set(this, "has_attack", false);

	static sound[64];
	if (AssetsGetRandomSound(g_oClassInfo, "leap", sound, charsmax(sound)))
		emit_sound(id, CHAN_VOICE, sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}