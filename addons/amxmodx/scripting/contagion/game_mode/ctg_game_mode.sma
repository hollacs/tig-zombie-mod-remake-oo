#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <oo_player_class>
#include <oo_game_mode>
#include <oo_assets>
#include <cs_painshock>

new Array:g_aGameModes;
new g_GameModeCount;

new GameMode:g_oGameMode;

new Float:cvar_ratio;
new Float:cvar_wait;
new cvar_lights[32];

new Assets:g_oAssets;
new g_fwInfectPlayer[2];

public oo_init()
{
	oo_class("ContagionGame", "GameMode");
	{
		new const cl[] = "ContagionGame";
		oo_var(cl, "has_intro", 1);
		oo_var(cl, "countdown_time", 1);

		oo_var(cl, "leader", 1);
		oo_var(cl, "leader_dead", 1);
		oo_var(cl, "boss", 1);
		oo_var(cl, "boss_dead", 1);
		oo_var(cl, "special_infected", 3);
		oo_var(cl, "special_infected_count", 1);
		oo_var(cl, "next_special_infected", 1); // a random time for special infected
		oo_var(cl, "next_boss", 1); // a random time for boss

		oo_ctor(cl, "Ctor");
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "Start");
		oo_mthd(cl, "End");

		oo_mthd(cl, "CheckWinConditions");
		oo_mthd(cl, "InfectPlayer", @int(victim), @int(attacker));
		oo_mthd(cl, "CanHavePlayerItem", @int(id), @int(item));
		oo_mthd(cl, "CanTouchWeapon", @int(id), @int(ent), @int(weapon_id));
		oo_mthd(cl, "CanPlayerRespawn", @int(id));
		oo_mthd(cl, "CanInfectPlayer", @int(attacker), @int(victim), @fl(damage));
		oo_mthd(cl, "ChooseRoundLeader");
		oo_mthd(cl, "ChooseBoss", @int(id));
		oo_mthd(cl, "ChooseSpecialInfected", @int(id));
		oo_mthd(cl, "GetWeight");
		oo_mthd(cl, "GetRoundMaxSpecialInfected");

		oo_mthd(cl, "OnThink");
		oo_mthd(cl, "OnRestartRound");
		oo_mthd(cl, "OnRestartRound_Post");
		oo_mthd(cl, "OnRoundFreezeEnd");
		oo_mthd(cl, "OnRoundTimeExpired");
		oo_mthd(cl, "OnRoundEnd", @int(status), @int(event), @fl(delay));
		oo_mthd(cl, "OnChooseTeam", @int(player), @int(slot));
		oo_mthd(cl, "OnChooseAppearance", @int(player), @int(slot));
		oo_mthd(cl, "OnPlayerSpawn", @int(id));
		oo_mthd(cl, "OnPlayerTakeDamage", @int(victim), @int(inflictor), @int(attacker), @ref(damage), @int(damagebits));
		oo_mthd(cl, "OnPlayerKilled", @int(id), @int(attacker), @int(shouldgib));
		oo_mthd(cl, "OnGiveDefaultItems", @int(id));
		oo_mthd(cl, "OnPlayerRespawn", @int(id));

		oo_smthd(cl, "Assets");
		oo_smthd(cl, "AddGameMode");
		oo_smthd(cl, "ChooseGameMode");
		oo_smthd(cl, "GetInstance");
	}
}

public plugin_precache()
{
	g_oGameMode = oo_new("ContagionGame");
	oo_gamemode_set(g_oGameMode);

	g_oAssets = oo_new("Assets");
	oo_call(g_oAssets, "LoadJson", "gamemode/contagion.json");
}

public plugin_init()
{
	register_plugin("[CTG] Game Mode", "0.1", "holla");

	new pcvar = create_cvar("ctg_gamemode_start_delay", "20");
	bind_pcvar_float(pcvar, cvar_wait);

	pcvar = create_cvar("ctg_gamemode_zombie_ratio", "0.2");
	bind_pcvar_float(pcvar, cvar_ratio);

	pcvar = create_cvar("ctg_gamemode_lights", "c");
	bind_pcvar_string(pcvar, cvar_lights, charsmax(cvar_lights));
	hook_cvar_change(pcvar, "OnCvarLights");

	g_fwInfectPlayer[0] = CreateMultiForward("CTG_OnInfectPlayer", ET_CONTINUE, FP_CELL, FP_CELL);
	g_fwInfectPlayer[1] = CreateMultiForward("CTG_OnInfectPlayer_Post", ET_IGNORE, FP_CELL, FP_CELL);

	set_member_game(m_bTCantBuy, true);
	set_member_game(m_bCTCantBuy, true);

	server_cmd("sv_restart 1");
	server_exec();
}

