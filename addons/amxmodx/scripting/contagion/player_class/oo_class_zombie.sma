#include <amxmodx>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <oo_player_class>
#include <oo_player_status>
#include <oo_assets>
#include <cs_painshock>
#include <cs_knockback>

const KNIFE_STABHIT = 4;

new PlayerClassInfo:g_oClassInfo;
new Float:cvar_idle_sound_time[2], Float:cvar_pain_sound_time[2];

public oo_init()
{
	oo_class("ZombieClassInfo", "PlayerClassInfo")
	{
		new const cl[] = "ZombieClassInfo";
		oo_mthd(cl, "CreateCvars");
	}

	oo_class("Zombie", "PlayerClass");
	{
		new const cl[] = "Zombie";
		oo_var(cl, "next_idle", 1);
		oo_var(cl, "next_pain", 1);
		oo_var(cl, "notify_rampage", 1);
		oo_var(cl, "next_restore_ap", 1);

		oo_ctor(cl, "Ctor", @obj(player));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "GetClassInfo");
		oo_mthd(cl, "RemoveWeapons");
		oo_mthd(cl, "SetProps", @bool(set_team));
		oo_mthd(cl, "SetTeam");
		oo_mthd(cl, "GetArmorPenetration");
		oo_mthd(cl, "ChangeSound", OO_CELL, OO_STRING, OO_CELL, OO_CELL, OO_CELL, OO_CELL);
		oo_mthd(cl, "OnGiveDamage", OO_CELL, OO_CELL, OO_BYREF, OO_CELL);
		oo_mthd(cl, "OnTakeDamage", OO_CELL, OO_CELL, OO_BYREF, OO_CELL);
		oo_mthd(cl, "OnThink");
		oo_mthd(cl, "OnPainShock", OO_CELL, OO_FLOAT, OO_BYREF);
		oo_mthd(cl, "OnPainShockBy", OO_CELL, OO_FLOAT, OO_BYREF);
		oo_mthd(cl, "OnKnockBack", OO_CELL, OO_FLOAT, OO_CELL, OO_ARRAY[3]);
		oo_mthd(cl, "OnKnifeAttack1", OO_CELL);
		oo_mthd(cl, "OnKnifeAttack2", OO_CELL);
		oo_mthd(cl, "OnKnifeAttack1_Post", OO_CELL);
		oo_mthd(cl, "OnKnifeAttack2_Post", OO_CELL);
		oo_mthd(cl, "Rampage");
		oo_mthd(cl, "OnKilledBy", @int(attacker), @int(shouldgib));

		oo_smthd(cl, "ClassInfo");
	}
}

public plugin_precache()
{
	g_oClassInfo = oo_new("ZombieClassInfo", "Zombie");
	oo_call(g_oClassInfo, "LoadJson", "zombie.json");
}

public plugin_init()
{
	register_plugin("[OO] Class: Zombie", "0.1", "holla");

	register_clcmd("drop", "CmdDrop");

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "OnKnifePrimaryAttack");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "OnKnifeSecondaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "OnKnifePrimaryAttack_Post", 1);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "OnKnifeSecondaryAttack_Post", 1);

	//register_forward(FM_TraceLine, "OnTraceLine");
	//register_forward(FM_TraceHull, "OnTraceHull");

	oo_call(g_oClassInfo, "CreateCvars");

	bind_pcvar_float(
		oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie", "idle_sound_time_min", "45"),
		cvar_idle_sound_time[0]);

	bind_pcvar_float(
		oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie", "idle_sound_time_max", "90"),
		cvar_idle_sound_time[1]);

	bind_pcvar_float(
		oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie", "pain_sound_time_min", "1.0"),
		cvar_pain_sound_time[0]);

	bind_pcvar_float(
		oo_call(g_oClassInfo, "CreateCvar", "ctg_zombie", "pain_sound_time_max", "2.0"),
		cvar_pain_sound_time[1]);
}

