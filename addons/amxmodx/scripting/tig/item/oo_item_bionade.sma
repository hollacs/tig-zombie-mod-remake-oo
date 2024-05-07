#include <amxmodx>
#include <reapi>
#include <oo>

new StoreItem:g_oItem;

public plugin_init()
{
	register_plugin("[OO] Item: Bio", "0.1", "holla");

	new Store:store_o = any:oo_call(0, "TigStore@GetInstance");
	g_oItem = oo_new("ItemBioNade", "病毒炸彈", "Infection", 200);
	oo_call(store_o, "AddItem", g_oItem);
}

public oo_init()
{
	oo_class("ItemBioNade", "ZombieItem");
	{
		new cl[] = "ItemBioNade";
		oo_mthd(cl, "CanBuy", @int(id));
		oo_mthd(cl, "Use", @int(id));
	}
}

public ItemBioNade@CanBuy(id)
{
	new this = oo_this();
	if (!oo_call(this, "CanUse", id))
		return false;

	if (user_has_weapon(id, CSW_HEGRENADE))
	{
		client_print(id, print_chat, "[Store] 無法購買: 你已經擁有了")
		return false;
	}

	return true;
}

public ItemBioNade@Use(id)
{
	rg_give_item(id, "weapon_hegrenade");
}