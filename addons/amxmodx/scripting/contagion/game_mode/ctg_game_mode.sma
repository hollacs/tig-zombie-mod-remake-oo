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

new const g_ObjectiveEnts[][] = {
	"func_bomb_target",
	"info_bomb_target",
	"hostage_entity",
	"monster_scientist",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone"
};

new Float:cvar_ratio;
new Float:cvar_wait;
new cvar_lights[32];

new Assets:g_oAssets;
new g_fwEntSpawn;
new g_fwInfectPlayer[2];

public oo_init()
{
	oo_class("ContagionGame", "GameMode");
	{
		new const cl[] = "ContagionGame";
		oo_var(cl, "has_intro", 1);
		oo_var(cl, "countdown_time", 1);
		oo_var(cl, "special_infected_count", 1);
		oo_var(cl, "next_special_infected", 1);
		oo_var(cl, "next_boss", 1);
		oo_var(cl, "has_boss", 1);
		oo_var(cl, "boss_dead", 1);

		oo_ctor(cl, "Ctor");
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "Start");
		oo_mthd(cl, "End");

		oo_mthd(cl, "CheckWinConditions");
		oo_mthd(cl, "InfectPlayer", @int(victim), @int(attacker));
		oo_mthd(cl, "CanHavePlayerItem", @int(id), @int(item));
		oo_mthd(cl, "CanTouchWeapon", @int(id), @int(ent), @int(weapon_id));
		oo_mthd(cl, "CanPlayerRespawn", @int(id));

		oo_mthd(cl, "OnThink");
		oo_mthd(cl, "OnRestartRound");
		oo_mthd(cl, "OnRoundFreezeEnd");
		oo_mthd(cl, "OnRoundTimeExpired");
		oo_mthd(cl, "OnRoundEnd", @int(status), @int(event), @fl(delay));
		oo_mthd(cl, "OnChooseTeam", @int(player), @int(slot));
		oo_mthd(cl, "OnPlayerSpawn", @int(id));
		oo_mthd(cl, "OnPlayerTakeDamage", @int(victim), @int(inflictor), @int(attacker), @fl(damage), @int(damagebits));
		oo_mthd(cl, "OnPlayerKilled", @int(id), @int(attacker), @int(shouldgib));
		oo_mthd(cl, "OnGiveDefaultItems", @int(id));
		oo_mthd(cl, "OnPlayerRespawn", @int(id));
	}
}

public plugin_precache()
{
	oo_gamemode_set(oo_new("ContagionGame"));

	g_oAssets = oo_new("Assets");
	oo_call(g_oAssets, "LoadJson", "gamemode/zombie.json");

	g_fwEntSpawn = register_forward(FM_Spawn, "OnEntSpawn");
}

public plugin_init()
{
	register_plugin("[CTG] Game Mode", "0.1", "holla");

	unregister_forward(FM_Spawn, g_fwEntSpawn);

	new pcvar = create_cvar("ctg_gamemode_start_delay", "20");
	bind_pcvar_float(pcvar, cvar_wait);

	pcvar = create_cvar("ctg_gamemode_zombie_ratio", "0.1");
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

public OnEntSpawn(ent)
{
	if (!pev_valid(ent))
		return FMRES_IGNORED;

	static classname[32];
	get_entvar(ent, var_classname, classname, charsmax(classname));
	for (new i = 0; i < sizeof g_ObjectiveEnts; i++)
	{
		if (equal(classname, g_ObjectiveEnts[i]))
		{
			rg_remove_entity(ent);
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public OnCvarLights(pcvar, const old_value[], const new_value[])
{
	new GameMode:mode_o = oo_gamemode_get();
	if (mode_o == @null || !oo_isa(mode_o, "ContagionGame", true))
		return;
	
	set_lights(new_value);
}

public ContagionGame@Ctor()
{
	oo_super_ctor("GameMode");
}

public ContagionGame@Dtor()
{
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
	new this = oo_this();
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
					show_dhudmessage(0, "遊戲將在 %d 秒後開始", countdown);

					new word[8];
					num_to_word(countdown, word, charsmax(word));
					client_cmd(0, "spk fvox/%s", word); // play sound

					oo_set(this, "countdown_time", current_time + 1.0);
				}
			}
		}
	}
}

