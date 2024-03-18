#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <fakemeta>
#include <hamsandwich>
#include <json>
#include <oo_assets>

#define var_nade_obj var_flTimeStepSound

new Array:g_aGrenades;
new g_GreandeCount;

public oo_init()
{
	oo_class("GrenadeInfo", "Assets")
	{
		new cl[] = "GrenadeInfo";
		oo_var(cl, "class", 32);

		oo_ctor(cl, "Ctor", @str(class));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "LoadJson", @str(filename));
		oo_mthd(cl, "Condition", @int(id), @str(class));
		oo_mthd(cl, "SetWeaponModel", @int(ent));
	}

	oo_class("Grenade")
	{
		new cl[] = "Grenade";
		oo_var(cl, "ent", 1);
		oo_var(cl, "is_detonated", 1);

		oo_ctor(cl, "Ctor", @int(ent));
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "Think");
		oo_mthd(cl, "Touch", @int(toucher));
		oo_mthd(cl, "Detonate");
		oo_mthd(cl, "DetonateEffect");
		oo_mthd(cl, "PlayDetonateSound");
		oo_mthd(cl, "GetInfo");
		oo_mthd(cl, "SetWorldModel");
		oo_mthd(cl, "RemoveEntity");
	}
}

public plugin_precache()
{
	g_aGrenades = ArrayCreate(1);
}

public plugin_init()
{
	register_plugin("[OO] Grenade", "0.1", "holla");

	register_forward(FM_SetModel, "OnSetModel");
	register_forward(FM_RemoveEntity, "OnRemoveEntity");

	RegisterHam(Ham_Think, "grenade", "OnGrenadeThink");
	RegisterHam(Ham_Touch, "grenade", "OnGreandeTouch");

	RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "OnGrenadeDeploy_Post", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_flashbang", "OnGrenadeDeploy_Post", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_smokegrenade", "OnGrenadeDeploy_Post", 1);
}

public GrenadeInfo@Ctor(const class[])
{
	new this = oo_this();
	oo_super_ctor("Assets");
	oo_set_str(this, "class", class);

	ArrayPushCell(g_aGrenades, this);
	g_GreandeCount++;
}

public GrenadeInfo@SetWeaponModel(ent)
{
	new this = oo_this();

	new id = get_member(ent, m_pPlayer);
	if (is_user_alive(id))
	{
		static v_model[64];
		if (AssetsGetModel(this, "v_model", v_model, charsmax(v_model)))
			set_entvar(id, var_viewmodel, v_model);

		static p_model[64];
		if (AssetsGetModel(this, "p_model", p_model, charsmax(p_model)))
			set_entvar(id, var_weaponmodel, p_model);
	}
}

public GrenadeInfo@LoadJson(const filename[])
{
	new this = oo_this();

	static filepath[100];
	get_configsdir(filepath, charsmax(filepath));
	format(filepath, charsmax(filepath), "%s/grenade/%s.json", filepath, filename);

	return oo_call(this, "Assets@LoadJson", filepath);
}

public GrenadeInfo@Dtor() {}

public GrenadeInfo@Condition()
{
	return false;
}

public Grenade@Ctor(ent)
{
	new this = oo_this();
	oo_set(this, "ent", ent);
	oo_set(this, "is_detonated", false);
	set_entvar(ent, var_nade_obj, this);
}

public Grenade@Dtor()
{
	new this = oo_this();

	new ent = oo_get(this, "ent");
	if (is_entity(ent))
		oo_call(this, "RemoveEntity");
}

public Grenade@SetWorldModel()
{
	new this = oo_this();

	new GrenadeInfo:info_o = any:oo_call(this, "GetInfo");
	if (info_o != @null)
	{
		static w_model[64];
		if (AssetsGetModel(info_o, "w_model", w_model, charsmax(w_model)))
		{
			new ent = oo_get(this, "ent");
			engfunc(EngFunc_SetModel, ent, w_model);
			return true;
		}
	}

	return false;
}

