#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <json>
#include <oo_player>

enum _:PlayerModel_e
{
	PM_Model[32],
	bool:PM_Index,
};


new PlayerClass:g_oPlayerClass[MAX_PLAYERS + 1];
new Trie:g_tItemDeploy;

public plugin_precache()
{
	g_tItemDeploy = TrieCreate();
}

public plugin_init()
{
	register_plugin("[OO] Player Class", "0.1", "holla");

	register_forward(FM_EmitSound, "OnEmitSound");
	register_forward(FM_CmdStart, "OnCmdStart");

	register_concmd("oo_playerclass", "CmdPlayerClass", ADMIN_BAN);

	oo_hook_mthd("Player", "OnPreThink", "OnPlayerPreThink");
	oo_hook_mthd("Player", "OnSpawn", "OnPlayerSpawn");
	oo_hook_mthd("Player", "OnTakeDamage", "OnPlayerTakeDamage");
	oo_hook_mthd("Player", "OnTraceAttack", "OnPlayerTraceAttack");
	oo_hook_mthd("Player", "OnTraceAttack_Post", "OnPlayerTraceAttack_Post");
	oo_hook_mthd("Player", "OnResetMaxSpeed", "OnPlayerResetMaxSpeed");
	oo_hook_mthd("Player", "OnKilled", "OnPlayerKilled");
	oo_hook_dtor("Player", "OnPlayerDtor");
}

public oo_init()
{
	oo_class("PlayerClassInfo", "Assets")
	{
		new const cl[] = "PlayerClassInfo";
		oo_var(cl, "name", 32);
		oo_var(cl, "player_models", 1);
		oo_var(cl, "v_models", 1);
		oo_var(cl, "p_models", 1);
		oo_var(cl, "replace_sounds", 1);
		oo_var(cl, "cvars", 1);

		oo_ctor(cl, "Ctor", @str(name));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "CreateCvar", @str(prefix), @str(name), @str(value));
		oo_mthd(cl, "CreateCvars");
		oo_mthd(cl, "LoadJson", @str(filename));
		oo_mthd(cl, "ParseJson", @int(json));
		oo_mthd(cl, "Clear");
		oo_mthd(cl, "Clone", @obj(obj));
	}

	oo_class("PlayerClass")
	{
		new const cl[] = "PlayerClass";
		oo_var(cl, "player", 1);
		oo_var(cl, "player_id", 1);

		oo_ctor(cl, "Ctor", @obj(player_o));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "GetCvarPtr", @str(cvar_name));
		oo_mthd(cl, "GetClassInfo");
		oo_mthd(cl, "GetClassName", @stref(output), @int(len));
		oo_mthd(cl, "SetProps", @bool(set_team));
		oo_mthd(cl, "SetTeam");

		oo_mthd(cl, "ChangeMaxSpeed");
		oo_mthd(cl, "ChangeWeaponModel", @int(entity));
		oo_mthd(cl, "ChangeSound", @int(channel), @str(sample), @fl(vol), @fl(attn), @int(flags), @int(pitch));

		oo_mthd(cl, "OnSpawn");
		oo_mthd(cl, "OnTakeDamage", @int(inflictor), @int(attacker), @ref(damage), @int(damagebits));
		oo_mthd(cl, "OnGiveDamage", @int(inflictor), @int(victim), @ref(damage), @int(damagebits));
		oo_mthd(cl, "OnTraceAttack", @int(victim), @ref(damage), @arr(dir[3]), @int(tr), @int(damagebits));
		oo_mthd(cl, "OnTraceAttack_Post", @int(victim), @fl(damage), @arr(dir[3]), @int(tr), @int(damagebits));
		oo_mthd(cl, "OnKilled", @int(victim), @int(shouldgibs));
		oo_mthd(cl, "OnKilledBy", @int(attacker), @int(shouldgibs));
		oo_mthd(cl, "OnThink");
		oo_mthd(cl, "OnCmdStart", @int(uc), @int(seed));

		oo_smthd(cl, "Change", @int(id), @str(class), @bool(set_props));
	}
}

