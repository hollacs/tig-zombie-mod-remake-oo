#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <engine>
#include <hamsandwich>
#include <oo_player_class>
#include <oo_player_status>
#include <oo_assets>
#include <render_layer>

#define UNIT_SECOND (1<<12)
#define FFADE_IN 0x0000
#define BREAK_GLASS 0x01

new Assets:g_oAssets;

public plugin_precache()
{
	g_oAssets = oo_new("Assets");
	oo_call(g_oAssets, "LoadJson", "playerstatus/frozen.json");
}

public plugin_init()
{
	register_plugin("[OO] Status: Frozen", "0.1", "holla");

	oo_hook_mthd("Player", "OnKilled", "OnPlayerKilled");
	oo_hook_dtor("PlayerClass", "OnPlayerClassDtor");

	RegisterHam(Ham_Player_Jump, "player", "OnPlayerJump");
}

public oo_init()
{
	oo_class("FrozenStatus", "PlayerStatus")
	{
		new cl[] = "FrozenStatus";
		oo_var(cl, "freezetime", 1); // float
		oo_var(cl, "start_time", 1); // float

		oo_ctor(cl, "Ctor", @int(player), @fl(freezetime));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "GetName", OO_STRING_REF, OO_CELL);
		oo_mthd(cl, "OnUpdate");

		oo_smthd(cl, "Add", @int(player), @fl(freezetime));
	}
}

public FrozenStatus@Add(id, Float:freezetime)
{
	new PlayerStatus:status_o = oo_playerstatus_get(id, "FrozenStatus");
	if (status_o != @null)
	{
		if (get_gametime() + freezetime > Float:oo_get(status_o, "start_time") + Float:oo_get(status_o, "freezetime"))
		{
			oo_set(status_o, "start_time", get_gametime());
			oo_set(status_o, "freezetime", freezetime);
		}
	}
	else
	{
		oo_playerstatus_add(id, oo_new("FrozenStatus", id, freezetime));
	}
}

public FrozenStatus@Ctor(id, Float:freezetime)
{
	new this = @this;
	oo_super_ctor("PlayerStatus", id);

	oo_set(this, "start_time", get_gametime());
	oo_set(this, "freezetime", freezetime);

	static msgDamage;
	msgDamage || (msgDamage = get_user_msgid("Damage"));

	message_begin(MSG_ONE_UNRELIABLE, msgDamage, _, id);
	write_byte(0); // damage save
	write_byte(0); // damage take
	write_long(DMG_DROWN); // damage type - DMG_FREEZE
	write_coord(0); // x
	write_coord(0); // y
	write_coord(0); // z
	message_end();

	static msgScreenFade;
	msgScreenFade || (msgScreenFade = get_user_msgid("ScreenFade"));

	emessage_begin(MSG_ONE, msgScreenFade, _, id);
	ewrite_short(1 * UNIT_SECOND); // duration
	ewrite_short(floatround(freezetime * UNIT_SECOND)); // hold time
	ewrite_short(FFADE_IN); // fade type
	ewrite_byte(0); // red
	ewrite_byte(150); // green
	ewrite_byte(200); // blue
	ewrite_byte(100); // alpha
	emessage_end();

	static sound[64];
	if (AssetsGetRandomSound(g_oAssets, "freeze", sound, charsmax(sound)))
		emit_sound(id, CHAN_BODY, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);

	render_push(id, kRenderFxGlowShell, {0, 200, 200}, kRenderNormal, 16, freezetime, "freeze", 10);
}

public FrozenStatus@Dtor()
{
	new this = @this;
	new id = oo_get(this, "player_id");

	rg_reset_maxspeed(id);

	new modelindex = AssetsGetSprite(g_oAssets, "gibs");
	if (modelindex)
	{
		static Float:origin[3];
		get_entvar(id, var_origin, origin);

		message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
		write_byte(TE_BREAKMODEL); // TE id
		write_coord_f(origin[0]); // x
		write_coord_f(origin[1]); // y
		write_coord_f(origin[2]+24); // z
		write_coord(16); // size x
		write_coord(16); // size y
		write_coord(16); // size z
		write_coord(random_num(-50, 50)); // velocity x
		write_coord(random_num(-50, 50)); // velocity y
		write_coord(25); // velocity z
		write_byte(10); // random velocity
		write_short(modelindex); // model
		write_byte(10); // count
		write_byte(25); // life
		write_byte(BREAK_GLASS); // flags
		message_end();
	}
	
	static sound[64];
	if (AssetsGetRandomSound(g_oAssets, "break", sound, charsmax(sound)))
		emit_sound(id, CHAN_BODY, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);

	render_pop(id, -1, "freeze");
}

public FrozenStatus@GetName(output[], len)
{
	return formatex(output, len, "Frozen");
}

public FrozenStatus@OnUpdate()
{
	new this = @this;
	if (get_gametime() >= Float:oo_get(this, "start_time") + Float:oo_get(this, "freezetime"))
	{
		//server_print("onupdate del (%d)", this);
		oo_call(this, "Delete");
		return;
	}

	set_entvar(oo_get(this, "player_id"), var_maxspeed, 1.0);
}

public OnPlayerJump(id)
{
	if (is_user_alive(id) && oo_playerstatus_get(id, "FrozenStatus"))
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public OnPlayerKilled()
{
	new id = oo_get(@this, "player_id");
	oo_playerstatus_remove(id, "FrozenStatus");
}

public OnPlayerClassDtor()
{
	new id = oo_get(@this, "player_id");
	oo_playerstatus_remove(id, "FrozenStatus");
}