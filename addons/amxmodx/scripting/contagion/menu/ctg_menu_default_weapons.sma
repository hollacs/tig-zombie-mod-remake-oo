#include <amxmodx>
#include <reapi>
#include <oo_player_class>

new g_HasChosen[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("[CTG] Menu: Default Weapons", "0.1", "holla");
}

public OO_OnPlayerClassSetProps(id, bool:set_team)
{
	if (oo_playerclass_isa(id, "Human"))
	{
		g_HasChosen[id] = 0;
		ShowWeaponMenu(id, 1);
	}
}

public ShowWeaponMenu(id, slot)
{
	new PlayerClass:class_o = any:oo_playerclass_get(id);
	if (!oo_isa(class_o, "Human") || !is_user_alive(id))
		return;
	
	static menu, str[128]; str[0] = 0;
	new pcvar = oo_call(class_o, "GetCvarPtr", slot == 1 ? "pri_guns" : slot == 2 ? "sec_guns" : "nades");
	if (pcvar)
		get_pcvar_string(pcvar, str, charsmax(str));

	if (!str[0] || g_HasChosen[id] >= slot)
	{
		if (g_HasChosen[id] < 2)
		{
			g_HasChosen[id]++;
			ShowWeaponMenu(id, slot + 1); // show next one
		}

		return;
	}

	if (slot < 3) // not nades?
	{
		static title[32];
		formatex(title, charsmax(title), "%s", slot == 1 ? "Choose a Primary Weapon" : "Choose a Pistol")
		menu = menu_create(title, "HandleWeaponMenu");
	}

	static weapon_name[32], class_name[32], name[32], info[64], weapon_id;
	oo_get_classname(class_o, class_name, charsmax(class_name));
	new count = 0;

	while (argbreak(str, name, charsmax(name), str, charsmax(str)) != -1)
	{
		format(weapon_name, charsmax(weapon_name), "weapon_%s", name);
		weapon_id = get_weaponid(weapon_name);
		if (!weapon_id)
			continue;

		if (slot == 3) // nades
		{
			rg_give_item(id, weapon_name);
			return;
		}

		if (count == 0 && !str[0])
		{
			GiveWeapon(id, slot, weapon_name);
			g_HasChosen[id]++;
			ShowWeaponMenu(id, slot + 1);
			return;
		}

		mb_strtoupper(name, charsmax(name));
		formatex(info, charsmax(info), "%s %s", class_name, weapon_name);
		menu_additem(menu, name, info);
		count++;
	}

	menu_display(id, menu);

	if (is_user_bot(id))
	{
		HandleWeaponMenu(id, menu, random(menu_items(menu)));
	}
}

public HandleWeaponMenu(id, menu, item)
{
	if (item == MENU_EXIT || g_HasChosen[id] >= 2 || !is_user_alive(id))
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	static info[64];
	menu_item_getinfo(menu, item, _, info, charsmax(info));
	menu_destroy(menu);

	static class_name[32], weapon_name[32];
	parse(info, class_name, charsmax(class_name), weapon_name, charsmax(weapon_name));

	if (!oo_playerclass_isa(id, class_name, false))
		return PLUGIN_HANDLED;
	
	g_HasChosen[id]++;
	GiveWeapon(id, g_HasChosen[id], weapon_name);
	ShowWeaponMenu(id, g_HasChosen[id] + 1);
	return PLUGIN_HANDLED;
}

GiveWeapon(id, slot, const weapon_name[])
{
	rg_drop_items_by_slot(id, any:slot);

	new ent = rg_give_item(id, weapon_name);
	if (ent)
	{
		new weapon_id = rg_get_weapon_info(weapon_name, WI_ID);
		new ammo = rg_get_iteminfo(ent, ItemInfo_iMaxAmmo1);
		rg_set_user_bpammo(id, any:weapon_id, ammo);
	}
}