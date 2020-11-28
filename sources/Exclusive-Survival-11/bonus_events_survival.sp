#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

int ig_start_map[MAXPLAYERS+1];
int ig_iTimer;
int ig_iTimerFix;

#define SOUND_BLIP "level/bell_impact.wav"

char sg_file[160];
char sMap[55];
char sMedal[40];
char sBuffer[50];

Handle Timers = null;

public Plugin myinfo = 
{
	name = "L4D2 Bonus Events",
	author = "dr lex (Exclusive Survival-11)",
	description = "Gives rewards for completing assignments",
	version = "1.2.1",
	url = ""
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_event", Cmd_event, "", FCVAR_NONE);
	
	HookEvent("survival_round_start", Event_SurvRoundStart);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
}

public void OnConfigsExecuted()
{
	char sBuf[12];
	
	FormatTime(sBuf, sizeof(sBuf)-1, "%Y-%U", GetTime());
	BuildPath(Path_SM, sg_file, sizeof(sg_file)-1, "data/%s_medals.txt", sBuf);
}

public void OnMapStart()
{
	ig_iTimer = 0;
	ig_iTimerFix = 0;
	GetCurrentMap(sMap, 54);
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		ig_start_map[client] = 0;
	}
}

public void OnClientDisconnect(int client)
{
	if (!IsFakeClient(client))
	{
		ig_start_map[client] = 0;
	}
}

public void Event_SurvRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ig_iTimer = 0;
	ig_iTimerFix = 1;
	
	int i = 1;
	while (i <= MaxClients)
	{
		ig_start_map[i] = 1;
		i += 1;
	}
	
	Timers = CreateTimer(60.0, Timer_Medal, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (ig_iTimerFix)
	{
		ig_iTimerFix = 0;
		if (Timers != null)
		{
			delete Timers;
			Timers = null;
		}
	}
	
	int i = 1;
	while (i <= MaxClients)
	{
		ig_start_map[i] = 0;
		i += 1;
	}
}

public Action Timer_Medal(Handle timer)
{
	ig_iTimer += 1;
	if (ig_iTimer == 4)
	{
		int i = 1;
		while (i <= MaxClients)
		{
			Medal1(i);
			i += 1;
		}
	}
	if (ig_iTimer == 7)
	{
		int i = 1;
		while (i <= MaxClients)
		{
			Medal2(i);
			i += 1;
		}
	}
	if (ig_iTimer == 10)
	{
		int i = 1;
		while (i <= MaxClients)
		{
			Medal3(i);
			i += 1;
		}
	}
	if (ig_iTimer == 30)
	{
		int i = 1;
		while (i <= MaxClients)
		{
			Medal4(i);
			i += 1;
		}
	}
	if (ig_iTimer == 31)
	{
		if (Timers != null)
		{
			delete Timers;
			Timers = null;
		}
	}
}

public void Medal1(int client)
{
	if (HxValidClient(client))
	{
		if (ig_start_map[client])
		{
			KeyValues hGM = new KeyValues("data");
			hGM.ImportFromFile(sg_file);

			char s1[32];
			GetClientAuthId(client, AuthId_Steam2, s1, sizeof(s1)-1);
		
			hGM.JumpToKey(s1, true);

			sMedal[0] = '\0';
			Format(sMedal, sizeof(sMedal)-1, "%s", sMap);

			int iNum1 = hGM.GetNum(sMedal, 0);
			iNum1 += 1;
			if (iNum1 == 1)
			{
				ServerCommand("sm_setnomoney 4 %s", s1);
				PrintToChat(client, "\x04[Medal] \x05Bronze \x01+4¤");
				
				hGM.SetNum(sMedal, iNum1);
				hGM.Rewind();
				hGM.ExportToFile(sg_file);
			}
			delete hGM;
		}
	}
}

