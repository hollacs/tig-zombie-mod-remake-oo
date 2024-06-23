#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <oo_player_class>
#include <oo_player_status>
#include <cs_painshock>
#include <player_rendering_layer>

public plugin_init()
{
	register_plugin("[OO] Status: Rampage", "0.1", "holla");

	oo_hook_mthd("Player", "OnKilled", "OnPlayerKilled");
	oo_hook_mthd("Player", "OnResetMaxSpeed", "OnPlayerResetMaxSpeed");
	oo_hook_mthd("Player", "OnTakeDamage", "OnPlayerTakeDamage");
	oo_hook_dtor("PlayerClass", "OnPlayerClassDtor");
}

public oo_init()
{
	oo_class("RampageStatus", "PlayerStatus")
	{
		new cl[] = "RampageStatus";
		oo_var(cl, "duration", 1); // float
		oo_var(cl, "start_time", 1); // float
		oo_var(cl, "speed", 1); // float
		oo_var(cl, "takedmg", 1); // float

		oo_ctor(cl, "Ctor", @int(player), @fl(duration), @fl(speed), @fl(takedmg));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "GetName", OO_STRING_REF, OO_CELL);
		oo_mthd(cl, "OnUpdate");

		oo_smthd(cl, "Set", @int(player), @fl(duration), @fl(speed), @fl(takedmg));
	}
}

public bool:RampageStatus@Set(id, Float:duration, Float:speed, Float:takedmg)
{
	if (oo_playerstatus_get(id, "FrozenStatus") != @null || oo_playerstatus_get(id, "RampageStatus") != @null)
		return false;

	oo_playerstatus_add(id, oo_new("RampageStatus", id, duration, speed, takedmg));
	return true;
}

public RampageStatus@Ctor(player, Float:duration, Float:speed, Float:takedmg)
{
	new this = @this;
	oo_super_ctor("PlayerStatus", player);

	oo_set(this, "duration", duration);
	oo_set(this, "start_time", get_gametime());
	oo_set(this, "speed", speed);
	oo_set(this, "takedmg", takedmg);

	SetFov(player, 110);

	render_push(player, kRenderFxGlowShell, Float:{0.0, 255.0, 0.0}, kRenderNormal, 16.0, duration, "rampage");

	RequestFrame("ResetMaxSpeed", player);
}

public RampageStatus@Dtor()
{
	new this = @this;
	new id = oo_get(this, "player_id");
	rg_reset_maxspeed(id);
	render_pop(id, -1, "rampage"); 
	SetFov(id, 90);
}

public RampageStatus@GetName(output[], len)
{
	return formatex(output, len, "Rampage");
}

public RampageStatus@OnUpdate()
{
	new this = @this;
	if (get_gametime() >= Float:oo_get(this, "start_time") + Float:oo_get(this, "duration"))
	{
		oo_call(this, "Delete");
	}
}

public CS_OnPainShock_Post(victim, inflictor, attacker, Float:damage, damagebits, &Float:value)
{
	if (oo_playerstatus_get(victim, "RampageStatus"))
	{
		value *= 0.6;
	}
}

public OnPlayerResetMaxSpeed()
{
	new id = oo_get(@this, "player_id");
	if (is_user_alive(id))
	{
		new PlayerStatus:status_o = oo_playerstatus_get(id, "RampageStatus");
		if (status_o != @null)
		{
			set_entvar(id, var_maxspeed, Float:get_entvar(id, var_maxspeed) * Float:oo_get(status_o, "speed"));
		}
	}
}

public OnPlayerTakeDamage(inflictor, attacker, &Float:damage, damagebits)
{
	new id = oo_get(@this, "player_id");
	if (inflictor == attacker && is_user_connected(attacker))
	{
		new PlayerStatus:status_o = oo_playerstatus_get(id, "RampageStatus");
		if (status_o != @null)
		{
			SetHookChainArg(4, ATYPE_FLOAT, damage * Float:oo_get(status_o, "takedmg"));
		}
	}
}

public OnPlayerKilled()
{
	new id = oo_get(@this, "player_id");
	oo_playerstatus_remove(id, "RampageStatus");
}

public OnPlayerClassDtor()
{
	new id = oo_get(@this, "player_id");
	oo_playerstatus_remove(id, "RampageStatus");
}

public ResetMaxSpeed(id)
{
	rg_reset_maxspeed(id);
}

SetFov(id, fov)
{
	static msgSetFOV;
	msgSetFOV || (msgSetFOV = get_user_msgid("SetFOV"));

	message_begin(MSG_ONE_UNRELIABLE, msgSetFOV, _, id);
	write_byte(fov);
	message_end();
}