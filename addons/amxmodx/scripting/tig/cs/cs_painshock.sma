#include <amxmodx>
#include <amxmisc>
#include <reapi>

new Float:g_PainShock[MAX_PLAYERS + 1] = {1.0, ...};
new Float:g_PainInterval[MAX_PLAYERS + 1];

new cvar_enable, Float:cvar_recover, Float:cvar_power[CSW_P90 + 1];

public plugin_init()
{
	register_plugin("[CS] Pain Shock", "0.1", "holla");

	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn_Post", 1);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnTakeDamage_Post", 1);
	RegisterHookChain(RG_PM_Move, "OnPmMove");

	new pcvar = create_cvar("cs_painshock", "1");
	bind_pcvar_num(pcvar, cvar_enable);

	pcvar = create_cvar("cs_painshock_recover", "0.2");
	bind_pcvar_float(pcvar, cvar_recover);

	new cvar_name[32];
	for (new i = CSW_P228; i <= CSW_P90; i++)
	{
		if (~CSW_ALL_GUNS & (1 << i))
			continue;
		
		rg_get_weapon_info(i, WI_NAME, cvar_name, charsmax(cvar_name));
		format(cvar_name, charsmax(cvar_name), "cs_painshock_%s", cvar_name[7]);

		pcvar = create_cvar(cvar_name, "0.5");
		bind_pcvar_float(pcvar, cvar_power[i]);
	}
}

public plugin_natives()
{
	register_library("cs_painshock");

	register_native("cs_painshock_set", "native_painshock_set");
	register_native("cs_painshock_get", "native_painshock_get");
}

public native_painshock_set()
{
	new id = get_param(1);
	g_PainShock[id] = get_param_f(2);
}

public Float:native_painshock_get()
{
	new id = get_param(1);
	return g_PainShock[id];
}

public plugin_cfg()
{
	new path[64];
	get_configsdir(path, charsmax(path));

	server_cmd("exec ^"%s/cs_painshock.cfg^"", path);
	server_exec();
}

public client_disconnected(id)
{
	g_PainShock[id] = 1.0;
}

public OnPlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return;

	g_PainShock[id] = 1.0;
}

public OnTakeDamage_Post(id, inflictor, attacker, Float:damage, damagebits)
{
	if (!cvar_enable || inflictor != attacker || !(1 <= attacker <= MaxClients) || !(damagebits & DMG_BULLET) || damage <= 0.0)
		return;

	if (get_member(id, m_iTeam) == get_member(attacker, m_iTeam))
		return;

	new weapon = get_user_weapon(attacker)
	if (~CSW_ALL_GUNS & (1 << weapon))
		return;

	set_member(id, m_flVelocityModifier, 1.0);

	new Float:power = cvar_power[weapon];
	if (power < g_PainShock[id])
	{
		g_PainShock[id] = power;
		g_PainInterval[id] = get_gametime();
	}
}

public OnPmMove(id)
{
	if (!cvar_enable || !is_user_alive(id))
		return;

	if (g_PainShock[id] < 1.0)
	{
		g_PainShock[id] += (get_gametime() - g_PainInterval[id]) / 1.0 * cvar_recover;
		if (g_PainShock[id] > 1.0)
			g_PainShock[id] = 1.0;

		set_pmove(pm_maxspeed, Float:get_entvar(id, var_maxspeed) * g_PainShock[id]);
		g_PainInterval[id] = get_gametime();
	}
}