public PlayerClassInfo@Ctor(const name[])
{
	new this = @this;
	oo_super_ctor("Assets");

	oo_set_str(this, "name", name);
	oo_set(this, "player_models", ArrayCreate(PlayerModel_e));
	oo_set(this, "v_models", TrieCreate());
	oo_set(this, "p_models", TrieCreate());
	oo_set(this, "replace_sounds", TrieCreate());
	oo_set(this, "cvars", TrieCreate());
}

public PlayerClassInfo@Dtor()
{
	new this = @this;

	new Array:player_models_a = Array:oo_get(this, "player_models");
	new Trie:v_models_t = Trie:oo_get(this, "v_models");
	new Trie:p_models_t = Trie:oo_get(this, "p_models");
	new Trie:replace_sounds_t = Trie:oo_get(this, "replace_sounds");
	new Trie:cvars_t = Trie:oo_get(this, "cvars");

	ArrayDestroy(player_models_a);
	TrieDestroy(v_models_t);
	TrieDestroy(p_models_t);
	TrieDestroy(cvars_t);

	TrieArrayDestory(replace_sounds_t);
	TrieDestroy(replace_sounds_t);
}

public PlayerClassInfo@Clear()
{
	new this = @this;
	oo_call(this, "Assets@Clear");

	ArrayClear(Array:oo_get(this, "player_models"));

	TrieClear(Trie:oo_get(this, "v_models"));
	TrieClear(Trie:oo_get(this, "p_models"));
	TrieClear(Trie:oo_get(this, "cvars"));

	new Trie:replace_sounds_t = Trie:oo_get(this, "replace_sounds");
	TrieArrayDestory(replace_sounds_t);
	TrieClear(replace_sounds_t);

	//server_print("PlayerClassInfo@Clear");
}

public PlayerClassInfo@CreateCvar(const prefix[], const name[], const value[])
{
	static cvar_name[64];
	formatex(cvar_name, charsmax(cvar_name), "%s_%s", prefix, name);

	new pcvar = get_cvar_pointer(cvar_name);
	if (!pcvar)
		pcvar = create_cvar(cvar_name, value);

	new Trie:cvars_t = Trie:oo_get(@this, "cvars");
	TrieSetCell(cvars_t, name, pcvar);
	return pcvar;
}

public PlayerClassInfo@CreateCvars() {}

public PlayerClassInfo@LoadJson(const filename[])
{
	static filepath[64];
	format(filepath, charsmax(filepath), "playerclass/%s", filename);

	return oo_call(@this, "Assets@LoadJson", filepath);
}

