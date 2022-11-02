// SPDX-License-Identifier: GPL-3.0-only
#if defined _hx_slay_included
 #endinput
#endif
#define _hx_slay_included

public int MenuHandler_Slay(Menu menu, MenuAction action, int param1, int param2)
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
						PrintToChatAll("\x05Slayed: \x04%N -> %N", param1, client);
						ForcePlayerSuicide(client);
					}
				}
			}
		}
	}
	return 0;
}

void HxSlay(int &client)
{
	char sName[32];
	char sNumber[8];
	int i = 1;

	Menu h1 = new Menu(MenuHandler_Slay);
	h1.SetTitle("Убить игрока");

	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (IsPlayerAlive(i))
			{
				if (client != i)
				{
					GetClientName(i, sName, sizeof(sName)-12);
					Format(sNumber, sizeof(sNumber)-1, "%d", i);
					h1.AddItem(sNumber, sName);
				}
			}
		}
		i += 1;
	}

	h1.ExitButton = true;
	h1.Display(client, 30);
}
