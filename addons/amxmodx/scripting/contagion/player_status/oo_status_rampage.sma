#include <amxmodx>
#include <reapi>
#include <oo_player_class>
#include <oo_player_status>
#include <cs_painshock>

enum _:Render_e
{
	RenderMode,
	RenderFx,
	Float:RenderColor[3],
	Float:RenderAmt
};

public plugin_init()
{
	register_plugin("[OO] Status: Rampage", "0.1", "holla");
}

public oo_init()
{
	oo_class("RampageStatus", "PlayerStatus")
	{
		new cl[] = "RampageStatus";
		oo_var(cl, "render", Render_e);
		oo_var(cl, "duration", 1); // float
		oo_var(cl, "start_time", 1); // float
		oo_var(cl, "speed", 1); // float
		oo_var(cl, "takedmg", 1); // float

		oo_ctor(cl, "Ctor", @int(player), @fl(duration), @fl(speed), @fl(takedmg));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "GetName", @stringex, @cell);
		oo_mthd(cl, "SetRendering");
		oo_mthd(cl, "ResetRendering");
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
	new this = oo_this();
	oo_super_ctor("PlayerStatus", player);

	oo_set(this, "duration", duration);
	oo_set(this, "start_time", get_gametime());
	oo_set(this, "speed", speed);
	oo_set(this, "takedmg", takedmg);

	static render[Render_e];
	render[RenderMode] = get_entvar(player, var_rendermode);
	render[RenderFx] = get_entvar(player, var_renderfx);
	get_entvar(player, var_rendercolor, render[RenderColor]);
	render[RenderAmt] = Float:get_entvar(player, var_renderamt);
	oo_set_arr(this, "render", render);

	oo_call(this, "SetRendering");
	SetFov(player, 100);

	RequestFrame("ResetMaxSpeed", player);
}

public RampageStatus@Dtor()
{
	new this = oo_this();
	new id = oo_get(this, "player_id");
	rg_reset_maxspeed(id);
	oo_call(this, "ResetRendering");
	SetFov(id, 90);
}

public RampageStatus@GetName(output[], len)
{
	return formatex(output, len, "Rampage");
}

public RampageStatus@SetRendering()
{
	new this = oo_this();
	new id = oo_get(this, "player_id");
	set_entvar(id, var_renderfx, kRenderFxGlowShell);
	set_entvar(id, var_rendermode, kRenderNormal);
	set_entvar(id, var_renderamt, 16.0);
	set_entvar(id, var_rendercolor, Float:{0.0, 200.0, 0.0});
}

public RampageStatus@ResetRendering()
{
	new this = oo_this();
	new id = oo_get(this, "player_id");

	static render[Render_e];
	oo_get_arr(this, "render", render);

	set_entvar(id, var_renderfx, render[RenderFx]);
	set_entvar(id, var_rendermode, render[RenderMode]);
	set_entvar(id, var_renderamt, render[RenderAmt]);
	set_entvar(id, var_rendercolor, render[RenderColor]);
}

public RampageStatus@OnUpdate()
{
	new this = oo_this();
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

public OO_OnPlayerResetMaxSpeed(id)
{
	if (is_user_alive(id))
	{
		new PlayerStatus:status_o = oo_playerstatus_get(id, "RampageStatus");
		if (status_o != @null)
		{
			set_entvar(id, var_maxspeed, Float:get_entvar(id, var_maxspeed) * Float:oo_get(status_o, "speed"));
		}
	}
}

public OO_OnPlayerTakeDamage(id, inflictor, attacker, Float:damage, damagebits)
{
	if (inflictor == attacker && is_user_connected(attacker))
	{
		new PlayerStatus:status_o = oo_playerstatus_get(id, "RampageStatus");
		if (status_o != @null)
		{
			SetHookChainArg(4, ATYPE_FLOAT, damage * Float:oo_get(status_o, "takedmg"));
		}
	}
}

public OO_OnPlayerKilled(id)
{
	oo_playerstatus_remove(id, "RampageStatus");
}

public OO_OnPlayerClassDtor(id)
{
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