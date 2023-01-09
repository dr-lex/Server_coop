#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "[L4D/L4D2] Snowfall",
	author = "dr_lex",
	description = "Adds snowfall",
	version = "0.1",
	url = "http://steamcommunity.com/id/dr_lex"
}

public void OnPluginStart()
{
	HookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);
}

public void RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.3, CreateSnowFall);
}

public Action CreateSnowFall(Handle timer)
{
	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt , "func_precipitation")) != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iEnt, "Kill");
	}

	iEnt = -1;
	iEnt = CreateEntityByName("func_precipitation");
	if (iEnt != -1)
	{
		char sMap[64];
		float vMins[3], vMax[3], vBuff[3];

		GetCurrentMap(sMap, 64);
		Format(sMap, sizeof(sMap), "maps/%s.bsp", sMap);
		PrecacheModel(sMap, true);

		DispatchKeyValue(iEnt, "model", sMap);
		DispatchKeyValue(iEnt, "preciptype", "3");

		GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMax);
		GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);

		SetEntPropVector(iEnt, Prop_Send, "m_vecMins", vMins);
		SetEntPropVector(iEnt, Prop_Send, "m_vecMaxs", vMax);

		vBuff[0] = vMins[0] + vMax[0];
		vBuff[1] = vMins[1] + vMax[1];
		vBuff[2] = vMins[2] + vMax[2];

		TeleportEntity(iEnt, vBuff, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(iEnt);
		ActivateEntity(iEnt);
	}
	return Plugin_Stop;
}