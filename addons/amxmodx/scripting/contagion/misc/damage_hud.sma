#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#define MAX_ROWS 8
new Float:g_Time[MAX_PLAYERS + 1][MAX_ROWS];

public plugin_init()
{
	register_plugin("Damage HUD", "0.1", "holla");

	RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnPlayerTakeDamage_Post", 1);
}

public OnPlayerTakeDamage_Post(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (inflictor != attacker || damage <= 0.0)
		return;
	
	if (!is_user_connected(attacker) 
	|| get_member(victim, m_iTeam) == get_member(attacker, m_iTeam))
		return;

	new bool:is_headshot = bool:(get_ent_data(victim, "CBaseMonster", "m_LastHitGroup") == HIT_HEAD);
	AddDamage(attacker, damage, is_headshot);
	//AddDamage(victim, damage, is_headshot, true);
}

AddDamage(id, Float:damage, bool:headshot=false)
{
	new index = -1;
	new Float:gametime = get_gametime();

	for (new i = 0; i < MAX_ROWS; i++)
	{
		if (gametime >= g_Time[id][i])
		{
			index = i;
			break;
		}
	}

	if (index == -1)
	{
		new Float:time = 9999999999.0;
		for (new i = 0; i < MAX_ROWS; i++)
		{
			if (g_Time[id][i] < time)
			{
				index = i;
				time = g_Time[id][i];
			}
		}
	}

	g_Time[id][index] = get_gametime() + 0.5;

	new color[3] = {0, 100, 255};
	new Float:x, Float:y;

	x = 0.49 + random_float(-0.01, 0.01);
	y = 0.4 - index * 0.025;

	if (headshot)
		color = {0, 255, 0};

	set_dhudmessage(color[0], color[1], color[2], x, y, 0, 0.0, 0.4, 0.0, 0.1);
	show_dhudmessage(id, "%d", floatround(damage, floatround_floor));
}