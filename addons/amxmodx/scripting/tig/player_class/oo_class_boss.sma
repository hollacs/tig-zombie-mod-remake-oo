#include <amxmodx>
#include <oo_player_class>

new g_oClassInfo;

public oo_init()
{
	oo_class("Boss", "Zombie");
	{
		new const cl[] = "Boss";
		oo_mthd(cl, "GetClassInfo");
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "Boss");
	oo_call(g_oClassInfo, "LoadJson", "boss");
}

public plugin_init()
{
	register_plugin("[OO] Class: Boss", "0.1", "holla");
}

public Boss@GetClassInfo()
{
	return g_oClassInfo;
}