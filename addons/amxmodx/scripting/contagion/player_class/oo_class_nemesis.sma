#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <reapi>
#include <oo_player_class>
#include <oo_assets>
#include <oo_nade_ice>

new PlayerClassInfo:g_oClassInfo;

new Float:cvar_rocket_speed, Float:cvar_rocket_radius, Float:cvar_rocket_mindmg, Float:cvar_rocket_maxdmg, Float:cvar_rocket_reload_time;
new sprite_trail, sprite_fireball1, sprite_fireball2, sprite_gibs, sprite_smoke;
new model_rocket[64];

public oo_init()
{
	oo_class("Nemesis", "Boss");
	{
		new const cl[] = "Nemesis";
		oo_var(cl, "rpg_reloaded", 1);
		oo_var(cl, "rpg_next_fire", 1);

		oo_mthd(cl, "GetClassInfo");

		oo_mthd(cl, "OnCmdStart", @int(uc), @int(seed));
		oo_mthd(cl, "OnThink");
		oo_mthd(cl, "SetProperties", @bool(set_team));
		oo_mthd(cl, "RocketLaunch");
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "Nemesis");
	oo_call(g_oClassInfo, "LoadJson", "nemesis.json");
}

public plugin_init()
{
	register_plugin("[OO] Class: Nemesis", "0.1", "holla");

	register_think("rpg_rocket", "OnRocketThink");
	register_touch("rpg_rocket", "*", "OnRocketTouch");

	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRestartRound");

	bind_pcvar_float(create_cvar("ctg_nemesis_rocket_speed", "1250"), cvar_rocket_speed);
	bind_pcvar_float(create_cvar("ctg_nemesis_rocket_radius", "250"), cvar_rocket_radius);
	bind_pcvar_float(create_cvar("ctg_nemesis_rocket_min_dmg", "10"), cvar_rocket_mindmg);
	bind_pcvar_float(create_cvar("ctg_nemesis_rocket_max_dmg", "150"), cvar_rocket_maxdmg);
	bind_pcvar_float(create_cvar("ctg_nemesis_rocket_reload_time", "30"), cvar_rocket_reload_time);

	oo_call(g_oClassInfo, "CreateCvars");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_nemesis", "health", "10000");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_nemesis", "health2", "1000");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_nemesis", "gravity", "0.9");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_nemesis", "speed", "1.05");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_nemesis", "dmg", "1.5");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_nemesis", "armor_penetration", "0.25");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_nemesis", "knockback", "0.5");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_nemesis", "painshock", "0.6");

	AssetsGetModel(g_oClassInfo, "rocket", model_rocket, charsmax(model_rocket));
	sprite_trail = AssetsGetSprite(g_oClassInfo, "trail");
	sprite_fireball1 = AssetsGetSprite(g_oClassInfo, "fireball1");
	sprite_fireball2 = AssetsGetSprite(g_oClassInfo, "fireball2");
	sprite_gibs = AssetsGetSprite(g_oClassInfo, "gibs");
	sprite_smoke = AssetsGetSprite(g_oClassInfo, "smoke");
}

public OnRestartRound()
{
	remove_entity_name("rpg_rocket");
}

public OnRocketThink(ent)
{
	if (!is_valid_ent(ent))
		return;

	if (!entity_get_int(ent, EV_INT_bInDuck))
	{
		entity_set_int(ent, EV_INT_bInDuck, 1);

		if (sprite_trail)
		{
			// Make trail
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_BEAMFOLLOW);
			write_short(ent); // entity
			write_short(sprite_trail); // sprite
			write_byte(10); // life
			write_byte(5); // width
			write_byte(100); // r
			write_byte(100); // g
			write_byte(100); // b
			write_byte(200); // brightness
			message_end();
		}
	}
	else
	{
		static Float:origin[3];
		entity_get_vector(ent, EV_VEC_origin, origin);

		message_begin_f(MSG_PAS, SVC_TEMPENTITY, origin);
		write_byte(TE_DLIGHT);
		write_coord_f(origin[0]); // position.x
		write_coord_f(origin[1]); // position.y
		write_coord_f(origin[2]); // position.z
		write_byte(20); // radius in 10's
		write_byte(200); // red
		write_byte(100); // green
		write_byte(0); // blue
		write_byte(1); // life in 0.1's
		write_byte(0) // decay rate in 0.1's
		message_end();
	}

	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.05);
}

