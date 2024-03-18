#if defined _oo_assets_included
	#endinput
#endif
#define _oo_assets_included

#include <oo>

stock AssetsGetSprite(any:this, const key[])
{
	return oo_call(this, "GetSprite", key);
}

stock AssetsGetModel(any:this, const key[], model[], len)
{
	return oo_call(this, "GetModel", key, model, len);
}

stock bool:AssetsGetOneSound(any:this, const key[], sound[], len)
{
	new Array:sound_a;
	if ((sound_a = any:oo_call(this, "GetSound", key)) != Invalid_Array)
	{
		ArrayGetString(sound_a, 0, sound, len);
		return true;
	}

	return false;
}

stock Array:AssetsGetSound(any:this, const key[])
{
	new Array:sound_a;
	if ((sound_a = any:oo_call(this, "GetSound", key)) != Invalid_Array)
	{
		return sound_a;
	}

	return Invalid_Array;
}