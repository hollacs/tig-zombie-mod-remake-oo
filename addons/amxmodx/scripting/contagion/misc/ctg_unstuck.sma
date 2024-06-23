#include <amxmodx>
#include <reapi>
#include <fakemeta>
#include <oo_player_class>
#include <csdm_spawn>

public plugin_init()
{
	register_plugin("[CTG] Unstuck", "0.1", "holla");

	oo_hook_mthd("PlayerClass", "SetProps", "OnPlayerClassSetProps");
}

public OnPlayerClassSetProps()
{
	new id = oo_get(@this, "player_id");
	if (IsPlayerStuck(id))
	{
		csdm_spawn(id);
	}
}

bool:IsPlayerStuck(id)
{
	static Float:origin[3];
	get_entvar(id, var_origin, origin);

	new team = get_member(id, m_iTeam);
	new solids[MAX_PLAYERS + 1] = {-1, ...};
	for (new i = 1; i <= MaxClients; i++)
	{
		if (is_user_alive(i) && get_member(i, m_iTeam) == team)
		{
			solids[i] = get_entvar(i, var_solid);
			set_entvar(i, var_solid, SOLID_NOT);
		}
	}

	new hull = (get_entvar(id, var_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN;
	engfunc(EngFunc_TraceHull, origin, origin, DONT_IGNORE_MONSTERS, hull, id, 0);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (solids[i] != -1)
			set_entvar(i, var_solid, solids[i]);
	}

	return bool:(get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen));
}