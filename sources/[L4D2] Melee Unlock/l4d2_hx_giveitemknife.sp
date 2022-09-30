#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

public Plugin myinfo =
{
	name = "[L4D2] Give Item Knife",
	author = "dr lex",
	description = "L4D2 coop save weapon",
	version = "0.1",
	url = "https://steamcommunity.com/id/dr_lex"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_team", Event_PlayerTeam);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.2, HxTimerRS, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action HxTimerRS(Handle timer)
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				HxGetSlot1(i);
			}
		}
		i += 1;
	}
	return Plugin_Stop;
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client)
	{
		if (event.GetInt("team") == 2)
		{
			CreateTimer(1.0, HxTimerTeam2, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action HxTimerTeam2(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (GetClientTeam(client) == 2)
		{
			HxGetSlot1(client);
		}
		if (!IsPlayerAlive(client))
		{
			CreateTimer(2.0, HxTimerTeam2, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Stop;
}

public void HxGetSlot1(int &client)
{
	if (IsPlayerAlive(client))
	{
		int iq_pistol = 0;
		int iSlot1 = GetPlayerWeaponSlot(client, 1);
		if (iSlot1 > 0)
		{
			char sg_Weapon[64];
			GetEntPropString(iSlot1, Prop_Data, "m_ModelName", sg_Weapon, sizeof(sg_Weapon)-1);
			if (StrContains(sg_Weapon, "v_pistol", true) != -1) // v_pistolA.mdl
			{
				iq_pistol = 1;
			}
			//if (StrContains(sg_Weapon, "dual_pistol", true) != -1) //v_dual_pistolA.mdl
			//{
			//	iq_pistol = 1;
			//}
			
			if (iq_pistol)
			{
				RemovePlayerItem(client, iSlot1);
				AcceptEntityInput(iSlot1, "Kill");
				
				GivePlayerItem(client, "knife");
			}
		}
	}
}