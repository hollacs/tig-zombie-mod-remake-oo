#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <oo_player_class>
#include <oo_player_status>
#include <oo_zombie_mode>

public plugin_init()
{
	register_plugin("[OO] Status: Poison", "0.1", "holla");
}

public oo_init()
{
	oo_class("PoisonStatus", "SustainedDamage", "PlayerStatus");
	{
		new cl[] = "PoisonStatus";
		oo_ctor(cl, "Ctor", @int(player), @int(attacker), @fl(interval), @fl(damage), @int(times));

		oo_mthd(cl, "Death");
		oo_mthd(cl, "Damage");
		oo_mthd(cl, "GetName", @stref(output), @int(maxlen));
		oo_mthd(cl, "OnUpdate");

		oo_smthd(cl, "Add", @int(player), @int(attacker), @fl(interval), @fl(damage), @int(times));
	}
}

public PoisonStatus@Add(player, attacker, Float:interval, Float:damage, times)
{
	new PlayerStatus:status_o = oo_playerstatus_get(player, "PoisonStatus");
	if (status_o != @null)
	{
		oo_set(status_o, "attacker", attacker);
		oo_set(status_o, "interval", interval);
		oo_set(status_o, "damage", damage);
		oo_set(status_o, "count", oo_get(status_o, "count") + times);
	}
	else
	{
		oo_playerstatus_add(player, oo_new("PoisonStatus", player, attacker, interval, damage, times));
	}
}

public PoisonStatus@Ctor(player, attacker, Float:interval, Float:damage, times)
{
	oo_super_ctor("PlayerStatus", player);
	oo_super_ctor("SustainedDamage", player, attacker, interval, damage, times);
}

public PoisonStatus@OnUpdate()
{
	new this = oo_this();
	oo_call(this, "SustainedDamage@OnUpdate");
}

public PoisonStatus@Damage()
{
	new this = oo_this();
	new id = oo_get(this, "player_id");

	if (oo_call(this, "SustainedDamage@Damage"))
	{
		static msgDamage;
		msgDamage || (msgDamage = get_user_msgid("Damage"));

		message_begin(MSG_ONE_UNRELIABLE, msgDamage, _, id);
		write_byte(0); // damage save
		write_byte(0); // damage take
		write_long(DMG_NERVEGAS); // damage type - DMG_RADIATION
		write_coord(0); // x
		write_coord(0); // y
		write_coord(0); // z
		message_end();

		return true;
	}

	return false;
}

public PoisonStatus@Death()
{
	new this = oo_this();
	new id = oo_get(this, "player_id");
	new attacker = oo_get(this, "attacker");

	oo_call(this, "Delete");
	oo_infect_player(id, attacker);
}

public PoisonStatus@GetName(output[], maxlen)
{
	return formatex(output, maxlen, "Poison");
}

public OO_OnPlayerKilled(id)
{
	oo_playerstatus_remove(id, "PoisonStatus");
}

public OO_OnPlayerClassDtor(id)
{
	oo_playerstatus_remove(id, "PoisonStatus");
}