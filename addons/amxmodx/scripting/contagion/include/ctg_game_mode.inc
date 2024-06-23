#if defined _oo_zombie_mode_included
	#endinput
#endif
#define _oo_zombie_mode_included

forward CTG_OnInfectPlayer(victim, attacker);
forward CTG_OnInfectPlayer_Post(victim, attacker);

native ctg_infect_player(id, attacker);