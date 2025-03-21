#include <amxmodx>
#include <oo>
#include <oo_player_class>

public plugin_init()
{
	register_plugin("[OO] Zombie Item", "0.1", "holla");
}

public oo_init()
{
	oo_class("ZombieItem", "GameItem", "StoreItem")
	{
		new cl[] = "ZombieItem";

		oo_ctor(cl, "Ctor", @str(name), @str(desc), @int(price), @int(limit));
		oo_mthd(cl, "CanUse", @int(id));
		oo_mthd(cl, "CanShowInStoreMenu", @int(id));
	}
}

public ZombieItem@Ctor(const name[], const desc[], price, limit)
{
	oo_super_ctor("GameItem", name, desc);
	oo_super_ctor("StoreItem", price, limit);
}

public ZombieItem@CanUse(id)
{
	return (is_user_alive(id) && oo_playerclass_isa(id, "Zombie") && !oo_playerclass_isa(id, "Boss"));
}

public ZombieItem@CanShowInStoreMenu(id)
{
	return (is_user_alive(id) && oo_playerclass_isa(id, "Zombie") && !oo_playerclass_isa(id, "Boss"));
}