#include <amxmodx>
#include <oo_player_class>
#include <reapi>
#include <engine>
#include <oo_assets>

new Assets:g_oAssets;

public oo_init()
{
	oo_class("Left4DeadMode", "ContagionGame");
	{
		new const cl[] = "Left4DeadMode";

		oo_mthd(cl, "CanInfectPlayer", @int(attacker), @int(victim), @fl(damage));
		oo_mthd(cl, "GetWeight");
		oo_mthd(cl, "Start");
		oo_mthd(cl, "ChooseRoundLeader");
	}
}

public plugin_init()
{
	register_plugin("[CTG] Mode: Left 4 Dead", "0.1", "holla");

	oo_call(0, "ContagionGame@AddGameMode", oo_new("Left4DeadMode"));
	g_oAssets = any:oo_call(0, "ContagionGame@Assets");
}

public Left4DeadMode@CanInfectPlayer(attacker, victim, Float:damage)
{
	return false;
}

public Left4DeadMode@GetWeight()
{
	return 15;
}

public Left4DeadMode@ChooseRoundLeader()
{
	return 0;
}

public Left4DeadMode@Start()
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

		if (!is_user_alive(i))
			rg_round_respawn(i);

		if (!is_user_bot(i))
			players[num++] = i;
	}
	
	new max_leaders = 4;
	new player, rand;

	while (max_leaders > 0 && num > 0)
	{
		rand = random(num);
		player = players[rand];
		players[rand] = players[--num];
		max_leaders--;

		oo_playerclass_change(player, "Leader", true);
	}

	if (max_leaders > 0)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!is_user_connected(i))
				continue;

			if (!IsSpawnablePlayer(i))
				continue;

			if (!is_user_alive(i))
				rg_round_respawn(i);

			if (is_user_bot(i))
				players[num++] = i;
		}
	}

	while (max_leaders > 0 && num > 0)
	{
		rand = random(num);
		player = players[rand];
		players[rand] = players[--num];
		max_leaders--;

		oo_playerclass_change(player, "Leader", true);
	}

	for (new i = 0; i < num; i++)
	{
		player = players[i];
		oo_playerclass_change(player, "Zombie", true);
	}

	set_lights("c");

	set_dhudmessage(0, 100, 255, -1.0, 0.2, 1, 0.0, 3.0, 0.0, 1.0);
	show_dhudmessage(0, "Left 4 Dead !!");

	static sound[64];
	if (AssetsGetRandomGeneric(g_oAssets, "klaxon", sound, charsmax(sound)))
		client_cmd(0, "spk %s", sound);

	oo_set(this, "next_boss", get_gametime() + 
		(float(get_member_game(m_iRoundTimeSecs) - 20) / 3.0 + random_float(-25.0, 25.0)));

	oo_set(this, "next_special_infected", get_gametime() + random_float(30.0, 60.0));
}

bool:IsSpawnablePlayer(id)
{
	return (TEAM_TERRORIST <= get_member(id, m_iTeam) <= TEAM_CT) && get_member(id, m_iMenu) != Menu_ChooseAppearance;
}