public PlayerClassInfo@ParseJson(JSON:json)
{
	new this = @this;
	oo_call(this, "Assets@ParseJson", json);

	static key[100], value[100];

	new JSON:models_j = json_object_get_value(json, "player_models");
	if (models_j != Invalid_JSON)
	{
		new Array:models_a = Array:oo_get(this, "player_models");
		ArrayClear(models_a);
		
		new JSON:value_j = Invalid_JSON;
		new model[PlayerModel_e];
		for (new i = json_object_get_count(models_j) - 1; i >= 0; i--)
		{
			json_object_get_name(models_j, i, key, charsmax(key));
			value_j = json_object_get_value_at(models_j, i);
			formatex(value, charsmax(value), "models/player/%s/%s.mdl", key, key);
			if (file_exists(value, true))
			{
				precache_model(value);
				copy(model[PM_Model], charsmax(model[PM_Model]), key);
				model[PM_Index] = json_get_bool(value_j);
				ArrayPushArray(models_a, model);
			}
			else
			{
				log_amx("PlayerClassInfo@ParseJson : player model '%s' does not exist", value);
			}
			json_free(value_j);
		}
		json_free(models_j);
	}

	models_j = json_object_get_value(json, "v_models");
	if (models_j != Invalid_JSON)
	{
		new JSON:value_j = Invalid_JSON;
		new Trie:models_t = Trie:oo_get(this, "v_models");
		for (new i = json_object_get_count(models_j) - 1; i >= 0; i--)
		{
			json_object_get_name(models_j, i, key, charsmax(key));
			value_j = json_object_get_value_at(models_j, i);
			json_get_string(value_j, value, charsmax(value));
			json_free(value_j);

			if (value[0] && file_exists(value, true))
				precache_model(value);
			else if (value[0])
				log_amx("PlayerClassInfo@ParseJson : v_model '%s' does not exist", value);

			TrieSetString(models_t, key, value);

			if (!TrieKeyExists(g_tItemDeploy, key) && rg_get_weapon_info(key, WI_ID))
			{
				TrieSetCell(g_tItemDeploy, key, 1);
				RegisterHam(Ham_Item_Deploy, key, "OnItemDeploy_Post", 1);
			}
		}
		json_free(models_j);
	}

	models_j = json_object_get_value(json, "p_models");
	if (models_j != Invalid_JSON)
	{
		new JSON:value_j = Invalid_JSON;
		new Trie:models_t = Trie:oo_get(this, "p_models");
		for (new i = json_object_get_count(models_j) - 1; i >= 0; i--)
		{
			json_object_get_name(models_j, i, key, charsmax(key));
			value_j = json_object_get_value_at(models_j, i);
			json_get_string(value_j, value, charsmax(value));
			json_free(value_j);

			if (value[0] && file_exists(value, true))
				precache_model(value);
			else if (value[0])
				log_amx("PlayerClassInfo@ParseJson : p_model '%s' does not exist", value);

			TrieSetString(models_t, key, value);

			if (!TrieKeyExists(g_tItemDeploy, key) && rg_get_weapon_info(key, WI_ID))
			{
				TrieSetCell(g_tItemDeploy, key, 1);
				RegisterHam(Ham_Item_Deploy, key, "OnItemDeploy_Post", 1);
			}
		}
		json_free(models_j);
	}

	new JSON:sounds_j = json_object_get_value(json, "replace_sounds");
	if (sounds_j != Invalid_JSON)
	{
		static soundpath[80], j;
		new JSON:value_j = Invalid_JSON;
		new Array:sounds_a = Invalid_Array;
		new Trie:sounds_t = Trie:oo_get(this, "replace_sounds");
		for (new i = json_object_get_count(sounds_j) - 1; i >= 0; i--)
		{
			json_object_get_name(sounds_j, i, key, charsmax(key));
			value_j = json_object_get_value_at(sounds_j, i);

			if (TrieGetCell(sounds_t, key, sounds_a))
			{
				ArrayDestroy(sounds_a);
				TrieDeleteKey(sounds_t, key);
			}

			sounds_a = ArrayCreate(64);
			for (j = json_array_get_count(value_j) - 1; j >= 0; j--)
			{
				json_array_get_string(value_j, j, value, charsmax(value));
				formatex(soundpath, charsmax(soundpath), "sound/%s", value);
				if (file_exists(soundpath, true))
				{
					precache_sound(value);
					ArrayPushString(sounds_a, value);
				}
				else
				{
					log_amx("PlayerClassInfo@ParseJson : replace sound '%s' does not exist", value);
				}
			}

			json_free(value_j);

			if (ArraySize(sounds_a) > 0)
				TrieSetCell(sounds_t, key, sounds_a);
			else
				ArrayDestroy(sounds_a);
		}

		json_free(sounds_j)
	}
}

