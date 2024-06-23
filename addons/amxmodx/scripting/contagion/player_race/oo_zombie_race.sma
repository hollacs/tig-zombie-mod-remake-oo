#include <amxmodx>
#include <oo>

new ZombieRaceMenu:g_oMenu;
new PlayerRace:g_NextZombieRace[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("[OO] Zombie Race", "0.1", "holla");

	register_clcmd("say /zclass", "CmdZombieClass");

	oo_hook_mthd("PlayerClass", "Change", "OnPlayerClassChange");
	oo_hook_dtor("Player", "OnPlayerDtor");

	g_oMenu = oo_new("ZombieRaceMenu");
	oo_call(g_oMenu, "AddClass", "Zombie");
}

public oo_init()
{
	oo_class("ZombieRaceMenu", "PlayerRaceMenu")
	{
		new cl[] = "ZombieRaceMenu";
		oo_mthd(cl, "GetTitle", @int(id), @stref(output), @int(len));
		oo_mthd(cl, "GetPlayerNextRace", @int(id));
		oo_mthd(cl, "SetPlayerNextRace", @int(id), @obj(race));

		oo_smthd(cl, "GetInstance");
	}
}

public ZombieRaceMenu@GetTitle(id, output[], maxlen)
{
	formatex(output, maxlen, "Choose your Zombie Race:");
}

public any:ZombieRaceMenu@GetPlayerNextRace(id)
{
	return g_NextZombieRace[id]
}

public ZombieRaceMenu@SetPlayerNextRace(id, PlayerRace:race_o)
{
	g_NextZombieRace[id] = race_o;
}

public any:ZombieRaceMenu@GetInstance()
{
	return g_oMenu;
}

public OnPlayerClassChange(id, const class[], bool:set_props)
{
	return oo_call(g_oMenu, "HandlePlayerClassChange", id, class, set_props) ?
		OO_SUPERCEDE : OO_CONTINUE;
}

public OnPlayerDtor()
{
	new id = oo_get(@this, "player_id");
	g_NextZombieRace[id] = @null;
}

public CmdZombieClass(id)
{
	oo_call(g_oMenu, "ShowMenu", id);
	return PLUGIN_CONTINUE;
}