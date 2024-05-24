#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

new Float:g_Velocity[MAX_PLAYERS + 1][3];
new Float:g_Multiplier[MAX_PLAYERS + 1] = {1.0, ...};

new g_Ret;
new g_fwKnockBack, g_fwKnockBackPost;

new cvar_enable, Float:cvar_duck, cvar_zvel, Float:cvar_power[CSW_P90 + 1];
new Float:cvar_distance, Float:cvar_multiplier;

public plugin_init()
{
	register_plugin("[CS] Knock Back", "0.1", "holla");

	RegisterHookChain(RG_CBasePlayer_TraceAttack, "OnTraceAttack_Post", 1);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnTakeDamage");
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnTakeDamage_Post", 1);

	new pcvar = create_cvar("cs_knockback", "1");
	bind_pcvar_num(pcvar, cvar_enable);

	pcvar = create_cvar("cs_knockback_duck", "0.25");
	bind_pcvar_float(pcvar, cvar_duck);

	pcvar = create_cvar("cs_knockback_zvel", "0");
	bind_pcvar_num(pcvar, cvar_zvel);

	pcvar = create_cvar("cs_knockback_multiplier", "1.0");
	bind_pcvar_float(pcvar, cvar_multiplier);

	pcvar = create_cvar("cs_knockback_distance", "500");
	bind_pcvar_float(pcvar, cvar_distance);

	new cvar_name[32];
	for (new i = CSW_P228; i <= CSW_P90; i++)
	{
		if (~CSW_ALL_GUNS & (1 << i))
			continue;
		
		rg_get_weapon_info(i, WI_NAME, cvar_name, charsmax(cvar_name));
		format(cvar_name, charsmax(cvar_name), "cs_knockback_%s", cvar_name[7]);

		pcvar = create_cvar(cvar_name, "0.0");
		bind_pcvar_float(pcvar, cvar_power[i]);
	}

	g_fwKnockBack = CreateMultiForward("CS_OnKnockBack", ET_CONTINUE, FP_CELL, FP_CELL, FP_FLOAT, FP_CELL);
	g_fwKnockBackPost = CreateMultiForward("CS_OnKnockBack_Post", ET_IGNORE, FP_CELL, FP_CELL, FP_FLOAT, FP_CELL, FP_ARRAY);
}

public plugin_natives()
{
	register_library("cs_knockback");

	register_native("cs_knockback_get", "native_get");
	register_native("cs_knockback_set", "native_set");
}

public Float:native_get()
{
	new id = get_param(1)
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return 1.0;
	}

	return g_Multiplier[id];
}

public native_set()
{
	new id = get_param(1)
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return;
	}

	g_Multiplier[id] = get_param_f(2);
}

public plugin_cfg()
{
	new path[64];
	get_configsdir(path, charsmax(path));

	server_cmd("exec ^"%s/cs_knockback.cfg^"", path);
	server_exec();
}

public client_putinserver(id)
{
	g_Multiplier[id] = cvar_multiplier;
}

public OnTakeDamage(id)
{
	if (cvar_enable)
		get_entvar(id, var_velocity, g_Velocity[id]);
}

public OnTakeDamage_Post(id)
{
	if (cvar_enable)
		set_entvar(id, var_velocity, g_Velocity[id]);
}

public OnTraceAttack_Post(id, attacker, Float:damage, Float:dir[3], tr, damagebits)
{
	if (!cvar_enable)
		return;
	
	if (!is_user_alive(attacker) || get_member(id, m_iTeam) == get_member(attacker, m_iTeam))
		return;

	if (!(damagebits & DMG_BULLET) || damage <= 0.0)
		return;

	if (get_tr2(tr, TR_pHit) != id)
		return;

	new weapon = get_user_weapon(attacker)
	if (~CSW_ALL_GUNS & (1 << weapon))
		return;

	new Float:start_pos[3], Float:end_pos[3];
	ExecuteHam(Ham_EyePosition, attacker, start_pos);
	get_tr2(tr, TR_vecEndPos, end_pos);

	if (get_distance_f(start_pos, end_pos) > cvar_distance)
		return;

	ExecuteForward(g_fwKnockBack, g_Ret, id, attacker, Float:damage, tr);

	new Float:velocity[3];
	get_entvar(id, var_velocity, velocity);

	xs_vec_mul_scalar(dir, cvar_power[weapon], dir);
	xs_vec_mul_scalar(dir, g_Multiplier[id], dir);

	new arr = PrepareArray(_:dir, sizeof dir, 1);
	ExecuteForward(g_fwKnockBackPost, g_Ret, id, attacker, Float:damage, tr, arr);

	if (get_entvar(id, var_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND))
		xs_vec_mul_scalar(dir, cvar_duck, dir);

	xs_vec_add(velocity, dir, dir);

	if (!cvar_zvel)
		dir[2] = velocity[2];

	set_entvar(id, var_velocity, dir);
}