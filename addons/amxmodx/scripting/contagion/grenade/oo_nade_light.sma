#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <reapi>
#include <oo_player_class>
#include <oo_assets>

new GrenadeInfo:g_oGrenadeInfo;

new sprite_trail;
new cvar_radius, cvar_duration, cvar_color[3];

public oo_init()
{
	oo_class("LightNadeInfo", "GrenadeInfo")
	{
		new cl[] = "LightNadeInfo";
		oo_mthd(cl, "Condition", @int(ent), @str(class));
	}

	oo_class("LightNade", "Grenade")
	{
		new cl[] = "LightNade";
		oo_dtor(cl, "Dtor");
		oo_mthd(cl, "Think");
		oo_mthd(cl, "GetInfo");
		oo_mthd(cl, "SetWorldModel");
	}
}

public plugin_precache()
{
	g_oGrenadeInfo = oo_new("LightNadeInfo", "LightNade");
	oo_call(g_oGrenadeInfo, "LoadJson", "light.json");

	sprite_trail = AssetsGetSprite(g_oGrenadeInfo, "trail");
}

public plugin_init()
{
	register_plugin("[OO] Nade: Light", "0.1", "holla");

	new pcvar = create_cvar("lightnade_radius", "25");
	bind_pcvar_num(pcvar, cvar_radius);

	pcvar = create_cvar("lightnade_duration", "50");
	bind_pcvar_num(pcvar, cvar_duration);

	pcvar = create_cvar("lightnade_color_r", "30");
	bind_pcvar_num(pcvar, cvar_color[0]);

	pcvar = create_cvar("lightnade_color_g", "30");
	bind_pcvar_num(pcvar, cvar_color[1]);

	pcvar = create_cvar("lightnade_color_b", "110");
	bind_pcvar_num(pcvar, cvar_color[2]);
}

public LightNadeInfo@Condition(id, const class[])
{
	if (equal(class, "smokegrenade"))
	{
		if (is_user_connected(id) && oo_playerclass_isa(id, "Human"))
			return true;
	}

	return false;
}

public GrenadeInfo:LightNade@GetInfo()
{
	return g_oGrenadeInfo;
}

public LightNade@Dtor()
{
}

public LightNade@SetWorldModel()
{
	new this = @this;
	oo_call(this, "Grenade@SetWorldModel");

	new ent = oo_get(this, "ent");
	if (sprite_trail)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW); // TE id
		write_short(ent); // entity
		write_short(sprite_trail); // sprite
		write_byte(10); // life
		write_byte(5); // width
		write_byte(50); // r
		write_byte(50); // g
		write_byte(150); // b
		write_byte(200); // brightness
		message_end();
	}
}

public LightNade@Think()
{
	new this = @this;
	new ent = oo_get(this, "ent");

	new Float:gametime = get_gametime();
	if (Float:get_entvar(ent, var_dmgtime) > gametime)
		return false;

	new duration = get_entvar(ent, var_flSwimTime);
	if (duration > 0)
	{
		if (duration == 1)
		{
			engfunc(EngFunc_RemoveEntity, ent);
			return true;
		}

		static Float:origin[3];
		get_entvar(ent, var_origin, origin);

		message_begin_f(MSG_PAS, SVC_TEMPENTITY, origin);
		write_byte(TE_DLIGHT);
		write_coord_f(origin[0]);
		write_coord_f(origin[1]);
		write_coord_f(origin[2]);
		write_byte(cvar_radius);
		write_byte(cvar_color[0]) // r
		write_byte(cvar_color[1]) // g
		write_byte(cvar_color[2]) // b
		write_byte(21);
		write_byte((duration < 2) ? 3 : 0);
		message_end();

		message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
		write_byte(TE_SPARKS);
		write_coord_f(origin[0]);
		write_coord_f(origin[1]);
		write_coord_f(origin[2]);
		message_end();

		set_entvar(ent, var_flSwimTime, --duration);
		set_entvar(ent, var_nextthink, gametime + 2.0);
	}
	else if ((get_entvar(ent, var_flags) & FL_ONGROUND) && get_speed(ent) < 10)
	{
		oo_call(this, "PlayDetonateSound");

		set_entvar(ent, var_flSwimTime, 1 + cvar_duration / 2);
		set_entvar(ent, var_nextthink, gametime + 0.1);
	}
	else
	{
		set_entvar(ent, var_nextthink, gametime + 0.1);
	}

	return true;
}