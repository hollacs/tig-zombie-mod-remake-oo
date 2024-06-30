#include <amxmodx>
#include <oo_player_class>
#include <reapi>
#include <engine>
#include <oo_assets>

new Assets:g_oAssets;

public oo_init()
{
	oo_class("BiohazardMode", "ContagionGame");
	{
		new const cl[] = "BiohazardMode";

		oo_mthd(cl, "CanInfectPlayer", @int(attacker), @int(victim), @fl(damage));
		oo_mthd(cl, "GetWeight");
		oo_mthd(cl, "Start");
	}
}

public plugin_init()
{
	register_plugin("[CTG] Mode: Biohazard", "0.1", "holla");

	oo_call(0, "ContagionGame@AddGameMode", oo_new("BiohazardMode"));
	g_oAssets = any:oo_call(0, "ContagionGame@Assets");
}

public BiohazardMode@CanInfectPlayer(attacker, victim, Float:damage)
{
	return false;
}

public BiohazardMode@GetWeight()
{
	return 35;
}

public BiohazardMode@Start()
{
	new this = @this;
	oo_call(this, "GameMode@Start");

	new players[32], num;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i))
			continue;

		if (!IsSpawnablePlayer(i))
			continue;

		if (oo_get(this, "leader") == i)
			continue;

		if (!is_user_alive(i))
			rg_round_respawn(i);

		players[num++] = i;
	}
	
	new max_zombies = floatround(num * 0.1, floatround_ceil);
	new player, rand;

	for (new i = 0; i < max_zombies; i++)
	{
		rand = random(num);
		player = players[rand];
		players[rand] = players[--num];

		oo_playerclass_change(player, "Zombie", true);
		rg_give_item(player, "weapon_hegrenade");

		if (i == 0)
			set_entvar(player, var_health, Float:get_entvar(player, var_health) * floatmax(num * 0.4, 1.0))
		else
			set_entvar(player, var_health, Float:get_entvar(player, var_health) * floatmax(num * 0.3, 1.0))
	}

	set_lights("c");

	set_dhudmessage(0, 255, 0, -1.0, 0.2, 1, 0.0, 3.0, 0.0, 1.0);
	show_dhudmessage(0, "Resident Evil");

	static sound[64];
	if (AssetsGetRandomGeneric(g_oAssets, "game_start", sound, charsmax(sound)))
		client_cmd(0, "spk ^"%s^"", sound);

	oo_set(this, "next_boss", get_gametime() + 
		(float(get_member_game(m_iRoundTimeSecs) - 20) / 3.0 + random_float(-25.0, 25.0)));

	oo_set(this, "next_special_infected", get_gametime() + random_float(30.0, 60.0));
}

bool:IsSpawnablePlayer(id)
{
	return (TEAM_TERRORIST <= get_member(id, m_iTeam) <= TEAM_CT) && get_member(id, m_iMenu) != Menu_ChooseAppearance;
}