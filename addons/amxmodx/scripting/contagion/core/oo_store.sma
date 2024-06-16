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
		oo_var(cl, "limit", 1);

		oo_ctor(cl, "Ctor", @int(price), @int(limit));

		oo_mthd(cl, "CanShowInStoreMenu", @int(id));
		oo_mthd(cl, "CanBuy", @int(id));
		oo_mthd(cl, "CanUse", @int(id));
		oo_mthd(cl, "Buy", @int(id));
		oo_mthd(cl, "Use", @int(id));

		oo_mthd(cl, "GetName", @stref(name), @int(maxlen));
		oo_mthd(cl, "GetDesc", @stref(name), @int(maxlen));
		oo_mthd(cl, "GetLimit");
		oo_mthd(cl, "GetPrice");
		oo_mthd(cl, "GetStoreMenuItemName", @int(id), @stref(name), @int(len));	
	}

	oo_class("Store")
	{
		new cl[] = "Store";
		oo_var(cl, "items", 1); // Array:
		oo_var(cl, "buy_count", MAX_PLAYERS + 1); // Trie:

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
		oo_mthd(cl, "ResetBuyCount", @int(id), @obj(item_o));
		oo_mthd(cl, "GetItemLimit", @int(id), @obj(item_o));
		oo_mthd(cl, "GetItemPrice", @int(id), @obj(item_o));
		oo_mthd(cl, "GetBuyCount", @int(id), @obj(item_o));
		oo_mthd(cl, "SetBuyCount", @int(id), @obj(item_o), @int(count));
		oo_mthd(cl, "GetPlayerMoney", @int(id));
		oo_mthd(cl, "SetPlayerMoney", @int(id), @int(value));
	}
}

public StoreItem@Ctor(price, limit)
{
	new this = oo_this();
	oo_set(this, "price", price);
	oo_set(this, "limit", limit);
}

public StoreItem@Dtor() {}

public StoreItem@GetStoreMenuItemName(id, dest[], maxlen)
{
	return false;
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

public StoreItem@GetLimit()
{
	return oo_get(oo_this(), "limit");
}

public StoreItem@GetPrice()
{
	return oo_get(oo_this(), "price");
}

public StoreItem@GetName(name[], maxlen) { }
public StoreItem@GetDesc(name[], maxlen) { }
public StoreItem@CanUse(id) {}
public StoreItem@Use(id) {}

public Store@Ctor()
{
	new this = oo_this();
	oo_set(this, "items", ArrayCreate());

	new Trie:t;
	for (new i = 1; i <= MaxClients; i++)
	{
		t = TrieCreate();
		oo_set(this, "buy_count", i, i+1, t, 0, 1);
	}
}

public Store@Dtor()
{
	new this = oo_this();

	new Array:items_a = Array:oo_get(oo_this(), "items");
	ArrayDestroy(items_a);

	new Trie:t;
	for (new i = 1; i <= MaxClients; i++)
	{
		oo_set(this, "buy_count", i, i+1, t, 0, 1);
		TrieDestroy(t);
	}
}

public Store@GetItemLimit(id, StoreItem:item_o)
{
	return oo_call(item_o, "GetLimit");
}

public Store@GetItemPrice(id, StoreItem:item_o)
{
	return oo_call(item_o, "GetPrice");
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

public Store@CreateMenu(const title[], const handler[], bool:ml)
{
	return menu_create(title, handler, ml);
}

public Store@GetMenuItemName(id, StoreItem:item_o, buffer[], len)
{
	if (oo_call(item_o, "GetStoreMenuItemName", id, buffer, len))
		return;

	new this = oo_this();
	
	static name[32], desc[32], limit, price;
	oo_call(item_o, "GetName", name, charsmax(name));
	oo_call(item_o, "GetDesc", desc, charsmax(desc));
	limit = oo_call(this, "GetItemLimit", id, item_o);
	price = oo_call(this, "GetItemPrice", id, item_o);

	if (limit > 0)
	{
		new count = oo_call(this, "GetBuyCount", id, item_o);
		formatex(buffer, len, "%s \d%s \y$%d \r(%d/%d)", name, desc, price, count, limit);
	}
	else
		formatex(buffer, len, "%s \d%s \y$%d", name, desc, price);
}

public Store@GetPlayerMoney(id) {}
public Store@SetPlayerMoney(id, money) {}

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
	new this = oo_this();

	new price = oo_call(this, "GetItemPrice", id, item_o);
	if (oo_call(this, "GetPlayerMoney", id) < price)
	{
		client_print_color(id, print_team_red, "^4[Store] ^3無法購買: ^1金錢不足 ^1(需要 ^3$%d^1)", price);
		return false;
	}

	new limit = oo_call(this, "GetItemLimit", id, item_o);
	if (limit > 0 && oo_call(this, "GetBuyCount", id, item_o) >= limit)
	{
		client_print_color(id, print_team_red, "^4[Store] ^3無法購買: ^1超出購買數量限制 (%d/%d)", limit, limit);
		return false;
	}

	return true;
}

public Store@Buy(id, StoreItem:item_o)
{
	new this = oo_this();
	if (!oo_call(this, "CanBuy", id, item_o))
		return false;

	oo_call(item_o, "Buy", id);

	if (oo_call(this, "GetItemLimit", id, item_o) > 0)
	{
		oo_call(this, "SetBuyCount", id, item_o, oo_call(this, "GetBuyCount", id, item_o) + 1);
	}

	new price = oo_call(this, "GetItemPrice", id, item_o);
	oo_call(this, "SetPlayerMoney", id, oo_call(this, "GetPlayerMoney", id) - price);

	static name[32];
	oo_call(item_o, "GetName", name, charsmax(name));

	client_print_color(id, print_team_blue, "^4[Store] ^1你花費 ^3$%d ^1購買了 ^3%s", price, name);
	return true;
}

public Store@GetBuyCount(id, StoreItem:item_o)
{
	new this = oo_this();

	new Trie:t;
	oo_get(this, "buy_count", id, id+1, t, 0, 1);

	static key[16];
	num_to_str(_:item_o, key, charsmax(key));

	new count;
	if (TrieGetCell(t, key, count))
		return count;
	
	return 0;
}

public Store@SetBuyCount(id, StoreItem:item_o, count)
{
	new this = oo_this();

	new Trie:t;
	oo_get(this, "buy_count", id, id+1, t, 0, 1);

	static key[16];
	num_to_str(_:item_o, key, charsmax(key));

	TrieSetCell(t, key, count);
}

public Store@ResetBuyCount(id, StoreItem:item_o)
{
	new this = oo_this();

	static key[16], Trie:t;
	num_to_str(_:item_o, key, charsmax(key));

	if (id == 0)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			oo_get(this, "buy_count", i, i+1, t, 0, 1);

			if (item_o == @null)
			{
				TrieClear(t);
				continue;
			}

			TrieDeleteKey(t, key);
		}

		return;
	}

	oo_get(this, "buy_count", id, id+1, t, 0, 1);

	if (item_o == @null)
	{
		TrieClear(t);
		return;
	}

	TrieDeleteKey(t, key);
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