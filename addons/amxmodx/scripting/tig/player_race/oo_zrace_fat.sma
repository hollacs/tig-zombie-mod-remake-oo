#include <amxmodx>
#include <oo>

new PlayerClassInfo:g_oClassInfo;

public oo_init()
{
	oo_class("ZombieFat", "Zombie");
	{
		new const cl[] = "ZombieFat";
		oo_mthd(cl, "GetClassInfo");
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "Fat Zombie");
	oo_call(g_oClassInfo, "LoadJson", "zombie");
}

public plugin_init()
{
	register_plugin("[OO] Zombie Race: Fat", "0.1", "holla");

	new ZombieRaceMenu:menu_o = any:oo_call(0, "ZombieRaceMenu@GetInstance");
	oo_call(menu_o, "AddRace", 
		oo_new("PlayerRace", g_oClassInfo, "ZombieFat", "厚血, 移速慢"));

	oo_call(g_oClassInfo, "CreateCvars");
	oo_call(g_oClassInfo, "CreateCvar", "tig_zombie_fat", "health", "3000");
	oo_call(g_oClassInfo, "CreateCvar", "tig_zombie_fat", "gravity", "1.0");
	oo_call(g_oClassInfo, "CreateCvar", "tig_zombie_fat", "speed", "1.0");
	oo_call(g_oClassInfo, "CreateCvar", "tig_zombie_fat", "knockback", "0.75");
}

public any:ZombieFat@GetClassInfo()
{
	return g_oClassInfo;
}