#if defined _tig_nightvision_included
	#endinput
#endif
#define _tig_nightvision_included

native tig_nightvision_set(id, bool:value);

native bool:tig_nightvision_get(id);

native tig_nightvision_toggle(id, bool:toggle);