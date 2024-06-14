#include <amxmodx>
#include <reapi>
#include <oo_player_class>

new PlayerClassInfo:g_oClassInfo;

public oo_init()
{
	oo_class("Leader", "Human")
	{
		new const cl[] = "Leader";
		oo_mthd(cl, "GetClassInfo");
		oo_mthd(cl, "CanKnifeKnockBack", @cell, @cell);
		oo_mthd(cl, "OnGiveDamage", @cell, @cell, @byref, @cell);
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("HumanClassInfo", "Leader");
	oo_call(g_oClassInfo, "LoadJson", "leader.json");
}

public plugin_init()
{
	register_plugin("[OO] Class: Leader", "0.1", "holla");

	oo_call(g_oClassInfo, "CreateCvars");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "health", "250");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "armor", "150");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "gravity", "0.9");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "speed", "1.1");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "pri_guns", "ak47");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "sec_guns", "deagle");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "nades", "hegrenade flashbang smokegrenade");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "swing_knockback", "400");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "pri_dmg", "1.5");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "sec_dmg", "2.0");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "bpammo", "2.0");
}

public any:Leader@GetClassInfo()
{
	return g_oClassInfo;
}

public Leader@CanKnifeKnockBack(victim, bool:is_stab)
{
	return true;
}

public Leader@OnGiveDamage(inflictor, victim, &Float:damage, damagebits)
{
	new this = oo_this();
	new attacker = oo_get(this, "player_id");

	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return HC_CONTINUE;

	if (inflictor == attacker && oo_playerclass_isa(victim, "Zombie"))
	{
		new current_weapon = get_user_weapon(attacker);

		static name[32];
		if ((CSW_ALL_SHOTGUNS|CSW_ALL_SMGS|CSW_ALL_RIFLES|
			CSW_ALL_SNIPERRIFLES|CSW_ALL_MACHINEGUNS) & (1 << current_weapon))
			copy(name, charsmax(name), "pri_");
		else if (CSW_ALL_PISTOLS & (1 << current_weapon))
			copy(name, charsmax(name), "sec_");
		else
			return HC_CONTINUE;

		new Trie:cvars_t = any:oo_get(info_o, "cvars");

		new weapon_name[32] = "weapon_";

		new pcvar;
		copy(name[4], charsmax(name)-4, "guns");
		if (TrieGetCell(cvars_t, name, pcvar))
			get_pcvar_string(pcvar, weapon_name[7], charsmax(weapon_name) - 7);

		new weapon_id = rg_get_weapon_info(weapon_name, WI_ID);
		if (weapon_id && current_weapon == weapon_id)
		{
			copy(name[4], charsmax(name)-4, "dmg");
			if (TrieGetCell(cvars_t, name, pcvar))
			{
				damage *= get_pcvar_float(pcvar);
				SetHookChainArg(4, ATYPE_FLOAT, damage);
			}
		}
	}

	return HC_CONTINUE;
}