public plugin_natives()
{
	register_library("ctg_game_mode");

	register_native("ctg_infect_player", "native_infect_player");
}

public native_infect_player()
{
	new id = get_param(1);
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not alive", id);
		return false;
	}

	new GameMode:mode_o = oo_gamemode_get();
	if (!oo_isa(mode_o, "ContagionGame"))
		return false;

	new attacker = get_param(2);
	oo_call(mode_o, "InfectPlayer", id, attacker);
	return true;
}

public OnCvarLights(pcvar, const old_value[], const new_value[])
{
	new GameMode:mode_o = oo_gamemode_get();
	if (mode_o == @null || !oo_isa(mode_o, "ContagionGame", true))
		return;
	
	set_lights(new_value);
}

public ContagionGame@ChooseRoundLeader()
{
	new this = @this;

	new players[32], num;

	get_players(players, num, "ac"); // exclude bot

	if (num <= 2)
		get_players(players, num, "a"); // include bot

	if (num > 0)
	{
		new player = players[random(num)];

		set_dhudmessage(0, 100, 255, 0.01, 0.4, 0, 0.0, 3.0, 0.0, 1.0);
		show_dhudmessage(0, "%n 被選中成為 Leader", player);

		oo_playerclass_change(player, "Leader");
		oo_set(this, "leader", player);
		return player;
	}

	return 0;
}

public ContagionGame@ChooseBoss(id)
{
	new this = @this;

	new Float:gametime = get_gametime();
	new Float:next_boss = Float:oo_get(this, "next_boss");
	if (gametime < next_boss) // it's not yet ready to choose
		return false;
	
	// if this is a bot, wait 30 more seconds for real player die
	if (is_user_bot(id) && gametime < next_boss + 30.0)
		return false;
	
	// boss was already chosen?
	if (oo_get(this, "boss"))
		return false;

	oo_playerclass_change(id, "Nemesis"); // 你是被選中的細路
	oo_set(this, "boss", id);

	set_dhudmessage(255, 50, 50, -1.0, 0.3, 0, 0.0, 3.0, 0.0, 1.0);
	show_dhudmessage(0, "Nemesis Detected !!");

	static sound[64];
	if (AssetsGetRandomGeneric(g_oAssets, "boss_detected", sound, charsmax(sound)))
		client_cmd(0, "spk %s", sound);

	return true;
}

public ContagionGame@ChooseSpecialInfected(id)
{
	new this = @this;

	new Float:gametime = get_gametime();
	new Float:next_special_infected = Float:oo_get(this, "next_special_infected");
	if (gametime < next_special_infected) // it's not yet ready to choose
		return false;
	
	// if this is a bot, wait 20 more seconds for real player die
	if (is_user_bot(id) && gametime < next_special_infected + 20.0)
		return false;
	
	// no more spawn
	if (oo_get(this, "special_infected_count") >= oo_call(this, "GetRoundMaxSpecialInfected"))
		return false;

	// hard code for now
	static const SPECIAL_INFECTED_CLASS[][] = {"Hunter", "Spitter", "Boomer"};

	static list[3], num, v;
	num = 0;

	for (new i = 0; i < sizeof SPECIAL_INFECTED_CLASS; i++)
	{
		v = oo_get(this, "special_infected", i, i+1, v, 0, 1);
		if (!v)
			list[num++] = i;
	}

	if (num < 1)
		return false;

	new rindex = list[random(num)];
	oo_playerclass_change(id, SPECIAL_INFECTED_CLASS[rindex]);
	oo_set(this, "special_infected", rindex, rindex+1, true, 0, 1);
	oo_set(this, "next_special_infected", get_gametime() + random_float(40.0, 100.0));
	oo_get(this, "special_infected_count", oo_get(this, "special_infected_count") + 1);

	set_dhudmessage(0, 100, 255, -1.0, 0.325, 0, 0.0, 3.0, 0.0, 1.0);
	show_dhudmessage(0, "%s Detected !", SPECIAL_INFECTED_CLASS[rindex]);

	static sound[64];
	if (AssetsGetRandomGeneric(g_oAssets, "klaxon", sound, charsmax(sound)))
		client_cmd(0, "spk %s", sound);

	return true;
}

