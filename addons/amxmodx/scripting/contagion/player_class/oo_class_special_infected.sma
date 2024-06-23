#include <amxmodx>
#include <reapi>
#include <oo_player_class>

new PlayerClassInfo:g_oClassInfo;

public oo_init()
{
	oo_class("SpecialInfected", "Zombie");
	{
		new const cl[] = "SpecialInfected";
		oo_mthd(cl, "GetClassInfo");
		oo_mthd(cl, "SetProps", @bool(set_team));

		oo_smthd(cl, "ClassInfo");
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "SpecialInfected");
	oo_call(g_oClassInfo, "Clone", oo_call(0, "Zombie@ClassInfo"));
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

public PlayerClassInfo:SpecialInfected@ClassInfo()
{
	return g_oClassInfo;
}

public SpecialInfected@SetProps(bool:set_team)
{
	new this = @this;
	new id = oo_get(this, "player_id");
	oo_call(this, "Zombie@SetProps", set_team);

	new pcvar;
	if ((pcvar = oo_call(this, "GetCvarPtr", "health2")))
	{
		set_entvar(id, var_health, Float:get_entvar(id, var_health) + oo_playerclass_count("Human") * get_pcvar_float(pcvar))
		oo_player_set_max_health(id, floatround(Float:get_entvar(id, var_health)));
	}
}