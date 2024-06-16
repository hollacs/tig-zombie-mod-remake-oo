#include <amxmodx>
#include <reapi>
#include <oo_class_human>

#define MAX_ITEMS 16

new const g_WeaponName[MAX_ITEMS][] = {"deagle", "m3", "xm1014", "mp5navy", "p90", "scout", "galil", "famas", "ak47", "m4a1", "sg552", "aug", "g3sg1", "sg550", "awp", "m249"};
new const g_WeaponCost[MAX_ITEMS] = {400, 100, 150, 100, 120, 90, 120, 120, 500, 300, 200, 220, 450, 420, 300, 350};
new StoreItem:g_oItems[MAX_ITEMS];

public plugin_init()
{
	register_plugin("[OO] Item: Weapons", "0.1", "holla");

	new Store:store_o = any:oo_call(0, "ContagionStore@GetInstance");

	static class[32], name[32];
	for (new i = 0; i < MAX_ITEMS; i++)
	{
		formatex(class, charsmax(class), "weapon_%s", g_WeaponName[i]);
		copy(name, charsmax(name), g_WeaponName[i]);
		strtoupper(name);
		g_oItems[i] = oo_new("ItemWeapon", class, name, "", g_WeaponCost[i], 0);
		oo_call(store_o, "AddItem", g_oItems[i]);
	}
}

public oo_init()
{
	oo_class("ItemWeapon", "HumanItem");
	{
		new cl[] = "ItemWeapon";
		oo_var(cl, "class", 32);
		oo_ctor(cl, "Ctor", @str(class), @str(name), @str(desc), @int(cost), @int(limit))
		oo_mthd(cl, "CanBuy", @int(id));
		oo_mthd(cl, "Use", @int(id));
	}
}

public ItemWeapon@Ctor(const class[], const name[], const desc[], cost, limit)
{
	oo_set_str(oo_this(), "class", class);
	oo_super_ctor("HumanItem", name, desc, cost, limit);
}

public ItemWeapon@CanBuy(id)
{
	new this = oo_this();
	if (!oo_call(this, "CanUse", id))
		return false;

	static class[32];
	oo_get_str(this, "class", class, sizeof class);

	new weapon_id = rg_get_weapon_info(class, WI_ID);
	if (user_has_weapon(id, weapon_id))
	{
		client_print_color(id, print_team_red, "^4[Store] ^3無法購買: ^1你已經擁有此武器");
		return false;
	}

	return true;
}

public ItemWeapon@Use(id)
{
	new this = oo_this();
	static class[32];
	oo_get_str(this, "class", class, sizeof class);

	new weapon_id = rg_get_weapon_info(class, WI_ID);
	new slot = rg_get_global_iteminfo(weapon_id, ItemInfo_iSlot) + 1;
	new maxammo = oo_human_get_max_bpammo(id, weapon_id);

	rg_drop_items_by_slot(id, any:slot);
	rg_give_item(id, class);
	rg_set_user_bpammo(id, any:weapon_id, maxammo);
}