#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <ctg_database>

new Handle:g_DbTuple;
new g_Query[256];

new g_Level[MAX_PLAYERS + 1] = {1, ...};
new g_Exp[MAX_PLAYERS + 1];

new cvar_maxlvl, Float:cvar_a, Float:cvar_b, Float:cvar_c, Float:cvar_d;

new g_fwLevelUp;
new g_fwLevelChange[2];
new g_fwAddExp[2];
new g_fwRet;

public plugin_init()
{
	register_plugin("[CTG] Player Level", "0.1", "holla");

	g_DbTuple = ctg_db_get_tuple();

	ctg_db_add_column("player", "level", "INTEGER NULL");
	ctg_db_add_column("player", "exp", "INTEGER NULL");

	register_concmd("ctg_give_exp", "CmdGiveExp", ADMIN_BAN, "<name or #userid> [exp]");
	register_concmd("ctg_set_level", "CmdSetLevel", ADMIN_BAN, "<name or #userid> [level]");

	bind_pcvar_num(create_cvar("ctg_plevel_max_lvl", "30"), cvar_maxlvl);
	bind_pcvar_float(create_cvar("ctg_plevel_a", "250"), cvar_a);
	bind_pcvar_float(create_cvar("ctg_plevel_b", "50"), cvar_b);
	bind_pcvar_float(create_cvar("ctg_plevel_c", "2.0"), cvar_c);
	bind_pcvar_float(create_cvar("ctg_plevel_d", "0.5"), cvar_d);

	g_fwLevelUp = CreateMultiForward("CTG_OnPlayerLevelUp", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwLevelChange[0] = CreateMultiForward("CTG_OnPlayerLevelChange", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	g_fwLevelChange[1] = CreateMultiForward("CTG_OnPlayerLevelChange_Post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	g_fwAddExp[0] = CreateMultiForward("CTG_OnPlayerAddExp", ET_IGNORE, FP_CELL, FP_VAL_BYREF, FP_CELL);
	g_fwAddExp[1] = CreateMultiForward("CTG_OnPlayerAddExp_Post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
}

public plugin_natives()
{
	register_library("ctg_player_level");

	register_native("ctg_get_player_level", "native_get_level");
	register_native("ctg_get_player_exp", "native_get_player_exp");
	register_native("ctg_get_required_exp", "native_get_required_exp");
	register_native("ctg_set_player_level", "native_set_level");
	register_native("ctg_add_player_exp", "native_add_exp");
}

public native_get_level()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return 0;
	}

	return g_Level[id];
}

public native_get_player_exp()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return 0;
	}

	return g_Exp[id];
}

public native_get_required_exp()
{
	new level = get_param(1);
	if (level < 1 || level > cvar_maxlvl)
	{
		log_error(AMX_ERR_NATIVE, "Level (%d) out of range", level);
		return 0;
	}

	return GetRequiredExp(level);
}

public native_set_level()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return;
	}

	new level = get_param(2);
	if (level < 1 || level > cvar_maxlvl)
	{
		log_error(AMX_ERR_NATIVE, "Level (%d) out of range", level);
		return;
	}

	SetLevel(id, level);
}

public native_add_exp()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return 0;
	}

	new exp = get_param(2);
	return AddExp(id, exp, bool:get_param(3));
}

public CmdGiveExp(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	static arg[32];
	read_argv(1, arg, charsmax(arg))

	new player = cmd_target(id, arg);
	if (!player)
		return PLUGIN_HANDLED;
	
	static authid[32], authid2[32];
	get_user_authid(id, authid, charsmax(authid));
	get_user_authid(player, authid, charsmax(authid));
	read_argv(2, arg, charsmax(arg));

	new exp = str_to_num(arg);
	if (exp <= 0)
		return PLUGIN_HANDLED;
	
	log_amx("GiveExp: ^"%n<%d><%s>^" give %d exp to ^"%n<%d><%s>^"", id, get_user_userid(id), authid, exp, player, get_user_userid(player), authid2);

	AddExp(player, exp);

	console_print(id, "[LEVEL] Player ^"%n^" received %d EXP", player, exp);
	client_print_color(0, player, "^4[LEVEL] ^1ADMIN give ^4%d ^1EXP to %n", exp, player);
	return PLUGIN_HANDLED;
}

