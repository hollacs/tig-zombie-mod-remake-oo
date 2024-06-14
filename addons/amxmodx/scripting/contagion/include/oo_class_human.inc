#if defined _oo_class_human_included
	#endinput
#endif
#define _oo_class_human_included

#include <reapi>
#include <oo_player_class>

stock oo_human_get_max_bpammo(id, weapon)
{
	new PlayerClass:class_o = oo_playerclass_get(id);
	if (class_o == @null || !oo_isa(class_o, "Human"))
		return rg_get_global_iteminfo(weapon, ItemInfo_iMaxAmmo1);

	return oo_call(class_o, "GetWeaponMaxBpAmmo", weapon);
}