#include <amxmodx>
#include <oo_player_class>

public plugin_init()
{
	register_plugin("[OO] Player Race", "0.1", "holla");
}

public oo_init()
{
	oo_class("PlayerRace")
	{
		new cl[] = "PlayerRace";
		oo_var(cl, "info", 1);
		oo_var(cl, "class", 32);
		oo_var(cl, "desc", 32);

		oo_ctor(cl, "Ctor", @obj(info), @str(class), @str(desc));

		oo_mthd(cl, "GetDesc", @stref(output), @int(len));
		oo_mthd(cl, "GetName", @stref(output), @int(len));
	}

	oo_class("PlayerRaceMenu");
	{
		new cl[] = "PlayerRaceMenu";
		oo_var(cl, "races", 1);
		oo_var(cl, "classes", 1);

		oo_ctor(cl, "Ctor");
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "GetTitle", @int(id), @stref(output), @int(len));
		oo_mthd(cl, "GetItemName", @int(id), @obj(race), @stref(output), @int(len));
		oo_mthd(cl, "ShowMenu", @int(id));
		oo_mthd(cl, "HandleMenu", @int(id), @int(menu), @int(item));
		oo_mthd(cl, "HandlePlayerClassChange", @int(id), @str(class), @bool(set_props));
		oo_mthd(cl, "GetPlayerNextRace", @int(id));
		oo_mthd(cl, "SetPlayerNextRace", @int(id), @obj(race));

		oo_mthd(cl, "AddRace", @obj(race));
		oo_mthd(cl, "AddClass", @str(class));
	}
}

public PlayerRace@Ctor(PlayerClassInfo:info_o, const class[], const desc[])
{
	new this = oo_this();
	oo_set(this, "info", info_o);
	oo_set_str(this, "class", class);
	oo_set_str(this, "desc", desc);
}

public PlayerRace@GetDesc(output[], maxlen)
{
	oo_get_str(oo_this(), "desc", output, maxlen);
}

public PlayerRace@GetName(output[], maxlen)
{
	new this = oo_this();
	new PlayerClassInfo:info_o = any:oo_get(this, "info");
	oo_get_str(info_o, "name", output, maxlen);
}

public PlayerRaceMenu@Ctor()
{
	new this = oo_this();
	oo_set(this, "races", ArrayCreate(1));
	oo_set(this, "classes", TrieCreate());
}

public PlayerRaceMenu@Dtor()
{
	new this = oo_this();
	new Array:races_a = any:oo_get(this, "races");
	new Trie:classes_t = any:oo_get(this, "classes");
	ArrayDestroy(races_a);
	TrieDestroy(classes_t);
}

public PlayerRaceMenu@GetTitle(id, output[], maxlen)
{
	formatex(output, maxlen, "Choose your Player Race:");
}

public PlayerRaceMenu@GetItemName(id, PlayerRace:race_o, output[], maxlen)
{
	new this = oo_this();

	static name[32], desc[32];
	oo_call(race_o, "GetName", name, charsmax(name));
	oo_call(race_o, "GetDesc", desc, charsmax(desc));

	new PlayerRace:next_race_o = any:oo_call(this, "GetPlayerNextRace", id);

	if (next_race_o == race_o)
		formatex(output, maxlen, "\r>> \w%s \r<< \y%s", name, desc);
	else
		formatex(output, maxlen, "%s \y%s", name, desc);
}

public PlayerRaceMenu@ShowMenu(id)
{
	new this = oo_this();

	new Array:races_a = any:oo_get(this, "races");

	static buffer[64], info[16], PlayerRace:race_o;
	oo_call(this, "GetTitle", id, buffer, charsmax(buffer));
	num_to_str(this, info, charsmax(info));

	new menu = menu_create(buffer, "HandleMenu");
	new count = ArraySize(races_a);

	for (new i = 0; i < count; i++)
	{
		race_o = any:ArrayGetCell(races_a, i);
		oo_call(this, "GetItemName", id, race_o, buffer, charsmax(buffer));
		menu_additem(menu, buffer, info);
	}

	if (menu_items(menu) < 1)
	{
		menu_destroy(menu);
		return;
	}

	menu_display(id, menu);
}

public PlayerRaceMenu@HandleMenu(id, menu, item)
{
	new this = oo_this();
	new Array:races_a = any:oo_get(this, "races");
	new PlayerRace:race_o = any:ArrayGetCell(races_a, item);
	oo_call(this, "SetPlayerNextRace", id, race_o);
}

public PlayerRaceMenu@HandlePlayerClassChange(id, const class[], bool:set_props)
{
	new this = oo_this();
	if (TrieKeyExists(Trie:oo_get(this, "classes"), class))
	{
		new Array:races_a = any:oo_get(this, "races");
		new next_race = oo_call(this, "GetPlayerNextRace", id);
		new PlayerRace:race_o = (next_race == @null) ? ArrayGetCell(races_a, random(ArraySize(races_a))) : next_race;

		new PlayerClass:class_o = oo_playerclass_get(id);
		if (class_o != @null)
			oo_delete(class_o);

		static classname[32];
		oo_get_str(race_o, "class", classname, charsmax(classname));

		class_o = oo_new(classname, oo_player_get(id));
		oo_playerclass_set(id, class_o);

		if (set_props)
			oo_call(class_o, "SetProperties", true);
		
		return true;
	}

	return false;
}

public PlayerRaceMenu@GetPlayerNextRace(id)
{
	return @null;
}

public PlayerRaceMenu@SetPlayerNextRace(id, PlayerRace:race_o) {}

public PlayerRaceMenu@AddRace(PlayerRace:race_o)
{
	new this = oo_this();

	new Array:races_a = any:oo_get(this, "races");
	if (!oo_isa(race_o, "PlayerRace"))
	{
		log_error(AMX_ERR_GENERAL, "Object (%d) not a (PlayerRace)", race_o);
		return;
	}

	ArrayPushCell(races_a, race_o);
}

public PlayerRaceMenu@AddClass(const class[])
{
	new Trie:classes_t = any:oo_get(oo_this(), "classes");
	TrieSetCell(classes_t, class, 1);
}

public HandleMenu(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	static info[16], PlayerRaceMenu:menu_o;
	menu_item_getinfo(menu, item, _, info, charsmax(info))
	menu_o = any:str_to_num(info);

	if (oo_object_exists(menu_o))
	{
		oo_call(menu_o, "HandleMenu", id, menu, item);
	}

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}