public ContagionGame@CanInfectPlayer(attacker, victim, Float:damage)
{
	if (Float:get_entvar(victim, var_armorvalue) <= 0.0)
		return true;
	
	return false;
}

public ContagionGame@AddGameMode(GameMode:mode_o)
{
	ArrayPushCell(g_aGameModes, mode_o);
	g_GameModeCount++;
}

public Assets:ContagionGame@Assets()
{
	return g_oAssets;
}

public ContagionGame@Ctor()
{
	oo_super_ctor("GameMode");
}

public ContagionGame@Dtor()
{
}

public ContagionGame@GetWeight()
{
	return 0;
}

public GameMode:ContagionGame@GetInstance()
{
	return g_oGameMode;
}

public GameMode:ContagionGame@ChooseGameMode()
{
	// weighted random
	new total = 0;
	for (new i = 0; i < g_GameModeCount; i++)
	{
		total += oo_call(ArrayGetCell(g_aGameModes, i), "GetWeight");
	}

	new random = random_num(0, total);

	new GameMode:mode_o;
	for (new i = 0; i < g_GameModeCount; i++)
	{
		mode_o = any:ArrayGetCell(g_aGameModes, i);
		random -= oo_call(mode_o, "GetWeight");

		if (random <= 0.0)
			return mode_o;
	}

	return g_oGameMode;
}

public ContagionGame@OnGiveDefaultItems(id)
{
	if (oo_playerclass_isa(id, "Human"))
	{
		rg_remove_all_items(id);
		rg_give_item(id, "weapon_knife");
	}

	return true;
}

public ContagionGame@OnThink()
{
	new this = @this;
	oo_call(this, "GameMode@OnThink");

	if (!oo_get(this, "is_started"))
	{
		if (!get_member_game(m_bFreezePeriod))
		{
			new Float:current_time = get_gametime();
			if (!oo_get(this, "has_intro"))
			{
				set_dhudmessage(0, 255, 0, -1.0, 0.2, 0, 0.0, 3.0, 1.0, 1.0);
				show_dhudmessage(0, "病毒在空氣中飄散...");
				oo_set(this, "has_intro", true);
				oo_set(this, "countdown_time", current_time + floatmax(cvar_wait - 10.0, 0.0));
			}
			else
			{
				new Float:countdown_time = Float:oo_get(this, "countdown_time");
				if (current_time >= countdown_time)
				{
					new Float:roundstart_time = Float:get_member_game(m_fRoundStartTime);
					if (current_time - roundstart_time >= cvar_wait)
					{
						oo_call(this, "Start"); // start gamemode
						return;
					}

					new countdown = floatround(roundstart_time + cvar_wait - current_time, floatround_ceil);
					set_dhudmessage(0, 255, 0, -1.0, 0.2, 0, 0.0, 1.0, 0.0, 0.0);
					show_dhudmessage(0, "遊戲在 %d 秒後開始", countdown);

					new word[8];
					num_to_word(countdown, word, charsmax(word));
					client_cmd(0, "spk fvox/%s", word); // play sound

					oo_set(this, "countdown_time", current_time + 1.0);
				}
			}
		}
	}
}

public ContagionGame@OnClientDisconnect(id)
{
	new this = @this;
	if (oo_get(this, "leader") == id)
	{
		oo_call(this, "ChooseRoundLeader");
	}

	if (oo_get(this, "boss") == id)
	{
		oo_set(this, "boss", 0);
	}
}

public ContagionGame@Start()
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
	
	new max_zombies = floatround(num * cvar_ratio, floatround_ceil);
	new player, rand;

	for (new i = 0; i < max_zombies; i++)
	{
		rand = random(num);
		player = players[rand];
		players[rand] = players[--num];

		oo_playerclass_change(player, "Zombie", true);
		rg_give_item(player, "weapon_hegrenade");
		set_entvar(player, var_health, Float:get_entvar(player, var_health) * floatmax(num * 0.3, 1.0))
	}

	set_lights(cvar_lights);

	set_dhudmessage(0, 255, 0, -1.0, 0.2, 1, 0.0, 3.0, 0.0, 1.0);
	show_dhudmessage(0, "遊戲開始!");

	static sound[64];
	if (AssetsGetRandomGeneric(g_oAssets, "game_start", sound, charsmax(sound)))
		client_cmd(0, "spk ^"%s^"", sound);

	oo_set(this, "next_boss", get_gametime() + 
		(float(get_member_game(m_iRoundTimeSecs) - 20) / 3.0 + random_float(-25.0, 25.0)));

	oo_set(this, "next_special_infected", get_gametime() + random_float(30.0, 60.0));
}