public ZombieClassInfo@CreateCvars()
{
	new this = @this;

	oo_call(this, "CreateCvar", "ctg_zombie", "health", "1000"); // 生命
	oo_call(this, "CreateCvar", "ctg_zombie", "gravity", "1.0"); // 重力
	oo_call(this, "CreateCvar", "ctg_zombie", "armor", "0");
	oo_call(this, "CreateCvar", "ctg_zombie", "speed", "1.0"); // 速度
	oo_call(this, "CreateCvar", "ctg_zombie", "knockback", "1.0"); // 擊退
	oo_call(this, "CreateCvar", "ctg_zombie", "painshock", "1.0"); // 僵直
	oo_call(this, "CreateCvar", "ctg_zombie", "armor_penetration", "0.0"); // 攻擊對人類的破甲率
	oo_call(this, "CreateCvar", "ctg_zombie", "ap_add_ratio", "0.35"); // 受到傷害對喪屍護甲增加的比率 (血量比率)
	oo_call(this, "CreateCvar", "ctg_zombie", "ap_restore_max", "100"); // 最大能恢復的護甲值
	oo_call(this, "CreateCvar", "ctg_zombie", "ap_restore_time", "1.0"); // 自動回甲的時間
	oo_call(this, "CreateCvar", "ctg_zombie", "ap_restore_amt", "1"); // 每次回多少甲
	oo_call(this, "CreateCvar", "ctg_zombie", "rampage_duration", "5.0"); // 暴走持續時間
	oo_call(this, "CreateCvar", "ctg_zombie", "rampage_speed", "1.3"); // 暴走速度
	oo_call(this, "CreateCvar", "ctg_zombie", "rampage_takedmg", "1.2"); // 暴走時承受的傷害倍率
	oo_call(this, "CreateCvar", "ctg_zombie", "rampage_needed", "100"); // 暴走需要的護甲值
	oo_call(this, "CreateCvar", "ctg_zombie", "swing_dmg", "10"); // 左刀傷害
	oo_call(this, "CreateCvar", "ctg_zombie", "swing2_dmg", "12"); // 左刀傷害2
	oo_call(this, "CreateCvar", "ctg_zombie", "swing_speed", "1.0"); // 左刀攻擊速度
	oo_call(this, "CreateCvar", "ctg_zombie", "swing_dist", "48"); // 左刀攻擊距離
	oo_call(this, "CreateCvar", "ctg_zombie", "swing_pain", "0.9"); // 左刀對人類造成的僵直
	oo_call(this, "CreateCvar", "ctg_zombie", "stab_dmg", "40"); // 右刀傷害
	oo_call(this, "CreateCvar", "ctg_zombie", "stab_speed", "1.0"); // 右刀攻擊速度
	oo_call(this, "CreateCvar", "ctg_zombie", "stab_dist", "32"); // 右刀攻擊距離
	oo_call(this, "CreateCvar", "ctg_zombie", "stab_pain", "1.0"); // 右刀對人類造成的僵直
	oo_call(this, "CreateCvar", "ctg_zombie", "backstab_dmg", "1.25"); // 背刀傷害
	oo_call(this, "CreateCvar", "ctg_zombie", "attack_pain", "1.0"); // 攻擊對人類造成的整體僵直
	oo_call(this, "CreateCvar", "ctg_zombie", "dmg", "1.0"); // 整體傷害
	oo_call(this, "CreateCvar", "ctg_zombie", "dmg_head", "3.0"); // 爆頭傷害
}

public CmdDrop(id)
{
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE;
	
	new PlayerClass:class_o = oo_playerclass_get(id);
	if (class_o == @null || !oo_isa(class_o, "Zombie"))
		return PLUGIN_CONTINUE;

	oo_call(class_o, "Rampage");
	return PLUGIN_HANDLED;
}

public Zombie@Ctor(player)
{
	oo_super_ctor("PlayerClass", player);

	new this = @this;
	oo_set(this, "next_idle", get_gametime() + random_float(cvar_idle_sound_time[0], cvar_idle_sound_time[1]));

	oo_set(this, "next_restore_ap", get_gametime() + 1.0);
	
	new id = oo_get(this, "player_id");
	set_member(id, m_bNotKilled, false);
}

