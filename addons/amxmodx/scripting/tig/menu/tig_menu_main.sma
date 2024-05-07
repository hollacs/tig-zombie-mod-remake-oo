#include <amxmodx>
#include <cstrike>
#include <oo_player_class>
#include <oo>

new Store:g_oStore;
new ZombieRaceMenu:g_oZRaceMenu;
new g_WeaponMenu[2];
new g_DisabledCallback;

public plugin_init()
{
	register_plugin("[CTG] Menu: Main", "0.1", "holla");

	register_clcmd("chooseteam", "CmdChooseTeam");

	g_oStore = any:oo_call(0, "TigStore@GetInstance");

	g_WeaponMenu[0] = find_plugin_byfile("tig_menu_default_weapons.amxx");
	if (g_WeaponMenu[0] != -1)
		g_WeaponMenu[1] = get_func_id("ShowWeaponMenu", g_WeaponMenu[0]);

	g_oZRaceMenu = any:oo_call(0, "ZombieRaceMenu@GetInstance");

	g_DisabledCallback = menu_makecallback("DisabledCallback");
}

public ShowMainMenu(id)
{
	new menu = menu_create("Contagion", "HandleMainMenu");

	menu_additem(menu, "Choose Weapon", .callback=(g_WeaponMenu[1] == -1) ? g_DisabledCallback : -1);
	menu_additem(menu, "Buy", .callback=(g_oStore == @null) ? g_DisabledCallback : -1);
	menu_additem(menu, "Choose Zombie Race", .callback=(g_oZRaceMenu == @null) ? g_DisabledCallback : -1);
	menu_addblank2(menu);
	menu_addblank2(menu);
	menu_additem(menu, "Choose Team");

	menu_display(id, menu);
}

public HandleMainMenu(id, menu, item)
{
	menu_destroy(menu);

	switch (item)
	{
		case 0:
		{
			if (is_user_alive(id) && oo_playerclass_isa(id, "Human"))
			{
				callfunc_begin_i(g_WeaponMenu[1], g_WeaponMenu[0]);
				callfunc_push_int(id);
				callfunc_push_int(1);
				callfunc_end();
			}
		}
		case 1:
		{
			oo_call(g_oStore, "ShowMenu", id, 0, -1);
		}
		case 2:
		{
			oo_call(g_oZRaceMenu, "ShowMenu", id);
		}
		case 5:
		{
			engclient_cmd(id, "chooseteam");
		}
	}
}

public CmdChooseTeam(id)
{
	new CsTeams:team = cs_get_user_team(id);
	if (team == CS_TEAM_UNASSIGNED || team == CS_TEAM_SPECTATOR)
		return PLUGIN_CONTINUE;
	
	ShowMainMenu(id);
	return PLUGIN_HANDLED;
}

public DisabledCallback(id, menu, item)
{
	return ITEM_DISABLED;
}