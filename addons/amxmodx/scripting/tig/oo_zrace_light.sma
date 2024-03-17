#include <amxmodx>
#include <oo>

new PlayerClassInfo:g_oClassInfo;

public oo_init()
{
	oo_class("ZombieLight", "Zombie");
	{
		new const cl[] = "ZombieLight";
		oo_mthd(cl, "GetClassInfo");
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "Light Zombie");
	oo_call(g_oClassInfo, "LoadJson", "zombie");
}

public plugin_init()
{
	register_plugin("[OO] Zombie Race: Light", "0.1", "holla");

	new ZombieRaceMenu:menu_o = any:oo_call(0, "ZombieRaceMenu@GetInstance");
	oo_call(menu_o, "AddRace", 
		oo_new("PlayerRace", g_oClassInfo, "ZombieLight", "低重力, 血量較低"));

	oo_call(g_oClassInfo, "CreateCvars");
	oo_call(g_oClassInfo, "CreateCvar", "tig_zombie_light", "health", "1000");
	oo_call(g_oClassInfo, "CreateCvar", "tig_zombie_light", "gravity", "0.7");
	oo_call(g_oClassInfo, "CreateCvar", "tig_zombie_light", "speed", "0.95");
	oo_call(g_oClassInfo, "CreateCvar", "tig_zombie_light", "knockback", "1.3");
}

public any:ZombieLight@GetClassInfo()
{
	return g_oClassInfo;
}