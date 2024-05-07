#include <amxmodx>
#include <reapi>
#include <oo_player_class>

new PlayerClassInfo:g_oClassInfo;

public plugin_precache()
{
	g_oClassInfo = oo_new("HumanClassInfo", "Human");
	oo_call(g_oClassInfo, "LoadJson", "human");
}

public plugin_init()
{
	register_plugin("[OO] Class: Human", "0.1", "holla");

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
	}
}

public HumanClassInfo@CreateCvars()
{
	new this = oo_this();
	oo_call(this, "CreateCvar", "tig_human", "health", "100");
	oo_call(this, "CreateCvar", "tig_human", "armor", "0");
	oo_call(this, "CreateCvar", "tig_human", "max_armor", "100");
	oo_call(this, "CreateCvar", "tig_human", "gravity", "1.0");
	oo_call(this, "CreateCvar", "tig_human", "speed", "1.0");
	oo_call(this, "CreateCvar", "tig_human", "pri_guns", "");
	oo_call(this, "CreateCvar", "tig_human", "sec_guns", "glock18 usp p228 fiveseven");
	oo_call(this, "CreateCvar", "tig_human", "nades", "");
	oo_call(this, "CreateCvar", "ctg_human", "armor_defense", "1.0");
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

			new Float:origin[3];
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