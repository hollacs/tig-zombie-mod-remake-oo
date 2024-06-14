#include <amxmodx>

public plugin_init()
{
	register_plugin("Remove Corpse", "0.1", "holla");

	register_message(get_user_msgid("ClCorpse"), "OnMessageCorpse");
}

public OnMessageCorpse()
{
	return PLUGIN_HANDLED;
}