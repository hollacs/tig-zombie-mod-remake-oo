#include <amxmodx>
#include <reapi>
#include <engine>
#include <oo_player_class>
#include <oo_player_status>

new const MODEL_FLAME[] = "sprites/fire.spr";
new const SPRITE_SMOKE[] = "sprites/black_smoke3.spr";

new g_sprSmoke;

public plugin_precache()
{
	precache_model(MODEL_FLAME);
	g_sprSmoke = precache_model(SPRITE_SMOKE);
}

public plugin_init()
{
	register_plugin("[OO] Status: Burn", "0.1", "holla");
}

public oo_init()
{
	oo_class("BurnStatus", "SustainedDamage", "PlayerStatus");
	{
		new cl[] = "BurnStatus";
		oo_var(cl, "ent", 1);

		oo_ctor(cl, "Ctor", @int(player), @int(attacker), @fl(interval), @fl(damage), @int(times));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "CreateFlame");
		oo_mthd(cl, "RemoveFlame");
		oo_mthd(cl, "Damage");
		oo_mthd(cl, "GetName", @stref(output), @int(maxlen));
		oo_mthd(cl, "OnUpdate");

		oo_smthd(cl, "Add", @int(player), @int(attacker), @fl(interval), @fl(damage), @int(times));
	}
}

public BurnStatus@Add(player, attacker, Float:interval, Float:damage, times)
{
	new PlayerStatus:status_o = oo_playerstatus_get(player, "BurnStatus");
	if (status_o != @null)
	{
		oo_set(status_o, "attacker", attacker);
		oo_set(status_o, "interval", interval);
		oo_set(status_o, "damage", damage);
		oo_set(status_o, "count", oo_get(status_o, "count") + times);
	}
	else
	{
		oo_playerstatus_add(player, oo_new("BurnStatus", player, attacker, interval, damage, times));
	}
}

public BurnStatus@Ctor(player, attacker, Float:interval, Float:damage, times)
{
	new this = oo_this();
	oo_super_ctor("PlayerStatus", player);
	oo_super_ctor("SustainedDamage", player, attacker, interval, damage, times);

	new ent = oo_call(this, "CreateFlame");
	oo_set(this, "ent", ent);
}

public BurnStatus@Dtor()
{
	new this = oo_this();
	oo_call(this, "RemoveFlame");
}

public BurnStatus@OnUpdate()
{
	new this = oo_this();
	new id = oo_get(this, "player_id");

	if (get_entvar(id, var_flags) & FL_INWATER)
	{
		oo_call(this, "Delete");
		return;
	}

	oo_call(this, "SustainedDamage@OnUpdate");
}

public BurnStatus@CreateFlame()
{
	new this = oo_this();
	new id = oo_get(this, "player_id");

	new ent = rg_create_entity("env_sprite");

	set_entvar(ent, var_aiment, id);
	set_entvar(ent, var_owner, id);
	set_entvar(ent, var_movetype, MOVETYPE_FOLLOW);
	set_entvar(ent, var_classname, "flame_sprite");

	entity_set_model(ent, MODEL_FLAME);

	set_entvar(ent, var_scale, 0.5);
	set_entvar(ent, var_framerate, 10.0);
	set_entvar(ent, var_spawnflags, SF_SPRITE_STARTON);

	set_rendering(ent, kRenderFxNoDissipation, 0, 0, 0, kRenderTransAdd, 255);

	DispatchSpawn(ent);
	return ent;
}

public BurnStatus@RemoveFlame()
{
	new this = oo_this();

	new ent = oo_get(this, "ent");
	remove_entity(ent);

	new id = oo_get(this, "player_id");

	new Float:origin[3];
	get_entvar(id, var_origin, origin);

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_SMOKE); // TE id
	write_coord_f(origin[0]); // x
	write_coord_f(origin[1]); // y
	write_coord_f(origin[2]-50.0); // z
	write_short(g_sprSmoke); // sprite
	write_byte(random_num(15, 20)); // scale
	write_byte(random_num(10, 20)); // framerate
	message_end();
}

public BurnStatus@Damage()
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
		write_long(DMG_BURN); // damage type - DMG_RADIATION
		write_coord(0); // x
		write_coord(0); // y
		write_coord(0); // z
		message_end();

		return true;
	}

	return false;
}

public BurnStatus@GetName(output[], maxlen)
{
	return formatex(output, maxlen, "Burn");
}

public OO_OnPlayerKilled(id)
{
	oo_playerstatus_remove(id, "BurnStatus");
}

public OO_OnPlayerClassDtor(id)
{
	oo_playerstatus_remove(id, "BurnStatus");
}