#include <amxmodx>
#include <oo>

new PlayerClassInfo:g_oClassInfo;

public oo_init()
{
	oo_class("ZombieFast", "CommonInfected");
	{
		new const cl[] = "ZombieFast";
		oo_mthd(cl, "GetClassInfo");
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "Fast Zombie");
	oo_call(g_oClassInfo, "LoadJson", "zombie.json");
}

public plugin_init()
{
	register_plugin("[OO] Zombie Race: Fast", "0.1", "holla");

	new ZombieRaceMenu:menu_o = any:oo_call(0, "ZombieRaceMenu@GetInstance");
	if (menu_o == @null)
	{
		set_fail_state("ZombieRaceMenu@GetInstance() failed");
		return;
	}

	oo_call(menu_o, "AddRace", 
		oo_new("PlayerRace", g_oClassInfo, "ZombieFast", "速度型"));

	oo_call(g_oClassInfo, "CreateCvars");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie_fast", "health", "750");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie_fast", "gravity", "1.0");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie_fast", "speed", "1.15");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie_fast", "knockback", "1.1");
	oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie_fast", "knockback", "1.1");
}

public any:ZombieFast@GetClassInfo()
{
	return g_oClassInfo;
}