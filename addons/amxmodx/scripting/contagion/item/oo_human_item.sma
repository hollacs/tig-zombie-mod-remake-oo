#include <amxmodx>
#include <oo>
#include <oo_player_class>

public plugin_init()
{
	register_plugin("[OO] Human Item", "0.1", "holla");
}

public oo_init()
{
	oo_class("HumanItem", "GameItem", "StoreItem")
	{
		new cl[] = "HumanItem";

		oo_ctor(cl, "Ctor", @str(name), @str(desc), @int(price), @int(limit));
		oo_mthd(cl, "CanUse", @int(id));
		oo_mthd(cl, "CanShowInStoreMenu", @int(id));
	}
}

public HumanItem@Ctor(const name[], const desc[], price, limit)
{
	oo_super_ctor("GameItem", name, desc);
	oo_super_ctor("StoreItem", price, limit);
}

public HumanItem@CanUse(id)
{
	return (is_user_alive(id) && oo_playerclass_isa(id, "Human"));
}

public HumanItem@CanShowInStoreMenu(id)
{
	return (is_user_alive(id) && oo_playerclass_isa(id, "Human"));
}