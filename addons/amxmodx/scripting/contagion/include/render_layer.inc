#if defined _render_layer_included
	#endinput
#endif
#define _render_layer_included

#include <render_layer_const>

native render_push(id, fx=kRenderFxNone, color[3]={0, 0, 0}, mode=kRenderNormal, amount=0, Float:duration=0.0, const class[]="", zindex=0);

native render_pop(id, pop_index=-1, const class[]="");

native render_clear(id);

native render_current(id);

native render_get_data(id, index, data[RenderingData]);