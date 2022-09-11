#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

public Plugin myinfo = 
{
	name = "[L4D2] Laser drop", 
	author = "dr lex", 
	description = "Allows the player to reset the laser", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/dr_lex/"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_laser", CMD_laser);
}

public Action CMD_laser(int client, int args)
{
	if (IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			if (GetClientTeam(client) == 2)
			{
				if (IsPlayerAlive(client) && !IsPlayerIncapped(client))
				{
					int iSlot0 = GetPlayerWeaponSlot(client, 0);
					if (iSlot0 > 0)
					{
						int ig_prop1 = GetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec");
						if (ig_prop1 >= 4)
						{
							ig_prop1 -= 4;
							SetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", ig_prop1);
							ReplaceAmmoWithLaser(client);
						}
						else
						{
							PrintToChat(client, "You don't have a laser");
						}
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

stock void ReplaceAmmoWithLaser(int client)
{
	int iEnt = CreateEntityByName("upgrade_laser_sight");
	if (iEnt == -1)
	{
		return;
	}
	float vecOrigin[3];
	float angRotation[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vecOrigin);
	GetEntPropVector(client, Prop_Send, "m_angRotation", angRotation);		
	TeleportEntity(iEnt, vecOrigin, angRotation, NULL_VECTOR);
	DispatchSpawn(iEnt);
}

stock bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
	{
		return true;
	}
	return false;
}