public ContagionGame@End()
{
	oo_call(@this, "GameMode@End");
}

public ContagionGame@OnRoundEnd(WinStatus:win, ScenarioEventEndRound:event, Float:tmDelay)
{
	new this = @this;
	oo_call(this, "End");

	switch (win)
	{
		case WINSTATUS_CTS:
		{
			set_dhudmessage(0, 255, 0, -1.0, 0.2, 0, 0.0, 3.0, 0.0, 1.0);
			show_dhudmessage(0, "Humans Win");

			static sound[32];
			if (AssetsGetRandomGeneric(g_oAssets, "survivors_win", sound, charsmax(sound)))
				client_cmd(0, "spk %s", sound);

			set_member_game(m_iNumCTWins, get_member_game(m_iNumCTWins) + 1);
			UpdateTeamScore();

			SlayPlayers("Zombie");
		}
		case WINSTATUS_TERRORISTS:
		{
			set_dhudmessage(255, 50, 50, -1.0, 0.2, 0, 0.0, 3.0, 0.0, 1.0);
			show_dhudmessage(0, "Zombie Win");

			static sound[32];
			if (AssetsGetRandomGeneric(g_oAssets, "zombies_win", sound, charsmax(sound)))
				client_cmd(0, "spk %s", sound);

			set_member_game(m_iNumTerroristWins, get_member_game(m_iNumTerroristWins) + 1);
			UpdateTeamScore();

			SlayPlayers("Human");
		}
	}
}