public Zombie@Dtor()
{
}

public PlayerClassInfo:Zombie@GetClassInfo()
{
	return g_oClassInfo;
}

public Zombie@OnKilledBy(attacker, shouldgib)
{
	
}

public Zombie@SetTeam()
{
	rg_set_user_team(oo_get(@this, "player_id"), TEAM_TERRORIST, MODEL_UNASSIGNED, true, true);
}

public Zombie@OnThink()
{
	new this = @this;
	new id = oo_get(this, "player_id");

	if (!is_user_alive(id))
		return;
	
	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return

	new Float:gametime = get_gametime();
	if (gametime >= Float:oo_get(this, "next_idle") && gametime >= Float:oo_get(this, "next_pain") + 3.0)
	{
		static sound[64];
		if (AssetsGetRandomSound(info_o, "idle", sound, charsmax(sound)))
			emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);

		oo_set(this, "next_idle", gametime + random_float(cvar_idle_sound_time[0], cvar_idle_sound_time[1]));
	}

	if (gametime >= Float:oo_get(this, "next_restore_ap"))
	{
		new Trie:cvars_t = any:oo_get(info_o, "cvars");

		new pcvar_amt, pcvar_max;
		if (TrieGetCell(cvars_t, "ap_restore_amt", pcvar_amt) &&
			TrieGetCell(cvars_t, "ap_restore_max", pcvar_max))
		{
			set_entvar(id, var_armorvalue, floatmin(
				Float:get_entvar(id, var_armorvalue) + get_pcvar_float(pcvar_amt), 
				get_pcvar_float(pcvar_max)));
		}

		if (is_user_bot(id))
		{
			new pcvar_needed;
			if (TrieGetCell(cvars_t, "rampage_needed", pcvar_needed))
			{
				if (Float:get_entvar(id, var_armorvalue) >= get_pcvar_float(pcvar_needed))
				{
					new aimid;
					get_user_aiming(id, aimid, _, 1500);

					if (is_user_alive(aimid) && oo_playerclass_isa(aimid, "Human") && entity_range(id, aimid) > 100.0)
					{
						oo_call(this, "Rampage");
					}
				}
			}
		}

		new pcvar_time;
		if (TrieGetCell(cvars_t, "ap_restore_time", pcvar_time))
			oo_set(this, "next_restore_ap", gametime + get_pcvar_float(pcvar_time));
	}

	if (oo_get(this, "notify_rampage"))
	{
		if (oo_playerstatus_get(id, "RampageStatus") == @null)
		{
			client_print(id, print_center, "暴走使用結束");
			oo_set(this, "notify_rampage", false);
		}
	}
}

public Zombie@ChangeSound(channel, sample[], Float:vol, Float:attn, flags, pitch)
{
	new this = @this;

	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return false;

	// player/bhit
	// player/headshot
	if (strlen(sample) > 12 && sample[0] == 'p' && sample[5] == 'r' && 
		((sample[7] == 'b' && sample[10] == 't') || (sample[7] == 'h' && sample[11] == 's')))
	{
		channel = CHAN_BODY;
		if (get_gametime() >= Float:oo_get(this, "next_pain"))
		{
			new Array:sound_a = any:oo_call(info_o, "GetSound", "pain");
			if (sound_a != Invalid_Array)
			{
				static sound[64];
				ArrayGetString(sound_a, random(ArraySize(sound_a)), sound, charsmax(sound));
				emit_sound(oo_get(this, "player_id"), CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);

				oo_set(this, "next_pain", get_gametime() + random_float(cvar_pain_sound_time[0], cvar_pain_sound_time[1]));
			}
		}
	}

	return oo_call(this, "PlayerClass@ChangeSound", channel, sample, vol, attn, flags, pitch);
}

public Zombie@SetProps(bool:set_team)
{
	new this = @this;
	oo_call(this, "RemoveWeapons");
	oo_call(this, "PlayerClass@SetProps", set_team);
}