public PlayerClassInfo@Clone(any:object)
{
	new this = @this;
	oo_call(this, "Assets@Clone", object);

	new Array:a[2];
	a[0] = Array:oo_get(this, "player_models");
	a[1] = Array:oo_get(object, "player_models");
	ArrayDestroy(a[0]);
	a[0] = ArrayClone(a[1]);
	oo_set(this, "player_models", a[0]);

	TrieCopyString(Trie:oo_get(object, "v_models"), Trie:oo_get(this, "v_models"));
	TrieCopyString(Trie:oo_get(object, "p_models"), Trie:oo_get(this, "p_models"));
	TrieCopyArray(Trie:oo_get(object, "replace_sounds"), Trie:oo_get(this, "replace_sounds"));

	new Trie:cvars_t = Trie:oo_get(this, "cvars");
	new TrieIter:iter = TrieIterCreate(Trie:oo_get(object, "cvars"));
	{
		static key[32], cell;
		while (!TrieIterEnded(iter))
		{
			TrieIterGetKey(iter, key, charsmax(key))
			TrieIterGetCell(iter, cell);
			TrieSetCell(cvars_t, key, cell);

			TrieIterNext(iter);
		}
		TrieIterDestroy(iter);
	}
}

public PlayerClass@Ctor(Player:player_o)
{
	new this = @this;
	oo_set(this, "player", player_o)

	new id = oo_get(player_o, "player_id");
	oo_set(this, "player_id", id);
}

public PlayerClass@Dtor()
{
}

public PlayerClass@GetCvarPtr(const cvar_name[])
{
	new this = @this;

	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return 0;

	new cvar_ptr;
	new Trie:cvars_t = Trie:oo_get(info_o, "cvars");
	if (TrieGetCell(cvars_t, cvar_name, cvar_ptr))
		return cvar_ptr;

	return 0;
}

public PlayerClass@GetClassInfo()
{
	return @null;
}

public PlayerClass@GetClassName(output[], len)
{
	new PlayerInfo:info_o = any:oo_call(@this, "GetClassInfo");
	if (info_o == @null)
		return;

	oo_get_str(info_o, "name", output, len);
}

public PlayerClass@SetProps(bool:set_team)
{
	new this = @this;

	new id = oo_get(this, "player_id");
	if (!is_user_alive(id))
		return;

	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return;

	new Player:player_o = any:oo_get(this, "player");
	new Trie:cvars_t = any:oo_get(info_o, "cvars");
	new pcvar;

	if (TrieGetCell(cvars_t, "health", pcvar))
		set_entvar(id, var_health, get_pcvar_float(pcvar));

	if (TrieGetCell(cvars_t, "max_health", pcvar))
		oo_set(player_o, "max_health", get_pcvar_num(pcvar));
	else
		oo_set(player_o, "max_health", floatround(Float:get_entvar(id, var_health)));

	if (TrieGetCell(cvars_t, "armor", pcvar))
		set_entvar(id, var_armorvalue, get_pcvar_float(pcvar));

	if (TrieGetCell(cvars_t, "max_armor", pcvar))
		oo_set(player_o, "max_armor", get_pcvar_num(pcvar));

	if (TrieGetCell(cvars_t, "gravity", pcvar))
		set_entvar(id, var_gravity, get_pcvar_float(pcvar));

	if (TrieGetCell(cvars_t, "speed", pcvar))
		rg_reset_maxspeed(id);

	new Array:models_a = Array:oo_get(info_o, "player_models");
	if (ArraySize(models_a) > 0)
	{
		static model[PlayerModel_e];
		ArrayGetArray(models_a, random(ArraySize(models_a)), model);
		rg_set_user_model(id, model[PM_Model], model[PM_Index]);
	}

	new item_ent = get_member(id, m_pActiveItem);
	if (is_entity(item_ent))
		ExecuteHamB(Ham_Item_Deploy, item_ent);

	if (set_team)
		oo_call(this, "SetTeam");
}

public PlayerClass@SetTeam() {}

