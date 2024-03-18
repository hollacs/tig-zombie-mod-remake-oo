#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <cstrike>
#include <reapi>
#include <oo_player_class>

enum (+=100)
{
	TASK_THINK = 0
};

new GameMode:g_oCurrentMode;

public plugin_init()
{
	register_plugin("[OO] Game Mode", "0.1", "holla");

	RegisterHookChain(RG_HandleMenu_ChooseTeam, "OnChooseTeam_Post", 1);
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn_Post", 1);
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKilled_Post", 1);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnPlayerTakeDamage");
	RegisterHookChain(RG_CSGameRules_CheckWinConditions, "OnCheckWinConditions");
	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRestartRound");
	RegisterHookChain(RG_CSGameRules_CanHavePlayerItem, "OnCanHavePlayerItem");
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "OnRoundFreezeEnd");
	RegisterHookChain(RG_CBasePlayer_GiveDefaultItems, "OnGiveDefaultItems");
	RegisterHookChain(RG_RoundEnd, "OnRoundEnd");

	RegisterHam(Ham_Touch, "weaponbox", "OnWeaponBoxTouch");
	RegisterHam(Ham_Touch, "armoury_entity", "OnArmouryTouch");
	RegisterHam(Ham_Touch, "weapon_shield", "OnShieldTouch");
}

public plugin_natives()
{
	register_library("oo_gamemode");

	register_native("oo_gamemode_get", "native_get");
	register_native("oo_gamemode_set", "native_set");
}

public any:native_get()
{
	return g_oCurrentMode;
}

public native_set()
{
	new GameMode:mode_o = any:get_param(1)

	if (!oo_object_exists(mode_o))
	{
		log_error(AMX_ERR_NATIVE, "Object (%d) not exist", mode_o);
		return false;
	}

	if (!oo_isa(mode_o, "GameMode"))
	{
		log_error(AMX_ERR_NATIVE, "Object (%d) not a GameMode", mode_o);
		return false;
	}

	g_oCurrentMode = mode_o;
	return true;
}

public oo_init()
{
	oo_class("GameMode")
	{
		new const cl[] = "GameMode";
		oo_var(cl, "is_started", 1);
		oo_var(cl, "is_ended", 1);

		oo_ctor(cl, "Ctor");
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "Start");
		oo_mthd(cl, "End");
		oo_mthd(cl, "StartThink", @fl(time));
		oo_mthd(cl, "StopThink");
		oo_mthd(cl, "CheckWinConditions");
		oo_mthd(cl, "CanHavePlayerItem", @int(id), @int(item));
		oo_mthd(cl, "CanTouchWeapon", @int(id), @int(ent), @int(weapon_id));
		oo_mthd(cl, "CanPlayerRespawn", @int(id));
		oo_mthd(cl, "OnPlayerSpawn", @int(id));
		oo_mthd(cl, "OnPlayerTakeDamage", @int(victim), @int(inflictor), @int(attacker), @fl(damage), @int(damagebits));
		oo_mthd(cl, "OnPlayerKilled", @int(victim), @int(attacker), @int(shouldgibs));
		oo_mthd(cl, "OnGiveDefaultItems", @int(id));
		oo_mthd(cl, "OnThink");
		oo_mthd(cl, "OnRoundTimeExpired");
		oo_mthd(cl, "OnRestartRound");
		oo_mthd(cl, "OnRoundFreezeEnd");
		oo_mthd(cl, "OnRoundEnd", @int(status), @int(event), @fl(delay));
		oo_mthd(cl, "OnChooseTeam", @int(player), @int(slot));
		oo_mthd(cl, "OnPlayerRespawn", @int(player));

		oo_smthd(cl, "GetCurrent");
		oo_smthd(cl, "SetCurrent", @int(mode));
	}
}

public GameMode@Ctor()
{
	new this = oo_this();
	oo_set(this, "is_started", false);
	oo_set(this, "is_ended", false);
}

public GameMode@Dtor()
{
	new this = oo_this();
	oo_call(this, "StopThink");
}

public GameMode@Start()
{
	oo_set(oo_this(), "is_started", true);
}

public GameMode@End()
{
	new this = oo_this();
	oo_set(this, "is_ended", true);
	oo_call(this, "StopThink");
}

public GameMode@StartThink(Float:time)
{
	new param[2];
	param[0] = oo_this();
	set_task_ex(time, "TaskThink", TASK_THINK, param, sizeof param, SetTask_Repeat);
}

public GameMode@StopThink()
{
	remove_task(TASK_THINK);
}

public GameMode@CheckWinConditions()
{
	return false;
}

public GameMode@OnThink()
{
	new this = oo_this();

	if (!get_member_game(m_bRoundTerminating)
		&& get_gametime() >= Float:get_member_game(m_fRoundStartTimeReal) + float(get_member_game(m_iRoundTimeSecs)))
	{
		oo_call(this, "OnRoundTimeExpired");
	}
}

public GameMode@OnRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
	oo_call(oo_this(), "End");
}

