#include <amxmodx>
#include <sqlx>

enum
{
	MODE_NONE = 0,
	MODE_LOAD,
	MODE_SAVE
};

new Trie:g_tAuthId;
new Handle:g_DbTuple;
new g_Query[256];

new g_Mode[MAX_PLAYERS + 1];
new g_Step[MAX_PLAYERS + 1];
new g_MaxStep[MAX_PLAYERS + 1];
new Float:g_Time[MAX_PLAYERS + 1];

new g_fwLoadPlayerData, g_fwSavePlayerData;

public plugin_init()
{
	register_plugin("[CTG] Database", "0.1", "holla");

	static host[64], user[64], pass[64];
	get_cvar_string("amx_sql_host", host, charsmax(host));
	get_cvar_string("amx_sql_user", user, charsmax(user));
	get_cvar_string("amx_sql_pass", pass, charsmax(pass));

	g_DbTuple = SQL_MakeDbTuple(host, user, pass, "contagion");

	static errcode, error[128];
	new Handle:connection_h = SQL_Connect(g_DbTuple, errcode, error, charsmax(error));

	new Handle:queries_h[2];

	queries_h[0] = SQL_PrepareQuery(connection_h, 
		"CREATE TABLE IF NOT EXISTS player ( \
			id INTEGER PRIMARY KEY, \
			steam_id VARCHAR(50) NOT NULL UNIQUE ON CONFLICT IGNORE, \
			created_at TIME DEFAULT CURRENT_TIMESTAMP, \
			updated_at TIME DEFAULT CURRENT_TIMESTAMP);");


	queries_h[1] = SQL_PrepareQuery(connection_h, 
		"CREATE TRIGGER IF NOT EXISTS trigger_updated_at \
		AFTER UPDATE ON player \
		FOR EACH ROW \
		BEGIN \
			UPDATE player SET updated_at = CURRENT_TIMESTAMP WHERE id = old.id; \
		END");

	for (new i = 0; i < sizeof queries_h; i++)
	{
		if (!SQL_Execute(queries_h[i]))
		{
			SQL_QueryError(queries_h[i], error, charsmax(error));
			set_fail_state(error);
		}

		SQL_FreeHandle(queries_h[i]);
	}

	SQL_FreeHandle(connection_h);

	g_tAuthId = TrieCreate();

	g_fwLoadPlayerData = CreateMultiForward("CTG_OnDbLoadPlayerData", ET_IGNORE, FP_CELL, FP_STRING);
	g_fwSavePlayerData = CreateMultiForward("CTG_OnDbSavePlayerData", ET_IGNORE, FP_CELL, FP_STRING);
}

public plugin_natives()
{
	register_library("ctg_database");

	register_native("ctg_db_add_step", "native_add_step");
	register_native("ctg_db_add_maxstep", "native_add_maxstep");
	register_native("ctg_db_add_column", "native_add_column");
	register_native("ctg_db_get_player_id", "native_get_player_id");
	register_native("ctg_db_load_player_data", "native_load_player_data");
	register_native("ctg_db_save_player_data", "native_save_player_data");
	register_native("ctg_db_get_tuple", "native_get_tuple");
}

public native_add_step()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return;
	}

	new amount = get_param(2);
	AddStep(id, amount);
}

public native_add_maxstep()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return;
	}

	new amount = get_param(2);
	AddMaxStep(id, amount);
}

public native_add_column()
{
	static error[128], errcode;

	new Handle:connection_h = SQL_Connect(g_DbTuple, errcode, error, charsmax(error));
	if (connection_h == Empty_Handle)
	{
		set_fail_state(error);
		return false;
	}

	static table[32], column[32], code[96];
	get_string(1, table, charsmax(table));
	get_string(2, column, charsmax(column));
	get_string(3, code, charsmax(code));

	formatex(g_Query, charsmax(g_Query), "SELECT %s FROM %s LIMIT 1;", column, table);

	new bool:exists = false;
	new Handle:query_h = SQL_PrepareQuery(connection_h, g_Query);
	if (SQL_Execute(query_h))
		exists = true;

	SQL_FreeHandle(query_h);

	new bool:result = false;
	if (!exists)
	{
		formatex(g_Query, charsmax(g_Query), "ALTER TABLE %s ADD COLUMN %s %s;", table, column, code);
		query_h = SQL_PrepareQuery(connection_h, g_Query);
		if (SQL_Execute(query_h))
			result = true;

		SQL_FreeHandle(query_h);
	}

	SQL_FreeHandle(connection_h)
	return result;
}