public ContagionGame@CheckWinConditions()
{
	new this = @this;
	oo_call(this, "GameMode@CheckWinConditions");

	if (!oo_get(this, "is_started") || oo_get(this, "is_ended"))
		return true;

	new human_count = 0;
	new zombie_count = 0;
	new spawnable_count = 0;

	for (new i = 1; i <= MaxClients; i++) // loop through all players
	{
		if (!is_user_connected(i)) // filter not connected
			continue;
		
		if (IsSpawnablePlayer(i))
		{
			if (is_user_alive(i))
			{
				if (oo_playerclass_isa(i, "Human"))
					human_count++;
				else if (oo_playerclass_isa(i, "Zombie"))
					zombie_count++;
			}
			spawnable_count++;
		}
	}

	if (spawnable_count > 1)
	{
		if (human_count < 1)
		{
			rg_round_end(5.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "Zombies Win", "", .trigger=true);
			return true;
		}

		if (zombie_count < 1 && human_count > 0 && oo_get(this, "boss_dead"))
		{
			rg_round_end(5.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "Humans Win", .trigger=true);
			return true;
		}

		if (zombie_count < 1 && human_count < 1) // all players are dead
		{
			rg_round_end(5.0, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Draw", .trigger=true);
			return true;
		}
	}

	return true;
}

public ContagionGame@OnRoundTimeExpired()	
{
	new this = @this;

	if (!oo_get(this, "is_started") || oo_get(this, "is_ended"))
		return;

	new human_count = 0;
	new zombie_count = 0;
	new spawnable_count = 0;

	for (new i = 1; i <= MaxClients; i++) // loop through all players
	{
		if (!is_user_connected(i)) // filter not connected
			continue;
		
		if (IsSpawnablePlayer(i))
		{
			if (is_user_alive(i))
			{
				if (oo_playerclass_isa(i, "Human", true))
					human_count++;
				else if (oo_playerclass_isa(i, "Zombie", true))
					zombie_count++;
			}
			spawnable_count++;
		}
	}

	if (human_count > 0 && zombie_count > 0 && spawnable_count > 0)
	{
		if (oo_get(this, "boss") && oo_get(this, "leader_dead"))
			rg_round_end(5.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "Zombies Win", "", .trigger=true);
		else
			rg_round_end(5.0, WINSTATUS_CTS, ROUND_CTS_WIN, "Humans Win", "", .trigger=true);

		return;
	}

	rg_round_end(5.0, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Draw", .trigger=true);
}

public ContagionGame@OnPlayerSpawn(id)
{
	oo_call(@this, "GameMode@OnPlayerSpawn", id);
}

public ContagionGame@OnPlayerKilled(id, attacker, shouldgib)
{
	new this = @this;
	oo_call(this, "GameMode@OnPlayerKilled", id, attacker, shouldgib);

	if (oo_call(this, "CanPlayerRespawn", id))
	{
		oo_player_set_respawn(id, 5.0);
	}

	if (oo_get(this, "boss") == id && !oo_get(this, "boss_dead"))
	{
		set_dhudmessage(0, 100, 255, -1.0, 0.3, 0, 0.0, 3.0, 0.0, 1.0)
		show_dhudmessage(0, "Nemesis 已經陣亡");

		static sound[64];
		if (AssetsGetRandomGeneric(g_oAssets, "boss_death", sound, charsmax(sound)))
			client_cmd(0, "spk %s", sound);

		oo_set(this, "boss_dead", true);
	}

	if (oo_get(this, "leader") == id && !oo_get(this, "leader_dead"))
	{
		set_dhudmessage(0, 100, 255, -1.0, 0.3, 0, 0.0, 3.0, 0.0, 1.0)
		show_dhudmessage(0, "Leader 已經死亡");

		//static sound[64];
		//if (AssetsGetRandomGeneric(g_oAssets, "boss_death", sound, charsmax(sound)))
		//	client_cmd(0, "spk %s", sound);

		oo_set(this, "leader_dead", true);
	}

	return true;
}

public ContagionGame@CanPlayerRespawn(id)
{
	new this = @this;
	if (oo_get(this, "boss_dead"))
		return false;

	return true;
}

public ContagionGame@OnPlayerRespawn(id)
{
	new this = @this;
	if (!oo_call(this, "CanPlayerRespawn", id))
		return false;

	if (oo_get(this, "is_started"))
	{
		if (oo_call(this, "ChooseBoss", id))
			return true;

		if (oo_call(this, "ChooseSpecialInfected", id))
			return true;

		oo_playerclass_change(id, "Zombie", false);
	}

	return true;
}

public ContagionGame@OnPlayerTakeDamage(victim, inflictor, attacker, &Float:damage, damagebits)
{
	new this = @this;

	if (inflictor == attacker && is_user_connected(attacker) && 
		oo_playerclass_isa(attacker, "Zombie") && get_user_weapon(attacker) == CSW_KNIFE &&
		oo_playerclass_isa(victim, "Human"))
	{
		if (oo_call(this, "CanInfectPlayer", attacker, victim, damage))
		{
			static Float:origin[3];
			get_entvar(attacker, var_origin, origin);

			static msgDamage;
			msgDamage || (msgDamage = get_user_msgid("Damage"));

			message_begin(MSG_ONE_UNRELIABLE, msgDamage, _, victim);
			write_byte(0); // damage save
			write_byte(1); // damage take
			write_long(DMG_SLASH); // damage type - DMG_FREEZE
			write_coord_f(origin[0]); // x
			write_coord_f(origin[1]); // y
			write_coord_f(origin[2]); // z
			message_end();

			oo_call(this, "InfectPlayer", victim, attacker);
			cs_painshock_set(victim, 0.0);
			set_entvar(victim, var_health, Float:get_entvar(victim, var_health) * 0.5);
			SetHookChainReturn(ATYPE_INTEGER, 0);
			return true;
		}
	}

	return false;
}

public ContagionGame@GetRoundMaxSpecialInfected()
{
	return 3;
}

public ContagionGame@InfectPlayer(victim, attacker)
{
	new this = @this;

	new ret;
	ExecuteForward(g_fwInfectPlayer[0], ret, victim, attacker);
	if (ret >= PLUGIN_HANDLED)
		return;

	static msgDeathMsg;
	msgDeathMsg || (msgDeathMsg = get_user_msgid("DeathMsg"));

	message_begin(MSG_BROADCAST, msgDeathMsg);
	write_byte(attacker);
	write_byte(victim);
	write_byte(0);
	write_string("infection");
	message_end();

	static msgScoreAttrib;
	msgScoreAttrib || (msgScoreAttrib = get_user_msgid("ScoreAttrib"));

	message_begin(MSG_BROADCAST, msgScoreAttrib);
	write_byte(victim); // id
	write_byte(0); // attrib
	message_end();

	new PlayerClass:class_o = any:oo_playerclass_change(victim, "Zombie", false);
	oo_call(class_o, "SetProps", false);

	new PlayerClassInfo:info_o = any:oo_call(class_o, "GetClassInfo");
	if (info_o != @null)
	{
		static sound[64];
		if (AssetsGetRandomSound(info_o, "infect", sound, charsmax(sound)))
			emit_sound(victim, CHAN_VOICE, sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}

	rg_set_user_team(victim, TEAM_TERRORIST, MODEL_UNASSIGNED, false, true);
	
	ExecuteHam(Ham_AddPoints, attacker, 1 - get_user_frags(victim), true); 

	remove_task(victim);
	set_task(0.1, "TaskChangeTeam", victim);

	if (oo_get(this, "leader") == victim && !oo_get(this, "leader_dead"))
	{
		set_dhudmessage(0, 100, 255, -1.0, 0.3, 0, 0.0, 3.0, 0.0, 1.0)
		show_dhudmessage(0, "Leader 已經死亡");

		oo_set(this, "leader_dead", true);
	}

	ExecuteForward(g_fwInfectPlayer[1], ret, victim, attacker);
}

public ContagionGame@OnRestartRound()
{
	new this = @this;
	oo_call(this, "GameMode@OnRestartRound");
	oo_set(this, "is_ended", false);
	oo_set(this, "is_started", false);
	oo_set(this, "has_intro", false);
	oo_set(this, "boss", 0);
	oo_set(this, "boss_dead", false);
	oo_set(this, "leader", 0);

	new arr[3];
	oo_set(this, "special_infected", 0, 3, arr, 0, 3);
	oo_set(this, "special_infected_count", 0);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i) || !(TEAM_TERRORIST <= TeamName:get_member(i, m_iTeam) <= TEAM_CT))
			continue;
		
		oo_playerclass_change(i, "Human", false);
	}

	oo_gamemode_set(oo_call(0, "ContagionGame@ChooseGameMode"));
}

