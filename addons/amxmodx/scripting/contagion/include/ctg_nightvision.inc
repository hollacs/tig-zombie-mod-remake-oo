#if defined _ctg_nightvision_included
	#endinput
#endif
#define _ctg_nightvision_included

native ctg_nightvision_set(id, bool:value);

native bool:ctg_nightvision_get(id);

native ctg_nightvision_toggle(id, bool:toggle);