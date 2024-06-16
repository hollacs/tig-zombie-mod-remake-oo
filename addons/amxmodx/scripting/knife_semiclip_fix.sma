#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>

new cvar_team;
new g_Soilds[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("Knife Semiclip Fix", "0.2", "holla");

	bind_pcvar_num(create_cvar("knife_semiclip_team", "1"), cvar_team);

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "OnKnifeAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "OnKnifeAttack_Post", 1);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "OnKnifeAttack");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "OnKnifeAttack_Post", 1);
}

public OnKnifeAttack(ent)
{
	if (!pev_valid(ent))
		return;

	arrayset(g_Soilds, -1, sizeof g_Soilds);

	new player = get_ent_data_entity(ent, "CBasePlayerItem", "m_pPlayer");
	if (!is_user_alive(player))
		return;

	if (cvar_team == 3 || get_ent_data(player, "CBasePlayer", "m_iTeam") == cvar_team)
	{
		SetSolidNot(player);
	}
}

public OnKnifeAttack_Post(ent)
{
	if (!pev_valid(ent))
		return;

	new player = get_ent_data_entity(ent, "CBasePlayerItem", "m_pPlayer");
	if (!is_user_alive(player))
		return;

	if (cvar_team == 3 || get_ent_data(player, "CBasePlayer", "m_iTeam") == cvar_team)
	{
		ResetSolid(player);
		arrayset(g_Soilds, -1, sizeof g_Soilds);
	}
}

SetSolidNot(player)
{
	new team = get_ent_data(player, "CBasePlayer", "m_iTeam");

	for (new i = 1; i <= MaxClients; i++)
	{
		if (i != player && is_user_alive(i) && get_ent_data(i, "CBasePlayer", "m_iTeam") == team)
		{
			g_Soilds[i] = pev(i, pev_solid);
			set_pev(i, pev_solid, SOLID_NOT);
		}
	}
}

ResetSolid(player)
{
	new team = get_ent_data(player, "CBasePlayer", "m_iTeam");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i != player && g_Soilds[i] != -1 && is_user_alive(i) && get_ent_data(i, "CBasePlayer", "m_iTeam") == team)
		{
			set_pev(i, pev_solid, g_Soilds[i]);
		}
	}
}
