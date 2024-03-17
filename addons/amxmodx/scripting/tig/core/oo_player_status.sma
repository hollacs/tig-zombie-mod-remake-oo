#include <amxmodx>
#include <oo_player>

#define MAX_PLAYERSTATUS 5

new PlayerStatus:g_oPlayerStatus[MAX_PLAYERS + 1][MAX_PLAYERSTATUS];
new g_PlayerStatusNum[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("[OO] Player Status", "0.1", "holla");
}

public oo_init()
{
	oo_class("PlayerStatus")
	{
		new cl[] = "PlayerStatus";
		oo_var(cl, "player_id", 1);

		oo_ctor(cl, "Ctor", @int(player_id));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "GetName", @stref(output), @int(len));
		oo_mthd(cl, "OnUpdate");
		oo_mthd(cl, "Delete");
	}
}

public PlayerStatus@Ctor(player_id)
{
	new this = oo_this();
	oo_set(this, "player_id", player_id);
}

public PlayerStatus@Dtor() {}
public PlayerStatus@GetName(output[], len) {}
public PlayerStatus@OnUpdate() {}

public PlayerStatus@Delete()
{
	new this = oo_this();
	new id = oo_get(this, "player_id");
	DeletePlayerStatus(id, PlayerStatus:this);
}

public plugin_natives()
{
	register_library("oo_playerstatus");

	register_native("oo_playerstatus_add", 		"native_add");
	register_native("oo_playerstatus_remove", 	"native_remove");
	register_native("oo_playerstatus_delete", 	"native_delete");
	register_native("oo_playerstatus_str", 		"native_str");
	register_native("oo_playerstatus_get", 		"native_get");
}

// oo_playerstatus_add(id, PlayerStatus:oo_new("BurnStatus", id))
public native_add()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return -1;
	}

	new PlayerStatus:status_o = any:get_param(2);
	if (!oo_isa(status_o, "PlayerStatus"))
	{
		log_error(AMX_ERR_NATIVE, "Object (%d) not a (PlayerStatus)", status_o);
		return -1;
	}

	return AddPlayerStatus(id, status_o);
}

// oo_playerstatus_remove(id, "FrozenStatus", true)
public PlayerStatus:native_remove()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return @null;
	}

	static class_name[32];
	get_string(2, class_name, charsmax(class_name));

	return RemovePlayerStatus(id, class_name, bool:get_param(3));
}

// oo_playerstatus_delete(id, status_o)
public native_delete()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return @null;
	}

	new PlayerStatus:status_o = any:get_param(2);
	return DeletePlayerStatus(id, status_o);
}

// oo_playerstatus_str(id, output[], maxlen)
public native_str()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return 0;
	}

	static str[64];
	GetPlayerStatusStr(id, str, charsmax(str));
	set_string(2, str, get_param(3));
	return 1;
}

// PlayerStatus:oo_playerclass_get(id, "PoisonStatus")
public PlayerStatus:native_get()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return @null;
	}

	static class_name[32];
	get_string(2, class_name, charsmax(class_name));

	new index = GetPlayerStatusIndex(id, class_name);
	if (index == -1)
		return @null;

	return g_oPlayerStatus[id][index];
}

public OO_OnPlayerDtor(id)
{
	for (new i = 0; i < MAX_PLAYERSTATUS; i++)
	{
		if (g_oPlayerStatus[id][i] != @null)
			oo_delete(g_oPlayerStatus[id][i]);
		
		g_oPlayerStatus[id][i] = @null;
	}

	g_PlayerStatusNum[id] = 0;
}

public OO_OnPlayerPreThink(id)
{
	for (new i = 0; i < g_PlayerStatusNum[id]; i++)
	{
		oo_call(g_oPlayerStatus[id][i], "OnUpdate");
	}
}

AddPlayerStatus(id, PlayerStatus:status_o)
{
	if (g_PlayerStatusNum[id] >= MAX_PLAYERSTATUS)
		return -1;

	static class_name[32];
	oo_get_classname(status_o, class_name, charsmax(class_name));

	new index = GetPlayerStatusIndex(id, class_name);
	if (index != -1)
	{
		oo_delete(g_oPlayerStatus[id][index]);
	}
	else
	{
		index = g_PlayerStatusNum[id];
		g_PlayerStatusNum[id]++;
	}

	g_oPlayerStatus[id][index] = status_o;
	return index;
}

PlayerStatus:RemovePlayerStatus(id, const class_name[], bool:delete=true)
{
	new index = GetPlayerStatusIndex(id, class_name);
	if (index == -1)
		return @null;
	
	new PlayerStatus:status_o = g_oPlayerStatus[id][index];
	g_oPlayerStatus[id][index] = g_oPlayerStatus[id][--g_PlayerStatusNum[id]];
	g_oPlayerStatus[id][g_PlayerStatusNum[id]] = @null;

	if (delete && oo_object_exists(status_o))
	{
		oo_delete(status_o);
		return @null;
	}

	return status_o;
}

DeletePlayerStatus(id, PlayerStatus:status_o)
{
	for (new i = 0; i < g_PlayerStatusNum[id]; i++)
	{
		if (g_oPlayerStatus[id][i] == status_o)
		{
			g_oPlayerStatus[id][i] = g_oPlayerStatus[id][--g_PlayerStatusNum[id]];
			g_oPlayerStatus[id][g_PlayerStatusNum[id]] = @null;

			oo_delete(status_o);
			return 1;
		}
	}

	return 0;
}

GetPlayerStatusIndex(id, const class_name[])
{
	for (new i = 0; i < g_PlayerStatusNum[id]; i++)
	{
		if (oo_isa(g_oPlayerStatus[id][i], class_name, false))
			return i;
	}

	return -1;
}

GetPlayerStatusStr(id, output[], maxlen)
{
	new len = 0;
	for (new i = 0; i < g_PlayerStatusNum[id]; i++)
	{
		if (i > 0) output[len++] = '+';
		len += oo_call(g_oPlayerStatus[id][i], "GetName", output[len], maxlen-len);
	}
}