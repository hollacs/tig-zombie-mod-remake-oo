#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <oo_player_class>
#include <oo_player_status>
#include <ctg_game_mode>
#include <oo_assets>

public plugin_init()
{
	register_plugin("[OO] Status: Acid", "0.1", "holla");

	oo_hook_mthd("Player", "OnKilled", "OnPlayerKilled");
	oo_hook_dtor("PlayerClass", "OnPlayerClassDtor");

	register_clcmd("Acid", "Cmd");
}

public Cmd(id)
{
	oo_call(0, "AcidStatus@Add", id, id, 1.0, 1.0, 10);
	return PLUGIN_HANDLED;
}

public oo_init()
{
	oo_class("AcidStatus", "SustainedDamage", "PlayerStatus");
	{
		new cl[] = "AcidStatus";
		oo_var(cl, "next_sound_time", 1);

		oo_ctor(cl, "Ctor", @int(player), @int(attacker), @fl(interval), @fl(damage), @int(times));

		oo_mthd(cl, "Damage");
		oo_mthd(cl, "GetName", @stref(output), @int(maxlen));
		oo_mthd(cl, "OnUpdate");
		oo_mthd(cl, "Delete");

		oo_smthd(cl, "Add", @int(player), @int(attacker), @fl(interval), @fl(damage), @int(times));
	}
}

public AcidStatus@Add(player, attacker, Float:interval, Float:damage, times)
{
	new PlayerStatus:status_o = oo_playerstatus_get(player, "AcidStatus");
	if (status_o != @null)
	{
		oo_set(status_o, "attacker", attacker);
		oo_set(status_o, "interval", interval);
		oo_set(status_o, "damage", damage);
		oo_set(status_o, "count", oo_get(status_o, "count") + times);
	}
	else
	{
		oo_playerstatus_add(player, oo_new("AcidStatus", player, attacker, interval, damage, times));
	}
}

public AcidStatus@Ctor(player, attacker, Float:interval, Float:damage, times)
{
	oo_super_ctor("PlayerStatus", player);
	oo_super_ctor("SustainedDamage", player, attacker, interval, damage, times);
	oo_set(@this, "next_sound_time", get_gametime() + 1.0);
}

public AcidStatus@OnUpdate()
{
	new this = @this;

	new Float:gametime = get_gametime();
	if (gametime >= Float:oo_get(this, "next_sound_time"))
	{
		new player = oo_get(this, "player_id");
		new PlayerClassInfo:info_o = oo_playerclass_get_info(player);
		if (info_o != @null)
		{
			static sound[64];
			if (AssetsGetRandomSound(info_o, "Acid", sound, charsmax(sound)))
				emit_sound(player, CHAN_VOICE, sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}

		oo_set(this, "next_sound_time", gametime + random_float(1.0, 2.0));
	}

	oo_call(this, "SustainedDamage@OnUpdate");
}

public AcidStatus@Damage()
{
	new this = @this;
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

		static Float:velocity[3];
		get_entvar(id, var_velocity, velocity);
		

		return true;
	}

	return false;
}

public AcidStatus@Delete()
{
	oo_call(@this, "PlayerStatus@Delete");
}

public AcidStatus@GetName(output[], maxlen)
{
	return formatex(output, maxlen, "Acid");
}

public OnPlayerKilled()
{
	new id = oo_get(@this, "player_id");
	oo_playerstatus_remove(id, "AcidStatus");
}

public OnPlayerClassDtor()
{
	new id = oo_get(@this, "player_id");
	oo_playerstatus_remove(id, "AcidStatus");
}