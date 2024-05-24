#include <amxmodx>
#include <oo_player_class>

new PlayerClassInfo:g_oClassInfo;

public oo_init()
{
	oo_class("Leader", "Human")
	{
		new const cl[] = "Leader";
		oo_mthd(cl, "GetClassInfo");
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
	oo_call(g_oClassInfo, "CreateCvar", "tig_leader", "health", "250");
	oo_call(g_oClassInfo, "CreateCvar", "tig_leader", "armor", "100");
	oo_call(g_oClassInfo, "CreateCvar", "tig_leader", "gravity", "0.9");
	oo_call(g_oClassInfo, "CreateCvar", "tig_leader", "speed", "1.1");
	oo_call(g_oClassInfo, "CreateCvar", "tig_leader", "pri_guns", "ak47");
	oo_call(g_oClassInfo, "CreateCvar", "tig_leader", "sec_guns", "deagle");
}

public any:Leader@GetClassInfo()
{
	return g_oClassInfo;
}