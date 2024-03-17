#if defined _oo_player_class_included
	#endinput
#endif
#define _oo_player_class_included

#include <oo_player>

forward OO_OnPlayerClassCtor(id);
forward OO_OnPlayerClassDtor(id);
forward OO_OnPlayerClassSetProps(id, bool:set_team);
forward OO_OnPlayerClassChange(id, const class[], bool:set_props);
forward OO_OnPlayerClassChange_Post(id, const class[], bool:set_props);

native oo_playerclass_set(id, PlayerClass:class_o);
native any:oo_playerclass_get(id);
native any:oo_playerclass_change(id, const class_name[], bool:set_props=true);

stock bool:oo_playerclass_isa(id, const class_name[], bool:super=true)
{
	new PlayerClass:class_o = oo_playerclass_get(id);
	if (class_o == @null) return false;
	
	return oo_isa(class_o, class_name, super);
}