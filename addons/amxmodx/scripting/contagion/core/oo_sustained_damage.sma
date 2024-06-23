#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <oo_player_class>

public plugin_init()
{
	register_plugin("[OO] Sustained Damage", "0.1", "holla");
}

public oo_init()
{
	oo_class("SustainedDamage")
	{
		new cl[] = "SustainedDamage";
		oo_var(cl, "player_id", 1); // int
		oo_var(cl, "attacker", 1); // int
		oo_var(cl, "interval", 1); // float
		oo_var(cl, "damage", 1); // float
		oo_var(cl, "count", 1); // int
		oo_var(cl, "next_hurt_time", 1); // float
		oo_var(cl, "killme", 1);

		oo_ctor(cl, "Ctor", @int(player), @int(attacker), @fl(interval), @fl(damage), @int(times));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "OnUpdate");
		oo_mthd(cl, "Damage");
		oo_mthd(cl, "Death");
		oo_mthd(cl, "Delete");
	}
}

public SustainedDamage@Ctor(player, attacker, Float:interval, Float:damage, times)
{
	new this = @this;
	oo_set(this, "player_id", player);
	oo_set(this, "attacker", attacker);
	oo_set(this, "interval", interval);
	oo_set(this, "damage", damage);
	oo_set(this, "count", times);
	oo_set(this, "next_hurt_time", get_gametime() + interval);
	oo_set(this, "killme", false);
}

public SustainedDamage@Dtor() {}

public SustainedDamage@OnUpdate()
{
	new this = @this;
	if (oo_get(this, "killme"))
	{
		//server_print("kill me");
		oo_call(this, "Delete");
		return;
	}

	new Float:current_time = get_gametime();
	if (current_time >= Float:oo_get(this, "next_hurt_time"))
	{
		new count = oo_get(this, "count");
		if (count <= 0)
		{
			oo_set(this, "killme", true);
			return;
		}

		if (!oo_call(this, "Damage"))
		{
			return;
		}
		
		oo_set(this, "count", count - 1);
		oo_set(this, "next_hurt_time", current_time + Float:oo_get(this, "interval"));
	}
}

public SustainedDamage@Damage()
{
	new this = @this;
	new id = oo_get(this, "player_id");

	new Float:damage = Float:oo_get(this, "damage");
	new Float:health = Float:get_entvar(id, var_health);
	if (health <= damage)
	{
		oo_call(this, "Death");
		return false;
	}

	set_entvar(id, var_health, health - damage);
	return true;
}

public SustainedDamage@Death()
{
	new this = @this;
	new id = oo_get(this, "player_id");
	new attacker = oo_get(this, "attacker");

	oo_set(this, "killme", true);
	ExecuteHamB(Ham_Killed, id, attacker, 0);
}

public SustainedDamage@Delete() {}