public OO_OnIceNadeFrozen(victim, attacker, &Float:duration)
{
	if (oo_playerclass_isa(victim, "Nemesis") && !oo_playerclass_isa(attacker, "Leader"))
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

public OnRocketTouch(ent, toucher)
{
	if (!is_entity(ent))
		return;

	CreateExplosionEffect(ent);

	static sound_explosion[64];
	if (AssetsGetRandomSound(g_oClassInfo, "rocket_explosion", sound_explosion, charsmax(sound_explosion)))
		emit_sound(ent, CHAN_WEAPON, sound_explosion, 1.0, ATTN_NORM, 0, PITCH_NORM);

	new attacker = get_entvar(ent, var_owner);

	static Float:origin[3];
	get_entvar(ent, var_origin, origin);

	new victim = -1;
	new Float:damage, Float:radius, Float:ratio, damagebits;
	
	while ((victim = find_ent_in_sphere(victim, origin, cvar_rocket_radius)) != 0)
	{
		if (!is_entity(victim))
			continue;

		if (entity_get_float(victim, EV_FL_takedamage) == DAMAGE_NO)
			continue;

		if (is_user_alive(victim) && oo_playerclass_isa(victim, "Zombie"))
			continue;

		radius = entity_range(ent, victim);
		ratio = (1.0 - radius / cvar_rocket_radius);
		damage = floatmax(ratio * cvar_rocket_maxdmg, cvar_rocket_mindmg);
		damagebits = ratio >= 0.75 ? (DMG_GRENADE|DMG_ALWAYSGIB) : DMG_GRENADE;

		if (victim == toucher)
			damage = cvar_rocket_maxdmg

		ExecuteHamB(Ham_TakeDamage, victim, ent, attacker, damage, damagebits);
	}

	remove_entity(ent);
}

public any:Nemesis@GetClassInfo()
{
	return g_oClassInfo;
}

public Nemesis@SetProperties(bool:set_team)
{
	new this = oo_this();
	new id = oo_get(this, "player_id");
	oo_call(this, "Boss@SetProperties", set_team);

	new pcvar;
	if ((pcvar = oo_call(this, "GetCvarPtr", "health2")))
	{
		set_entvar(id, var_health, Float:get_entvar(id, var_health) + oo_playerclass_count("Human") * get_pcvar_float(pcvar))
		oo_player_set_max_health(id, floatround(Float:get_entvar(id, var_health)));
	}

	oo_set(this, "rpg_reloaded", true);
}

public Nemesis@OnCmdStart(uc, seed)
{
	new this = oo_this()
	new id = oo_get(this, "player_id");

	if (!is_user_alive(id))
		return;

	if (get_user_weapon(id) == CSW_KNIFE)
	{
		if (oo_get(this, "rpg_reloaded"))
		{
			if (is_user_bot(id))
			{
				new aiming;
				get_user_aiming(id, aiming, _, 1000);
				if (is_user_alive(aiming) && oo_playerclass_isa(aiming, "Human"))
					oo_call(this, "RocketLaunch");
			}
			else if ((get_uc(uc, UC_Buttons) & IN_RELOAD) && (~pev(id, pev_oldbuttons) & IN_RELOAD))
				oo_call(this, "RocketLaunch");
		}
	}
}

public Nemesis@RocketLaunch()
{
	new this = oo_this();
	new id = oo_get(this, "player_id");

	new ent = rg_create_entity("info_target");

	if (model_rocket[0])
		entity_set_model(ent, model_rocket);

	entity_set_size(ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0});

	set_entvar(ent, var_classname, "rpg_rocket");
	set_entvar(ent, var_movetype, MOVETYPE_FLY);
	set_entvar(ent, var_owner, id);
	set_entvar(ent, var_solid, SOLID_BBOX);

	static Float:origin[3];
	ExecuteHam(Ham_EyePosition, id, origin);
	entity_set_origin(ent, origin);

	static Float:vec[3];
	get_entvar(id, var_v_angle, vec);
	set_entvar(ent, var_angles, vec);

	velocity_by_aim(id, floatround(cvar_rocket_speed), vec);
	set_entvar(ent, var_velocity, vec);

	static sound_fire[64];
	if (AssetsGetRandomSound(g_oClassInfo, "rocket_fire", sound_fire, charsmax(sound_fire)))
		emit_sound(id, CHAN_WEAPON, sound_fire, 1.0, ATTN_NORM, 0, PITCH_NORM);

	oo_set(this, "rpg_reloaded", false);
	oo_set(this, "rpg_next_fire", get_gametime() + cvar_rocket_reload_time);

	set_entvar(ent, var_nextthink, get_gametime() + 0.3);

	set_dhudmessage(255, 50, 50, -1.0, 0.3, 0, 0.0, 3.0, 0.1, 1.0);
	show_dhudmessage(0, "Nemesis 發射火箭炮!");
}