public Grenade@GetInfo()
{
	return @null;
}

public Grenade@Think()
{
	new this = oo_this();
	new ent = oo_get(this, "ent");

	if (!oo_get(this, "is_detonated"))
	{
		if (Float:get_entvar(ent, var_dmgtime) <= get_gametime())
		{
			oo_call(this, "Detonate");
			return true;
		}
	}
	else
	{
		return true;
	}

	return false;
}

public Grenade@Touch(toucher) {}

public Grenade@Detonate()
{
	new this = oo_this();
	oo_set(this, "is_detonated", true);
	oo_call(this, "PlayDetonateSound");
	oo_call(this, "DetonateEffect");
	oo_delete(this);
}

public Grenade@DetonateEffect() {}

public Grenade@PlayDetonateSound()
{
	new this = oo_this();
	new ent = oo_get(this, "ent");

	oo_set(this, "is_detonated", true);

	new GrenadeInfo:info = any:oo_call(this, "GetInfo");
	if (info != @null)
	{
		new Array:sounds_a = AssetsGetSound(info, "detonate");
		if (sounds_a != Invalid_Array)
		{
			static sound[64];
			ArrayGetString(sounds_a, random(ArraySize(sounds_a)), sound, charsmax(sound));
			emit_sound(ent, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
	}
}

public Grenade@RemoveEntity()
{
	new ent = oo_get(oo_this(), "ent");
	if (is_entity(ent))
		engfunc(EngFunc_RemoveEntity, ent);
}

public OnGrenadeDeploy_Post(ent)
{
	if (!is_entity(ent))
		return;

	static class[32];
	get_entvar(ent, var_classname, class, charsmax(class));

	new id = get_member(ent, m_pPlayer);
	if (!is_user_alive(id))
		return;

	new GrenadeInfo:info_o;
	for (new i = 0; i < g_GreandeCount; i++)
	{
		info_o = any:ArrayGetCell(g_aGrenades, i);
		if (oo_call(info_o, "Condition", id, class[7]))
		{
			oo_call(info_o, "SetWeaponModel", ent);
		}
	}
}

public OnSetModel(ent, model[])
{
	if (strlen(model) < 8)
		return FMRES_IGNORED;

	if (model[7] != 'w' || model[8] != '_')
		return FMRES_IGNORED;

	if (Float:get_entvar(ent, var_dmgtime) == 0.0)
		return FMRES_IGNORED;

	new owner = get_entvar(ent, var_owner);
	model[strlen(model) - 4] = 0;

	new GrenadeInfo:info_o;
	for (new i = 0; i < g_GreandeCount; i++)
	{
		info_o = any:ArrayGetCell(g_aGrenades, i);
		if (oo_call(info_o, "Condition", owner, model[9]))
		{
			new class[32];
			oo_get_str(info_o, "class", class, sizeof(class));
			return oo_call(oo_new(class, ent), "SetWorldModel") ? FMRES_SUPERCEDE : FMRES_IGNORED;
		}
	}

	return FMRES_IGNORED;
}

public OnRemoveEntity(ent)
{
	if (!is_entity(ent))
		return HAM_IGNORED;

	new Grenade:nade_o = any:get_entvar(ent, var_nade_obj);
	if (oo_object_exists(nade_o))
	{
		oo_delete(nade_o);
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public OnGrenadeThink(ent)
{
	if (!is_entity(ent))
		return HAM_IGNORED;

	new Grenade:nade_o = any:get_entvar(ent, var_nade_obj);
	if (oo_object_exists(nade_o))
	{
		return oo_call(nade_o, "Think") ? HAM_SUPERCEDE : HAM_IGNORED;
	}

	return HAM_IGNORED;
}

public OnGreandeTouch(ent, toucher)
{
	if (!is_entity(ent))
		return;

	new Grenade:nade_o = any:get_entvar(ent, var_nade_obj);
	if (oo_object_exists(nade_o))
	{
		oo_call(nade_o, "Touch", toucher);
	}
}