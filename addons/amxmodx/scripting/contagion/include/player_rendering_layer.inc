#if defined _player_rendering_layer_included
	#endinput
#endif
#define _player_rendering_layer_included

native render_push(id, fx, Float:color[3], mode, Float:amount, Float:duration=0.0, const class[]="");

native render_pop(id, pop_index, const class[]="");

native render_clear(id);