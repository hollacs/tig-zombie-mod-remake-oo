#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <hamsandwich>

const WEAPONS_BITS = CSW_ALL_GUNS|(1 << CSW_KNIFE);

new Float:g_PainShock[MAX_PLAYERS + 1] = {1.0, ...};
new Float:g_PainInterval[MAX_PLAYERS + 1];

new g_fwPainShock[2];

new cvar_enable, Float:cvar_recover, Float:cvar_power[CSW_P90 + 1], Float:cvar_ducking;
new Float:cvar_head, Float:cvar_chest, Float:cvar_stomach, Float:cvar_arms, Float:cvar_legs;

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

	pcvar = create_cvar("cs_painshock_ducking", "0.5");
	bind_pcvar_float(pcvar, cvar_ducking);

	pcvar = create_cvar("cs_painshock_head", "1.0");
	bind_pcvar_float(pcvar, cvar_head);

	pcvar = create_cvar("cs_painshock_chest", "0.95");
	bind_pcvar_float(pcvar, cvar_chest);

	pcvar = create_cvar("cs_painshock_stomach", "0.975");
	bind_pcvar_float(pcvar, cvar_stomach);

	pcvar = create_cvar("cs_painshock_arms", "0.9");
	bind_pcvar_float(pcvar, cvar_arms);

	pcvar = create_cvar("cs_painshock_legs", "1.1");
	bind_pcvar_float(pcvar, cvar_legs);

	static cvar_name[32];
	for (new i = CSW_P228; i <= CSW_P90; i++)
	{
		if (~WEAPONS_BITS & (1 << i))
			continue;
		
		rg_get_weapon_info(i, WI_NAME, cvar_name, charsmax(cvar_name));
		format(cvar_name, charsmax(cvar_name), "cs_painshock_%s", cvar_name[7]);

		pcvar = create_cvar(cvar_name, "0.5");
		bind_pcvar_float(pcvar, cvar_power[i]);
	}

	g_fwPainShock[0] = CreateMultiForward("CS_OnPainShock", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_FLOAT, FP_CELL);
	g_fwPainShock[1] = CreateMultiForward("CS_OnPainShock_Post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_FLOAT, FP_CELL, FP_VAL_BYREF);
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
	g_PainInterval[id] = get_gametime();
}

public Float:native_painshock_get()
{
	new id = get_param(1);
	return g_PainShock[id];
}

public plugin_cfg()
{
	static path[64];
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
	if (!cvar_enable || inflictor != attacker || id == attacker || !(1 <= attacker <= MaxClients) || !(damagebits & DMG_BULLET))
		return;

	if (get_member(id, m_iTeam) == get_member(attacker, m_iTeam))
		return;

	new weapon = get_user_weapon(attacker);
	if (~WEAPONS_BITS & (1 << weapon))
		return;

	new ret;
	ExecuteForward(g_fwPainShock[0], ret, id, inflictor, attacker, damage, damagebits);
	if (ret == PLUGIN_HANDLED)
		return;

	set_member(id, m_flVelocityModifier, 1.0);

	new Float:value = 1.0 - cvar_power[weapon];

	new Float:ratio = 1.0;
	switch (get_member(id, m_LastHitGroup))
	{
		case HIT_HEAD: ratio = cvar_head;
		case HIT_CHEST: ratio = cvar_chest;
		case HIT_STOMACH: ratio = cvar_stomach;
		case HIT_LEFTARM, HIT_RIGHTARM: ratio = cvar_arms;
		case HIT_LEFTLEG, HIT_RIGHTLEG: ratio = cvar_legs;
	}

	value *= ratio;
	ExecuteForward(g_fwPainShock[1], ret, id, inflictor, attacker, damage, damagebits, value);

	value = floatmax(1.0 - value, 0.0);

	if (value < g_PainShock[id])
	{
		g_PainShock[id] = value;
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

		new Float:value = 1.0 - g_PainShock[id];
		value *= (get_pmove(pm_flags) & FL_DUCKING) ? cvar_ducking : 1.0;
		value = 1.0 - value;

		set_pmove(pm_maxspeed, Float:get_entvar(id, var_maxspeed) * value);
		g_PainInterval[id] = get_gametime();
	}
}