#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <oo>
#include <ctg_nightvision>

new StoreItem:g_oItem;

public plugin_init()
{
	register_plugin("[OO] Item: Night Vision", "0.1", "holla");

	new Store:store_o = any:oo_call(0, "ContagionStore@GetInstance");
	g_oItem = oo_new("ItemNightVision", "夜視鏡", "(一回合)", 100, 0);
	oo_call(store_o, "AddItem", g_oItem);
}

public oo_init()
{
	oo_class("ItemNightVision", "HumanItem");
	{
		new cl[] = "ItemNightVision";
		oo_mthd(cl, "CanBuy", @int(id));
		oo_mthd(cl, "Use", @int(id));
	}
}

public ItemNightVision@CanBuy(id)
{
	new this = @this;
	if (!oo_call(this, "CanUse", id))
		return false;

	if (ctg_nightvision_get(id))
	{
		client_print_color(id, print_team_red, "^4[Store] ^3無法購買: ^1你已經有夜視鏡了");
		return false;
	}

	return true;
}

public ItemNightVision@Use(id)
{
	ctg_nightvision_set(id, true);
	ctg_nightvision_toggle(id, true);
}