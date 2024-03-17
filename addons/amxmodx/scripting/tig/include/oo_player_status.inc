#if defined _oo_player_status_included
	#endinput
#endif
#define _oo_player_status_included

native oo_playerstatus_add(id, any:status_o);
native oo_playerstatus_remove(id, const class[], bool:delete=true);
native oo_playerstatus_delete(id, any:status_o);
native oo_playerstatus_str(id, output[], maxlen);
native any:oo_playerstatus_get(id, const class[]);