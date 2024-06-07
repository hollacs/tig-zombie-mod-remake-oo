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

new Float:cvar_spit_speed[2], Float:cvar_spit_cooldown, Float:cvar_spit_slowdown, Float:cvar_spit_radius;
new sprite_trail;
new sprite_poison;
new model_poison[64];

public oo_init()
{
	oo_class("Spitter", "SpecialInfected");
	{
		new const cl[] = "Spitter";
		oo_var(cl, "next_spit_time", 1);
		oo_var(cl, "start_hold_time", 1);
		oo_var(cl, "notify", 1);

		oo_mthd(cl, "GetClassInfo");
		oo_mthd(cl, "OnCmdStart", @int(uc), @int(seed));
		oo_mthd(cl, "SetProperties", @bool(set_team));
		oo_mthd(cl, "Spit", @fl(time));
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "Spitter");
	oo_call(g_oClassInfo, "LoadJson", "spitter.json");
}

public plugin_init()
{
	register_plugin("[OO] Class: Spitter", "0.1", "holla");

	register_touch("spit_ent", "*", "OnSpitEntTouch");
	register_think("poison_spr", "OnPoisonSpr");

	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRestartRound");

	bind_pcvar_float(create_cvar("ctg_spitter_spit_speed_min", "750"), cvar_spit_speed[0]);
	bind_pcvar_float(create_cvar("ctg_spitter_spit_speed_max", "1500"), cvar_spit_speed[1]);
	bind_pcvar_float(create_cvar("ctg_spitter_spit_cooldown", "10"), cvar_spit_cooldown);
	bind_pcvar_float(create_cvar("ctg_spitter_spit_slowdown", "0.3"), cvar_spit_slowdown);
	bind_pcvar_float(create_cvar("ctg_spitter_spit_radius", "100"), cvar_spit_radius);

	oo_call(g_oClassInfo, "CreateCvars");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_spitter", "health", "3000");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_spitter", "health2", "80");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_spitter", "gravity", "0.95");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_spitter", "speed", "1.05");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_spitter", "dmg", "1.1");

	sprite_trail = AssetsGetSprite(g_oClassInfo, "trail");
	sprite_poison = AssetsGetSprite(g_oClassInfo, "poison");
	AssetsGetModel(g_oClassInfo, "poison", model_poison, charsmax(model_poison))
}

public OnRestartRound()
{
	remove_entity_name("spit_ent");
	remove_entity_name("poison_spr");
}

