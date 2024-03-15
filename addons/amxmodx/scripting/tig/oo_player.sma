#include <amxmodx>
#include <reapi>
#include <oo>

enum _:Forward_e
{
	FW_ALLOCATE,
	FW_CTOR,
	FW_DTOR,
	FW_SPAWN,
	FW_PRETHINK,
	FW_TAKEDAMAGE,
	FW_KILLED,
	FW_RESETMAXSPEED,
	FW_RESPAWN,
};

enum (+=100)
{
	TASK_RESPAWN = 0,
};


new Player:g_oPlayer[MAX_PLAYERS + 1] = {@null, ...};

new g_Forward[Forward_e];
new g_ForwardResult;


public plugin_init()
{
	register_plugin("[OO] Player", "0.1", "holla");

	RegisterHookChain(RG_CBasePlayer_Spawn, 		"OnPlayerSpawn_Post", 1);
	RegisterHookChain(RG_CBasePlayer_PreThink, 		"OnPlayerPreThink");
	RegisterHookChain(RG_CBasePlayer_TakeDamage, 	"OnPlayerTakeDamage");
	RegisterHookChain(RG_CBasePlayer_Killed, 		"OnPlayerKilled");
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "OnPlayerResetMaxSpeed_Post", 1);

	g_Forward[FW_ALLOCATE] 		= CreateMultiForward("OO_OnPlayerAllocate", ET_CONTINUE, FP_CELL);
	g_Forward[FW_CTOR] 			= CreateMultiForward("OO_OnPlayerCtor", ET_IGNORE, FP_CELL);
	g_Forward[FW_DTOR] 			= CreateMultiForward("OO_OnPlayerDtor", ET_IGNORE, FP_CELL);
	g_Forward[FW_SPAWN] 		= CreateMultiForward("OO_OnPlayerSpawn", ET_IGNORE, FP_CELL);
	g_Forward[FW_TAKEDAMAGE]	= CreateMultiForward("OO_OnPlayerTakeDamage", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_FLOAT, FP_CELL);
	g_Forward[FW_PRETHINK] 		= CreateMultiForward("OO_OnPlayerPreThink", ET_CONTINUE, FP_CELL);
	g_Forward[FW_KILLED] 		= CreateMultiForward("OO_OnPlayerKilled", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	g_Forward[FW_RESETMAXSPEED] = CreateMultiForward("OO_OnPlayerResetMaxSpeed", ET_CONTINUE, FP_CELL);
	g_Forward[FW_RESPAWN] 		= CreateMultiForward("OO_OnPlayerRespawn", ET_CONTINUE, FP_CELL);
}


public oo_init()
{
	oo_class("Player")
	{
		new cl[] = "Player";
		oo_var(cl, "player_id", 1);
		oo_var(cl, "max_health", 1);
		oo_var(cl, "max_armor", 1);

		oo_ctor(cl, "Ctor", @int(id));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "OnPreThink");
		oo_mthd(cl, "OnSpawn");
		oo_mthd(cl, "OnTakeDamage", @int(inflictor), @int(attacker), @fl(damage), @int(damagebits));
		oo_mthd(cl, "OnKilled", @int(killer), @int(shouldgib));
		oo_mthd(cl, "OnResetMaxSpeed");

		oo_mthd(cl, "SetRespawn", @fl(time));
		oo_mthd(cl, "ResetRespawn");
		oo_mthd(cl, "IsRespawnPending");
		oo_mthd(cl, "Respawn");
	}
}

public Player@Ctor(player)
{
	new this = oo_this();
	oo_set(this, "player_id", player);
	oo_set(this, "max_health", 100.0);
	oo_set(this, "max_armor", 100.0);

	ExecuteForward(g_Forward[FW_CTOR], g_ForwardResult, player);
}

public Player@Dtor()
{
	new id = oo_get(oo_this(), "player_id");
	remove_task(id + TASK_RESPAWN);
	ExecuteForward(g_Forward[FW_DTOR], g_ForwardResult, id);
}

public Player@OnSpawn()
{
	new id = oo_get(oo_this(), "player_id");
	remove_task(id + TASK_RESPAWN);
	ExecuteForward(g_Forward[FW_SPAWN], g_ForwardResult, id);
}

