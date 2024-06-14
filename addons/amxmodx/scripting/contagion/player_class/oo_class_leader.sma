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
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "stab_knockback", "800");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "dmg_ak47", "1.5");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "dmg_deagle", "2.0");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "bpammo", "2.0");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "bpammo_deagle", "35");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "bpammo_hegrenade", "4");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_leader", "bpammo_flashbang", "4");
}

public any:Leader@GetClassInfo()
{
	return g_oClassInfo;
}

public Leader@CanKnifeKnockBack(victim, bool:is_stab)
{
	return true;
}