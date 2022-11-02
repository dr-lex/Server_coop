// SPDX-License-Identifier: GPL-3.0-only
#if defined _hx_unban_included
 #endinput
#endif
#define _hx_unban_included

public void HxListBan(int client)
{
	char sTeamID[64];
	char sName[64];
	char sBuffer[128];
	
	int iBan
	int iMute
	int iGag
	int iVote
	int iTime = GetTime();
	int iDelete;
	
	KeyValues hGM = new KeyValues("gagmute");
	if (hGM.ImportFromFile(sg_file))
	{
		Menu menu = new Menu(MenuHandler_UnBan);
		menu.SetTitle("UnBan");
		
		if (hGM.GotoFirstSubKey())
		{
			while (hGM.GetSectionName(sTeamID, sizeof(sTeamID)-1))
			{				
				sName[0] = '\0';
				hGM.GetString("Name", sName, sizeof(sName)-1, "");
				
				iBan = hGM.GetNum("ban", 0);
				iMute = hGM.GetNum("mute", 0);
				iGag = hGM.GetNum("gag", 0);
				iVote = hGM.GetNum("vote", 0);
				iDelete = 0;
				
				if (iBan > iTime)
				{
					iDelete = 1;
				}
				if (iMute > iTime)
				{
					iDelete = 1;
				}
				if (iGag > iTime)
				{
					iDelete = 1;
				}
				if (iVote > iTime)
				{
					iDelete = 1;
				}
				
				if (iDelete)
				{
					Format(sBuffer, sizeof(sBuffer)-1, "%s %s", sTeamID, sName);
					menu.AddItem(sTeamID, sBuffer);
				}
				
				if (hGM.GotoNextKey())
				{
					continue;
				}
				
				break;
			}
		}
		
		menu.ExitBackButton = true;
		menu.Display(client, 30);
	}
	else
	{
		PrintToChat(client, "\x05[\x04GMB\x05] \x04No data available");
	}
	delete hGM;
}

public int MenuHandler_UnBan(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[64];
			menu.GetItem(param2, info, sizeof(info));
			ListBanPlay(param1, info);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hTopMenu)
			{
				hTopMenu.Display(param1, TopMenuPosition_LastCategory);
			}
		}
	}
	return 0;
}

public Action ListBanPlay(int client, char[] sTeamID)
{
	KeyValues hGM = new KeyValues("gagmute");
	if (hGM.ImportFromFile(sg_file))
	{
		if (hGM.JumpToKey(sTeamID))
		{
			char sTime[32];
			char sName[64];
			hGM.GetString("Name", sName, sizeof(sName)-1, "");
			int iBan = hGM.GetNum("ban", 0);
			int iMute = hGM.GetNum("mute", 0);
			int iGag = hGM.GetNum("gag", 0);
			int iVote = hGM.GetNum("vote", 0);
			int iTime = GetTime();
			
			Panel text = CreatePanel();
			text.SetTitle("List ban");
			text.DrawText(" \n");
			
			text.DrawText(sName);
			text.DrawText(sTeamID);
			
			text.DrawText(" \n");
			
			if (iBan > iTime)
			{
				sTime[0] = '\0';
				FormatTime(sTime, sizeof(sTime)-1, "Ban: %Y-%m-%d %H:%M:%S", iBan);
				text.DrawText(sTime);
			}
			if (iMute > iTime)
			{
				sTime[0] = '\0';
				FormatTime(sTime, sizeof(sTime)-1, "Mute: %Y-%m-%d %H:%M:%S", iMute);
				text.DrawText(sTime);
			}
			if (iGag > iTime)
			{				
				sTime[0] = '\0';
				FormatTime(sTime, sizeof(sTime)-1, "Gag: %Y-%m-%d %H:%M:%S", iGag);
				text.DrawText(sTime);
			}
			if (iVote > iTime)
			{
				sTime[0] = '\0';
				FormatTime(sTime, sizeof(sTime)-1, "Vote: %Y-%m-%d %H:%M:%S", iVote);
				text.DrawText(sTime);
			}
			text.DrawText(" \n");
			
			text.CurrentKey = 8;
			text.DrawItem("Back");
			text.CurrentKey = 10;
			text.DrawItem("Exit");
			
			text.Send(client, PanelHandler, 20);
			delete text;
		}
	}
	delete hGM;
	return Plugin_Handled;
}

public int PanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 8:	HxListBan(param1);
			}
		}
	}
	return 0;
}