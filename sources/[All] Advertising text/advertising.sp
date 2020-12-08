#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

ConVar Cvar_VKontakte_Group_Name;
ConVar Cvar_ServerIP;

public Plugin myinfo =
{
	name = "[All] Advertising text",
	author = "dr lex",
	description = "Shows text message in chat",
	version = "1.1",
	url = "http://steamcommunity.com/id/dr_lex"
}

public void OnPluginStart()
{
	Cvar_VKontakte_Group_Name = CreateConVar("hm_vkontakte_group_name", "no", "Устанавливает название VK-группы сервера", FCVAR_NONE);
	Cvar_ServerIP = CreateConVar("hm_server_ip", "no", "", FCVAR_NONE);
	
	LoadTranslations("advertising.phrases");
}

public void OnMapStart()
{
	CreateTimer(60.0, Timer_Message, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Message(Handle hTimer)
{
	char HostName[96];
	FindConVar("hostname").GetString(HostName, sizeof(HostName));
	char ServerIP[96];
	Cvar_ServerIP.GetString(ServerIP, sizeof(ServerIP));
	char VKontakteGroupName[96];
	Cvar_VKontakte_Group_Name.GetString(VKontakteGroupName, sizeof(VKontakteGroupName));
	
	int i, iCount;
	for (i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			switch(GetRandomInt(1, 6))
			{
				case 1: PrintToChat(i, "\x05%t \x04%s", "Spamtxt1", HostName);
				case 2: PrintToChat(i, "\x05%t", "Spamtxt2");
				case 3: PrintToChat(i, "\x05%t \x04%s", "Spamtxt3", ServerIP);
				case 4: PrintToChat(i, "\x05%t \x04%s", "Spamtxt4", VKontakteGroupName);
				case 5: PrintToChat(i, "\x05%t", "Spamtxt5");
				case 6: PrintToChat(i, "\x05%t", "Spamtxt6");
			}
			++iCount;
		}
	}
	
	if (iCount == 0)
	{
		return Plugin_Stop; 
	}
	
	return Plugin_Continue;
}
