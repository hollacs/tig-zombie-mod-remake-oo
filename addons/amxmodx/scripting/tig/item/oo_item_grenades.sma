#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <oo>

new StoreItem:g_oItem[3];

public plugin_init()
{
	register_plugin("[OO] Item: Grenades", "0.1", "holla");

	new Store:store_o = any:oo_call(0, "TigStore@GetInstance");

	g_oItem[0] = oo_new("ItemGrenade", "燃燒彈", "Fire", 50, CSW_HEGRENADE, 5);
	g_oItem[1] = oo_new("ItemGrenade", "寒冰彈", "Ice", 60, CSW_FLASHBANG, 3);
	g_oItem[2] = oo_new("ItemGrenade", "照明彈", "Light", 40, CSW_SMOKEGRENADE, 1);

	for (new i = 0; i < sizeof g_oItem; i++)
		oo_call(store_o, "AddItem", g_oItem[i]);
}

public oo_init()
{
	oo_class("ItemGrenade", "HumanItem");
	{
		new cl[] = "ItemGrenade";
		oo_var(cl, "max_carry", 1);
		oo_var(cl, "weapon_id", 1);

		oo_ctor(cl, "Ctor", @str(name), @str(desc), @int(price), @int(weapon), @int(max_carry))
		oo_mthd(cl, "CanBuy", @int(id));
		oo_mthd(cl, "Use", @int(id));
	}
}

public ItemGrenade@Ctor(const name[], const desc[], price, weapon, max_carry)
{
	new this = oo_this();
	oo_super_ctor("HumanItem", name, desc, price);
	oo_set(this, "weapon_id", weapon);
	oo_set(this, "max_carry", max_carry);
}

public ItemGrenade@CanBuy(id)
{
	new this = oo_this();
	if (!oo_call(this, "CanUse", id))
		return false;

	new weapon = oo_get(this, "weapon_id");
	if (rg_get_user_bpammo(id, WeaponIdType:weapon) >= oo_get(this, "max_carry"))
	{
		client_print(id, print_chat, "[Store] 無法購買: 你不能再攜帶更多手榴彈")
		return false;
	}

	return true;
}

public ItemGrenade@Use(id)
{
	new this = oo_this();
	new weapon = oo_get(this, "weapon_id");
	if (!user_has_weapon(id, weapon))
	{
		static name[32];
		rg_get_weapon_info(weapon, WI_NAME, name, charsmax(name));
		rg_give_item(id, name);
	}
	else if (rg_get_user_bpammo(id, _:weapon) < oo_get(this, "max_carry"))
	{
		static ammo_name[32];
		rg_get_weapon_info(weapon, WI_AMMO_NAME, ammo_name, charsmax(ammo_name));
		ExecuteHamB(Ham_GiveAmmo, id, 1, ammo_name, oo_get(this, "max_carry"));
		emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
}