public PlayerClass@ChangeMaxSpeed()
{
	new this = @this;

	new player = oo_get(this, "player_id");
	if (!is_user_alive(player))
		return false;

	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return false;

	new Trie:cvars_t = Trie:oo_get(info_o, "cvars");
	new pcvar;

	if (!TrieGetCell(cvars_t, "speed", pcvar))
		return false;

	set_entvar(player, var_maxspeed, Float:get_entvar(player, var_maxspeed) * get_pcvar_float(pcvar));
	return true;
}

public PlayerClass@ChangeSound(channel, sample[], Float:vol, Float:attn, flags, pitch)
{
	new this = @this;

	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return false;

	new player = oo_get(this, "player_id");

	new Array:sounds_a = Invalid_Array;
	new Trie:sounds_t = Trie:oo_get(info_o, "replace_sounds");

	if (!TrieGetCell(sounds_t, sample, sounds_a))
	{
		new len = strlen(sample);
		if (isdigit(sample[len - 5]))
		{
			sample[len - 5] = '*';
			sample[len - 4] = '^0';
			if (!TrieGetCell(sounds_t, sample, sounds_a))
				return false;
		}
		else
		{
			return false;
		}
	}

	static sound[64];
	ArrayGetString(sounds_a, random(ArraySize(sounds_a)), sound, charsmax(sound));
	emit_sound(player, channel, sound, vol, attn, flags, pitch);
	return true;
}

public PlayerClass@ChangeWeaponModel(ent)
{
	new this = @this;

	new player = oo_get(this, "player_id");
	if (!is_user_alive(player))
		return false;

	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return false;

	static classname[32], model[64];
	get_entvar(ent, var_classname, classname, charsmax(classname));

	new bool:has_changed = false;
	new Trie:models_t = any:oo_get(info_o, "v_models");
	if (TrieGetString(models_t, classname, model, charsmax(model)))
	{
		set_entvar(player, var_viewmodel, model);
		has_changed = true;
	}

	models_t = any:oo_get(info_o, "p_models");
	if (TrieGetString(models_t, classname, model, charsmax(model)))
	{
		set_entvar(player, var_weaponmodel, model);
		has_changed = true;
	}

	return has_changed;
}

public PlayerClass@OnSpawn()
{
	oo_call(@this, "SetProps", true);
}

public PlayerClass@OnTakeDamage(inflictor, attacker, &Float:damage, damagebits) {}
public PlayerClass@OnGiveDamage(inflictor, victim, &Float:damage, damagebits) {}
public PlayerClass@OnTraceAttack(victim, &Float:damage, Float:dir[3], tr, damagebits) {}
public PlayerClass@OnTraceAttack_Post(victim, Float:damage, Float:dir[3], tr, damagebits) {}
public PlayerClass@OnKilled(victim, shouldgibs) {}
public PlayerClass@OnKilledBy(attacker, shouldgibs) {}
public PlayerClass@OnThink() {}
public PlayerClass@OnCmdStart(uc, seed) {}

public PlayerClass@Change(id, const class[], bool:set_props)
{
	return ChangePlayerClass(id, class, set_props);
}

public plugin_natives()
{
	register_library("oo_playerclass");

	register_native("oo_playerclass_get", "native_get");
	register_native("oo_playerclass_set", "native_set");
	register_native("oo_playerclass_change", "native_change");
}

public PlayerClass:native_get()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "player (%d) not connected", id);
		return @null;
	}

	return g_oPlayerClass[id];
}

public native_set()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "player (%d) not connected", id);
		return false;
	}

	new PlayerClass:class_o = any:get_param(2);
	if (class_o != @null)
	{
		if (!oo_object_exists(class_o))
		{
			log_error(AMX_ERR_NATIVE, "object (#%d) does not exist", class_o);
			return false;
		}

		if (!oo_isa(class_o, "PlayerClass"))
		{
			log_error(AMX_ERR_NATIVE, "object (#%d) is not a (PlayerClass)", class_o);
			return false;
		}
	}

	g_oPlayerClass[id] = class_o;
	return true;
}

