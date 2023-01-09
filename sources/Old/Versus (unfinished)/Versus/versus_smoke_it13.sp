#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

bool Grabbed[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Smoke'n Move",
	author = "Olj, raziEiL [disawar1]",
	description = "Wanna move while smoking? No problem!",
	version = "1.3",
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	HookEvent("tongue_grab", GrabEvent, EventHookMode_Pre);
	HookEvent("tongue_release", ReleaseEvent, EventHookMode_Pre);
}

public void OnClientPutInServer(int client)
{
	Grabbed[client] = false;
}

public void GrabEvent(Event event, const char[] name, bool dontBroadcast)
{
	int Smoker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFakeClient(Smoker))
	{
		return;
	}
	Grabbed[Smoker] = true;
	
	int Victim = GetClientOfUserId(GetEventInt(event, "victim"));
	SetEntityMoveType(Smoker, MOVETYPE_ISOMETRIC);
	SetEntPropFloat(Smoker, Prop_Send, "m_flLaggedMovementValue", 0.20);
	Handle pack;
	CreateDataTimer(0.2, RangeCheckTimerFunction, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	WritePackCell(pack, Smoker);
	WritePackCell(pack, Victim);
}

public Action RangeCheckTimerFunction(Handle timer, Handle pack)
{
	ResetPack(pack);
	int Smoker = ReadPackCell(pack);
	if (!Grabbed[Smoker])
	{
		return Plugin_Stop;
	}

	int Victim = ReadPackCell(pack);
	if (!IsValidClient(Smoker) || GetClientTeam(Smoker) != 3 || IsFakeClient(Smoker) || !IsSmoker(Smoker) || !IsValidClient(Victim) || GetClientTeam(Victim) != 2)
	{
		Grabbed[Smoker] = false;
		return Plugin_Stop;
	}

	float SmokerPosition[3], VictimPosition[3];
	GetClientAbsOrigin(Smoker,SmokerPosition);
	GetClientAbsOrigin(Victim,VictimPosition);

	if (RoundToNearest(GetVectorDistance(SmokerPosition, VictimPosition)) > 2000)
	{
		SlapPlayer(Smoker, 0, false);
	}
	return Plugin_Continue;
}

public void ReleaseEvent(Event event, const char[] name, bool dontBroadcast)
{
	int Smoker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!Grabbed[Smoker])
	{
		return;
	}
	Grabbed[Smoker] = false;
	SetEntityMoveType(Smoker, MOVETYPE_CUSTOM);
	SetEntPropFloat(Smoker, Prop_Send, "m_flLaggedMovementValue", 1.0);
}

bool IsValidClient(int client)
{
	return client && IsClientInGame(client) && IsPlayerAlive(client);
}

bool IsSmoker(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass") == 1;
}