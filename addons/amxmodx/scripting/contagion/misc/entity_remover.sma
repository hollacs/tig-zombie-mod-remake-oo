#include <amxmodx>
#include <fakemeta>
#include <reapi>

new const g_ObjectiveEnts[][] = 
{
	"func_bomb_target",
	"info_bomb_target",
	"hostage_entity",
	"monster_scientist",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone"
};

new g_fwEntSpawn;

public plugin_precache()
{
	g_fwEntSpawn = register_forward(FM_Spawn, "OnEntSpawn");
}

public plugin_init()
{
	register_plugin("Entity Remover", "0.1", "holla");

	unregister_forward(FM_Spawn, g_fwEntSpawn);
}

public OnEntSpawn(ent)
{
	if (!pev_valid(ent))
		return FMRES_IGNORED;

	static classname[32];
	get_entvar(ent, var_classname, classname, charsmax(classname));
	for (new i = 0; i < sizeof g_ObjectiveEnts; i++)
	{
		if (equal(classname, g_ObjectiveEnts[i]))
		{
			rg_remove_entity(ent);
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}