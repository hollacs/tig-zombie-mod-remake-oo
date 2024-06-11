#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <oo_player_class>
#include <cs_painshock>

new PlayerClassInfo:g_oClassInfo;

public plugin_precache()
{
	g_oClassInfo = oo_new("HumanClassInfo", "Human");
	oo_call(g_oClassInfo, "LoadJson", "human.json");
}

public plugin_init()
{
	register_plugin("[OO] Class: Human", "0.1", "holla");

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "OnKnifePrimaryAttack");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "OnKnifeSecondaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "OnKnifePrimaryAttack_Post", 1);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "OnKnifeSecondaryAttack_Post", 1);

	oo_call(g_oClassInfo, "CreateCvars");
}

public oo_init()
{
	oo_class("HumanClassInfo", "PlayerClassInfo")
	{
		new const cl[] = "HumanClassInfo";
		oo_mthd(cl, "CreateCvars");
	}

	oo_class("Human", "PlayerClass");
	{
		new const cl[] = "Human";

		oo_ctor(cl, "Ctor", @obj(player));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "GetClassInfo");
		oo_mthd(cl, "SetTeam");
		oo_mthd(cl, "GetArmorDefense");
		oo_mthd(cl, "OnTakeDamage", @int(inflictor), @int(attacker), @ref(damage), @int(damagebits));
		oo_mthd(cl, "OnPainShock", @cell, @float, @byref);
		oo_mthd(cl, "OnKnifeAttack1", @cell);
		oo_mthd(cl, "OnKnifeAttack2", @cell);
		oo_mthd(cl, "OnKnifeAttack1_Post", @cell);
		oo_mthd(cl, "OnKnifeAttack2_Post", @cell);
	}
}

public HumanClassInfo@CreateCvars()
{
	new this = oo_this();
	oo_call(this, "CreateCvar", "ctg_human", "health", "100");
	oo_call(this, "CreateCvar", "ctg_human", "armor", "0");
	oo_call(this, "CreateCvar", "ctg_human", "max_armor", "100");
	oo_call(this, "CreateCvar", "ctg_human", "gravity", "1.0");
	oo_call(this, "CreateCvar", "ctg_human", "speed", "1.0");
	oo_call(this, "CreateCvar", "ctg_human", "pri_guns", "");
	oo_call(this, "CreateCvar", "ctg_human", "sec_guns", "glock18 usp p228 fiveseven");
	oo_call(this, "CreateCvar", "ctg_human", "nades", "");
	oo_call(this, "CreateCvar", "ctg_human", "armor_defense", "1.0");
	oo_call(this, "CreateCvar", "ctg_human", "painshock", "1.0");
	oo_call(this, "CreateCvar", "ctg_human", "painshock_armor", "0.5");
	oo_call(this, "CreateCvar", "ctg_human", "swing_dmg", "15");
	oo_call(this, "CreateCvar", "ctg_human", "swing2_dmg", "20");
	oo_call(this, "CreateCvar", "ctg_human", "swing_dist", "48");
	oo_call(this, "CreateCvar", "ctg_human", "stab_dmg", "65");
	oo_call(this, "CreateCvar", "ctg_human", "stab_dist", "32");
	oo_call(this, "CreateCvar", "ctg_human", "backstab_dmg", "3.0");
}

public Human@Ctor(player)
{
	oo_super_ctor("PlayerClass", player);
}

public Human@Dtor()
{
}

public PlayerClassInfo:Human@GetClassInfo()
{
	return g_oClassInfo;
}

public Human@SetTeam()
{
	new id = oo_get(oo_this(), "player_id");
	rg_set_user_team(id, TEAM_CT, MODEL_UNASSIGNED, true, true);
}

public Float:Human@GetArmorDefense()
{
	new this = oo_this();

	new pcvar = oo_call(this, "GetCvarPtr", "armor_defense");
	if (pcvar)
		return get_pcvar_float(pcvar);

	return 1.0;
}

public Human@OnTakeDamage(inflictor, attacker, &Float:damage, damagebits)
{
	new this = oo_this();
	new victim = oo_get(this, "player_id");

	if ((1 <= attacker <= MaxClients) && oo_playerclass_isa(attacker, "Zombie"))
	{
		new PlayerClass:zombie_o = oo_playerclass_get(attacker);

		new Float:new_dmg = damage * Float:oo_call(zombie_o, "GetArmorPenetration");
		new Float:armor_dmg = (damage - new_dmg) * Float:oo_call(this, "GetArmorDefense");
		new Float:armor = Float:get_entvar(victim, var_armorvalue);

		if (armor_dmg > armor)
		{
			new_dmg = damage - armor;
			set_entvar(victim, var_armorvalue, 0.0);
		}
		else
		{
			armor -= armor_dmg;
			set_entvar(victim, var_armorvalue, armor);

			static Float:origin[3];
			get_entvar(attacker, var_origin, origin);

			if (new_dmg == 0)
			{
				static msgDamage;
				msgDamage || (msgDamage = get_user_msgid("Damage"));

				message_begin(MSG_ONE_UNRELIABLE, msgDamage, _, victim);
				write_byte(0); // damage save
				write_byte(1); // damage take
				write_long(DMG_SLASH); // damage type - DMG_FREEZE
				write_coord_f(origin[0]); // x
				write_coord_f(origin[1]); // y
				write_coord_f(origin[2]); // z
				message_end();
			}
		}

		damage = new_dmg;
		SetHookChainArg(4, ATYPE_FLOAT, damage);
	}

	return HC_CONTINUE;
}