public ContagionGame@OnRestartRound_Post()
{
	set_lights("");
}

public ContagionGame@OnRoundFreezeEnd()
{
	oo_call(@this, "ChooseRoundLeader");
}

public ContagionGame@OnChooseTeam(id, MenuChooseTeam:slot)
{
	if (slot == MenuChoose_Spec)
	{
		oo_playerclass_change(id, "", false);
	}
}

public ContagionGame@OnChooseAppearance(id)
{
	new this = @this;
	if (oo_get(this, "is_started"))
	{
		oo_playerclass_change(id, "Zombie", false);
		rg_set_user_team(id, TEAM_TERRORIST, MODEL_UNASSIGNED, true, true);
		oo_player_set_respawn(id, 10.0)
	}
	else
	{
		oo_playerclass_change(id, "Human", false);
		rg_set_user_team(id, TEAM_CT, MODEL_UNASSIGNED, true, true);
		oo_player_set_respawn(id, 1.0)
	}
}

public ContagionGame@CanHavePlayerItem(id, item)
{
	if (oo_playerclass_isa(id, "Zombie"))
	{
		new weapon_id = get_member(item, m_iId);
		if (weapon_id != CSW_KNIFE && !(CSW_ALL_GRENADES & (1 << weapon_id)))
			return false;
	}

	return true;
}

public ContagionGame@CanTouchWeapon(id, ent, weapon_id)
{
	if (oo_playerclass_isa(id, "Zombie"))
		return false;

	return true;
}

public TaskChangeTeam(id)
{
	if (is_user_connected(id) && oo_playerclass_isa(id, "Zombie"))
	{
		rg_set_user_team(id, TEAM_TERRORIST, MODEL_UNASSIGNED, true);
	}
}

public client_disconnected(id)
{
	remove_task(id);
}

bool:IsSpawnablePlayer(id)
{
	return (TEAM_TERRORIST <= get_member(id, m_iTeam) <= TEAM_CT) && get_member(id, m_iMenu) != Menu_ChooseAppearance;
}

UpdateTeamScore()
{
	static msgTeamScore;
	msgTeamScore || (msgTeamScore = get_user_msgid("TeamScore"));

	message_begin(MSG_ALL, msgTeamScore);
	write_string("CT");
	write_short(get_member_game(m_iNumCTWins));
	message_end();

	message_begin(MSG_ALL, msgTeamScore);
	write_string("TERRORIST");
	write_short(get_member_game(m_iNumTerroristWins));
	message_end();
}

SlayPlayers(const class[])
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (is_user_alive(i) && oo_playerclass_isa(i, class))
			user_silentkill(i, 1);
	}
}