public CmdSetLevel(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	static arg[32];
	read_argv(1, arg, charsmax(arg))

	new player = cmd_target(id, arg);
	if (!player)
		return PLUGIN_HANDLED;

	static authid[32], authid2[32];
	get_user_authid(id, authid, charsmax(authid));
	get_user_authid(player, authid, charsmax(authid));
	read_argv(2, arg, charsmax(arg));

	new level = str_to_num(arg);
	if (level < 1 || level > cvar_maxlvl)
		return PLUGIN_HANDLED;

	log_amx("GiveExp: ^"%n<%d><%s>^" set %d level for ^"%n<%d><%s>^"", id, get_user_userid(id), authid, level, player, get_user_userid(player), authid2);

	SetLevel(id, level);

	console_print(id, "[LEVEL] Player ^"%n^" changed to Lv.%d", player, level);
	client_print_color(0, player, "^4[LEVEL] ^1ADMIN set ^3%n level to ^4%d", player, level);
	return PLUGIN_HANDLED;
}

public CTG_OnDbLoadPlayerData(id, const authid[])
{
	ctg_db_add_maxstep(id);

	formatex(g_Query, charsmax(g_Query), 
		"SELECT level, exp FROM player WHERE steam_id='%s' \
		AND level IS NOT NULL \
		AND exp IS NOT NULL;", authid);

	static data[50];
	copy(data, charsmax(data), authid);
	SQL_ThreadQuery(g_DbTuple, "SelectHandle", g_Query, data, sizeof data);
}

public SelectHandle(failstate, Handle:query_h, const error[], errcode, const data[], datasize)
{
	if (!CheckSqlQueryHandle(failstate, error, errcode))
		return;
	
	new id = ctg_db_get_player_id(data);
	if (!id)
		return;
	
	if (SQL_MoreResults(query_h) && SQL_NumColumns(query_h) == 2)
	{
		g_Level[id] = SQL_ReadResult(query_h, 0);
		g_Exp[id] = SQL_ReadResult(query_h, 1);
	}
	else
	{
		g_Level[id] = 1;
		g_Exp[id] = 0;
	}

	ctg_db_add_step(id);
}

public CTG_OnDbSavePlayerData(id, const authid[])
{
	ctg_db_add_maxstep(id);

	formatex(g_Query, charsmax(g_Query), 
		"UPDATE player SET level=%d, exp=%d WHERE steam_id='%s';",
		g_Level[id], g_Exp[id], authid);

	static data[50];
	copy(data, charsmax(data), authid);
	SQL_ThreadQuery(g_DbTuple, "UpdateHandle", g_Query, data, sizeof data);
}

public UpdateHandle(failstate, Handle:query_h, const error[], errcode, const data[], datasize)
{
	if (!CheckSqlQueryHandle(failstate, error, errcode))
		return;

	new id = ctg_db_get_player_id(data);
	if (id)
		ctg_db_add_step(id);
}

public client_disconnected(id)
{
	g_Level[id] = 1;
	g_Exp[id] = 0;
}

AddExp(id, exp, bool:notify=true)
{
	ExecuteForward(g_fwAddExp[0], g_fwRet, id, exp, notify);
	if (g_fwRet >= PLUGIN_HANDLED)
		return 0;

	g_Exp[id] += exp;

	new required_exp;
	new old_level = g_Level[id];

	while (g_Exp[id] >= (required_exp = GetRequiredExp(g_Level[id])) && g_Level[id] < cvar_maxlvl)
	{
		SetLevel(id, g_Level[id] + 1);
		g_Exp[id] -= required_exp;

		ExecuteForward(g_fwLevelUp, g_fwRet, id, g_Level[id]);
	}

	if (notify)
	{
		if (g_Level[id] > old_level)
		{
			client_print_color(0, print_team_blue, "^4[Level] ^1%n ^3升級至 ^4Lv.%d ^3!!", id, g_Level[id]);
		}
	}

	ExecuteForward(g_fwAddExp[1], g_fwRet, id, exp, notify);
	return g_Level[id] - old_level;
}

SetLevel(id, level)
{
	if (g_Level[id] == level)
		return;
	
	new old_level = g_Level[id];
	ExecuteForward(g_fwLevelChange[0], g_fwRet, id, old_level, level);

	if (g_fwRet >= PLUGIN_HANDLED)
		return;

	g_Level[id] = level;
	ExecuteForward(g_fwLevelChange[1], g_fwRet, id, old_level, level);
}

GetRequiredExp(level)
{
	return floatround(cvar_a + cvar_b * floatpower(float(level-1), cvar_c) * cvar_d, floatround_floor);
}