public Zombie@RemoveWeapons()
{
	new id = oo_get(@this, "player_id");
	for (new i = _:PRIMARY_WEAPON_SLOT; i <= _:PISTOL_SLOT; i++)
	{
		rg_drop_items_by_slot(id, any:i);
	}

	rg_remove_all_items(id);
	rg_give_item(id, "weapon_knife");
}

public Zombie@OnGiveDamage(inflictor, victim, &Float:damage, damagebits)
{
	new this = @this;
	new attacker = oo_get(this, "player_id");

	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return HC_CONTINUE;

	if (inflictor == attacker && get_user_weapon(attacker) == CSW_KNIFE && oo_playerclass_isa(victim, "Human"))
	{
		new Trie:cvars_t = any:oo_get(info_o, "cvars");

		new pcvar;
		if (TrieGetCell(cvars_t, "dmg_head", pcvar))
		{
			new hitgroup = get_member(victim, m_LastHitGroup);
			if (hitgroup == HIT_HEAD)
			{
				damage /= 4.0;
				damage *= get_pcvar_float(pcvar);
			}
		}

		new Float:armor = Float:get_entvar(victim, var_armorvalue);
		new anim = get_entvar(attacker, var_weaponanim);
		if (anim == KNIFE_STABHIT) // stab
		{
			if (armor <= 0.0)
				oo_call(0, "VirusStatus@Add", victim, attacker, 1.0, 1.0, 10);
		}
		else
		{
			if (armor <= 0.0)
				oo_call(0, "VirusStatus@Add", victim, attacker, 1.0, 1.0, 3);
		}

		if (TrieGetCell(cvars_t, "dmg", pcvar))
		{
			damage *= get_pcvar_float(pcvar);
		}

		SetHookChainArg(4, ATYPE_FLOAT, damage);
	}
	return HC_CONTINUE;
}

public Zombie@OnTakeDamage(inflictor, attacker, &Float:damage, damagebits)
{
	new this = @this;
	new id = oo_get(this, "player_id");

	if (inflictor != attacker || !is_user_connected(attacker) || oo_playerclass_isa(attacker, "Zombie"))
		return HC_CONTINUE;

	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return HC_CONTINUE;

	new Trie:cvars_t = any:oo_get(info_o, "cvars");

	new pcvar_ratio, pcvar_needed, pcvar_max;
	if (TrieGetCell(cvars_t, "ap_add_ratio", pcvar_ratio) &&
		TrieGetCell(cvars_t, "rampage_needed", pcvar_needed) &&
		TrieGetCell(cvars_t, "ap_restore_max", pcvar_max))
	{
		new max_health = oo_player_get_max_health(id);
		new Float:ratio = get_pcvar_float(pcvar_needed) / (max_health * get_pcvar_float(pcvar_ratio));
		new Float:amount = damage * ratio;

		set_entvar(id, var_armorvalue, floatmin(Float:get_entvar(id, var_armorvalue) + amount, get_pcvar_float(pcvar_max)));
	}

	return HC_CONTINUE;
}

