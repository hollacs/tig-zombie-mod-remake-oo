#include <amxmodx>
#include <reapi>

new g_HudSyncObj;

public plugin_init()
{
	register_plugin("Damage HUD", "0.1", "holla");

	RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnPlayerTakeDamage_Post", 1);

	g_HudSyncObj = CreateHudSyncObj();
}

public OnPlayerTakeDamage_Post(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (inflictor != attacker || damage < 1.0 || !(damagebits & DMG_BULLET))
		return;
	
	if (!is_user_connected(attacker) || get_member(victim, m_iTeam) == get_member(attacker, m_iTeam))
		return;
	
	ClearSyncHud(attacker, g_HudSyncObj);

	set_hudmessage(255, 25, 25, -1.0, 0.7, 0, 0.0, 1.0, 0.0, 1.0);
	ShowSyncHudMsg(attacker, g_HudSyncObj, "%.f", damage);
}