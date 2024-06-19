#include <amxmodx>
#include <oo_player_class>

new g_oClassInfo;

public oo_init()
{
	oo_class("Boss", "Zombie");
	{
		new const cl[] = "Boss";
		oo_mthd(cl, "GetClassInfo");

		oo_smthd(cl, "ClassInfo");
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "Boss");
	oo_call(g_oClassInfo, "Clone", oo_call(0, "Zombie@ClassInfo"));
	oo_call(g_oClassInfo, "LoadJson", "boss.json");
}

public plugin_init()
{
	register_plugin("[OO] Class: Boss", "0.1", "holla");
}

public Boss@GetClassInfo()
{
	return g_oClassInfo;
}

public Boss@ClassInfo()
{
	return g_oClassInfo;
}