public bool:Zombie@Rampage()
{
	new this = @this;
	new id = oo_get(this, "player_id");

	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return false;

	new Trie:cvars_t = any:oo_get(info_o, "cvars");

	new pcvar_duration, pcvar_speed, pcvar_needed, pcvar_takedmg;
	if (!TrieGetCell(cvars_t, "rampage_duration", pcvar_duration) ||
		!TrieGetCell(cvars_t, "rampage_speed", pcvar_speed) ||
		!TrieGetCell(cvars_t, "rampage_takedmg", pcvar_takedmg) ||
		!TrieGetCell(cvars_t, "rampage_needed", pcvar_needed))
		return false;

	new needed = get_pcvar_num(pcvar_needed);
	if (Float:get_entvar(id, var_armorvalue) < needed)
	{
		client_print(id, print_center, "護甲值未滿 %d", needed);
		return false;
	}

	if (!oo_call(0, "RampageStatus@Set", id, 
		get_pcvar_float(pcvar_duration), get_pcvar_float(pcvar_speed), get_pcvar_float(pcvar_takedmg)))
	{
		client_print(id, print_center, "目前暫時無法使用暴走");
		return false;
	}

	client_print(id, print_center, "你使用了暴走");
	set_entvar(id, var_armorvalue, Float:get_entvar(id, var_armorvalue) - needed);
	oo_set(this, "notify_rampage", true);

	static sound[64];
	if (AssetsGetRandomSound(info_o, "rampage", sound, charsmax(sound)))
		emit_sound(id, CHAN_VOICE, sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	return true;
}

public Float:Zombie@GetArmorPenetration()
{
	new this = @this;

	new pcvar = oo_call(this, "GetCvarPtr", "armor_penetration");
	if (pcvar)
		return get_pcvar_float(pcvar);

	return 0.0;
}

public Zombie@OnPainShock(victim, Float:damage, &Float:value)
{
	new this = @this;
	new id = oo_get(this, "player_id");

	if (get_user_weapon(id) != CSW_KNIFE)
		return;

	new pcvar;
	new anim = get_entvar(id, var_weaponanim);
	if (anim == KNIFE_STABHIT) // stab
		pcvar = oo_call(this, "GetCvarPtr", "stab_pain");
	else
		pcvar = oo_call(this, "GetCvarPtr", "slash_pain");

	if (!pcvar)
		return;

	value *= get_pcvar_float(pcvar);
	
	pcvar = oo_call(this, "GetCvarPtr", "attack_pain");
	if (!pcvar)
		return;
	
	value *= get_pcvar_float(pcvar);
}

public Zombie@OnPainShockBy(attacker, Float:damage, &Float:value)
{
	new this = @this;

	new pcvar_painshock = oo_call(this, "GetCvarPtr", "painshock");
	if (pcvar_painshock)
	{
		value *= get_pcvar_float(pcvar_painshock);
	}
}

public Zombie@OnKnockBack(attacker, Float:damage, tr, Float:vec[3])
{
	new this = @this;

	new pcvar_knockback = oo_call(this, "GetCvarPtr", "knockback");
	if (pcvar_knockback)
	{
		xs_vec_mul_scalar(vec, get_pcvar_float(pcvar_knockback), vec);
	}
}

public Zombie@OnKnifeAttack1(ent)
{
	new this = @this;

	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return false;

	new Trie:cvars_t = any:oo_get(info_o, "cvars");
	new pcvar;

	if (TrieGetCell(cvars_t, "swing_dmg", pcvar))
		set_member(ent, m_Knife_flSwingBaseDamage, get_pcvar_float(pcvar));

	if (TrieGetCell(cvars_t, "swing2_dmg", pcvar))
		set_member(ent, m_Knife_flSwingBaseDamage_Fast, get_pcvar_float(pcvar));

	if (TrieGetCell(cvars_t, "swing_dist", pcvar))
		set_member(ent, m_Knife_flSwingDistance, get_pcvar_float(pcvar));

	return false;
}

public Zombie@OnKnifeAttack2(ent)
{
	new this = @this;

	new PlayerClassInfo:info_o = any:oo_call(this, "GetClassInfo");
	if (info_o == @null)
		return false;

	new Trie:cvars_t = any:oo_get(info_o, "cvars");
	new pcvar;

	if (TrieGetCell(cvars_t, "stab_dmg", pcvar))
		set_member(ent, m_Knife_flStabBaseDamage, get_pcvar_float(pcvar));

	if (TrieGetCell(cvars_t, "stab_dist", pcvar))
		set_member(ent, m_Knife_flStabDistance, get_pcvar_float(pcvar));

	if (TrieGetCell(cvars_t, "backstab_dmg", pcvar))
		set_member(ent, m_Knife_flBackStabMultiplier, get_pcvar_float(pcvar));

	return false;
}

public Zombie@OnKnifeAttack1_Post(ent)
{
	new this = @this;

	new pcvar = oo_call(this, "GetCvarPtr", "swing_speed");
	if (pcvar)
	{
		set_member(ent, m_Weapon_flNextPrimaryAttack, 
			Float:get_member(ent, m_Weapon_flNextPrimaryAttack) * get_pcvar_float(pcvar));
		set_member(ent, m_Weapon_flNextSecondaryAttack, 
			Float:get_member(ent, m_Weapon_flNextSecondaryAttack) * get_pcvar_float(pcvar));
		set_member(ent, m_Weapon_flTimeWeaponIdle, 
			Float:get_member(ent, m_Weapon_flTimeWeaponIdle) * get_pcvar_float(pcvar));
	}
}

public Zombie@OnKnifeAttack2_Post(ent)
{
	new this = @this;
	
	new pcvar = oo_call(this, "GetCvarPtr", "stab_speed");
	if (pcvar)
	{
		set_member(ent, m_Weapon_flNextPrimaryAttack, 
			Float:get_member(ent, m_Weapon_flNextPrimaryAttack) * get_pcvar_float(pcvar));
		set_member(ent, m_Weapon_flNextSecondaryAttack, 
			Float:get_member(ent, m_Weapon_flNextSecondaryAttack) * get_pcvar_float(pcvar));
		set_member(ent, m_Weapon_flTimeWeaponIdle, 
			Float:get_member(ent, m_Weapon_flTimeWeaponIdle) * get_pcvar_float(pcvar));
	}
}

public PlayerClassInfo:Zombie@ClassInfo()
{
	return g_oClassInfo;
}

public OnKnifePrimaryAttack(ent)
{
	if (!is_entity(ent))
		return HAM_IGNORED;
	
	new player = get_member(ent, m_pPlayer);
	if (!player)
		return HAM_IGNORED;
	
	new PlayerClass:class_o = oo_playerclass_get(player)
	if (class_o != @null && oo_isa(class_o, "Zombie"))
	{
		return oo_call(class_o, "OnKnifeAttack1", ent) ? HAM_SUPERCEDE : HAM_IGNORED;
	}

	return HAM_IGNORED;
}

public OnKnifeSecondaryAttack(ent)
{
	if (!is_entity(ent))
		return HAM_IGNORED;
	
	new player = get_member(ent, m_pPlayer);
	if (!player)
		return HAM_IGNORED;
	
	new PlayerClass:class_o = oo_playerclass_get(player)
	if (class_o != @null && oo_isa(class_o, "Zombie"))
	{
		return oo_call(class_o, "OnKnifeAttack2", ent) ? HAM_SUPERCEDE : HAM_IGNORED;
	}

	return HAM_IGNORED;
}

public OnKnifePrimaryAttack_Post(ent)
{
	if (!is_entity(ent))
		return;
	
	new player = get_member(ent, m_pPlayer);
	if (!player)
		return;
	
	new PlayerClass:class_o = oo_playerclass_get(player)
	if (class_o != @null && oo_isa(class_o, "Zombie"))
	{
		oo_call(class_o, "OnKnifeAttack1_Post", ent);
	}
}

public OnKnifeSecondaryAttack_Post(ent)
{
	if (!is_entity(ent))
		return;
	
	new player = get_member(ent, m_pPlayer);
	if (!player)
		return;
	
	new PlayerClass:class_o = oo_playerclass_get(player)
	if (class_o != @null && oo_isa(class_o, "Zombie"))
	{
		oo_call(class_o, "OnKnifeAttack2_Post", ent);
	}
}

public CS_OnPainShock_Post(victim, inflictor, attacker, Float:damage, damagebits, &Float:value)
{
	new PlayerClass:class_o = oo_playerclass_get(victim);
	if (class_o != @null && oo_isa(class_o, "Zombie"))
	{
		oo_call(class_o, "OnPainShockBy", attacker, damage, value);
	}

	class_o = oo_playerclass_get(attacker);
	if (class_o != @null && oo_isa(class_o, "Zombie"))
	{
		oo_call(class_o, "OnPainShock", victim, damage, value);
	}
}

public CS_OnKnockBack_Post(victim, attacker, Float:damage, tr, Float:vec[3])
{
	new PlayerClass:class_o = oo_playerclass_get(victim)
	if (class_o != @null && oo_isa(class_o, "Zombie"))
	{
		oo_call(class_o, "OnKnockBack", attacker, damage, tr, vec);
	}
}