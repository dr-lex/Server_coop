#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required; 

#define MOVETYPE_WALK 2
#define MOVETYPE_FLYGRAVITY 5
#define MOVECOLLIDE_DEFAULT 0
#define MOVECOLLIDE_FLY_BOUNCE 1

#define TEAM_INFECTED 3

#define CVAR_FLAGS FCVAR_NONE

#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)

#define IS_VALID_INGAME(%1) (IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))

#define IS_VALID_SURVIVOR(%1) (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_INGAME(%1) && IS_INFECTED(%1))

#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

float g_fFlySpeed = 50.0;
float g_fMaxSpeed = 500.0;

bool Flying[MAXPLAYERS+1];

#define PLUGIN_VERSION "1.1.1a"

public Plugin myinfo =
{
	name = "L4D Ghost Fly",
	author = "Madcap (modified by dcx2)",
	description = "Fly as a ghost.",
	version = PLUGIN_VERSION,
	url = "http://maats.org"
}


public void OnPluginStart()
{
	CreateConVar("l4d_ghost_fly_version", PLUGIN_VERSION, " Ghost Fly Plugin Version ", FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("ghost_spawn_time", EventGhostNotify2);
	HookEvent("player_first_spawn", EventGhostNotify1);
}

public void OnClientConnected(int client)
{
	Flying[client] = false;
}

// moving this outside of to save initialization,
bool elig;

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	elig = IS_VALID_INFECTED(client) && IsPlayerGhost(client);
	if (elig && buttons & IN_RELOAD)
	{
		if (Flying[client])
		{
			KeepFlying(client);
		}
		else
		{
			StartFlying(client);
		}
	}
	else if (Flying[client])
	{
		StopFlying(client);
	}
	return Plugin_Continue;
}

stock bool IsPlayerGhost(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isGhost", 1) > 0);
}

public Action StartFlying(int client)
{
	Flying[client]=true;
	SetMoveType(client, MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE);
	AddVelocity(client, g_fFlySpeed);
	return Plugin_Continue;
}

public Action KeepFlying(int client)
{
	AddVelocity(client, g_fFlySpeed);
	return Plugin_Continue;
}

public Action StopFlying(int client)
{
	Flying[client]=false;
	SetMoveType(client, MOVETYPE_WALK, MOVECOLLIDE_DEFAULT);
	return Plugin_Continue;
}

int AddVelocity(int client, float speed)
{
	float vecVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVelocity);
	vecVelocity[2] += speed;
	if ((vecVelocity[2]) > g_fMaxSpeed)
	{
		vecVelocity[2] = g_fMaxSpeed;
	}

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
	return 0;
}

int SetMoveType(int client, int movetype, int movecollide)
{
	SetEntProp(client, Prop_Send, "movecollide", movecollide);
	SetEntProp(client, Prop_Send, "movetype", movetype);
	return 0;
}

public void EventGhostNotify1(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	Notify(client,0);
}

public void EventGhostNotify2(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	Notify(client,GetEventInt(event, "spawntime"));
}

public int Notify(int client, int time)
{
	CreateTimer((3.0+time), NotifyClient, client);
	return 0;
}

public Action NotifyClient(Handle timer, any client)
{
	if (IS_VALID_INFECTED(client) && IsPlayerGhost(client))
	{
		PrintToChat(client, "As a ghost you can fly by holding your RELOAD button.");
	}
	return Plugin_Continue;
}
