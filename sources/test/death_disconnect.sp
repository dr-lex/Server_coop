#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

char sg_ar_file[160];

int ig_deadplay[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Death Disconnect",
	author = "dr lex",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/dr_lex"
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsFakeClient(client))
	{
		if (GetClientTeam(client) == 2)
		{
			ig_deadplay[client] = 1;
		}
	}
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	if (!event.GetBool("bot"))
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (client && IsClientInGame(client))
		{
			if (ig_deadplay[client])
			{
				char s1[32];
				event.GetString("networkid", s1, sizeof(s1));
				
				KeyValues h1 = new KeyValues("ban_connect");
				h1.ImportFromFile(sg_ar_file);
				h1.JumpToKey(s1, true);
				
				int iBan = h1.GetNum("ban_connect", 0);
				if (iBan < GetTime())
				{
					int iTimeBan = GetTime() + 60*3;
					h1.SetNum("ban_connect", iTimeBan);
					h1.Rewind();
					h1.ExportToFile(sg_ar_file);
				}
				delete h1;
			}
		}
	}
}

public void OnConfigsExecuted()
{
	BuildPath(Path_SM, sg_ar_file, sizeof(sg_ar_file)-1, "data/Anti_Reconnect.txt");
}

public void OnMapStart()
{
	HXdeletFile(sg_ar_file);
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		ig_deadplay[client] = 0;
		
		char s1[24];
		GetClientAuthId(client, AuthId_Steam2, s1, sizeof(s1)-1);
		
		KeyValues h1 = new KeyValues("ban_connect");
		h1.ImportFromFile(sg_ar_file);
		h1.JumpToKey(s1, true);
		
		int iBan = h1.GetNum("ban_connect", 0);
		if (iBan > GetTime())
		{
			char sTime[24];
			FormatTime(sTime, sizeof(sTime)-1, "%Y-%m-%d %H:%M:%S", iBan);
			KickClient(client,"Banned connect(%s)", sTime);
		}
		delete h1;
	}
}

public void HXdeletFile(char [] sFile)
{
	File hFile = OpenFile(sFile, "w");
	if (hFile != null)
	{
		delete hFile;
	}
}
