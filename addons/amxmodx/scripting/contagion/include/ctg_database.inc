#if defined _ctg_database_included
	#endinput
#endif
#define _ctg_database_included

forward CTG_OnDbLoadPlayerData(id, const authid[]);
forward CTG_OnDbSavePlayerData(id, const authid[]);

native ctg_db_add_step(id, amount=1);
native ctg_db_add_maxstep(id, amount=1);

native ctg_db_add_column(const table[], const column[], const code[]);

native ctg_db_get_player_id(const authid[]);

native ctg_db_load_player_data(id, bool:notify=false);
native ctg_db_save_player_data(id, bool:notify=false);

native Handle:ctg_db_get_tuple();

stock CheckSqlQueryHandle(failstate, const error[], errcode)
{
	if (failstate == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.");
	else if(failstate == TQUERY_QUERY_FAILED)
		return set_fail_state("Query failed: %s", error);
   
	if	(errcode)
		return log_amx("Error on query: %s", error);

	return 1;
}