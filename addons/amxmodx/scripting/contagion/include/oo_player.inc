#if defined _oo_player_included
	#endinput
#endif
#define _oo_player_included

#include <oo>

#define CHECK_PLAYER(%0) 	new Player:%0 = oo_player_get(id); if (%0 == @null)

native any:oo_player_get(id);
native oo_player_set(id, any:player_o);

stock any:oo_player_set_respawn(id, Float:time)
{
	CHECK_PLAYER(player_o) return;
	oo_call(player_o, "SetRespawn", time);
}

stock oo_player_reset_respawn(id)
{
	CHECK_PLAYER(player_o) return;
	oo_call(player_o, "ResetRespawn");
}

stock bool:oo_player_is_respawning(id)
{
	CHECK_PLAYER(player_o) return false;
	return bool:oo_call(player_o, "IsRespawnPending");
}

stock Float:oo_player_get_respawn_time(id)
{
	CHECK_PLAYER(player_o) return false;
	return Float:oo_call(player_o, "GetRespawnTime");
}

stock oo_player_get_max_armor(id)
{
	CHECK_PLAYER(player_o) return 0;
	return oo_get(player_o, "max_armor");
}

stock oo_player_get_max_health(id)
{
	CHECK_PLAYER(player_o) return 0;
	return oo_get(player_o, "max_health");
}

stock oo_player_set_max_armor(id, value)
{
	CHECK_PLAYER(player_o) return;
	oo_set(player_o, "max_armor", value);
}

stock oo_player_set_max_health(id, value)
{
	CHECK_PLAYER(player_o) return;
	oo_set(player_o, "max_health", value);
}