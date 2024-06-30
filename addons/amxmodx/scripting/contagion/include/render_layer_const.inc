#if defined _render_layer_const_included
	#endinput
#endif
#define _render_layer_const_included

enum _:RenderingData
{
	render_fx,
	render_mode,
	render_color[3],
	render_amount,
	Float:render_until,
	render_class[32],
	render_index,
	render_zindex
};