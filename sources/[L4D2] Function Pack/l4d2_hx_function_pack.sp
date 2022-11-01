#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define ENTITY_PROPANE	"models/props_junk/propanecanister001a.mdl"
#define ENTITY_OXYGEN	"models/props_equipment/oxygentank01.mdl"
#define ENTITY_GASCAN	"models/props_junk/gascan001a.mdl"

// * native float Hx_Effect_Boom(float fxyz[3]);
// * native float Hx_Effect_Boom2(float fxyz[3]);
// * native float Hx_Effect_Fire(float fxyz[3]);

public Plugin myinfo = 
{
	name = "[L4D2] Function Pack",
	author = "dr lex",
	description = "",
	version = "0.0.0.1",
	url = "https://steamcommunity.com/id/dr_lex/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Hx_Effect_Boom", Native_Hx_Effect_Boom);
	CreateNative("Hx_Effect_Boom2", Native_Hx_Effect_Boom2);
	CreateNative("Hx_Effect_Fire", Native_Hx_Effect_Fire);

	RegPluginLibrary("l4d2_hx_function_pack");
	return APLRes_Success;
}

public void OnMapStart()
{
	CheckPrecacheModel("models/props_junk/propanecanister001a.mdl");
	CheckPrecacheModel("models/props_equipment/oxygentank01.mdl");
	CheckPrecacheModel("models/props_junk/gascan001a.mdl");
}

public void CheckPrecacheModel(const char[] Model)
{
	if (!IsModelPrecached(Model))
	{
		PrecacheModel(Model);
	}
}

//==================================

stock int Native_Hx_Effect_Boom(Handle plugin, int numParams)
{
	float vDir[3];
	GetNativeArray(1, vDir, sizeof(vDir));
	Boom(vDir);
	return 0;
}

stock int Native_Hx_Effect_Boom2(Handle plugin, int numParams)
{
	float vDir[3];
	GetNativeArray(1, vDir, sizeof(vDir));
	Boom2(vDir);
	return 0;
}

stock int Native_Hx_Effect_Fire(Handle plugin, int numParams)
{
	float vDir[3];
	GetNativeArray(1, vDir, sizeof(vDir));
	Fire(vDir);
	return 0;
}

//==================================

stock void Boom(float fxyz[3])
{
	int iEnt = CreateEntityByName("prop_physics", -1);
	if (iEnt > 0)
	{
		DispatchKeyValue(iEnt, "model", ENTITY_PROPANE);
		TeleportEntity(iEnt, fxyz, NULL_VECTOR, NULL_VECTOR);

		DispatchSpawn(iEnt);
		SetEntData(iEnt, GetEntSendPropOffs(iEnt, "m_CollisionGroup"), 1, 1, true);
		AcceptEntityInput(iEnt, "break", -1, -1, 0);
	}
}

stock void Boom2(float fxyz[3])
{
	int iEnt = CreateEntityByName("prop_physics", -1);
	if (iEnt > 0)
	{
		DispatchKeyValue(iEnt, "model", ENTITY_OXYGEN);
		TeleportEntity(iEnt, fxyz, NULL_VECTOR, NULL_VECTOR);

		DispatchSpawn(iEnt);
		SetEntData(iEnt, GetEntSendPropOffs(iEnt, "m_CollisionGroup"), 1, 1, true);
		AcceptEntityInput(iEnt, "break", -1, -1, 0);
	}
}

stock void Fire(float fxyz[3])
{
	int iEnt = CreateEntityByName("prop_physics", -1);
	if (iEnt > 0)
	{
		DispatchKeyValue(iEnt, "model", ENTITY_GASCAN);
		TeleportEntity(iEnt, fxyz, NULL_VECTOR, NULL_VECTOR);

		DispatchSpawn(iEnt);
		SetEntData(iEnt, GetEntSendPropOffs(iEnt, "m_CollisionGroup"), 1, 1, true);
		AcceptEntityInput(iEnt, "break", -1, -1, 0);
	}
}
