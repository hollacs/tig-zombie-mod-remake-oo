#if defined _ctg_player_level_included
	#endinput
#endif
#define _ctg_player_level_included

forward CTG_OnPlayerLevelUp(id, level);
forward CTG_OnPlayerLevelChange(id, old_level, new_level);
forward CTG_OnPlayerLevelChange_Post(id, old_level, new_level);
forward CTG_OnPlayerAddExp(id, &exp, bool:notify);
forward CTG_OnPlayerAddExp_Post(id, exp, bool:notify);

native ctg_get_player_level(id);
native ctg_get_player_exp(id);
native ctg_get_required_exp(level);
native ctg_set_player_level(id, level);
native ctg_add_player_exp(id, exp, bool:notify=true);