public Human@OnPainShock(attacker, Float:damage, &Float:value)
{
	new this = oo_this();
	new id = oo_get(this, "player_id");

	new pcvar_painshock = oo_call(this, "GetCvarPtr", "painshock");
	if (pcvar_painshock)
	{
		value *= get_pcvar_float(pcvar_painshock);
	}

	if (Float:get_entvar(id, var_armorvalue) > 0.0)
	{
		new pcvar_painshock_armor = oo_call(this, "GetCvarPtr", "painshock_armor");
		if (pcvar_painshock_armor)
		{
			value *= get_pcvar_float(pcvar_painshock_armor);
		}
	}
}


public Human@OnKnifeAttack1(ent)
{
	new this = oo_this();

	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return false;

	new Trie:cvars_t = any:oo_get(info_o, "cvars");
	new pcvar;

	if (TrieGetCell(cvars_t, "swing_dmg", pcvar))
		set_member(ent, m_Knife_flSwingBaseDamage, get_pcvar_float(pcvar));

	if (TrieGetCell(cvars_t, "swing2_dmg", pcvar))
		set_member(ent, m_Knife_flSwingBaseDamage_Fast, get_pcvar_float(pcvar));

	if (TrieGetCell(cvars_t, "swing_dist", pcvar))
		set_member(ent, m_Knife_flSwingDistance, get_pcvar_float(pcvar));

	return false;
}

public Human@OnKnifeAttack2(ent)
{
	new this = oo_this();

	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return false;

	new Trie:cvars_t = any:oo_get(info_o, "cvars");
	new pcvar

	if (TrieGetCell(cvars_t, "stab_dmg", pcvar))
		set_member(ent, m_Knife_flStabBaseDamage, get_pcvar_float(pcvar));

	if (TrieGetCell(cvars_t, "stab_dist", pcvar))
		set_member(ent, m_Knife_flStabDistance, get_pcvar_float(pcvar));

	if (TrieGetCell(cvars_t, "backstab_dmg", pcvar))
		set_member(ent, m_Knife_flBackStabMultiplier, get_pcvar_float(pcvar));

	return false;
}

public Human@OnKnifeAttack1_Post(ent)
{
}

public Human@OnKnifeAttack2_Post(ent)
{
}

public OnKnifePrimaryAttack(ent)
{
	if (!is_entity(ent))
		return HAM_IGNORED;
	
	new player = get_member(ent, m_pPlayer);
	if (!player)
		return HAM_IGNORED;
	
	new PlayerClass:class_o = oo_playerclass_get(player);
	if (class_o != @null && oo_isa(class_o, "Human"))
	{
		return oo_call(class_o, "OnKnifeAttack1", ent) ? HAM_SUPERCEDE : HAM_IGNORED;
	}

	return HAM_IGNORED;
}

public OnKnifeSecondaryAttack(ent)
{
	if (!is_entity(ent))
		return HAM_IGNORED;
	
	new player = get_member(ent, m_pPlayer);
	if (!player)
		return HAM_IGNORED;
	
	new PlayerClass:class_o = oo_playerclass_get(player);
	if (class_o != @null && oo_isa(class_o, "Human"))
	{
		return oo_call(class_o, "OnKnifeAttack2", ent) ? HAM_SUPERCEDE : HAM_IGNORED;
	}

	return HAM_IGNORED;
}

public OnKnifePrimaryAttack_Post(ent)
{
	if (!is_entity(ent))
		return;
	
	new player = get_member(ent, m_pPlayer);
	if (!player)
		return;
	
	new PlayerClass:class_o = oo_playerclass_get(player);
	if (class_o != @null && oo_isa(class_o, "Human"))
	{
		oo_call(class_o, "OnKnifeAttack1_Post", ent);
	}
}

public OnKnifeSecondaryAttack_Post(ent)
{
	if (!is_entity(ent))
		return;
	
	new player = get_member(ent, m_pPlayer);
	if (!player)
		return;
	
	new PlayerClass:class_o = oo_playerclass_get(player);
	if (class_o != @null && oo_isa(class_o, "Human"))
	{
		oo_call(class_o, "OnKnifeAttack2_Post", ent);
	}
}

public CS_OnPainShock_Post(victim, inflictor, attacker, Float:damage, damagebits, &Float:value)
{
	new PlayerClass:class_o = oo_playerclass_get(victim)
	if (class_o != @null && oo_isa(class_o, "Human"))
	{
		oo_call(class_o, "OnPainShock", attacker, damage, value);
	}
}