public native_change()
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "player (%d) not connected", id);
		return @null;
	}

	static class_name[32];
	get_string(2, class_name, charsmax(class_name));

	if (class_name[0])
	{
		if (!oo_class_exists(class_name))
		{
			log_error(AMX_ERR_NATIVE, "class (%s) does not exists", class_name);
			return @null;
		}

		if (!oo_subclass_of(class_name, "PlayerClass"))
		{
			log_error(AMX_ERR_NATIVE, "Class (%s) not a subclass of (PlayerClass)", class_name);
			return @null;
		}
	}
	
	return oo_call(0, "PlayerClass@Change", id, class_name, get_param(3));
}

public CmdPlayerClass(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED

	static arg[32];
	read_argv(1, arg, charsmax(arg));

	new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
	if (!player)
		return PLUGIN_HANDLED

	static class[32]
	read_argv(2, class, charsmax(class));
	if (!oo_class_exists(class) || !oo_subclass_of(class, "PlayerClass"))
	{
		console_print(id, "invalid player class (%s)", class);
		return PLUGIN_HANDLED;
	}

	ChangePlayerClass(player, class, true);
	return PLUGIN_HANDLED;
}

public OnPlayerPreThink()
{
	new id = oo_get(@this, "player_id");
	if (g_oPlayerClass[id] != @null)
		oo_call(g_oPlayerClass[id], "OnThink");
}

public OnPlayerSpawn()
{
	new id = oo_get(@this, "player_id");
	if (!is_user_alive(id))
		return;

	if (g_oPlayerClass[id] != @null)
		oo_call(g_oPlayerClass[id], "OnSpawn");
}

public OnPlayerTakeDamage(inflictor, attacker, &Float:damage, damagebits)
{
	new id = oo_get(@this, "player_id");

	new ret = OO_CONTINUE;
	if (1 <= attacker <= MaxClients) // valid attacker
	{
		if (g_oPlayerClass[attacker] != @null)
			ret = oo_call(g_oPlayerClass[attacker], "OnGiveDamage", inflictor, id, damage, damagebits);
	}

	if (g_oPlayerClass[id] != @null)
	{
		new tmp = oo_call(g_oPlayerClass[id], "OnTakeDamage", inflictor, attacker, damage, damagebits);
		ret = (tmp > ret) ? tmp : ret;
	}

	if (ret >= OO_SUPERCEDE)
	{
		oo_hook_set_return(HC_SUPERCEDE);
		SetHookChainReturn(ATYPE_INTEGER, 0);
	}
	return ret;
}

public OnPlayerTraceAttack(attacker, &Float:damage, Float:dir[3], tr, damagebits)
{
	new id = oo_get(@this, "player_id");

	new ret = OO_CONTINUE;
	if (1 <= attacker <= MaxClients)
	{
		if (g_oPlayerClass[attacker] != @null)
			ret = oo_call(g_oPlayerClass[attacker], "OnTraceAttack", id, damage, dir, tr, damagebits);
	}

	if (ret >= OO_SUPERCEDE)
		oo_hook_set_return(HC_SUPERCEDE);
	
	return ret;
}

public OnPlayerTraceAttack_Post(attacker, Float:damage, Float:dir[3], tr, damagebits)
{
	new id = oo_get(@this, "player_id");

	if (1 <= attacker <= MaxClients)
	{
		if (g_oPlayerClass[attacker] != @null)
			oo_call(g_oPlayerClass[attacker], "OnTraceAttack_Post", id, damage, dir, tr, damagebits);
	}
}

public OnPlayerResetMaxSpeed()
{
	new id = oo_get(@this, "player_id");
	if (!is_user_alive(id))
		return;

	if (g_oPlayerClass[id] != @null)
		oo_call(g_oPlayerClass[id], "ChangeMaxSpeed");
}

