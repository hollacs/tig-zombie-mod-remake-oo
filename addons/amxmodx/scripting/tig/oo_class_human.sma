#include <amxmodx>
#include <reapi>
#include <oo_player_class>

new PlayerClassInfo:g_oClassInfo;

public plugin_precache()
{
	g_oClassInfo = oo_new("HumanClassInfo", "Human");
	oo_call(g_oClassInfo, "LoadJson", "human");
}

public plugin_init()
{
	register_plugin("[OO] Class: Human", "0.1", "holla");

	oo_call(g_oClassInfo, "CreateCvars");
}

public oo_init()
{
	oo_class("HumanClassInfo", "PlayerClassInfo")
	{
		new const cl[] = "HumanClassInfo";
		oo_mthd(cl, "CreateCvars");
	}

	oo_class("Human", "PlayerClass");
	{
		new const cl[] = "Human";

		oo_ctor(cl, "Ctor", @obj(player));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "GetClassInfo");
		oo_mthd(cl, "SetTeam");
	}
}

public HumanClassInfo@CreateCvars()
{
	new this = oo_this();
	oo_call(this, "CreateCvar", "tig_human", "health", "100");
	oo_call(this, "CreateCvar", "tig_human", "armor", "0");
	oo_call(this, "CreateCvar", "tig_human", "max_armor", "100");
	oo_call(this, "CreateCvar", "tig_human", "gravity", "1.0");
	oo_call(this, "CreateCvar", "tig_human", "speed", "1.0");
}

public Human@Ctor(player)
{
	oo_super_ctor("PlayerClass", player);
}

public Human@Dtor()
{
}

public PlayerClassInfo:Human@GetClassInfo()
{
	return g_oClassInfo;
}

public Human@SetTeam()
{
	new id = oo_get(oo_this(), "player_id");
	rg_set_user_team(id, TEAM_CT, MODEL_UNASSIGNED, true, true);
}