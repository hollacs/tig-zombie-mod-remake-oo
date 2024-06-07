#include <amxmodx>
#include <reapi>

new cvar_flags[32];

public plugin_init()
{
	register_plugin("[CS] Money", "0.1", "holla");

	RegisterHookChain(RG_CBasePlayer_AddAccount, "OnAddAccount");

	bind_pcvar_string(create_cvar("cs_money_reward", ""), cvar_flags, charsmax(cvar_flags));
}

public OnAddAccount(id, amount, RewardType:type, bool:change)
{
	if (type == RT_NONE)
		return HC_CONTINUE;

	new flags = read_flags(cvar_flags);
	if (flags & (1 << _:type-1))
		return HC_CONTINUE;

	return HC_SUPERCEDE;
}