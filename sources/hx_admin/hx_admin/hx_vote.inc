// SPDX-License-Identifier: GPL-3.0-only
#if defined _hx_vote_included
 #endinput
#endif
#define _hx_vote_included

static char sMemu_TimeVote[][][] =
{
	{"5",			"5 mins"},
	{"30",			"30 mins"},
	{"60",			"60 mins"},
	{"180", 		"3 hrs"},
	{"360", 		"6 hrs"},
	{"720", 		"12 hrs"},
	{"1440", 		"1 day"},
	{"4320", 		"3 days"},
	{"7200", 		"5 days"},
	{"10080", 		"7 days"},
	{"20160", 		"14 days"},
	{"30240", 		"21 days"},
	{"43200", 		"30 days"},
	{"86400", 		"60 days"},
	{"259200", 		"180 days"},
	{"525600", 		"365 days"}
};

public int MenuHandler_Vote(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char sInfo[8];
			
			bool found = menu.GetItem(param2, sInfo, sizeof(sInfo)-1);
			if (found && param1)
			{
				int client = StringToInt(sInfo);
				if (client > 0)
				{
					if (IsClientInGame(client))
					{
						HxSetClientVote(client, ig_minutes);
						LogToFileEx(sg_log, "block vote: %N(Admin) -> %N -> %d minute(s)", param1, client, ig_minutes);
						PrintToChatAll("\x05%d min block vote:\x04 %N", ig_minutes, client);
					}
				}
			}
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

public void HxVote(int &client)
{
	char sName[32];
	char sNumber[8];
	int i = 1;

	Menu h6 = new Menu(MenuHandler_Vote);
	h6.SetTitle("Block Vote");

	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (client != i)
			{
				GetClientName(i, sName, sizeof(sName)-12);
				Format(sNumber, sizeof(sNumber)-1, "%d", i);
				h6.AddItem(sNumber, sName);
			}
		}
		i += 1;
	}
	
	h6.ExitBackButton = true;
	h6.Display(client, 30);
}

public void HxAddVote(int client)
{
	Menu menu = new Menu(MenuHandler_AddVote);
	menu.SetTitle("Vote Time");
	for (int i = 0; i < sizeof(sMemu_TimeVote); i++)
	{
		menu.AddItem(sMemu_TimeVote[i][0], sMemu_TimeVote[i][1]);
	}
	menu.ExitBackButton = true;
	menu.Display(client, 30);
}

public int MenuHandler_AddVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char sInfo[8];
			bool found = menu.GetItem(param2, sInfo, sizeof(sInfo)-1);
			if (found && param1)
			{
				int iTime = StringToInt(sInfo);
				if (iTime > 0)
				{
					ig_minutes = iTime;
					HxVote(param1);
				}
			}
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