public Nemesis@OnThink()
{
	new this = oo_this();
	new id = oo_get(this, "player_id");

	oo_call(this, "Zombie@OnThink");

	if (!is_user_alive(id))
		return;

	if (!oo_get(this, "rpg_reloaded"))
	{
		if (get_gametime() >= Float:oo_get(this, "rpg_next_fire"))
		{
			oo_set(this, "rpg_reloaded", true);
			
			set_dhudmessage(255, 50, 50, -1.0, 0.3, 0, 0.0, 3.0, 0.1, 1.0);
			show_dhudmessage(0, "Nemesis 的火箭炮已經裝填完成");
		}
	}
}

stock CreateExplosionEffect(ent)
{
	static Float:origin[3];
	get_entvar(ent, var_origin, origin);

	if (sprite_fireball1)
	{	
		message_begin_f(MSG_PAS, SVC_TEMPENTITY, origin);
		write_byte(TE_EXPLOSION);	// This makes a dynamic light and the explosion sprites/sound
		write_coord_f(origin[0]);		// Send to PAS because of the sound
		write_coord_f(origin[1]);
		write_coord_f(origin[2] + 20.0);
		write_short(sprite_fireball1);
		write_byte(25);			// scale * 10
		write_byte(30);		// framerate
		write_byte(TE_EXPLFLAG_NOSOUND);	// flags
		message_end();
	}

	if (sprite_fireball2)
	{	
		message_begin_f(MSG_PAS, SVC_TEMPENTITY, origin);
		write_byte(TE_EXPLOSION);	// This makes a dynamic light and the explosion sprites/sound
		write_coord_f(origin[0] + random_float(-64.0, 64.0));	// Send to PAS because of the sound
		write_coord_f(origin[1] + random_float(-64.0, 64.0));
		write_coord_f(origin[2] + random_float(30.0, 35.0));
		write_short(sprite_fireball2);
		write_byte(30);			// scale * 10
		write_byte(30);		// framerate
		write_byte(TE_EXPLFLAG_NONE);	// flags
		message_end();
	}

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_WORLDDECAL);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_byte(random_num(46, 48));
	message_end();

	if (sprite_gibs)
	{
		message_begin_f(MSG_PAS, SVC_TEMPENTITY, origin);
		write_byte(TE_EXPLODEMODEL);
		write_coord_f(origin[0]);
		write_coord_f(origin[1]);
		write_coord_f(origin[2] + 10.0);
		write_coord(random_num(400, 600));// velocity
		write_short(sprite_gibs); //(model index)
		write_short(random_num(10, 15)); //(count)
		write_byte(30); //(life in 0.1's)
		message_end();
	}

	static Float:normal[3];
	normal = origin;
	normal[2] -= 40.0;

	engfunc(EngFunc_TraceLine, origin, normal, IGNORE_MONSTERS, ent, 0);
	get_tr2(0, TR_vecPlaneNormal, normal);

	new num = random_num(1, 3);
	new spark_ent;
	for (new i = 0; i < num; i++)
	{
		spark_ent = create_entity("spark_shower");
		if (!spark_ent) continue;
		
		entity_set_origin(spark_ent, origin);
		set_pev(spark_ent, pev_angles, normal);
		DispatchSpawn(spark_ent);
	}

	static param[3];
	FVecIVec(origin, param);

	set_task(0.75, "ShowSmoke", 9999, param, sizeof(param));
}

public ShowSmoke(param[], taskid)
{
	static origin[3];
	origin[0] = param[0];
	origin[1] = param[1];
	origin[2] = param[2] + 5;

	if (sprite_smoke)
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
		write_byte(TE_SMOKE);
		write_coord(origin[0]);
		write_coord(origin[1]);
		write_coord(origin[2]);
		write_short(sprite_smoke);
		write_byte(35 + random_num(0, 10)); // scale * 10
		write_byte(5); // framerate
		message_end();
	}
}