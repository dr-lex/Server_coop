#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define L4D2 Charger Jump

#define ZOMBIECLASS_CHARGER 6

Handle PluginStartTimer = INVALID_HANDLE;
Handle cvarResetDelayTimer[MAXPLAYERS+1];

bool isCharging[MAXPLAYERS+1];
bool buttondelay[MAXPLAYERS+1];
bool isInertiaVault = false;

public Plugin myinfo = 
{
    name = "[L4D2] Charger Jump",
    author = "Mortiegama",
    description = "Allows the Charger to jump while Charging.",
    version = "1.11",
    url = "https://forums.alliedmods.net/showthread.php?p=2116076#post2116076"
};

public void OnPluginStart()
{
	HookEvent("charger_charge_start", Event_ChargeStart);
	HookEvent("charger_charge_end", Event_ChargeEnd);	

	PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action OnPluginStart_Delayed(Handle timer)
{	
	isInertiaVault = true;
	
	if (PluginStartTimer != INVALID_HANDLE)
	{
 		KillTimer(PluginStartTimer);
		PluginStartTimer = INVALID_HANDLE;
	}
	return Plugin_Stop;
}

public Action Event_ChargeStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client))
	{
		isCharging[client] = true;
	}
	return Plugin_Continue;
}

public Action Event_ChargeEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client))
	{
		isCharging[client] = false;
		buttondelay[client] = false;
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (buttons & IN_JUMP && IsValidCharger(client) && isCharging[client])
	{
		if (isInertiaVault && !buttondelay[client] && IsPlayerOnGround(client))
		{
			buttondelay[client] = true;
			float vec[3];
			float power = 400.0;
			vec[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
			vec[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
			vec[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]") + power;
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
			cvarResetDelayTimer[client] = CreateTimer(1.0, ResetDelay, client);
		}
	}
	return Plugin_Continue;
}

public Action ResetDelay(Handle timer, any client)
{
	buttondelay[client] = false;
	if (cvarResetDelayTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarResetDelayTimer[client]);
		cvarResetDelayTimer[client] = INVALID_HANDLE;
	}
	return Plugin_Stop;
}

public void OnMapEnd()
{
    for (int client=1; client<=MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			isCharging[client] = false;
		}
	}
}

public bool IsValidClient(int client)
{
	if (client <= 0)
	{
		return false;
	}
	if (client > MaxClients)
	{
		return false;
	}
	if (!IsClientInGame(client))
	{
		return false;
	}
	if (!IsPlayerAlive(client))
	{
		return false;
	}
	return true;
}

public bool IsPlayerOnGround(int client)
{
	if (GetEntProp(client, Prop_Send, "m_fFlags") & FL_ONGROUND)
	{
		return true;
	}
	else
	{
		return false;
	}
}

public bool IsValidCharger(int client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == ZOMBIECLASS_CHARGER)
		{
			return true;
		}
		return false;
	}
	return false;
}