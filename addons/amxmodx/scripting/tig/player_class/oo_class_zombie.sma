#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <xs>
#include <oo_player_class>

new PlayerClassInfo:g_oClassInfo;
new Float:cvar_idle_sound_time[2], Float:cvar_pain_sound_time[2];

public oo_init()
{
	oo_class("ZombieClassInfo", "PlayerClassInfo")
	{
		new const cl[] = "ZombieClassInfo";
		oo_mthd(cl, "CreateCvars");
	}

	oo_class("Zombie", "PlayerClass");
	{
		new const cl[] = "Zombie";
		oo_var(cl, "next_idle", 1);
		oo_var(cl, "next_pain", 1);

		oo_ctor(cl, "Ctor", @obj(player));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "GetClassInfo");
		oo_mthd(cl, "RemoveWeapons");
		oo_mthd(cl, "SetProperties", @bool(set_team));
		oo_mthd(cl, "SetTeam");
		oo_mthd(cl, "ChangeSound", @cell, @string, @cell, @cell, @cell, @cell);
		oo_mthd(cl, "OnGiveDamage", @cell, @cell, @byref, @cell);
		oo_mthd(cl, "OnThink");
		oo_mthd(cl, "OnTouchWeapon", @int(ent));
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "Zombie");
	oo_call(g_oClassInfo, "LoadJson", "zombie");
}

public plugin_init()
{
	register_plugin("[OO] Class: Zombie", "0.1", "holla");

	RegisterHam(Ham_Touch, "weaponbox", 	 "OnWeaponTouch");
	RegisterHam(Ham_Touch, "armoury_entity", "OnWeaponTouch");
	RegisterHam(Ham_Touch, "weapon_shield",  "OnWeaponTouch");

	oo_call(g_oClassInfo, "CreateCvars");

	bind_pcvar_float(
		oo_call(g_oClassInfo, "CreateCvar", "tig_zombie", "idle_sound_time_min", "40"),
		cvar_idle_sound_time[0]);

	bind_pcvar_float(
		oo_call(g_oClassInfo, "CreateCvar", "tig_zombie", "idle_sound_time_max", "80"),
		cvar_idle_sound_time[0]);

	bind_pcvar_float(
		oo_call(g_oClassInfo, "CreateCvar", "tig_zombie", "pain_sound_time_min", "1.0"),
		cvar_pain_sound_time[0]);

	bind_pcvar_float(
		oo_call(g_oClassInfo, "CreateCvar", "tig_zombie", "pain_sound_time_max", "2.0"),
		cvar_pain_sound_time[1]);
}

public ZombieClassInfo@CreateCvars()
{
	new this = oo_this();

	oo_call(this, "CreateCvar", "tig_zombie", "dmg_slash", "10");
	oo_call(this, "CreateCvar", "tig_zombie", "dmg_stab", "40");
	oo_call(this, "CreateCvar", "tig_zombie", "dmg_head", "3.0");
	oo_call(this, "CreateCvar", "tig_zombie", "dmg_backstab", "1.25");
	oo_call(this, "CreateCvar", "tig_zombie", "dmg", "1.0");
	oo_call(this, "CreateCvar", "tig_zombie", "health", "1000");
	oo_call(this, "CreateCvar", "tig_zombie", "gravity", "1.0");
	oo_call(this, "CreateCvar", "tig_zombie", "speed", "1.0");
}

public Zombie@Ctor(player)
{
	oo_super_ctor("PlayerClass", player);
	oo_set(oo_this(), "next_idle", get_gametime() + random_float(cvar_idle_sound_time[0], cvar_idle_sound_time[1]))
}

public Zombie@Dtor()
{
}

public PlayerClassInfo:Zombie@GetClassInfo()
{
	return g_oClassInfo;
}

public Zombie@SetTeam()
{
	rg_set_user_team(oo_get(oo_this(), "player_id"), TEAM_TERRORIST, MODEL_UNASSIGNED, true, true);
}

public Zombie@OnThink()
{
	new this = oo_this();
	new id = oo_get(this, "player_id");

	if (is_user_alive(id))
	{
		new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
		if (info_o == @null)
			return

		new Float:gametime = get_gametime();
		if (gametime >= Float:oo_get(this, "next_idle") && gametime >= Float:oo_get(this, "next_pain") + 3.0)
		{
			new Array:sound_a;
			if ((sound_a = any:oo_call(info_o, "GetSound", "idle")) != Invalid_Array)
			{
				static sound[64];
				ArrayGetString(sound_a, random(ArraySize(sound_a)), sound, charsmax(sound));
				emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);
			}

			oo_set(this, "next_idle", gametime + random_float(cvar_idle_sound_time[0], cvar_idle_sound_time[1]));
		}
	}
}

