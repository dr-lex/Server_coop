#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

int laggedMovementOffset = 0;

public void OnPluginStart()
{
	HookEvent("jockey_ride", Event_JockeyRideStart);
	HookEvent("jockey_ride_end", Event_JockeyRideEnd);
	
	laggedMovementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
}

public void Event_JockeyRideStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (IsValidClient(client) && IsValidClient(victim))
	{
		SetEntDataFloat(victim, laggedMovementOffset, 1.5, true);
	}
}

public void Event_JockeyRideEnd(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (IsValidClient(victim))
	{
		SetEntDataFloat(victim, laggedMovementOffset, 1.0, true);
	}
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client));
}