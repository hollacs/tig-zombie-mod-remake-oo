#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <oo>
#include <tig_nightvision>

new StoreItem:g_oItem;

public plugin_init()
{
	register_plugin("[OO] Item: Night Vision", "0.1", "holla");

	new Store:store_o = any:oo_call(0, "TigStore@GetInstance");
	g_oItem = oo_new("ItemNightVision", "夜視鏡", "(一回合)", 100);
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
	new this = oo_this();
	if (!oo_call(this, "CanUse", id))
		return false;

	if (tig_nightvision_get(id))
	{
		client_print_color(id, print_team_default, "^4[Store] 無法購買: 你已經有夜視鏡了");
		return false;
	}

	return true;
}

public ItemNightVision@Use(id)
{
	tig_nightvision_set(id, true);
	tig_nightvision_toggle(id, true);
}