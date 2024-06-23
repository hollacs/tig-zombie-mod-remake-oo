#include <amxmodx>
#include <reapi>
#include <oo>

new StoreItem:g_oItem;

public plugin_init()
{
	register_plugin("[OO] Item: Shock Nade", "0.1", "holla");

	new Store:store_o = any:oo_call(0, "ContagionStore@GetInstance");
	g_oItem = oo_new("ItemShockNade", "喪屍震撼彈", "ShockNade", 200, 3);
	oo_call(store_o, "AddItem", g_oItem);
}

public oo_init()
{
	oo_class("ItemShockNade", "ZombieItem");
	{
		new cl[] = "ItemShockNade";
		oo_mthd(cl, "CanBuy", @int(id));
		oo_mthd(cl, "Use", @int(id));
	}
}

public ItemShockNade@CanBuy(id)
{
	new this = @this;
	if (!oo_call(this, "CanUse", id))
		return false;

	if (user_has_weapon(id, CSW_HEGRENADE))
	{
		client_print_color(id, print_team_red, "^4[Store] ^3無法購買: ^1你已經擁有了");
		return false;
	}

	return true;
}

public ItemShockNade@Use(id)
{
	rg_give_item(id, "weapon_flashbang");
}