#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

ConVar g_hConVar_ChargerChargeInterval;
bool g_ButtonDelay[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[L4D2] Infected Release",
	author = "Thraka",
	description = "Allows infected players to release victims with the melee button.",
	version = "1.3a",
	url = "http://forums.alliedmods.net/showthread.php?t=109715"
}

public void OnPluginStart()
{
	g_hConVar_ChargerChargeInterval = FindConVar("z_charge_interval");
}

/*
* ===========================================================================================================
* ===========================================================================================================
* 
* Normal Hooks\Events
* 
* ===========================================================================================================
* ===========================================================================================================
*/

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (client)
	{
		if (buttons & IN_ATTACK2 && !g_ButtonDelay[client])
		{
			if (GetClientTeam(client) == 3)
			{
				int zombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
				switch (zombieClass)
				{
					case 3:
					{
						int h_vic = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
						if (IsValidEntity(h_vic) && h_vic != 0)
						{
							CallOnPounceEnd(client);

							CreateTimer(1.5, ResetDelay, client);
							g_ButtonDelay[client] = true;
						}
					}
					case 5:
					{
						int h_vic = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
						if (IsValidEntity(h_vic) && h_vic != 0)
						{
							ExecuteCommand(client, "dismount");
							
							CreateTimer(1.5, ResetDelay, client);
							g_ButtonDelay[client] = true;
						}
					}
					case 6:
					{
						int h_vic = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
						if (IsValidEntity(h_vic) && h_vic != 0)
						{
							CallOnPummelEnded(client);
							
							if (g_hConVar_ChargerChargeInterval != INVALID_HANDLE)
							{
								CallResetAbility(client, GetConVarFloat(g_hConVar_ChargerChargeInterval));
							}
							
							CreateTimer(1.5, ResetDelay, client);
							g_ButtonDelay[client] = true;
						}
					}
				}
			}
		}
		
		// If delayed, don't let them click
		if (buttons & IN_ATTACK && g_ButtonDelay[client])
		{
			buttons &= ~IN_ATTACK;
		}
		
		// If delayed, don't let them click
		if (buttons & IN_ATTACK2 && g_ButtonDelay[client])
		{
			buttons &= ~IN_ATTACK2;
		}
	}
	return Plugin_Continue;
}

public Action ResetDelay(Handle timer, any client)
{
	g_ButtonDelay[client] = false;
	return Plugin_Continue;
}
/*
* ===========================================================================================================
* ===========================================================================================================
* 
* Private Methods
* 
* ===========================================================================================================
* ===========================================================================================================
*/

void ExecuteCommand(int Client, char[] strCommand)
{
	int flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s", strCommand);
	SetCommandFlags(strCommand, flags);
}

void CallOnPummelEnded(int client)
{
    static Handle hOnPummelEnded = INVALID_HANDLE;
    if (hOnPummelEnded == INVALID_HANDLE)
	{
        Handle hConf = INVALID_HANDLE;
        hConf = LoadGameConfigFile("l4d2_infected_release");
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTerrorPlayer::OnPummelEnded");
        PrepSDKCall_AddParameter(SDKType_Bool,SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_CBasePlayer,SDKPass_Pointer,VDECODE_FLAG_ALLOWNULL);
        hOnPummelEnded = EndPrepSDKCall();
        CloseHandle(hConf);
        if (hOnPummelEnded == INVALID_HANDLE)
		{
            SetFailState("Can't get CTerrorPlayer::OnPummelEnded SDKCall!");
            return;
        }            
    }
    SDKCall(hOnPummelEnded,client,true,-1);
}

void CallOnPounceEnd(int client)
{
    static Handle hOnPounceEnd = INVALID_HANDLE;
    if (hOnPounceEnd == INVALID_HANDLE)
	{
        Handle hConf = INVALID_HANDLE;
        hConf = LoadGameConfigFile("l4d2_infected_release");
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTerrorPlayer::OnPounceEnd");
        hOnPounceEnd = EndPrepSDKCall();
        CloseHandle(hConf);
        if (hOnPounceEnd == INVALID_HANDLE)
		{
            SetFailState("Can't get CTerrorPlayer::OnPounceEnd SDKCall!");
            return;
        }            
    }
    SDKCall(hOnPounceEnd,client);
} 

void CallResetAbility(int client, float time)
{
	static Handle hStartActivationTimer = INVALID_HANDLE;
	if (hStartActivationTimer == INVALID_HANDLE)
	{
		Handle hConf = INVALID_HANDLE;
		hConf = LoadGameConfigFile("l4d2_infected_release");

		StartPrepSDKCall(SDKCall_Entity);

		PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CBaseAbility::StartActivationTimer");
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);

		hStartActivationTimer = EndPrepSDKCall();
		CloseHandle(hConf);
		
		if (hStartActivationTimer == INVALID_HANDLE)
		{
			SetFailState("Can't get CBaseAbility::StartActivationTimer SDKCall!");
			return;
		}            
	}
	int AbilityEnt = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	SDKCall(hStartActivationTimer, AbilityEnt, time, 0.0);
}