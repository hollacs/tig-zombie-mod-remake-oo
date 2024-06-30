#include <amxmodx>
#include <oo_player_class>
#include <reapi>
#include <engine>
#include <oo_assets>

new Assets:g_oAssets;

public oo_init()
{
	oo_class("NemesisMode", "ContagionGame");
	{
		new const cl[] = "NemesisMode";

		oo_mthd(cl, "CanInfectPlayer", @int(attacker), @int(victim), @fl(damage));
		oo_mthd(cl, "GetWeight");
		oo_mthd(cl, "Start");
		oo_mthd(cl, "SetPlayerRespawn", @int(id), @fl(delay));
		oo_mthd(cl, "ChooseBoss", @int(id));
	}
}

public plugin_init()
{
	register_plugin("[CTG] Mode: Nemesis", "0.1", "holla");

	oo_call(0, "ContagionGame@AddGameMode", oo_new("NemesisMode"));
	g_oAssets = any:oo_call(0, "ContagionGame@Assets");
}

public NemesisMode@ChooseBoss(id)
{
	return 0;
}

public NemesisMode@SetPlayerRespawn(id, Float:delay)
{
	oo_player_set_respawn(id, 30.0);
}

public NemesisMode@CanInfectPlayer(attacker, victim, Float:damage)
{
	return false;
}

public NemesisMode@GetWeight()
{
	return 10;
}

public NemesisMode@Start()
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
	
	new max_zombies = 1;
	new player, rand;

	for (new i = 0; i < max_zombies; i++)
	{
		rand = random(num);
		player = players[rand];
		players[rand] = players[--num];

		oo_playerclass_change(player, "Nemesis", true);
	}

	set_lights("b");

	set_dhudmessage(255, 50, 50, -1.0, 0.2, 1, 0.0, 3.0, 0.0, 1.0);
	show_dhudmessage(0, "Nemesis Detected !!");

	static sound[64];
	if (AssetsGetRandomGeneric(g_oAssets, "boss_detected", sound, charsmax(sound)))
		client_cmd(0, "spk %s", sound);
}

bool:IsSpawnablePlayer(id)
{
	return (TEAM_TERRORIST <= get_member(id, m_iTeam) <= TEAM_CT) && get_member(id, m_iMenu) != Menu_ChooseAppearance;
}