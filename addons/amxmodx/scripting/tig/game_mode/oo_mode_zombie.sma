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

new Float:CvarRatio;
new Float:CvarWait;
new CvarLights[32];
new CvarMoneyDamage, Float:CvarMoneyHumanDamagedHp;
new CvarMoneyZombieKilled, CvarMoneyHumanKilled;
new CvarMoneyHumanWin, CvarMoneyZombieWin;

new Assets:g_oAssets;
new g_fwEntSpawn;

new Float:g_DamageDealt[MAX_PLAYERS + 1];

public oo_init()
{
	oo_class("ZombieMode", "GameMode");
	{
		new const cl[] = "ZombieMode";
		oo_var(cl, "has_intro", 1);
		oo_var(cl, "countdown_time", 1);

		oo_ctor(cl, "Ctor");
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "Start");

		oo_mthd(cl, "CheckWinConditions");
		oo_mthd(cl, "InfectPlayer", @int(victim), @int(attacker));
		oo_mthd(cl, "CanHavePlayerItem", @int(id), @int(item));
		oo_mthd(cl, "CanTouchWeapon", @int(id), @int(ent), @int(weapon_id));

		oo_mthd(cl, "OnThink");
		oo_mthd(cl, "OnRestartRound");
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
	oo_gamemode_set(oo_new("ZombieMode"));

	static file_path[64];
	get_configsdir(file_path, charsmax(file_path));
	format(file_path, charsmax(file_path), "%s/gamemode/zombie.json", file_path);

	g_oAssets = oo_new("Assets");
	oo_call(g_oAssets, "LoadJson", file_path);

	g_fwEntSpawn = register_forward(FM_Spawn, "OnEntSpawn");
}

public plugin_init()
{
	register_plugin("[OO] Mode: Zombie", "0.1", "holla");

	register_message(get_user_msgid("SendAudio"), "Message_SendAudio");

	unregister_forward(FM_Spawn, g_fwEntSpawn);

	new pcvar = create_cvar("tig_gamemode_start_delay", "20");
	bind_pcvar_float(pcvar, CvarWait);

	pcvar = create_cvar("tig_gamemode_zombie_ratio", "0.1");
	bind_pcvar_float(pcvar, CvarRatio);

	pcvar = create_cvar("tig_gamemode_lights", "c");
	bind_pcvar_string(pcvar, CvarLights, charsmax(CvarLights));
	hook_cvar_change(pcvar, "OnCvarLights");

	pcvar = create_cvar("tig_money_damage", "10");
	bind_pcvar_num(pcvar, CvarMoneyDamage);

	pcvar = create_cvar("tig_money_human_damaged_hp", "400");
	bind_pcvar_float(pcvar, CvarMoneyHumanDamagedHp);

	pcvar = create_cvar("tig_money_human_killed", "20");
	bind_pcvar_num(pcvar, CvarMoneyHumanKilled);

	pcvar = create_cvar("tig_money_zombie_killed", "10");
	bind_pcvar_num(pcvar, CvarMoneyZombieKilled);

	pcvar = create_cvar("tig_money_human_win", "20");
	bind_pcvar_num(pcvar, CvarMoneyHumanWin);

	pcvar = create_cvar("tig_money_zombie_win", "20");
	bind_pcvar_num(pcvar, CvarMoneyZombieWin);

	set_member_game(m_bTCantBuy, true);
	set_member_game(m_bCTCantBuy, true);

	server_cmd("sv_restart 1");
	server_exec();
}

public plugin_natives()
{
	register_library("oo_zombie_mode");

	register_native("oo_infect_player", "native_infect_player");
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
	if (!oo_isa(mode_o, "ZombieMode"))
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

public Message_SendAudio(msgid, msgdest, id)
{
	static audio[17];
	get_msg_arg_string(2, audio, charsmax(audio));
	
	if(equal(audio[7], "terwin") || equal(audio[7], "ctwin"))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public OnCvarLights(pcvar, const old_value[], const new_value[])
{
	new GameMode:mode_o = oo_gamemode_get();
	if (mode_o == @null || !oo_isa(mode_o, "ZombieMode", true))
		return;
	
	set_lights(new_value);
}

public ZombieMode@Ctor()
{
	oo_super_ctor("GameMode");
}

public ZombieMode@Dtor() {}

public ZombieMode@OnGiveDefaultItems(id)
{
	if (oo_playerclass_isa(id, "Human"))
	{
		rg_remove_all_items(id);
		rg_give_item(id, "weapon_knife");
	}

	return true;
}

public ZombieMode@OnThink()
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
				oo_set(this, "countdown_time", current_time + floatmax(CvarWait - 10.0, 0.0));
			}
			else
			{
				new Float:countdown_time = Float:oo_get(this, "countdown_time");
				if (current_time >= countdown_time)
				{
					new Float:roundstart_time = Float:get_member_game(m_fRoundStartTime);
					if (current_time - roundstart_time >= CvarWait)
					{
						oo_call(this, "Start"); // start gamemode
						return;
					}

					new countdown = floatround(roundstart_time + CvarWait - current_time, floatround_ceil);
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

public ZombieMode@Start()
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
	
	new max_zombies = floatround(num * CvarRatio, floatround_ceil);
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

	set_lights(CvarLights);

	set_dhudmessage(0, 255, 0, -1.0, 0.2, 1, 0.0, 3.0, 0.0, 1.0);
	show_dhudmessage(0, "遊戲開始!");

	static sound[64];
	if (AssetsGetRandomGeneric(g_oAssets, "game_start", sound, charsmax(sound)))
		client_cmd(0, "spk ^"%s^"", sound);
}

public ZombieMode@OnRoundEnd(WinStatus:win, ScenarioEventEndRound:event, Float:tmDelay)
{
	new this = oo_this();
	oo_call(this, "GameMode@OnRoundEnd", win, event, tmDelay);

	switch (win)
	{
		case WINSTATUS_TERRORISTS:
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (is_user_connected(i) && get_member(i, m_iMenu) != Menu_ChooseAppearance &&
					(TEAM_TERRORIST <= TeamName:get_member(i, m_iTeam) <= TEAM_CT) &&
					oo_playerclass_isa(i, "Zombie"))
				{
					rg_add_account(i, CvarMoneyZombieWin);
				}
			}
		}
		case WINSTATUS_CTS:
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (is_user_connected(i) && get_member(i, m_iMenu) != Menu_ChooseAppearance &&
					(TEAM_TERRORIST <= TeamName:get_member(i, m_iTeam) <= TEAM_CT) &&
					oo_playerclass_isa(i, "Human"))
				{
					rg_add_account(i, CvarMoneyHumanWin);
				}
			}
		}
	}
}

