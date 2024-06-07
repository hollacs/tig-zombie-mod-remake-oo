#include <amxmodx>
#include <oo>

new PlayerClassInfo:g_oClassInfo;

public oo_init()
{
	oo_class("ZombieNormal", "CommonInfected");
	{
		new const cl[] = "ZombieNormal";
		oo_mthd(cl, "GetClassInfo");
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "Normal Zombie");
	oo_call(g_oClassInfo, "LoadJson", "zombie.json");
}

public plugin_init()
{
	register_plugin("[OO] Zombie Race: Normal", "0.1", "holla");

	new ZombieRaceMenu:menu_o = any:oo_call(0, "ZombieRaceMenu@GetInstance");
	if (menu_o == @null)
	{
		set_fail_state("ZombieRaceMenu@GetInstance() failed");
		return;
	}

	oo_call(menu_o, "AddRace", 
		oo_new("PlayerRace", g_oClassInfo, "ZombieNormal", "平衡型"));

	oo_call(g_oClassInfo, "CreateCvars");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie_normal", "health", "1500");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie_normal", "gravity", "1.0");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie_normal", "speed", "1.0");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie_normal", "knockback", "1.0");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie_normal", "painshock", "1.0");
}

public any:ZombieNormal@GetClassInfo()
{
	return g_oClassInfo;
}