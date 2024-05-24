#include <amxmodx>
#include <oo>

public plugin_init()
{
	register_plugin("[OO] Game Item", "0.1", "holla");
}

public oo_init()
{
	oo_class("GameItem")
	{
		new cl[] = "GameItem";
		oo_var(cl, "name", 32);
		oo_var(cl, "desc", 32);

		oo_ctor(cl, "Ctor", @str(name), @str(desc));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "CanUse", @int(id));
		oo_mthd(cl, "Use", @int(id));

		oo_mthd(cl, "GetName", @stref(name), @int(maxlen));
		oo_mthd(cl, "GetDesc", @stref(name), @int(maxlen));
	}
}

public GameItem@Ctor(const name[], const desc[])
{
	new this = oo_this();
	oo_set_str(this, "name", name);
	oo_set_str(this, "desc", desc);
}

public GameItem@Dtor() {}

public GameItem@CanUse()
{
	return true;
}

public GameItem@Use() {}

public GameItem@GetName(name[], maxlen)
{
	oo_get_str(oo_this(), "name", name, maxlen);
}

public GameItem@GetDesc(name[], maxlen)
{
	oo_get_str(oo_this(), "desc", name, maxlen);
}