public GameMode@OnRestartRound()
{
	new this = oo_this();
	oo_call(this, "StopThink");
	oo_call(this, "StartThink", 0.1);
}

public GameMode@CanHavePlayerItem(id, item) { return true; }
public GameMode@OnPlayerSpawn(id) {}
public GameMode@OnPlayerKilled(victim, attacker, shouldgibs) {}
public GameMode@OnRoundFreezeEnd() {}
public GameMode@OnRoundTimeExpired() {}
public GameMode@OnPlayerTakeDamage(victim, inflictor, attacker, Float:damage, damagebits) {}
public GameMode@OnGiveDefaultItems(id) { return false; }
public GameMode@CanTouchWeapon(id, ent, weapon_id) { return true; }
public GameMode@OnChooseTeam(id, MenuChooseTeam:slot) {}
public GameMode@CanPlayerRespawn(id) { return true; }

public GameMode@OnPlayerRespawn(id)
{
	return oo_call(oo_this(), "CanPlayerRespawn", id) ? true : false;
}


public GameMode:GameMode@GetCurrent()
{
	return g_oCurrentMode;
}

public GameMode@SetCurrent(GameMode:mode_o)
{
	g_oCurrentMode = mode_o;
}

public OnChooseTeam_Post(id, MenuChooseTeam:slot)
{
	if (!GetHookChainReturn(ATYPE_INTEGER))
		return;
	
	if (g_oCurrentMode != @null)
		oo_call(g_oCurrentMode, "OnChooseTeam", id, slot);
}

public OnRestartRound()
{
	if (g_oCurrentMode != @null)
		oo_call(g_oCurrentMode, "OnRestartRound");
}

public OnRoundFreezeEnd()
{
	if (g_oCurrentMode != @null)
		oo_call(g_oCurrentMode, "OnRoundFreezeEnd");
}

public OnRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
	if (g_oCurrentMode != @null)
		oo_call(g_oCurrentMode, "OnRoundEnd", status, event, tmDelay);
}

public OnCheckWinConditions()
{
	if (get_member_game(m_iRoundWinStatus) != WINSTATUS_NONE)
		return HC_CONTINUE;

	if (g_oCurrentMode != @null)
		return oo_call(g_oCurrentMode, "CheckWinConditions") ? HC_SUPERCEDE : HC_CONTINUE;

	return HC_CONTINUE;
}

public OnPlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return;

	if (g_oCurrentMode != @null)
		oo_call(g_oCurrentMode, "OnPlayerSpawn", id);
}

public OnPlayerKilled_Post(victim, attacker, shouldgibs)
{
	if (g_oCurrentMode != @null)
	{
		oo_call(g_oCurrentMode, "OnPlayerKilled", victim, attacker, shouldgibs);
	}
}

public OnPlayerTakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (g_oCurrentMode != @null)
		return oo_call(g_oCurrentMode, "OnPlayerTakeDamage", victim, inflictor, attacker, damage, damagebits) ? 
			HC_SUPERCEDE : HC_CONTINUE;

	return HC_CONTINUE;
}

public OnCanHavePlayerItem(id, item)
{
	if (g_oCurrentMode != @null)
	{
		if (!oo_call(g_oCurrentMode, "CanHavePlayerItem", id, item))
		{
			SetHookChainReturn(ATYPE_INTEGER, false);
			return HC_SUPERCEDE;
		}
	}

	return HC_CONTINUE;
}

public OnGiveDefaultItems(id)
{
	if (g_oCurrentMode != @null)
		return oo_call(g_oCurrentMode, "OnGiveDefaultItems", id) ? HC_SUPERCEDE : HC_CONTINUE;

	return HC_CONTINUE;
}

public OnWeaponBoxTouch(ent, toucher)
{
	if (g_oCurrentMode != @null && is_entity(ent) && is_user_alive(toucher))
		return oo_call(g_oCurrentMode, "CanTouchWeapon", toucher, ent, rg_get_weaponbox_id(ent)) ? HAM_IGNORED : HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public OnArmouryTouch(ent, toucher)
{
	if (g_oCurrentMode != @null && is_entity(ent) && is_user_alive(toucher))
		return oo_call(g_oCurrentMode, "CanTouchWeapon", toucher, ent, cs_get_armoury_type(ent)) ? HAM_IGNORED : HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public OnShieldTouch(ent, toucher)
{
	if (g_oCurrentMode != @null && is_entity(ent) && is_user_alive(toucher))
		return oo_call(g_oCurrentMode, "CanTouchWeapon", toucher, ent, CSW_NONE) ? HAM_IGNORED : HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public OO_OnPlayerRespawn(id)
{
	if (g_oCurrentMode != @null)
	{
		new r = oo_call(g_oCurrentMode, "OnPlayerRespawn", id) ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
		return r;
	}

	return PLUGIN_CONTINUE;
}

public TaskThink(param[], taskid)
{
	new GameMode:mode_o = any:param[0];
	if (!oo_object_exists(mode_o))
	{
		remove_task(taskid);
		return;
	}

	oo_call(mode_o, "OnThink");
}