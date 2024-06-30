#include <amxmodx>
#include <oo_game_mode>
#include <oo_player_status>
#include <oo_player_class>
#include <cs_painshock>
#include <reapi>
#include <engine>
#include <oo_assets>

new Assets:g_oAssets;

public oo_init()
{
	oo_class("InfectionMode", "ContagionGame");
	{
		new const cl[] = "InfectionMode";

		oo_mthd(cl, "CanInfectPlayer", @int(attacker), @int(victim), @fl(damage));
		oo_mthd(cl, "GetWeight");
		oo_mthd(cl, "Start");
		oo_mthd(cl, "SetPlayerRespawn", @int(id), @fl(delay));
		oo_mthd(cl, "ChooseBoss", @int(id));
	}
}

public plugin_init()
{
	register_plugin("[CTG] Mode: Infection", "0.1", "holla");

	oo_hook_mthd("Zombie", "OnKnifeAttack1", "OnZombieKnifeAttack1", 1);
	oo_hook_mthd("Zombie", "OnKnifeAttack2", "OnZombieKnifeAttack2", 1);
	oo_hook_mthd("RampageStatus", "Set", "OnRampageStatusSet");
	oo_hook_mthd("Zombie", "OnPainShockBy", "OnZombiePainShockBy");

	oo_call(0, "ContagionGame@AddGameMode", oo_new("InfectionMode"));
	g_oAssets = any:oo_call(0, "ContagionGame@Assets");
}

public InfectionMode@ChooseBoss(id)
{
	return false;
}

public InfectionMode@SetPlayerRespawn(id, Float:delay)
{
	oo_player_set_respawn(id, 10.0);
}

public InfectionMode@CanInfectPlayer(attacker, victim, Float:damage)
{
	if (Float:get_entvar(victim, var_armorvalue) <= 0.0)
		return true;
	
	return false;
}

public InfectionMode@GetWeight()
{
	return 30;
}

public InfectionMode@Start()
{
	new this = @this;
	oo_call(this, "GameMode@Start");

	new players[32], num;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i))
			continue;

		if (!IsSpawnablePlayer(i))
			continue;

		if (oo_get(this, "leader") == i)
			continue;

		if (!is_user_alive(i))
			rg_round_respawn(i);

		players[num++] = i;
	}
	
	new max_zombies = floatround(num * 0.1, floatround_ceil);
	new player, rand;

	for (new i = 0; i < max_zombies; i++)
	{
		rand = random(num);
		player = players[rand];
		players[rand] = players[--num];

		oo_playerclass_change(player, "Zombie", true);
		rg_give_item(player, "weapon_hegrenade");

		if (i == 0)
			set_entvar(player, var_health, Float:get_entvar(player, var_health) * floatmax(num * 0.5, 1.0))
		else
			set_entvar(player, var_health, Float:get_entvar(player, var_health) * floatmax(num * 0.25, 1.0))
	}

	set_lights("d");

	set_dhudmessage(0, 255, 0, -1.0, 0.2, 1, 0.0, 3.0, 0.0, 1.0);
	show_dhudmessage(0, "Infection Mode");

	static sound[64];
	if (AssetsGetRandomGeneric(g_oAssets, "game_start", sound, charsmax(sound)))
		client_cmd(0, "spk ^"%s^"", sound);
}

public OnZombieKnifeAttack1(ent)
{
	if (!oo_gamemode_isa("InfectionMode"))
		return;

	new pcvar;
	if ((pcvar = oo_call(@this, "GetCvarPtr", "stab_dist")))
		set_member(ent, m_Knife_flSwingDistance, get_pcvar_float(pcvar));
}

public OnZombieKnifeAttack2(ent)
{
	if (!oo_gamemode_isa("InfectionMode"))
		return;

	new pcvar;
	if ((pcvar = oo_call(@this, "GetCvarPtr", "swing_dist")))
		set_member(ent, m_Knife_flStabDistance, get_pcvar_float(pcvar));
}

public OnZombiePainShockBy(attacker, Float:damage, &Float:value)
{
	new victim = oo_get(@this, "player_id");
	if (oo_gamemode_isa("InfectionMode") && oo_playerstatus_get(victim, "RampageStatus"))
		value *= 1.3;
}

// 暴走設定事件
public OnRampageStatusSet(id, Float:duration, Float:speed, Float:takedmg)
{
	if (!oo_gamemode_isa("InfectionMode")) // 感染模式
		return;

	oo_hook_set_param(2, OO_FLOAT, 5.0); // 改變持續時間
	oo_hook_set_param(4, OO_FLOAT, 1.3); // 改變承受的傷害倍率
}

bool:IsSpawnablePlayer(id)
{
	return (TEAM_TERRORIST <= get_member(id, m_iTeam) <= TEAM_CT) && get_member(id, m_iMenu) != Menu_ChooseAppearance;
}