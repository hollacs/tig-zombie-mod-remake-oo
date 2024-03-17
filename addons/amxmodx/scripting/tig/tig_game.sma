#include <amxmodx>
#include <reapi>
#include <oo_player_class>

enum (+=100)
{
	TASK_GAMESTART = 0,
};

new g_GameReadyCount;
new bool:g_IsGameStarted;
new Float:cvar_game_ready_time;

public plugin_init()
{
	register_plugin("[TiG] Game", "0.1", "holla");

	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRestartRound");
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "OnRoundFreezeEnd");
	RegisterHookChain(RG_HandleMenu_ChooseAppearance, "OnChooseAppearance_Post", 1);
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn");
	RegisterHookChain(RG_CSGameRules_CheckWinConditions, "OnCheckWinConditions");

	bind_pcvar_float(create_cvar("tig_game_ready_time", "20.0"), cvar_game_ready_time);

	set_member_game(m_bTCantBuy, true);

	OnRestartRound();
}

public OnRestartRound()
{
	g_IsGameStarted = false;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i))
			continue;
		
		if ((TEAM_TERRORIST <= TeamName:get_member(i, m_iTeam) <= TEAM_CT))
		{
			if (oo_playerclass_isa(i, "Zombie"))
				set_member(i, m_bNotKilled, false);

			oo_playerclass_change(i, "Human", false);
		}
	}

	remove_task(TASK_GAMESTART);
}

public OnRoundFreezeEnd()
{
	set_dhudmessage(0, 255, 0, -1.0, 0.2, 0, 0.0, 3.0, 1.0, 1.0);
	show_dhudmessage(0, "病毒在空氣中飄散...");

	g_GameReadyCount = floatround(cvar_game_ready_time);
	set_task(1.0, "TaskGameReadyCountDown", TASK_GAMESTART, _, _, "a", g_GameReadyCount-1);
	set_task(cvar_game_ready_time, "GameStart", TASK_GAMESTART);
}

public OnChooseAppearance_Post(id, slot)
{
	oo_playerclass_change(id, "Human");
}

public OnCheckWinConditions()
{
	if (get_member_game(m_iRoundWinStatus) != WINSTATUS_NONE)
		return HC_CONTINUE;

	if (g_IsGameStarted)
	{
		new human_count = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (is_user_alive(i) && oo_playerclass_isa(i, "Human"))
				human_count++;
		}

		if (human_count == 0)
		{
			rg_round_end(5.0, WINSTATUS_CTS, ROUND_TERRORISTS_WIN);
			return HC_SUPERCEDE;
		}
	}

	return HC_CONTINUE;
}

public OnPlayerSpawn(id)
{
	if (is_entity(id) && (TEAM_TERRORIST <= TeamName:get_member(id, m_iTeam) <= TEAM_CT))
	{
		if (oo_playerclass_isa(id, "Zombie"))
			set_member(id, m_iTeam, TEAM_TERRORIST);
		else
			set_member(id, m_iTeam, TEAM_CT);
	}
}

public OO_OnPlayerKilled(id, attacker, shouldgib)
{
	oo_player_set_respawn(id, 3.0);
}

public OO_OnPlayerRespawn(id)
{
	oo_playerclass_change(id, "Zombie", false);
}

public TaskGameReadyCountDown()
{
	g_GameReadyCount--;

	if (g_GameReadyCount > 0 && g_GameReadyCount <= 10)
	{
		set_dhudmessage(0, 255, 0, -1.0, 0.2, 0, 0.0, 1.0, 0.0, 0.0);
		show_dhudmessage(0, "遊戲將在 %d 秒後開始...", g_GameReadyCount);

		new word[16];
		num_to_word(g_GameReadyCount, word, charsmax(word));

		client_cmd(0, "spk fvox/%s", word);
	}
}

public GameStart()
{
	g_IsGameStarted = true;

	new players[32], num;
	get_players(players, num, "a");

	if (num > 0)
	{
		new player = players[random(num)];
		oo_playerclass_change(player, "Zombie");
		
		set_dhudmessage(0, 255, 0, -1.0, 0.2, 0, 0.0, 3.0, 1.0, 1.0);
		show_dhudmessage(0, "%n 變成了喪屍!", player);
	}
}