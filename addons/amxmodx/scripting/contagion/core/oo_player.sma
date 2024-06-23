#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <oo>

enum (+=100)
{
	TASK_RESPAWN = 0,
};

new Player:g_oPlayer[MAX_PLAYERS + 1] = {@null, ...};

public plugin_init()
{
	register_plugin("[OO] Player", "0.1", "holla");

	RegisterHookChain(RG_CBasePlayer_Spawn, 		"OnPlayerSpawn_Post", 1);
	RegisterHookChain(RG_CBasePlayer_PreThink, 		"OnPlayerPreThink");
	RegisterHookChain(RG_CBasePlayer_Killed, 		"OnPlayerKilled");
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "OnPlayerResetMaxSpeed_Post", 1);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, 	"OnPlayerTakeDamage");
	RegisterHookChain(RG_CBasePlayer_TraceAttack, 	"OnPlayerTraceAttack");
	RegisterHookChain(RG_CBasePlayer_TraceAttack, 	"OnPlayerTraceAttack_Post", 1);
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

public oo_init()
{
	oo_class("Player")
	{
		new cl[] = "Player";
		oo_var(cl, "player_id", 1);
		oo_var(cl, "max_health", 1);
		oo_var(cl, "max_armor", 1);
		oo_var(cl, "respawn_after", 1);

		oo_ctor(cl, "Ctor", @int(id));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "OnPreThink");
		oo_mthd(cl, "OnSpawn");
		oo_mthd(cl, "OnTakeDamage", @int(inflictor), @int(attacker), @ref(damage), @int(damagebits));
		oo_mthd(cl, "OnTraceAttack", @int(attacker), @ref(damage), @arr(dir[3]), @int(tr), @int(damagebits));
		oo_mthd(cl, "OnTraceAttack_Post", @int(attacker), @fl(damage), @arr(dir[3]), @int(tr), @int(damagebits));
		oo_mthd(cl, "OnKilled", @int(killer), @int(shouldgib));
		oo_mthd(cl, "OnResetMaxSpeed");

		oo_mthd(cl, "SetRespawn", @fl(time));
		oo_mthd(cl, "ResetRespawn");
		oo_mthd(cl, "IsRespawnPending");
		oo_mthd(cl, "GetRespawnTime");
		oo_mthd(cl, "Respawn");

		oo_smthd(cl, "New", @int(id));
	}
}

public Player@Ctor(player)
{
	new this = @this;
	oo_set(this, "player_id", player);
	oo_set(this, "max_health", 100);
	oo_set(this, "max_armor", 100);
}

public Player@Dtor()
{
	new id = oo_get(@this, "player_id");
	remove_task(id + TASK_RESPAWN);
}

public Player@OnSpawn()
{
	new id = oo_get(@this, "player_id");
	remove_task(id + TASK_RESPAWN);
}

public Player@OnPreThink()
{
	return HC_CONTINUE;
}

public Player@OnTakeDamage(inflictor, attacker, &Float:damage, damagebits)
{
	return HC_CONTINUE;
}

public Player@OnTraceAttack(attacker, &Float:damage, Float:dir[3], tr, damagebits)
{
	return HC_CONTINUE;
}

public Player@OnTraceAttack_Post(attacker, Float:damage, Float:dir[3], tr, damagebits)
{
}

public Player@OnKilled(attacker, shouldgibs)
{
	return HC_CONTINUE;
}

public Player@OnResetMaxSpeed()
{
}

public Player@SetRespawn(Float:time)
{
	new this = @this;
	oo_set(this, "respawn_after", get_gametime() + time);

	new id = oo_get(this, "player_id");
	remove_task(id + TASK_RESPAWN);
	set_task(time, "RespawnPlayer", id + TASK_RESPAWN);
}

public Player@ResetRespawn()
{
	new this = @this;
	new id = oo_get(this, "player_id");
	oo_set(this, "respawn_after", 0.0);
	remove_task(id + TASK_RESPAWN);
}

public Player@IsRespawnPending()
{
	new id = oo_get(@this, "player_id");
	return task_exists(id + TASK_RESPAWN);
}

public Float:Player@GetRespawnTime()
{
	return Float:oo_get(@this, "respawn_after");
}

public Player@Respawn()
{
	new id = oo_get(@this, "player_id");
	rg_round_respawn(id);
}

public Player@New(id)
{
	g_oPlayer[id] = oo_new("Player", id);
}

public client_putinserver(id)
{	
	if (g_oPlayer[id] == @null)
	{
		oo_call(0, "Player@New", id)
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

public OnPlayerTraceAttack(id, attacker, Float:damage, Float:dir[3], tr, damagebits)
{
	if (g_oPlayer[id] != @null)
		return oo_call(g_oPlayer[id], "OnTraceAttack", attacker, damage, dir, tr, damagebits);

	return HC_CONTINUE;
}

public OnPlayerTraceAttack_Post(id, attacker, Float:damage, Float:dir[3], tr, damagebits)
{
	if (g_oPlayer[id] != @null)
		oo_call(g_oPlayer[id], "OnTraceAttack_Post", attacker, damage, dir, tr, damagebits);
}

public RespawnPlayer(taskid)
{
	new id = taskid - TASK_RESPAWN;
	if (g_oPlayer[id] != @null)
		oo_call(g_oPlayer[id], "Respawn");
}