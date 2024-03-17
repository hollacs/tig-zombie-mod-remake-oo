#if defined _oo_game_mode_included
	#endinput
#endif
#define _oo_game_mode_included

#include <oo>

native any:oo_gamemode_get();
native oo_gamemode_set(any:mode_o);

stock oo_gamemode_isa(const class[], bool:super=true)
{
	new GameMode:mode_o = oo_gamemode_get();
	if (mode_o == @null)
		return !class[0];

	return oo_isa(mode_o, class, super);
}