#include <amxmodx>
#include <fun>
#include <oo_player_class>
#include <oo_player_status>

public plugin_init()
{
	register_plugin("[OO] Status: Health", "0.1", "holla");

	oo_hook_mthd("Player", "OnKilled", "OnPlayerKilled");
	oo_hook_mthd("Player", "OnSpawn", "OnPlayerSpawn");
}

public oo_init()
{
	oo_class("HealthStatus", "PlayerStatus")
	{
		new cl[] = "HealthStatus";
		oo_mthd(cl, "GetName", OO_STRING_REF, OO_CELL);
	}
}

public HealthStatus@GetName(output[], len)
{
	new id = oo_get(@this, "player_id");
	if (oo_playerclass_isa(id, "Boss"))
	{
		return formatex(output, len, "B.O.W.");
	}
	else if (oo_playerclass_isa(id, "SpecialInfected"))
	{
		return formatex(output, len, "Special Infected");
	}
	else if (oo_playerclass_isa(id, "Zombie"))
	{
		return formatex(output, len, "Infected");
	}

	new health = get_user_health(id);
	new max_health = oo_player_get_max_health(id);
	if (health <= max_health * 0.25)
		return formatex(output, len, "Danger");
	else if (health <= max_health * 0.5)
		return formatex(output, len, "Caution");

	return formatex(output, len, "Fine");
}

public OnPlayerSpawn()
{
	new id = oo_get(@this, "player_id");
	oo_playerstatus_add(id, oo_new("HealthStatus", id));
}

public OnPlayerKilled()
{
	new id = oo_get(@this, "player_id");
	oo_playerstatus_remove(id, "HealthStatus");
}