public Zombie@ChangeSound(channel, sample[], Float:vol, Float:attn, flags, pitch)
{
	new this = oo_this();

	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return false;

	// player/bhit
	// player/headshot
	if (strlen(sample) > 12 && sample[0] == 'p' && sample[5] == 'r' && 
		((sample[7] == 'b' && sample[10] == 't') || (sample[7] == 'h' && sample[11] == 's')))
	{
		channel = CHAN_BODY;
		if (get_gametime() >= Float:oo_get(this, "next_pain"))
		{
			new Array:sound_a = any:oo_call(info_o, "GetSound", "pain");
			if (sound_a != Invalid_Array)
			{
				static sound[64];
				ArrayGetString(sound_a, random(ArraySize(sound_a)), sound, charsmax(sound));
				emit_sound(oo_get(this, "player_id"), CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);

				oo_set(this, "next_pain", get_gametime() + random_float(cvar_pain_sound_time[0], cvar_pain_sound_time[1]));
			}
		}
	}

	return oo_call(this, "PlayerClass@ChangeSound", channel, sample, vol, attn, flags, pitch);
}

public Zombie@SetProperties(bool:set_team)
{
	new this = oo_this();
	oo_call(this, "RemoveWeapons");
	oo_call(this, "PlayerClass@SetProperties", set_team);
}

public Zombie@RemoveWeapons()
{
	new id = oo_get(oo_this(), "player_id");
	for (new i = _:PRIMARY_WEAPON_SLOT; i <= _:PISTOL_SLOT; i++)
	{
		rg_drop_items_by_slot(id, any:i);
	}

	rg_remove_all_items(id);
	rg_give_item(id, "weapon_knife");
}

public Zombie@OnGiveDamage(inflictor, victim, &Float:damage, damagebits)
{
	new this = oo_this();
	new attacker = oo_get(this, "player_id");

	if ((1 <= attacker <= MaxClients) && inflictor == attacker && get_user_weapon(attacker) == CSW_KNIFE)
	{
		if (oo_playerclass_isa(victim, "Human"))
		{
			const KNIFE_STABHIT = 4;

			new pcvar;
			if ((pcvar = oo_call(this, "GetCvarPtr", "dmg_head")))
			{
				new hitgroup = get_member(victim, m_LastHitGroup);
				if (hitgroup == HIT_HEAD)
				{
					damage /= 4.0;
					damage *= get_pcvar_float(pcvar);
				}
			}

			new anim = get_entvar(attacker, var_weaponanim);
			if (anim == KNIFE_STABHIT) // stab
			{
				if ((pcvar = oo_call(this, "GetCvarPtr", "dmg_backstab")) && IsBackStab(attacker, victim))
				{
					damage /= 3.0;
					damage *= get_pcvar_float(pcvar);
				}

				if ((pcvar = oo_call(this, "GetCvarPtr", "dmg_stab")))
					damage *= get_pcvar_float(pcvar) / 65.0;
			}
			else if ((pcvar = oo_call(this, "GetCvarPtr", "dmg_slash"))) // slash
			{
				damage *= get_pcvar_float(pcvar) / 15.0;
			}

			if ((pcvar = oo_call(this, "GetCvarPtr", "dmg")))
			{
				damage *= get_pcvar_float(pcvar);
			}

			SetHookChainArg(4, ATYPE_FLOAT, damage);
		}
	}
	return HC_CONTINUE;
}

public Zombie@OnTouchWeapon(ent)
{
	return false;
}

public OnWeaponTouch(ent, toucher)
{
	if (is_user_alive(toucher) && oo_playerclass_isa(toucher, "Zombie"))
	{
		return oo_call(oo_playerclass_get(toucher), "OnTouchWeapon", ent) ? HAM_IGNORED : HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

stock bool:IsBackStab(attacker, victim)
{
	new Float:vlos[3];
	new Float:vforward[3];

	velocity_by_aim(attacker, 1, vlos);
	xs_vec_normalize(vlos, vlos);

	get_entvar(victim, var_angles, vforward);
	angle_vector(vforward, ANGLEVECTOR_FORWARD, vforward);

	vlos[2] = vforward[2] = 0.0;
	return (xs_vec_dot(vlos, vforward) > 0.8)
}