#include <amxmodx>
#include <oo_game_mode>
#include <reapi>

public plugin_init()
{
	register_plugin("[CTG] Game", "0.1", "holla");

	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRestartRound");
}

public plugin_cfg()
{
	server_cmd("sv_restart 1");
}

public OnRestartRound()
{
	oo_gamemode_set(oo_call(0, "ContagionGame@ChooseGameMode"));
}