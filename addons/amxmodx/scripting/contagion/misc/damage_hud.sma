#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#define MAX_ROWS 8
new Float:g_Time[MAX_PLAYERS + 1][MAX_ROWS];
new bool:g_Take[MAX_PLAYERS + 1][MAX_ROWS];

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
	AddDamage(attacker, damage, is_headshot, false);
	AddDamage(victim, damage, is_headshot, true);
}

AddDamage(id, Float:damage, bool:headshot=false, bool:is_take=false)
{
	new index = -1;
	new take_index = -1;
	new take_count = 0;
	new Float:gametime = get_gametime();

	for (new i = 0; i < MAX_ROWS; i++)
	{
		if (gametime >= g_Time[id][i])
		{
			take_index = take_count;
			take_count++;
			index = i;
			break;
		}
		else if (g_Take[id][i])
		{
			take_count++;
		}
	}

	if (index == -1)
	{
		for (new i = 0; i < MAX_ROWS; i++)
		{
			g_Time[id][i] = 0.0;
			g_Take[id][i] = false;
		}

		take_index = 0;
		index = 0;
	}

	g_Time[id][index] = get_gametime() + 0.5;
	g_Take[id][index] = is_take;

	new color[3] = {0, 100, 255};
	new Float:x, Float:y;

	if (is_take)
	{
		x = 0.49;
		if (take_index + 1 <= 4)
			x -= 0.1;
		else
			x += 0.1;

		x += random_float(-0.01, 0.01);

		y = 0.8 - (take_index % 4) * 0.025;

		if (headshot)
			color = {255, 100, 0};
		else
			color = {255, 0, 0};
	}
	else
	{
		x = 0.49 + random_float(-0.01, 0.01);
		y = 0.4 - index * 0.025;

		if (headshot)
			color = {0, 255, 0};
	}

	set_dhudmessage(color[0], color[1], color[2], x, y, 0, 0.0, 0.4, 0.0, 0.1);
	show_dhudmessage(id, "%d", floatround(damage));
}