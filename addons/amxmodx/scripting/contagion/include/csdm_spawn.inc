#if defined _csdm_spawn_included
	#endinput
#endif
#define _csdm_spawn_included

forward CSDM_OnGetPlayerSpawnSpot(id);
forward CSDM_CheckSpawnSpot(id, Float:origin[3]);

native csdm_spawn(id);