public OnPlayerKilled(attacker, shouldgibs)
{
	new id = oo_get(@this, "player_id");

	new ret = OO_CONTINUE;
	if (1 <= attacker <= MaxClients)
	{
		if (g_oPlayerClass[attacker] != @null)
			ret = oo_call(g_oPlayerClass[attacker], "OnKilled", id, shouldgibs);
	}

	if (g_oPlayerClass[id] != @null)
	{
		new tmp = oo_call(g_oPlayerClass[id], "OnKilledBy", attacker, shouldgibs);
		ret = (tmp > ret) ? tmp : ret;
	}

	if (ret >= OO_SUPERCEDE)
		oo_hook_set_return(HC_SUPERCEDE);

	return ret;
}

public OnPlayerDtor()
{
	new id = oo_get(@this, "player_id");
	
	if (g_oPlayerClass[id] != @null)
	{
		oo_delete(g_oPlayerClass[id]);
		g_oPlayerClass[id] = @null;
	}
}

public OnEmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (!is_user_connected(id))
		return FMRES_IGNORED;

	if (g_oPlayerClass[id] != @null)
		return oo_call(g_oPlayerClass[id], "ChangeSound", channel, sample, volume, attn, flags, pitch) ? FMRES_SUPERCEDE : FMRES_IGNORED;

	return FMRES_IGNORED;
}

public OnCmdStart(id, uc, seed)
{
	if (!is_user_connected(id))
		return FMRES_IGNORED;

	if (g_oPlayerClass[id] != @null)
		return oo_call(g_oPlayerClass[id], "OnCmdStart", uc, seed) ? FMRES_SUPERCEDE : FMRES_IGNORED;

	return FMRES_IGNORED;
}

public OnItemDeploy_Post(ent)
{
	if (!pev_valid(ent))
		return FMRES_IGNORED;
	
	new id = get_member(ent, m_pPlayer);
	if (!is_user_alive(id))
		return FMRES_IGNORED;

	if (g_oPlayerClass[id] != @null)
		oo_call(g_oPlayerClass[id], "ChangeWeaponModel", ent);

	return FMRES_IGNORED;
}

any:ChangePlayerClass(id, const class_name[], bool:set_props=true)
{
	if (g_oPlayerClass[id] != @null)
		oo_delete(g_oPlayerClass[id]);

	if (!class_name[0]) // Delete object if empty classname has been set
	{
		g_oPlayerClass[id] = @null;
		return @null;
	}

	g_oPlayerClass[id] = oo_new(class_name, oo_player_get(id));

	if (g_oPlayerClass[id] != @null && set_props)
		oo_call(g_oPlayerClass[id], "SetProps", true);

	return g_oPlayerClass[id];
}

stock TrieCopyString(Trie:t1, Trie:t2)
{
	new TrieIter:iter = TrieIterCreate(t1);
	{
		static key[32], value[64];
		while (!TrieIterEnded(iter))
		{
			TrieIterGetKey(iter, key, charsmax(key))
			TrieIterGetString(iter, value, charsmax(value));
			TrieSetString(t2, key, value);

			TrieIterNext(iter);
		}
		TrieIterDestroy(iter);
	}
}

stock TrieArrayDestory(Trie:t)
{
	new TrieIter:iter = TrieIterCreate(t);
	{
		new Array:a;
		while (!TrieIterEnded(iter))
		{
			TrieIterGetCell(iter, a);
			ArrayDestroy(a);

			TrieIterNext(iter);
		}
		TrieIterDestroy(iter);
	}
}

stock TrieCopyArray(Trie:t1, Trie:t2)
{
	new TrieIter:iter = TrieIterCreate(t1);
	{
		static key[32], Array:a1, Array:a2;
		while (!TrieIterEnded(iter))
		{
			TrieIterGetKey(iter, key, charsmax(key))
			TrieIterGetCell(iter, a1);

			a2 = ArrayClone(a1);
			TrieSetCell(t2, key, a2);

			TrieIterNext(iter);
		}
		TrieIterDestroy(iter);
	}
}