public void Medal2(int client)
{
	if (HxValidClient(client))
	{
		if (ig_start_map[client])
		{
			KeyValues hGM = new KeyValues("data");
			hGM.ImportFromFile(sg_file);
			
			char s1[32];
			GetClientAuthId(client, AuthId_Steam2, s1, sizeof(s1)-1);
			
			hGM.JumpToKey(s1, true);
			
			sMedal[0] = '\0';
			Format(sMedal, sizeof(sMedal)-1, "%s", sMap);
			
			int iNum1 = hGM.GetNum(sMedal, 0);
			iNum1 += 1;
			if (iNum1 == 2)
			{
				ServerCommand("sm_setnomoney 7 %s", s1);
				PrintToChat(client, "\x04[Medal] \x05Silver \x01+7¤");
				
				hGM.SetNum(sMedal, iNum1);
				hGM.Rewind();
				hGM.ExportToFile(sg_file);
			}
			delete hGM;
		}
	}
}

public void Medal3(int client)
{
	if (HxValidClient(client))
	{
		if (ig_start_map[client])
		{
			KeyValues hGM = new KeyValues("data");
			hGM.ImportFromFile(sg_file);
			
			char s1[32];
			GetClientAuthId(client, AuthId_Steam2, s1, sizeof(s1)-1);
			
			hGM.JumpToKey(s1, true);
			
			sMedal[0] = '\0';
			Format(sMedal, sizeof(sMedal)-1, "%s", sMap);
			
			int iNum1 = hGM.GetNum(sMedal, 0);
			iNum1 += 1;
			if (iNum1 == 3)
			{
				ServerCommand("sm_setnomoney 10 %s", s1);
				PrintToChat(client, "\x04[Medal] \x05Gold \x01+10¤");
				
				hGM.SetNum(sMedal, iNum1);
				hGM.Rewind();
				hGM.ExportToFile(sg_file);
			}
			delete hGM;
		}
	}
}

public void Medal4(int client)
{
	if (HxValidClient(client))
	{
		if (ig_start_map[client])
		{
			KeyValues hGM = new KeyValues("data");
			hGM.ImportFromFile(sg_file);
			
			char s1[32];
			GetClientAuthId(client, AuthId_Steam2, s1, sizeof(s1)-1);
			
			hGM.JumpToKey(s1, true);
			
			sMedal[0] = '\0';
			Format(sMedal, sizeof(sMedal)-1, "%s", sMap);
			
			int iNum1 = hGM.GetNum(sMedal, 0);
			iNum1 += 1;
			if (iNum1 == 4)
			{
				ServerCommand("sm_setnomoney 30 %s", s1);
				PrintToChat(client, "\x04[Medal] \x05Platinum \x01+30¤");
				
				hGM.SetNum(sMedal, iNum1);
				hGM.Rewind();
				hGM.ExportToFile(sg_file);
			}
			delete hGM;
		}
	}
}

int HxValidClient(int &i)
{
	if (IsClientInGame(i))
	{
		if (!IsFakeClient(i))
		{
			if (GetClientTeam(i) == 2)
			{
				return 1;
			}
		}
	}
	return 0;
}

public Action Cmd_event(int client, int args)
{
	if (IsClientInGame(client))
	{
		KeyValues hGM2 = new KeyValues("data");
		hGM2.ImportFromFile(sg_file);
		
		char s1[24];
		GetClientAuthId(client, AuthId_Steam2, s1, sizeof(s1)-1);
		
		hGM2.JumpToKey(s1, true);
		
		Format(sBuffer, sizeof(sBuffer)-1, "%s", sMap);
		int Maps = hGM2.GetNum(sBuffer, 0);
		delete hGM2;
		
		Panel hPanel = new Panel();
		hPanel.SetTitle("Event Mission");
		switch (Maps)
		{
			case 0: hPanel.DrawText("Medal: ☆☆☆☆ | No");
			case 1: hPanel.DrawText("Medal: ★☆☆☆ | Bronze");
			case 2: hPanel.DrawText("Medal: ★★☆☆ | Silver");
			case 3: hPanel.DrawText("Medal: ★★★☆ | Gold");
			case 4: hPanel.DrawText("Medal: ★★★★ | Platinum");
		}
		hPanel.DrawText("Bronze > +4¤");
		hPanel.DrawText("Silver > +7¤");
		hPanel.DrawText("Gold > +10¤");
		hPanel.DrawText("Platinum > +30¤");
		hPanel.DrawText(" \n");
		hPanel.DrawItem("Close");
		hPanel.Send(client, PanelHandler, 20);
		delete hPanel;
	}
}

public int PanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}
