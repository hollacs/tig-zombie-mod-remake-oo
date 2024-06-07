#include <amxmodx>
#include <reapi>
#include <oo_player_class>

new const PRIMARY_WEAPONS[] = {CSW_AK47, CSW_M4A1, CSW_AUG, CSW_SG552, CSW_G3SG1, CSW_SG550, CSW_M249, CSW_P90, CSW_MP5NAVY, CSW_M3, CSW_XM1014};
new const SECONDARY_WEAPONS[] = {CSW_USP, CSW_P228, CSW_GLOCK18, CSW_FIVESEVEN, CSW_ELITE};

public plugin_init()
{
	register_plugin("[CTG] BOT Weapons", "0.1", "holla");
}

public OO_OnPlayerClassSetProps(id)
{
	if (is_user_bot(id) && oo_playerclass_isa(id, "Human"))
	{
		rg_remove_all_items(id);
		
		static name[32];
		new weapon = PRIMARY_WEAPONS[random(sizeof PRIMARY_WEAPONS)];
		rg_get_weapon_info(weapon, WI_NAME, name, charsmax(name));
		rg_give_item(id, name);
		rg_set_user_bpammo(id, any:weapon, 999999);

		weapon = SECONDARY_WEAPONS[random(sizeof SECONDARY_WEAPONS)];
		rg_get_weapon_info(weapon, WI_NAME, name, charsmax(name));
		rg_give_item(id, name);
		rg_set_user_bpammo(id, any:weapon, 999999);

		if (random_num(0, 1))
			rg_give_item(id, "weapon_hegreande");
		
		if (random_num(0, 1))
			rg_give_item(id, "weapon_flashbang");

		if (random_num(0, 1))
			rg_give_item(id, "weapon_smokegrenade");
	}
}