public ZombieMode@CheckWinConditions()
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
				if (oo_playerclass_isa(i, "Human", true))
					human_count++;
				else if (oo_playerclass_isa(i, "Zombie", true))
					zombie_count++;
			}
			spawnable_count++;
		}
	}

	if (spawnable_count > 1 && human_count < 1) // all humans are dead
	{
		rg_round_end(5.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "Zombies Win");

		set_dhudmessage(255, 50, 50, -1.0, 0.3, 0, 0.0, 3.0, 1.0, 1.0);
		show_dhudmessage(0, "Zombies Win");

		static sound[64];
		if (AssetsGetRandomGeneric(g_oAssets, "zombies_win", sound, charsmax(sound)))
			client_cmd(0, "spk ^"%s^"", sound);

		return true;
	}

	if (spawnable_count > 1 && zombie_count < 1 && human_count < 1) // all players are dead
	{
		rg_round_end(5.0, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Draw");
		return true;
	}

	return true;
}

public ZombieMode@OnRoundTimeExpired()	
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
		oo_call(oo_this(), "RoundEnd", WINSTATUS_CTS, ROUND_CTS_WIN, "Survivors Win");

		set_dhudmessage(0, 255, 0, -1.0, 0.3, 0, 0.0, 3.0, 1.0, 1.0);
		show_dhudmessage(0, "Humans Win");

		static sound[64];
		if (AssetsGetRandomGeneric(g_oAssets, "survivors_win", sound, charsmax(sound)))
			client_cmd(0, "spk ^"%s^"", sound);

		return;
	}

	rg_round_end(5.0, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Draw");
}

public ZombieMode@OnPlayerSpawn(id)
{
	oo_call(oo_this(), "GameMode@OnPlayerSpawn", id);
}

public ZombieMode@OnPlayerKilled(id, attacker, shouldgib)
{
	new this = oo_this();
	oo_call(this, "GameMode@OnPlayerKilled", id, attacker, shouldgib);

	if (oo_call(this, "CanPlayerRespawn", id))
	{
		oo_player_set_respawn(id, 5.0);
	}

	if (is_user_connected(attacker) && oo_playerclass_isa(attacker, "Human"))
	{
		if (oo_playerclass_isa(id, "Zombie"))
		{
			rg_add_account(attacker, CvarMoneyZombieKilled);
		}
		else
		{
			rg_add_account(attacker, CvarMoneyHumanKilled);
		}
	}
}

public ZombieMode@OnPlayerRespawn(id)
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

public ZombieMode@OnPlayerTakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if ((damagebits & DMG_BULLET) && inflictor == attacker && is_user_connected(attacker))
	{
		if (oo_playerclass_isa(attacker, "Human") && oo_playerclass_isa(victim, "Zombie"))
		{
			g_DamageDealt[attacker] += damage;

			if (g_DamageDealt[attacker] >= CvarMoneyHumanDamagedHp)
			{
				rg_add_account(attacker, CvarMoneyDamage);
				g_DamageDealt[attacker] = 0.0;
			}
		}
	}
}

public ZombieMode@InfectPlayer(victim, attacker)
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

public ZombieMode@OnRestartRound()
{
	new this = oo_this();
	oo_call(this, "GameMode@OnRestartRound");
	oo_set(this, "is_ended", false);
	oo_set(this, "is_started", false);
	oo_set(this, "has_intro", false);

	set_lights("");

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i))
			continue;
		
		oo_playerclass_change(i, "Human", false);
	}
}

public ZombieMode@OnChooseTeam(id, MenuChooseTeam:slot)
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

public ZombieMode@CanHavePlayerItem(id, item)
{
	if (oo_playerclass_isa(id, "Zombie"))
	{
		new weapon_id = get_member(item, m_iId);
		if (weapon_id != CSW_KNIFE && !(CSW_ALL_GRENADES & (1 << weapon_id)))
			return false;
	}

	return true;
}

public ZombieMode@CanTouchWeapon(id, ent, weapon_id)
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