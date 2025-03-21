#include <amxmodx>
#include <reapi>
#include <oo_player>

new GameItem:g_oItem;

public plugin_init()
{
	register_plugin("[OO] Item: Armor", "0.1", "holla");

	new Store:store_o = any:oo_call(0, "ContagionStore@GetInstance");
	g_oItem = oo_new("ItemArmor", "Armor", "+100 ap", 40, 3);
	oo_call(store_o, "AddItem", g_oItem);
}

public oo_init()
{
	oo_class("ItemArmor", "HumanItem");
	{
		new cl[] = "ItemArmor";
		oo_mthd(cl, "CanBuy", @int(id));
		oo_mthd(cl, "Use", @int(id));
	}
}

public ItemArmor@CanBuy(id)
{
	if (!oo_call(@this, "CanUse", id))
		return false;

	if (Float:get_entvar(id, var_armorvalue) >= oo_player_get_max_armor(id))
	{
		client_print_color(id, print_team_red, "^4[Store] ^3無法購買: ^1你的護甲已滿")
		return false;
	}

	return true;
}

public ItemArmor@Use(id)
{
	set_entvar(id, var_armorvalue, floatmin(Float:get_entvar(id, var_armorvalue) + 100.0, float(oo_player_get_max_armor(id))));
}