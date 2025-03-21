#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <oo_class_human>

new StoreItem:g_oItem[3];

public plugin_init()
{
	register_plugin("[OO] Item: Grenades", "0.1", "holla");

	new Store:store_o = any:oo_call(0, "ContagionStore@GetInstance");

	g_oItem[0] = oo_new("ItemGrenade", "燃燒彈", "Fire", 50, 4, CSW_HEGRENADE);
	g_oItem[1] = oo_new("ItemGrenade", "寒冰彈", "Ice", 60, 4, CSW_FLASHBANG);
	g_oItem[2] = oo_new("ItemGrenade", "照明彈", "Light", 40, 4, CSW_SMOKEGRENADE);

	for (new i = 0; i < sizeof g_oItem; i++)
		oo_call(store_o, "AddItem", g_oItem[i]);
}

public oo_init()
{
	oo_class("ItemGrenade", "HumanItem");
	{
		new cl[] = "ItemGrenade";
		oo_var(cl, "weapon_id", 1);

		oo_ctor(cl, "Ctor", @str(name), @str(desc), @int(price), @int(limit), @int(weapon))
		oo_mthd(cl, "CanBuy", @int(id));
		oo_mthd(cl, "Use", @int(id));
	}
}

public ItemGrenade@Ctor(const name[], const desc[], price, limit, weapon)
{
	new this = @this;
	oo_super_ctor("HumanItem", name, desc, price, limit);
	oo_set(this, "weapon_id", weapon);
}

public ItemGrenade@CanBuy(id)
{
	new this = @this;
	if (!oo_call(this, "CanUse", id))
		return false;

	new weapon = oo_get(this, "weapon_id");
	if (rg_get_user_bpammo(id, any:weapon) >= oo_human_get_max_bpammo(id, weapon))
	{
		client_print_color(id, print_team_red, "^4[Store] ^3無法購買: ^1你不能再攜帶更多手榴彈")
		return false;
	}

	return true;
}

public ItemGrenade@Use(id)
{
	new this = @this;
	new weapon = oo_get(this, "weapon_id");
	if (!user_has_weapon(id, weapon))
	{
		static name[32];
		rg_get_weapon_info(weapon, WI_NAME, name, charsmax(name));
		rg_give_item(id, name);
		return;
	}

	new max_ammo = oo_human_get_max_bpammo(id, weapon);
	if (rg_get_user_bpammo(id, any:weapon) < max_ammo)
	{
		static ammo_name[32];
		GetAmmoName(weapon, ammo_name, charsmax(ammo_name));
		ExecuteHamB(Ham_GiveAmmo, id, 1, ammo_name, max_ammo);
		emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
}

GetAmmoName(weapon, output[], maxlen)
{
	switch (weapon)
	{
		case CSW_HEGRENADE:
			copy(output, maxlen, "HEGrenade");
		case CSW_FLASHBANG:
			copy(output, maxlen, "Flashbang");
		case CSW_SMOKEGRENADE:
			copy(output, maxlen, "SmokeGrenade");
	}
}