#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

int ig_time[MAXPLAYERS+1];
int ig_time_s[MAXPLAYERS+1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_join", CMD_join, "", 0);
	RegConsoleCmd("sm_kill", CMD_Suicide, "", 0);
}

public void OnMapStart()
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				ig_time_s[i] = 0;
			}
		}
		i += 1;
	}
}

public Action CMD_join(int client, int args)
{
	if (client)
	{
		if (ig_time_s[client] < 2)
		{
			if (!IsFakeClient(client))
			{
				int iTeam = GetClientTeam(client);
				if (iTeam == 1)
				{
					switch(GetRandomInt(1, 2))
					{
						case 1: ChangeClientTeam(client, 2);
						case 2: ChangeClientTeam(client, 3);
					}
					ig_time_s[client] += 1;
				}
				if (iTeam == 2)
				{
					if (IsPlayerAlive(client))
					{
						ChangeClientTeam(client, 3);
						ig_time_s[client] += 1;
					}
				}
				if (iTeam == 3)
				{
					if (!IsPlayerGhost(client))
					{
						if (IsPlayerAlive(client))
						{
							ForcePlayerSuicide(client);
							ChangeClientTeam(client, 2);
							ig_time_s[client] += 1;
						}
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

stock bool IsPlayerGhost(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isGhost", 1) > 0);
}

public Action CMD_Suicide(int client, int args)
{
	if (client)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == 3)
			{
				if (ig_time[client] < GetTime())
				{
					if (IsPlayerAlive(client))
					{
						ig_time[client] = GetTime() + 15;
						ForcePlayerSuicide(client);
					}
				}
			}
		}
	}
	return Plugin_Handled;
}