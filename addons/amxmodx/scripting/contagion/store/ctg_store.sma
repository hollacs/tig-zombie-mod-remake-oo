#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <oo>
#include <oo_player_class>
#include <oo_class_human>

new Store:g_oStore;
new cvar_ammo_price;

public plugin_init()
{
	register_plugin("[CTG] Store", "0.1", "holla");

	register_clcmd("say /store", "CmdSayStore");
	register_clcmd("buyammo1", "CmdBuyAmmo1");
	register_clcmd("buyammo2", "CmdBuyAmmo2");

	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRestartRound");

	g_oStore = oo_new("ContagionStore");

	new pcvar = create_cvar("ctg_store_ammo_price", "10");
	bind_pcvar_num(pcvar, cvar_ammo_price);
}

public oo_init()
{
	oo_class("ContagionStore", "Store")
	{
		new cl[] = "ContagionStore";
		oo_mthd(cl, "GetPlayerMoney", @int(id));
		oo_mthd(cl, "SetPlayerMoney", @int(id), @int(value));
		oo_smthd(cl, "GetInstance");
	}
}

public Store:ContagionStore@GetInstance() { return g_oStore; }

public ContagionStore@GetPlayerMoney(id)
{
	return get_member(id, m_iAccount);
}

public ContagionStore@SetPlayerMoney(id, value)
{
	rg_add_account(id, value, AS_SET, true);
}

public OnRestartRound()
{
	oo_call(g_oStore, "ResetBuyCount", 0, 0);
}

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
					oo_human_get_max_bpammo(id, weapon_id)))
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