public native_get_player_id()
{
	static steamid[50];
	get_string(1, steamid, charsmax(steamid));

	new player;
	if (TrieGetCell(g_tAuthId, steamid, player))
		return player;
	
	return 0;
}

public native_load_player_data()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return;
	}

	LoadPlayerData(id, bool:get_param(2));
}

public native_save_player_data()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return;
	}

	SavePlayerData(id, bool:get_param(2));
}

public Handle:native_get_tuple()
{
	return g_DbTuple;
}

public client_putinserver(id)
{
	if (!is_user_bot(id))
	{
		static steamid[50];
		get_user_authid(id, steamid, charsmax(steamid));
		TrieSetCell(g_tAuthId, steamid, id);

		formatex(g_Query, charsmax(g_Query), 
			"INSERT INTO player (id, steam_id) VALUES (NULL, '%s');", steamid);

		SQL_ThreadQuery(g_DbTuple, "InsertHandle", g_Query, steamid, sizeof steamid);
	}
}

public client_disconnected(id)
{
	if (!is_user_bot(id) && is_user_connected(id))
	{
		g_Mode[id] = MODE_NONE;

		static steamid[50];
		get_user_authid(id, steamid, charsmax(steamid));

		new player;
		if (TrieGetCell(g_tAuthId, steamid, player) && player == id)
		{
			SavePlayerData(id, false);
		}

		TrieDeleteKey(g_tAuthId, steamid);
	}
}

public InsertHandle(failstate, Handle:query_h, const error[], errcode, const data[], datasize)
{
	if (!CheckQueryHandle(failstate, error, errcode) || !TrieKeyExists(g_tAuthId, data))
		return;
	
	formatex(g_Query, charsmax(g_Query), 
		"SELECT id, steam_id FROM player WHERE steam_id='%s'", data);

	SQL_ThreadQuery(g_DbTuple, "SelectHandle", g_Query);
}

public SelectHandle(failstate, Handle:query_h, const error[], errcode, const data[], datasize)
{
	if (!CheckQueryHandle(failstate, error, errcode))
		return;
	
	if (SQL_MoreResults(query_h))
	{
		static steamid[50];
		SQL_ReadResult(query_h, 1, steamid, charsmax(steamid));

		new player;
		if (TrieGetCell(g_tAuthId, steamid, player))
		{
			LoadPlayerData(player);
		}
	}
}

LoadPlayerData(id, bool:notify=false)
{
	if (notify)
	{
		g_Mode[id] = MODE_LOAD;		
		g_Step[id] = 0;
		g_MaxStep[id] = 0;
		g_Time[id] = get_gametime();
	}

	static steamid[50];
	get_user_authid(id, steamid, charsmax(steamid));

	new ret;
	ExecuteForward(g_fwLoadPlayerData, ret, id, steamid);
}

SavePlayerData(id, bool:notify=false)
{
	if (notify)
	{
		g_Mode[id] = MODE_SAVE;		
		g_Step[id] = 0;
		g_MaxStep[id] = 0;
		g_Time[id] = get_gametime();
	}

	static steamid[50];
	get_user_authid(id, steamid, charsmax(steamid));

	new ret;
	ExecuteForward(g_fwSavePlayerData, ret, id, steamid);
}

AddMaxStep(id, amount=1)
{
	if (g_Mode[id] == MODE_NONE)
		return;

	g_MaxStep[id] += amount;
}

AddStep(id, amount=1)
{
	if (g_Mode[id] == MODE_NONE)
		return;
	
	g_Step[id] += amount;

	if (g_Step[id] >= g_MaxStep[id])
	{
		if (g_Mode[id] == MODE_LOAD)
			client_print_color(id, print_team_blue, "^4[Database] ^3資料載入完成 ^1(%dms)", 
				floatround((get_gametime() - g_Time[id]) / 0.001, floatround_floor));
		else
			client_print_color(id, print_team_blue, "^4[Database] ^3資料儲存完成 ^1(%dms)", 
				floatround((get_gametime() - g_Time[id]) / 0.001, floatround_floor));

		g_Mode[id] = MODE_NONE;		
		g_Step[id] = 0;
		g_MaxStep[id] = 0;
	}
}

CheckQueryHandle(failstate, const error[], errcode)
{
	if (failstate == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.");
	else if(failstate == TQUERY_QUERY_FAILED)
		return set_fail_state("Query failed: %s", error);
   
	if	(errcode)
		return log_amx("Error on query: %s", error);

	return 1;
}