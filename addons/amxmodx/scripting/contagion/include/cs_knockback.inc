#if defined _cs_knockback_included
	#endinput
#endif
#define _cs_knockback_included

forward CS_OnKnockBack(victim, attacker, Float:damage, tr);
forward CS_OnKnockBack_Post(victim, attacker, Float:damage, tr, Float:vec[3]);