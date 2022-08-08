// SPDX-License-Identifier: GPL-3.0-only
#if defined _hx_gag_included
 #endinput
#endif
#define _hx_gag_included

static char sMemu_TimeGag[][][] =
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

public int MenuHandler_Gag(Menu menu, MenuAction action, int param1, int param2)
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
						if (HxSetClientGag(client, ig_minutes))
						{
							LogToFileEx(sg_log, "gag: %N(Admin) -> %N -> %d minute(s)", param1, client, ig_minutes);
							//ServerCommand("sm_gag #%d", GetClientUserId(client));
							PrintToChatAll("\x05%d min gag:\x04 %N", ig_minutes, client);
						}
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

public void HxGag(int &client)
{
	char sName[32];
	char sNumber[8];
	int i = 1;

	Menu h5 = new Menu(MenuHandler_Gag);
	h5.SetTitle("Gag");

	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (client != i)
			{
				GetClientName(i, sName, sizeof(sName)-12);
				Format(sNumber, sizeof(sNumber)-1, "%d", i);
				h5.AddItem(sNumber, sName);
			}
		}
		i += 1;
	}

	h5.ExitBackButton = true;
	h5.Display(client, 30);
}

public void HxAddGag(int client)
{
	Menu menu = new Menu(MenuHandler_AddGag);
	menu.SetTitle("Gag Time");
	for (int i = 0; i < sizeof(sMemu_TimeGag); i++)
	{
		menu.AddItem(sMemu_TimeGag[i][0], sMemu_TimeGag[i][1]);
	}
	menu.ExitBackButton = true;	
	menu.Display(client, 30);
}

public int MenuHandler_AddGag(Menu menu, MenuAction action, int param1, int param2)
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
					HxGag(param1);
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