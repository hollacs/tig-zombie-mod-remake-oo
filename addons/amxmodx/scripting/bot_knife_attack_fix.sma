#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

new Float:g_NextThink[MAX_PLAYERS + 1];
new Float:g_LastAttackable[MAX_PLAYERS + 1];
new bool:g_KeepAttack[MAX_PLAYERS + 1];

new Float:cvar_no_attack_time;

public plugin_init()
{
	register_plugin("BOT Knife Attack Fix", "0.2", "holla");

	bind_pcvar_float(create_cvar("bot_knife_no_attack_time", "1.0"), cvar_no_attack_time)

	register_forward(FM_PlayerPreThink, "OnPlayerPreThink");

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "OnKnifeAttack_Post", 1);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "OnKnifeAttack_Post", 1);
}

public OnKnifeAttack_Post(ent)
{
	if (!pev_valid(ent))
		return;

	new player = get_ent_data_entity(ent, "CBasePlayerItem", "m_pPlayer");
	if (!is_user_alive(player))
		return;

	if (is_user_bot(player))
	{
		g_LastAttackable[player] = 0.0;
	}
}

public OnPlayerPreThink(id)
{
	if (!is_user_bot(id) || !is_user_alive(id))
		return;

	new Float:gametime = get_gametime();
	if (gametime < g_NextThink[id])
		return;

	new weapon_ent = get_ent_data_entity(id, "CBasePlayer", "m_pActiveItem");
	if (!pev_valid(weapon_ent))
		return;

	if (get_ent_data(weapon_ent, "CBasePlayerItem", "m_iId") != CSW_KNIFE)
		return;

	new Float:next_secondary_attack = get_ent_data_float(weapon_ent, "CBasePlayerWeapon", "m_flNextSecondaryAttack");
	new Float:next_primary_attack = get_ent_data_float(weapon_ent, "CBasePlayerWeapon", "m_flNextPrimaryAttack");
	new bool:is_onground = bool:(pev(id, pev_flags) & FL_ONGROUND);

	if (next_secondary_attack == -1.0 && CheckMeleeAttack(id, 32.0))
	{
		if (!is_onground || g_KeepAttack[id] || (g_LastAttackable[id] && gametime - g_LastAttackable[id] > cvar_no_attack_time))
		{
			set_pev(id, pev_button, pev(id, pev_button) | IN_ATTACK2);
			g_KeepAttack[id] = true;
		}
		else if (!g_LastAttackable[id])
		{
			g_LastAttackable[id] = gametime;
		}
	}
	else if (next_primary_attack == -1.0 && CheckMeleeAttack(id, 48.0))
	{
		if (!is_onground || g_KeepAttack[id] || (g_LastAttackable[id] && gametime - g_LastAttackable[id] > cvar_no_attack_time))
		{
			set_pev(id, pev_button, pev(id, pev_button) | IN_ATTACK);
			g_KeepAttack[id] = true;
		}
		else if (!g_LastAttackable[id])
		{
			g_LastAttackable[id] = gametime;
		}
	}
	else
	{
		if (next_primary_attack != -1.0 && next_secondary_attack != -1.0)
			g_KeepAttack[id] = false;

		g_LastAttackable[id] = 0.0;
	}
	
	g_NextThink[id] = gametime + 0.1;
}

bool:CheckMeleeAttack(id, Float:dist)
{
	new team = get_ent_data(id, "CBasePlayer", "m_iTeam");
	new solids[MAX_PLAYERS + 1] = {-1, ...};
	for (new i = 1; i <= MaxClients; i++)
	{
		if (is_user_alive(i) && get_ent_data(i, "CBasePlayer", "m_iTeam") == team)
		{
			solids[i] = pev(i, pev_solid);
			set_pev(i, pev_solid, SOLID_NOT);
		}
	}

	new aim_id;
	get_user_aiming(id, aim_id, _, floatround(dist));

	for (new i = 1; i <= MaxClients; i++)
	{
		if (solids[i] != -1)
			set_pev(i, pev_solid, solids[i]);
	}

	if (is_user_alive(aim_id) && !is_user_bot(aim_id))
		return true;
	
	return false;
}