#include <amxmodx>
#include <reapi>

new Float:g_SpawnTime[MAX_PLAYERS + 1];
new Float:cvar_time;

public plugin_init()
{
	register_plugin("[CTG] Spawn Protection", "0.1", "holla");

	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn_Post", 1);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnPlayerTakeDamage");

	bind_pcvar_float(create_cvar("spawn_protect_time", "3.0"), cvar_time);
}

public OnPlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return;
	
	g_SpawnTime[id] = get_gametime();
}

public OnPlayerTakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (inflictor != attacker || !(damagebits & DMG_BULLET))
		return;
	
	if (!is_user_connected(attacker) || get_member(victim, m_iTeam) == get_member(attacker, m_iTeam))
		return;

	if (get_gametime() < g_SpawnTime[victim] + cvar_time)
		SetHookChainArg(4, ATYPE_FLOAT, 0.0);
}