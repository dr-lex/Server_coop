#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

ConVar sv_visiblemaxplayers;

int PlayerAfk[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "AFK Autokick",
	author = "Accelerator",
	description = "AutoKick AFK Players",
	version = "3.0",
	url = "http://core-ss.org"
}

public void OnPluginStart()
{
	HookEvent("player_afk", Event_PlayerAfk);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	
	RegConsoleCmd("sm_afktime", Command_AfkTime);
	
	sv_visiblemaxplayers = FindConVar("sv_visiblemaxplayers");
	
	CreateTimer(120.0, TimerCheck, _, TIMER_REPEAT);
}

public Action Command_AfkTime(int client, int args)
{
	int thetarget;
	if (args > 0)
	{
		char target[65];
		GetCmdArg(1, target, sizeof(target));
		
		thetarget = FindTarget(client, target, true, false);
		if (thetarget < 1)
		{
			return Plugin_Handled;
		}
	}
	else
	{
		thetarget = client;
	}
	
	if (!thetarget || !IsClientInGame(thetarget))
	{
		return Plugin_Handled;
	}
		
	if (GetClientTeam(thetarget) != 1)
	{
		return Plugin_Handled;
	}
	
	char time_remain[12];
	TimeRemain(GetTime() - PlayerAfk[thetarget], time_remain, sizeof(time_remain));
	
	PrintToChat(client, "\x05AFK Time (\x04%N\x05): \x03%s", thetarget, time_remain);
	return Plugin_Continue;
}

public Action TimerCheck(Handle timer)
{
	if (GetPlayersCount() > (sv_visiblemaxplayers.IntValue - 2))
	{
		int c = 0;
		for (int i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				if (!IsFakeClient(i))
				{
					if (GetClientTeam(i) == 1)
					{
						if (GetUserAdmin(i) == INVALID_ADMIN_ID)
						{
							if (PlayerAfk[i] > 0)
							{
								int remain = GetTime() - PlayerAfk[i];
								if (remain >= 1080)
								{
									if (c++ < 3)
									{
										KickClient(i, "Afk more 15 minutes!");
									}
								}
								else
								{
									char time_remain[12];
									TimeRemain(remain, time_remain, sizeof(time_remain));
									
									PrintToChat(i, "\x05AFK Time: \x03%s", time_remain);
								}
							}
							else
							{
								PlayerAfk[i] = GetTime();
							}
						}
						else
						{
							PlayerAfk[i] = 0;
						}
					}
					else
					{
						PlayerAfk[i] = 0;
					}
				}
				else
				{
					PlayerAfk[i] = 0;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_PlayerAfk(Event event, char[] name, bool dontBroadcast)
{
	PlayerAfk[GetClientOfUserId(GetEventInt(event, "player"))] = GetTime();
	return Plugin_Continue;
}

public Action Event_PlayerDisconnect(Event event, char[] name, bool dontBroadcast)
{
	PlayerAfk[GetClientOfUserId(GetEventInt(event, "userid"))] = 0;
	return Plugin_Continue;
}

public int GetPlayersCount()
{
	int PlayersCount = 0;
	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				PlayersCount++;
			}
		}
	}
	return PlayersCount;
}

stock void TimeRemain(int seconds, char[] buffer, int maxlen)
{
	if (seconds >= 60)
	{
		Format(buffer, maxlen, "%d min", seconds/60%60);
	}
	else
	{
		Format(buffer, maxlen, "%d sec", seconds);
	}
}