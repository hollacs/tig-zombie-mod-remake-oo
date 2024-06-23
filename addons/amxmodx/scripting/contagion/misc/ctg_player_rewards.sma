#include <amxmodx>
#include <reapi>
#include <oo_player_class>
#include <ctg_player_level>

new cvar_kill_boss_xp, cvar_kill_special_xp, cvar_kill_zombie_xp;
new cvar_kill_human_xp, cvar_kill_leader_xp;
new Float:cvar_kill_random_xp;

new Float:cvar_damage_human_amount, Float:cvar_damage_zombie_amount;
new cvar_damage_human_xp, cvar_damage_zombie_xp;

new Float:g_Damage[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("[CTG] Player Rewards", "0.1", "holla");

	oo_hook_mthd("Player", "OnTakeDamage", "OnPlayerTakeDamage");
	oo_hook_mthd("Player", "OnKilled", "OnPlayerKilled");
	oo_hook_mthd("PlayerClass", "Change", "OnPlayerClassChange");

	bind_pcvar_num(create_cvar("ctg_kill_boss_xp", "200"), cvar_kill_boss_xp);
	bind_pcvar_num(create_cvar("ctg_kill_special_xp", "50"), cvar_kill_special_xp);
	bind_pcvar_num(create_cvar("ctg_kill_zombie_xp", "10"), cvar_kill_zombie_xp);

	bind_pcvar_num(create_cvar("ctg_kill_human_xp", "20"), cvar_kill_human_xp);
	bind_pcvar_num(create_cvar("ctg_kill_leader_xp", "80"), cvar_kill_leader_xp);

	bind_pcvar_float(create_cvar("ctg_kill_random_xp", "0.2"), cvar_kill_random_xp);

	bind_pcvar_float(create_cvar("ctg_damage_zombie_amount", "300"), cvar_damage_zombie_amount);
	bind_pcvar_num(create_cvar("ctg_damage_zombie_xp", "10"), cvar_damage_zombie_xp);

	bind_pcvar_float(create_cvar("ctg_damage_human_amount", "750"), cvar_damage_human_amount);
	bind_pcvar_num(create_cvar("ctg_damage_human_xp", "10"), cvar_damage_human_xp);
}

public OnPlayerClassChange(id, const class[], bool:set_props)
{
	g_Damage[id] = 0.0;
}

public OnPlayerTakeDamage(inflictor, attacker, &Float:damage, damagebits)
{
	new victim = oo_get(@this, "player_id");
	if (inflictor != attacker || !(damagebits & DMG_BULLET) || !is_user_connected(attacker))
		return;
	
	if (get_member(victim, m_iTeam) == get_member(attacker, m_iTeam))
		return;

	g_Damage[attacker] += damage;

	new bool:is_zombie = bool:(oo_playerclass_isa(attacker, "Zombie"));
	new Float:damage_amount = (is_zombie) ? cvar_damage_zombie_amount : cvar_damage_human_amount;

	if (g_Damage[attacker] >= damage_amount)
	{
		g_Damage[attacker] = 0.0;
		ctg_add_player_exp(attacker, (is_zombie) ? cvar_damage_zombie_xp : cvar_damage_human_xp, true);
	}
}

public OnPlayerKilled(killer)
{
	new victim = oo_get(@this, "player_id");
	if (!is_user_connected(killer) || get_member(victim, m_iTeam) == get_member(killer, m_iTeam))
		return;
	
	new add_exp = 0;

	if (oo_playerclass_isa(victim, "Zombie"))
	{
		if (oo_playerclass_isa(victim, "Boss"))
			add_exp = cvar_kill_boss_xp;
		else if (oo_playerclass_isa(victim, "SpecialInfected"))
			add_exp = cvar_kill_special_xp;
		else
			add_exp = cvar_kill_zombie_xp;
	}
	else
	{
		if (oo_playerclass_isa(victim, "Leader"))
			add_exp = cvar_kill_leader_xp;
		else
			add_exp = cvar_kill_human_xp;
	}

	if (get_member(victim, m_LastHitGroup) == HIT_HEAD)
		add_exp = floatround(add_exp * 1.5);

	add_exp = floatround(add_exp * (1.0 + random_float(-cvar_kill_random_xp, cvar_kill_random_xp)));

	ctg_add_player_exp(killer, add_exp, true);
}

public CTG_OnPlayerAddExp_Post(id, exp, bool:notify)
{
	if (!notify)
		return;
	
	set_hudmessage(0, 255, 0, -1.0, 0.75, 0, 0.0, 2.0, 0.0, 1.0, 4);
	show_hudmessage(id, "+ %d EXP", exp);
}