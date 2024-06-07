#if defined _cs_painshock_included
	#endinput
#endif
#define _cs_painshock_included

forward CS_OnPainShock(victim, inflictor, attacker, Float:damage, damagebits);
forward CS_OnPainShock_Post(victim, inflictor, attacker, Float:damage, damagebits, &Float:value);

native Float:cs_painshock_get(id);
native cs_painshock_set(id, Float:value);