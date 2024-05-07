#include <amxmodx>
#include <oo>

public plugin_init()
{
	register_plugin("[OO] Store", "0.1", "holla");
}

public oo_init()
{
	oo_class("StoreItem")
	{
		new cl[] = "StoreItem";
		oo_var(cl, "price", 1);

		oo_ctor(cl, "Ctor", @int(price));

		oo_mthd(cl, "CanShowInStoreMenu", @int(id));
		oo_mthd(cl, "CanBuy", @int(id));
		oo_mthd(cl, "CanUse", @int(id));
		oo_mthd(cl, "Buy", @int(id));
		oo_mthd(cl, "Use", @int(id));

		oo_mthd(cl, "GetName", @stref(name), @int(maxlen));
		oo_mthd(cl, "GetDesc", @stref(name), @int(maxlen));
		oo_mthd(cl, "GetStoreMenuItemName", @int(id), @stref(name), @int(len));	
	}

	oo_class("Store")
	{
		new cl[] = "Store";
		oo_var(cl, "items", 1); // Array:

		oo_ctor(cl, "Ctor");
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "AddItem", @obj(item));
		oo_mthd(cl, "CanShowMenu", @int(id));
		oo_mthd(cl, "CanBuy", @int(id), @obj(item_o));
		oo_mthd(cl, "GetMenuTitle", @int(id), @stref(title), @int(len));
		oo_mthd(cl, "CreateMenu", @str(title), @str(handler), @int(ml));
		oo_mthd(cl, "GetMenuItemName", @int(id), @obj(item_o), @stref(name), @int(len));
		oo_mthd(cl, "ShowMenu", @int(id), @int(page), @int(time));
		oo_mthd(cl, "MenuHandler", @int(id), @int(menu), @int(item), @obj(item_o));
		oo_mthd(cl, "Buy", @int(id), @obj(item_o));
	}
}

public StoreItem@Ctor(price)
{
	new this = oo_this();
	oo_set(this, "price", price);
}

public StoreItem@Dtor() {}

public StoreItem@GetStoreMenuItemName(id, dest[], maxlen)
{
	new this = oo_this();

	static name[32], desc[32];
	oo_call(this, "GetName", name, charsmax(name));
	oo_call(this, "GetDesc", desc, charsmax(desc));

	formatex(dest, maxlen, "%s \d%s \y$%d", name, desc, oo_get(this, "price"));
}

public StoreItem@CanShowInStoreMenu(id)
{
	return true;
}

public StoreItem@CanBuy(id)
{
	return oo_call(oo_this(), "CanUse", id);
}

public StoreItem@Buy(id)
{
	oo_call(oo_this(), "Use", id);
}

public StoreItem@GetName(name[], maxlen) { }
public StoreItem@GetDesc(name[], maxlen) { }
public StoreItem@CanUse(id) {}
public StoreItem@Use(id) {}

public Store@Ctor()
{
	oo_set(oo_this(), "items", ArrayCreate());
}

public Store@Dtor()
{
	new Array:items_a = Array:oo_get(oo_this(), "items");
	ArrayDestroy(items_a);
}

public Store@AddItem(StoreItem:item_o)
{
	new Array:items_a = Array:oo_get(oo_this(), "items");
	ArrayPushCell(items_a, item_o);
}

public Store@CanShowMenu(id)
{
	return true;
}

public Store@GetMenuTitle(id, title[], len)
{
	formatex(title, len, "Store");
}

public Store@CreateMenu(const title[], const handler[], ml)
{
	return menu_create(title, handler, ml);
}

public Store@GetMenuItemName(id, StoreItem:item_o, buffer[], len)
{
	oo_call(item_o, "GetStoreMenuItemName", id, buffer, len);
}

public Store@ShowMenu(id, page, time)
{
	new this = oo_this();
	if (!oo_call(this, "CanShowMenu", id))
		return -1;

	new menu, Array:items_a, items_num, StoreItem:item_o;
	static buffer[64], info[32];

	oo_call(this, "GetMenuTitle", id, buffer, charsmax(buffer));
	menu = oo_call(this, "CreateMenu", buffer, "StoreHandler", 1);
	items_a = Array:oo_get(this, "items");
	items_num = ArraySize(items_a);

	for (new i = 0; i < items_num; i++)
	{
		buffer[0] = '^0';
		item_o = any:ArrayGetCell(items_a, i);

		if (!oo_call(item_o, "CanShowInStoreMenu", id))
			continue;

		formatex(info, charsmax(info), "%d %d", this, item_o);
		oo_call(this, "GetMenuItemName", id, item_o, buffer, charsmax(buffer));
		menu_additem(menu, buffer, info);
	}

	if (menu_items(menu) < 1)
	{
		menu_destroy(menu);
		return -1;
	}

	menu_display(id, menu, page, time);
	return menu;
}

public Store@MenuHandler(id, menu, item, StoreItem:item_o)
{
	new this = oo_this();
	if (!oo_call(this, "CanShowMenu", id))
		return;

	if (!oo_call(item_o, "CanBuy", id))
		return;

	oo_call(this, "Buy", id, item_o);
}

public Store@CanBuy(id, StoreItem:item_o)
{
	return true;
}

public Store@Buy(id, StoreItem:item_o)
{
	if (!oo_call(oo_this(), "CanBuy", id, item_o))
		return false;

	oo_call(item_o, "Buy", id);
	return true;
}

public StoreHandler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	static info[32], args[2][16];
	menu_item_getinfo(menu, item, _, info, charsmax(info));
	parse(info, args[0], charsmax(args[]), args[1], charsmax(args[]));

	new Store:store_o = any:str_to_num(args[0]);
	if (oo_object_exists(store_o))
	{
		new StoreItem:item_o = any:str_to_num(args[1]);
		oo_call(store_o, "MenuHandler", id, menu, item, item_o);
	}

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}