#include <amxmodx>
#include <reapi>
#include <oo_player_class>
#include <oo_player_status>
#include <oo_assets>

new PlayerClassInfo:g_oClassInfo;

public oo_init()
{
	oo_class("CommonInfected", "Zombie");
	{
		new const cl[] = "CommonInfected";
		oo_mthd(cl, "GetClassInfo");
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "CommonInfected");
	oo_call(g_oClassInfo, "LoadJson", "common_infected.json");
}

public plugin_init()
{
	register_plugin("[OO] Class: Common Infected", "0.1", "holla");
}

public PlayerClassInfo:CommonInfected@GetClassInfo()
{
	return g_oClassInfo;
}