public ContagionGame@Start()
{
	new this = oo_this();
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
		if (i == 0)
			rg_give_item(player, "weapon_hegrenade");
	}

	set_lights(cvar_lights);

	set_dhudmessage(0, 255, 0, -1.0, 0.2, 1, 0.0, 3.0, 0.0, 1.0);
	show_dhudmessage(0, "遊戲開始!");

	static sound[64];
	if (AssetsGetRandomGeneric(g_oAssets, "game_start", sound, charsmax(sound)))
		client_cmd(0, "spk ^"%s^"", sound);
}

public ContagionGame@End()
{
}

public ContagionGame@OnRoundEnd(WinStatus:win, ScenarioEventEndRound:event, Float:tmDelay)
{
	new this = oo_this();
	oo_call(this, "End");
}

public ContagionGame@CheckWinConditions()
{
	new this = oo_this();
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

	if (spawnable_count > 1 && human_count < 1) // all humans are dead
	{
		rg_round_end(5.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "Zombies Win", .trigger=true);
		return true;
	}

	if (spawnable_count > 1 && zombie_count < 1 && human_count > 0)
	{
		rg_round_end(5.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "Humans Win", .trigger=true);
		return true;
	}

	if (spawnable_count > 1 && zombie_count < 1 && human_count < 1) // all players are dead
	{
		rg_round_end(5.0, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Draw", .trigger=true);
		return true;
	}

	return true;
}

public ContagionGame@OnRoundTimeExpired()	
{
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
		rg_round_end(5.0, WINSTATUS_CTS, ROUND_CTS_WIN, "Humans Win", .trigger=true);
		return;
	}

	rg_round_end(5.0, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Draw", .trigger=true);
}

public ContagionGame@OnPlayerSpawn(id)
{
	oo_call(oo_this(), "GameMode@OnPlayerSpawn", id);
}

public ContagionGame@OnPlayerKilled(id, attacker, shouldgib)
{
	new this = oo_this();
	oo_call(this, "GameMode@OnPlayerKilled", id, attacker, shouldgib);

	if (oo_call(this, "CanPlayerRespawn", id))
	{
		oo_player_set_respawn(id, 5.0);
	}
}

public ContagionGame@CanPlayerRespawn(id)
{
	return true;
}

public ContagionGame@OnPlayerRespawn(id)
{
	new this = oo_this();
	if (!oo_call(this, "CanPlayerRespawn", id))
		return false;

	if (oo_get(this, "is_started"))
	{
		oo_playerclass_change(id, "Zombie", false);
	}

	return true;
}

public ContagionGame@OnPlayerTakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
}

public ContagionGame@InfectPlayer(victim, attacker)
{
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
	oo_call(class_o, "SetProperties", false);

	new PlayerClassInfo:info_o = any:oo_call(class_o, "GetClassInfo");
	if (info_o != @null)
	{
		static sound[64];
		if (AssetsGetRandomSound(info_o, "infect", sound, charsmax(sound)))
			emit_sound(victim, CHAN_VOICE, sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}

	rg_set_user_team(victim, TEAM_TERRORIST, MODEL_UNASSIGNED, false, true);

	remove_task(victim);
	set_task(0.1, "TaskChangeTeam", victim);
}

public ContagionGame@OnRestartRound()
{
	new this = oo_this();
	oo_call(this, "GameMode@OnRestartRound");
	oo_set(this, "is_ended", false);
	oo_set(this, "is_started", false);
	oo_set(this, "has_intro", false);

	set_lights("");

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i) || !(TEAM_TERRORIST <= TeamName:get_member(i, m_iTeam) <= TEAM_CT))
			continue;
		
		oo_playerclass_change(i, "Human", false);
	}
}

public ContagionGame@OnRoundFreezeEnd()
{
}

public ContagionGame@OnChooseTeam(id, MenuChooseTeam:slot)
{
	if (slot == MenuChoose_Spec)
	{
		oo_playerclass_change(id, "", false);
	}
	else
	{
		new this = oo_this();
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