public Player@OnPreThink()
{
	new id = oo_get(oo_this(), "player_id");
	ExecuteForward(g_Forward[FW_PRETHINK], g_ForwardResult, id);
	return g_ForwardResult;
}

public Player@OnTakeDamage(inflictor, attacker, Float:damage, damagebits)
{
	new id = oo_get(oo_this(), "player_id");
	ExecuteForward(g_Forward[FW_TAKEDAMAGE], g_ForwardResult, id, inflictor, attacker, damage, damagebits);
	return g_ForwardResult;
}

public Player@OnKilled(attacker, shouldgibs)
{
	new id = oo_get(oo_this(), "player_id");
	ExecuteForward(g_Forward[FW_KILLED], g_ForwardResult, id, attacker, shouldgibs);
	return g_ForwardResult;
}

public Player@OnResetMaxSpeed()
{
	new id = oo_get(oo_this(), "player_id");
	ExecuteForward(g_Forward[FW_RESETMAXSPEED], g_ForwardResult, id);
	return g_ForwardResult;
}

public Player@SetRespawn(Float:time)
{
	new id = oo_get(oo_this(), "player_id");
	remove_task(id + TASK_RESPAWN);
	set_task(time, "RespawnPlayer", id + TASK_RESPAWN);
}

public Player@ResetRespawn()
{
	new id = oo_get(oo_this(), "player_id");
	remove_task(id + TASK_RESPAWN);
}

public Player@IsRespawnPending()
{
	new id = oo_get(oo_this(), "player_id");
	return task_exists(id + TASK_RESPAWN);
}

public Player@Respawn()
{
	new id = oo_get(oo_this(), "player_id");
	ExecuteForward(g_Forward[FW_RESPAWN], g_ForwardResult, id);
	rg_round_respawn(id);
}


public plugin_natives()
{
	register_library("oo_player");

	register_native("oo_player_get", "native_get");
	register_native("oo_player_set", "native_set");
}

public Player:native_get()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "player (%d) not connected", id);
		return @null;
	}

	return g_oPlayer[id];
}

public native_set()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "player (%d) not connected", id);
		return false;
	}

	new Player:player_o = any:get_param(2);
	if (player_o != @null)
	{
		if (!oo_object_exists(player_o))
		{
			log_error(AMX_ERR_NATIVE, "object (#%d) does not exist", player_o);
			return false;
		}

		if (!oo_isa(player_o, "Player"))
		{
			log_error(AMX_ERR_NATIVE, "object (#%d) not a (Player)", player_o);
			return false;
		}
	}

	g_oPlayer[id] = player_o;
	return true;
}


public client_putinserver(id)
{	
	if (g_oPlayer[id] == @null)
	{
		ExecuteForward(g_Forward[FW_ALLOCATE], g_ForwardResult, id);
		if (g_ForwardResult == PLUGIN_HANDLED)
			return;

		g_oPlayer[id] = oo_new("Player", id);
	}
}

public client_disconnected(id)
{
	if (g_oPlayer[id] != @null)
	{
		oo_delete(g_oPlayer[id]);
		g_oPlayer[id] = @null;
	}
}

public OnPlayerSpawn_Post(id)
{
	if (g_oPlayer[id] != @null)
		oo_call(g_oPlayer[id], "OnSpawn");
}

public OnPlayerPreThink(id)
{
	if (g_oPlayer[id] != @null)
		return oo_call(g_oPlayer[id], "OnPreThink");

	return HC_CONTINUE;
}

public OnPlayerTakeDamage(id, inflictor, attacker, Float:damage, damagebits)
{
	if (g_oPlayer[id] != @null)
		return oo_call(g_oPlayer[id], "OnTakeDamage", inflictor, attacker, damage, damagebits);

	return HC_CONTINUE;
}

public OnPlayerKilled(id, attacker, shouldgibs)
{
	if (g_oPlayer[id] != @null)
		return oo_call(g_oPlayer[id], "OnKilled", attacker, shouldgibs);

	return HC_CONTINUE;
}

public OnPlayerResetMaxSpeed_Post(id)
{
	if (g_oPlayer[id] != @null)
		oo_call(g_oPlayer[id], "OnResetMaxSpeed");
}

public RespawnPlayer(taskid)
{
	new id = taskid - TASK_RESPAWN;
	if (g_oPlayer[id] != @null)
		oo_call(g_oPlayer[id], "Respawn");
}