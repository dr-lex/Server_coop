#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

public Plugin myinfo =
{
	name = "Chainsaw Revive Abuse Fix & Unlimited Chainsaw",
	author = "bullet28",
	description = "Making impossible to use chainsaw while reviving a teammate & Chainsaw fuel always at 100%",
	version = "1.1",
	url = ""
}

bool bIsReviving[MAXPLAYERS+1];

public void OnPluginStart()
{
	HookEvent("round_start", eventRoundStart);
	HookEvent("revive_begin", eventReviveBegin);
	HookEvent("revive_success", eventReviveEnd);
	HookEvent("player_spawn", eventReviveEnd);
	HookEvent("revive_end", eventReviveEnd);
	HookEvent("weapon_fire", eventWeaponFire);
}

public void eventRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		bIsReviving[i] = false;
	}
}

public void eventReviveBegin(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (isPlayerValid(client))
	{
		bIsReviving[client] = true;
	}
}

public void eventReviveEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (isPlayerValid(client))
	{
		bIsReviving[client] = false;
	}
}

public void eventWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	if (event.GetInt("weaponid") == 20)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (!isPlayerAliveSurvivor(client))
		{
			return;
		}

		int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (!isValidEntity(activeWeapon))
		{
			return;
		}

		char classname[32];
		GetEntityClassname(activeWeapon, classname, sizeof(classname));
		if (!StrEqual(classname, "weapon_chainsaw"))
		{
			return;
		}
		SetEntProp(activeWeapon, Prop_Data, "m_iClip1", 30);
	}
}

stock bool isPlayerAliveSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

public void OnPlayerRunCmd(int client, int &buttons)
{
	if (!bIsReviving[client])
	{
		return;
	}
	if (!(buttons & IN_ATTACK))
	{
		return;
	}
	if (!isPlayerRealAliveSurvivor(client))
	{
		return;
	}

	if (GetEntProp(client, Prop_Send, "m_reviveTarget") <= 0)
	{
		bIsReviving[client] = false;
		return;
	}

	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!isValidEntity(activeWeapon))
	{
		return;
	}

	char weaponName[32];
	GetEdictClassname(activeWeapon, weaponName, sizeof(weaponName));
	if (!StrEqual(weaponName, "weapon_chainsaw"))
	{
		return;
	}
	
	ClientCommand(client, "lastinv");
	bIsReviving[client] = false;
}

stock bool isPlayerValid(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock bool isPlayerRealAliveSurvivor(int client)
{
	return isPlayerValid(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

stock bool isValidEntity(int entity)
{
	return entity > 0 && entity <= 2048 && IsValidEdict(entity) && IsValidEntity(entity);
}