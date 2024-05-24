#include <amxmodx>
#include <oo_player_class>

new PlayerClassInfo:g_oClassInfo;

public oo_init()
{
	oo_class("SpecialInfected", "Zombie");
	{
		new const cl[] = "SpecialInfected";
		oo_mthd(cl, "GetClassInfo");
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "SpecialInfected");
	oo_call(g_oClassInfo, "LoadJson", "special_infected.json");
}

public plugin_init()
{
	register_plugin("[OO] Class: Special Infected", "0.1", "holla");
}

public PlayerClassInfo:SpecialInfected@GetClassInfo()
{
	return g_oClassInfo;
}