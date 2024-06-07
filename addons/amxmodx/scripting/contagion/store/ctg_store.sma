#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <oo>
#include <oo_player_class>

new Store:g_oStore;
new cvar_ammo_price;

public plugin_init()
{
	register_plugin("[CTG] Store", "0.1", "holla");

	register_clcmd("say /store", "CmdSayStore");
	register_clcmd("buyammo1", "CmdBuyAmmo1");
	register_clcmd("buyammo2", "CmdBuyAmmo2");

	RegisterHookChain(RG_HandleMenu_ChooseAppearance, "OnChooseAppearance_Post", 1);

	g_oStore = oo_new("TigStore");

	new pcvar = create_cvar("ctg_store_ammo_price", "10");
	bind_pcvar_num(pcvar, cvar_ammo_price);
}

public oo_init()
{
	oo_class("TigStore", "Store")
	{
		new cl[] = "TigStore";

		//oo_ctor(cl, "Ctor")
		oo_mthd(cl, "GetMenuTitle", @int(id), @stref(title), @int(len));
		oo_mthd(cl, "CanShowMenu", @int(id));
		oo_mthd(cl, "CanBuy", @int(id), @int(item_o));
		oo_mthd(cl, "Buy", @int(id), @int(item_o));

		oo_smthd(cl, "GetInstance");
	}
}

public OnChooseAppearance_Post(id)
{
	rg_add_account(id, 10000, AS_SET);
}

public TigStore@GetMenuTitle(id, title[], len)
{
	new PlayerClass:class_o = oo_playerclass_get(id);
	if (class_o)
	{
		static class[32];
		oo_call(class_o, "GetClassName", class, charsmax(class));
		formatex(title, len, "%s Store", class);
	}
	else
	{
		oo_call(oo_this(), "Store@GetMenuTitle", id, title, len);
	}
}

public TigStore@CanShowMenu(id)
{
	if (!is_user_alive(id))
		return false;

	return true;
}

public TigStore@CanBuy(id, StoreItem:item_o)
{
	new price = oo_get(item_o, "price");
	if (get_member(id, m_iAccount) < price)
	{
		client_print_color(id, print_team_default, "^4[Store] ^1你的金錢不足 (需要 ^3$%d^1)", price);
		return false;
	}

	return true;
}

public TigStore@Buy(id, Item:item_o)
{
	if (oo_call(oo_this(), "Store@Buy", id, item_o))
	{
		new price = oo_get(item_o, "price");
		rg_add_account(id, -price, AS_ADD, true);
		
		static name[32];
		oo_get_str(item_o, "name", name, charsmax(name));
		client_print_color(id, print_team_default, "^4[Store] ^1你花費 ^3$%d ^1購買了 ^3%s", price, name);
		return true;
	}

	return false;
}

public Store:TigStore@GetInstance() { return g_oStore; }

public CmdSayStore(id)
{
	oo_call(g_oStore, "ShowMenu", id, 0, -1);
	return PLUGIN_HANDLED;
}

public CmdBuyAmmo1(id)
{
	if (!is_user_alive(id) || !oo_playerclass_isa(id, "Human"))
		return PLUGIN_HANDLED;

	BuyWeaponAmmo(id, 1);
	return PLUGIN_HANDLED;
}

public CmdBuyAmmo2(id)
{
	if (!is_user_alive(id) || !oo_playerclass_isa(id, "Human"))
		return PLUGIN_HANDLED;

	BuyWeaponAmmo(id, 2);
	return PLUGIN_HANDLED;
}

bool:BuyWeaponAmmo(id, slot)
{
	new item_ent = get_member(id, m_rgpPlayerItems, slot);
	new ammo_bits = 0;
	new money = get_member(id, m_iAccount);
	new bool:had_weapon = false;
	new bool:not_enough_money = false;
	new price = cvar_ammo_price;
	new weapon_id;
	static ammo_name[32], ammo;

	while (item_ent > 0)
	{
		new ammo_type = get_member(item_ent, m_Weapon_iPrimaryAmmoType);
		if (ammo_type > 0 && (~ammo_bits & (1 << ammo_type)))
		{
			had_weapon = true;

			if (money >= price)
			{
				weapon_id = get_member(item_ent, m_iId);
				rg_get_iteminfo(item_ent, ItemInfo_pszAmmo1, ammo_name, charsmax(ammo_name));
				ammo = get_member(id, m_rgAmmo, ammo_type);

				if (ExecuteHamB(Ham_GiveAmmo, id, 
					rg_get_weapon_info(weapon_id, WI_BUY_CLIP_SIZE), ammo_name, 
					rg_get_iteminfo(item_ent, ItemInfo_iMaxAmmo1)))
				{
					if (get_member(id, m_rgAmmo, ammo_type) > ammo)
					{
						emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

						ammo_bits |= (1 << ammo_type);
						money -= price;
					}
				}
			}
			else
			{
				not_enough_money = true;
			}
		}

		item_ent = get_member(item_ent, m_pNext);
	}

	if (!had_weapon || !ammo_bits)
		return false;

	if (not_enough_money)
	{
		client_print_color(id, print_team_default, "^4[Store] ^1你的金錢不足 (需要 ^3$%d^1)", price);
		return false;
	}

	rg_add_account(id, money, AS_SET, true);
	return true;
}