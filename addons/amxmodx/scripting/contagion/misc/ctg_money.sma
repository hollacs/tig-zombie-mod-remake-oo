#include <amxmodx>
#include <reapi>
#include <sqlx>
#include <ctg_database>

new Handle:g_DbTuple;
new g_Query[256];

new cvar_startmoney;

public plugin_init()
{
	register_plugin("[CTG] Money", "0.1", "holla");

	g_DbTuple = ctg_db_get_tuple();

	ctg_db_add_column("player", "money", "INTEGER NULL");

	bind_pcvar_num(create_cvar("ctg_start_money", "2000"), cvar_startmoney);
}

public CTG_OnDbLoadPlayerData(id, const authid[])
{
	ctg_db_add_maxstep(id);

	formatex(g_Query, charsmax(g_Query), 
		"SELECT money FROM player WHERE steam_id='%s' AND money IS NOT NULL;", authid);

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
	
	if (SQL_MoreResults(query_h) && SQL_NumColumns(query_h) == 1)
	{
		new money = SQL_ReadResult(query_h, 0);
		rg_add_account(id, money, AS_SET);

		ctg_db_add_step(id);
	}
	else
	{
		rg_add_account(id, cvar_startmoney, AS_SET);
	}
}

public CTG_OnDbSavePlayerData(id, const authid[])
{
	ctg_db_add_maxstep(id);

	formatex(g_Query, charsmax(g_Query), 
		"UPDATE player SET money=%d WHERE steam_id='%s';",
		get_member(id, m_iAccount), authid);

	static data[50];
	copy(data, charsmax(data), authid);
	SQL_ThreadQuery(g_DbTuple, "UpdateHandle", g_Query, data, sizeof data);
}

public UpdateHandle(failstate, Handle:query_h, const error[], errcode, const data[], datasize)
{
	if (!CheckSqlQueryHandle(failstate, error, errcode))
		return;

	if (SQL_AffectedRows(query_h) == 1)
	{
		new id = ctg_db_get_player_id(data);
		if (id)
			ctg_db_add_step(id);
	}
}