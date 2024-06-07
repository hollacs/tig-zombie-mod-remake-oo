#include <amxmodx>
#include <oo>

new PlayerClassInfo:g_oClassInfo;

public oo_init()
{
	oo_class("ZombieLight", "CommonInfected");
	{
		new const cl[] = "ZombieLight";
		oo_mthd(cl, "GetClassInfo");
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "Light Zombie");
	oo_call(g_oClassInfo, "LoadJson", "zombie.json");
}

public plugin_init()
{
	register_plugin("[OO] Zombie Race: Light", "0.1", "holla");

	new ZombieRaceMenu:menu_o = any:oo_call(0, "ZombieRaceMenu@GetInstance");
	oo_call(menu_o, "AddRace", 
		oo_new("PlayerRace", g_oClassInfo, "ZombieLight", "跳躍型"));

	oo_call(g_oClassInfo, "CreateCvars");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie_light", "health", "1000");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie_light", "gravity", "0.7");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie_light", "speed", "0.98");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie_light", "knockback", "1.5");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie_light", "painshock", "1.0");
}

public any:ZombieLight@GetClassInfo()
{
	return g_oClassInfo;
}