#include <amxmodx>
#include <reapi>
#include <oo_player_class>

new StoreItem:g_oItem;

public plugin_init()
{
	register_plugin("[OO] Item: Medkit", "0.1", "holla");

	new Store:store_o = any:oo_call(0, "ContagionStore@GetInstance");
	g_oItem = oo_new("ItemMedkit", "First Aid Kit", "+100 hp", 50, 3);
	oo_call(store_o, "AddItem", g_oItem);
}

public oo_init()
{
	oo_class("ItemMedkit", "HumanItem");
	{
		new cl[] = "ItemMedkit";
		oo_mthd(cl, "CanBuy", @int(id));
		oo_mthd(cl, "Use", @int(id));
	}
}

public ItemMedkit@CanBuy(id)
{
	if (!oo_call(@this, "CanUse", id))
		return false;

	if (get_entvar(id, var_health) >= float(oo_player_get_max_health(id)))
	{
		client_print_color(id, print_team_red, "^4[Store] ^3無法購買: ^1你的血量已滿")
		return false;
	}

	return true;
}

public ItemMedkit@Use(id)
{
	set_entvar(id, var_health, floatmin(Float:get_entvar(id, var_health) + 100.0, float(oo_player_get_max_health(id))));
}