public OnSpitEntTouch(ent, toucher)
{
	if (!is_entity(ent))
		return;

	new flags = get_entvar(ent, var_flags)
	if (!(flags & FL_KILLME))
	{
		new poison_ent = rg_create_entity("env_sprite");

		if (model_poison[0])
		{
			static Float:origin[3];
			get_entvar(ent, var_origin, origin);
			origin[2] += 16.0;

			entity_set_model(poison_ent, model_poison);
			entity_set_origin(poison_ent, origin);
			set_entvar(poison_ent, var_classname, "poison_spr");
			set_entvar(poison_ent, var_scale, 1.0);
			set_entvar(poison_ent, var_framerate, 10.0);
			set_entvar(poison_ent, var_spawnflags, SF_SPRITE_STARTON);
			set_entvar(poison_ent, var_owner, get_entvar(ent, var_owner));
			DispatchSpawn(poison_ent);

			set_entvar(poison_ent, var_rendermode, kRenderTransAdd);
			set_entvar(poison_ent, var_renderamt, 255.0);
			set_entvar(poison_ent, var_fuser4, get_gametime() + 15.0);

			static sound[64];
			if (AssetsGetRandomSound(g_oClassInfo, "spithit", sound, charsmax(sound)))
				emit_sound(poison_ent, CHAN_VOICE, sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}

		set_entvar(ent, var_flags, flags | FL_KILLME);
	}
}

public OnPoisonSpr(ent)
{
	if (!is_entity(ent))
		return;

	static Float:angles[3];
	get_entvar(ent, var_angles, angles);
	angles[2] += 1.0;
	set_entvar(ent, var_angles, angles);

	new Float:gametime = get_gametime();
	new Float:next_poison_time = Float:get_entvar(ent, var_fuser1);
	if (gametime >= next_poison_time)
	{
		static Float:origin[3];
		get_entvar(ent, var_origin, origin);

		origin[0] += random_float(-100.0, 100.0);
		origin[1] += random_float(-100.0, 100.0);
		origin[2] += random_float(-16.0, 16.0);

		if (sprite_poison)
		{
			message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
			write_byte(TE_SPRITE);
			write_coord_f(origin[0]);
			write_coord_f(origin[1]);
			write_coord_f(origin[2]);
			write_short(sprite_poison);
			write_byte(random_num(10, 15));
			write_byte(200);
			message_end();
		}

		set_entvar(ent, var_fuser1, gametime + 0.7);
	}

	new Float:next_hurt_time = Float:get_entvar(ent, var_fuser2);
	if (gametime >= next_hurt_time)
	{
		static Float:origin[3];
		get_entvar(ent, var_origin, origin);

		new attacker = get_entvar(ent, var_owner);
		new victim = -1;
		while ((victim = find_ent_in_sphere(victim, origin, 100.0)))
		{
			if (!is_user_alive(victim) || !oo_playerclass_isa(victim, "Human"))
				continue;

			oo_call(0, "AcidStatus@Add", victim, attacker, 0.5, 2.0, 1);
		}

		set_entvar(ent, var_fuser2, gametime + 0.35);
	}

	new Float:next_slow_down = Float:get_entvar(ent, var_fov);
	if (gametime >= next_slow_down)
	{
		static Float:velocity[3], Float:vec[3], Float:maxspeed, Float:speed;
		
		static Float:origin[3];
		get_entvar(ent, var_origin, origin);

		new victim = -1;
		while ((victim = find_ent_in_sphere(victim, origin, 100.0)))
		{
			if (!is_user_alive(victim) || !oo_playerclass_isa(victim, "Human"))
				continue;
			
			get_entvar(victim, var_velocity, velocity);
			vec = velocity;
			maxspeed = Float:get_entvar(victim, var_maxspeed);
			speed = xs_vec_len_2d(velocity);
			if (speed > maxspeed * cvar_spit_slowdown)
			{
				xs_vec_mul_scalar(vec, cvar_spit_slowdown / (speed / maxspeed), vec);
				vec[2] = velocity[2]
				set_entvar(victim, var_velocity, vec);
			}
		}

		set_entvar(ent, var_fov, gametime + 0.1);
	}

	new Float:next_sound_time = Float:get_entvar(ent, var_fuser3);
	if (gametime >= next_sound_time)
	{
		static sound[64];
		if (AssetsGetRandomSound(g_oClassInfo, "acid", sound, charsmax(sound)))
			emit_sound(ent, CHAN_BODY, sound, VOL_NORM, ATTN_NORM, 0, random_num(95, 105));

		set_entvar(ent, var_fuser3, gametime + random_float(1.0, 2.0));
	}

	if (gametime >= Float:get_entvar(ent, var_fuser4))
	{
		set_entvar(ent, var_flags, get_entvar(ent, var_flags) | FL_KILLME);
	}
}

public PlayerClassInfo:Spitter@GetClassInfo()
{
	return g_oClassInfo;
}

public Spitter@SetProperties(bool:set_team)
{
	new this = oo_this();
	new id = oo_get(this, "player_id");
	oo_call(this, "SpecialInfected@SetProperties", set_team);

	new pcvar;
	if ((pcvar = oo_call(this, "GetCvarPtr", "health2")))
	{
		set_entvar(id, var_health, Float:get_entvar(id, var_health) + oo_playerclass_count("Human") * get_pcvar_float(pcvar))
		oo_player_set_max_health(id, floatround(Float:get_entvar(id, var_health)));
	}
}

public Spitter@OnCmdStart(uc, seed)
{
	new this = oo_this();
	new id = oo_get(this, "player_id");

	if (!is_user_alive(id))
		return;

	new buttons = get_uc(uc, UC_Buttons);
	new oldbuttons = get_entvar(id, var_oldbuttons);

	new Float:gametime = get_gametime();
	if (gametime < Float:oo_get(this, "next_spit_time"))
		return;

	if (!is_user_bot(id))
	{
		if (!oo_get(this, "notify"))
		{
			client_print(id, print_center, "噴毒技能已經準備好");
			oo_set(this, "notify", true);
		}

		new Float:start_hold_time = Float:oo_get(this, "start_hold_time");
		if (start_hold_time == 0.0 && (buttons & IN_RELOAD) && !(oldbuttons & IN_RELOAD))
		{
			cs_painshock_set(id, 0.0);
			oo_set(this, "start_hold_time", gametime);
			SendBarTime(id, 1);
		}
		
		if (start_hold_time > 0.0 && ((!(buttons & IN_RELOAD) && (oldbuttons & IN_RELOAD)) || gametime - start_hold_time >= 1.0))
		{
			oo_set(this, "notify", false);
			oo_set(this, "start_hold_time", 0.0);

			SendBarTime(id, 0);
			set_uc(uc, UC_Buttons, buttons & ~IN_RELOAD);
			set_entvar(id, var_oldbuttons, oldbuttons | IN_RELOAD);

			oo_call(this, "Spit", gametime - start_hold_time);
		}
	}
	else
	{
		new Float:start_hold_time = Float:oo_get(this, "start_hold_time");
		if (start_hold_time == 0.0)
		{
			new aimid;
			get_user_aiming(id, aimid, _, 1500);

			if (is_user_alive(aimid) && oo_playerclass_isa(aimid, "Human") && (100.0 <= entity_range(id, aimid) <= 1000.0))
			{
				cs_painshock_set(id, 0.0);
				oo_set(this, "start_hold_time", gametime);
			}
		}

		if (gametime - start_hold_time >= 1.0)
		{
			oo_set(this, "start_hold_time", 0.0);

			new aimid;
			get_user_aiming(id, aimid, _, 1500);

			new Float:dist = entity_range(id, aimid);
			if (is_user_alive(aimid) && oo_playerclass_isa(aimid, "Human") && (100.0 <= dist <= 1000.0))
			{
				oo_call(this, "Spit", floatclamp((dist - 100.0) / 900.0, 0.0, 1.0));
			}
		}
	}
}

public Spitter@Spit(Float:time)
{
	new this = oo_this();
	new id = oo_get(this, "player_id");

	static sound[64];
	if (AssetsGetRandomSound(g_oClassInfo, "spit", sound, charsmax(sound)))
		emit_sound(id, CHAN_VOICE, sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	new ent = rg_create_entity("info_target");

	entity_set_model(ent, "models/w_flashbang.mdl");
	entity_set_size(ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0});

	set_entvar(ent, var_classname, "spit_ent");
	set_entvar(ent, var_movetype, MOVETYPE_TOSS);
	set_entvar(ent, var_owner, id);
	set_entvar(ent, var_solid, SOLID_BBOX);
	set_entvar(ent, var_rendermode, kRenderTransAlpha);
	set_entvar(ent, var_renderamt, 0.0);

	static Float:origin[3];
	ExecuteHam(Ham_EyePosition, id, origin);
	entity_set_origin(ent, origin);

	static Float:vec[3]
	velocity_by_aim(id, floatround(cvar_spit_speed[0] + (cvar_spit_speed[1] - cvar_spit_speed[0]) * time), vec);
	set_entvar(ent, var_velocity, vec);

	if (sprite_trail)
	{
		// Make trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW);
		write_short(ent); // entity
		write_short(sprite_trail); // sprite
		write_byte(10); // life
		write_byte(5); // width
		write_byte(0); // r
		write_byte(200); // g
		write_byte(0); // b
		write_byte(200); // brightness
		message_end();
	}

	oo_set(this, "next_spit_time", get_gametime() + cvar_spit_cooldown);
}

stock SendBarTime(id, duration)
{
	static msgBarTime;
	msgBarTime || (msgBarTime = get_user_msgid("BarTime"));

	message_begin(MSG_ONE_UNRELIABLE, msgBarTime, _, id);
	write_short(duration);
	message_end();
}