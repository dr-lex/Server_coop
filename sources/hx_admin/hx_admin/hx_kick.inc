// SPDX-License-Identifier: GPL-3.0-only
#if defined _hx_kick_included
 #endinput
#endif
#define _hx_kick_included

public int MenuHandler_Kick(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
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
					PrintToChatAll("\x05Kicked: \x04%N -> %N", param1, client);
					KickClient(client, "Kicked by admin");
				}
			}
		}
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

void HxKick(int &client)
{
	char sName[32];
	char sNumber[8];
	int i = 1;

	Menu h2 = new Menu(MenuHandler_Kick);
	h2.SetTitle("Выгнать игрока");

	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (client != i)
			{
				GetClientName(i, sName, sizeof(sName)-12);
				Format(sNumber, sizeof(sNumber)-1, "%d", i);
				h2.AddItem(sNumber, sName);
			}
		}
		i += 1;
	}

	h2.ExitButton = true;
	h2.Display(client, 30);
}
