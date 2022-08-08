// SPDX-License-Identifier: GPL-3.0-only
#if defined _hx_teleport_included
 #endinput
#endif
#define _hx_teleport_included

void Teleport(int client, int client2)
{
	float fg_xyz[3];
	GetClientAbsOrigin(client, fg_xyz);
	if (fg_xyz[2] != 0.0)
	{
		TeleportEntity(client2, fg_xyz, NULL_VECTOR, NULL_VECTOR);
	}
}

public int MenuHandler_Teleport(Menu menu, MenuAction action, int param1, int param2)
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
					if (IsClientInGame(client) && IsPlayerAlive(client))
					{
						Teleport(param1, client);
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

public void HxTeleport(int &client)
{
	char sName[32];
	char sNumber[8];
	int i = 1;

	Menu h7 = new Menu(MenuHandler_Teleport);
	h7.SetTitle("Teleport player");

	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
		{
			if (client != i)
			{
				GetClientName(i, sName, sizeof(sName)-12);
				Format(sNumber, sizeof(sNumber)-1, "%d", i);
				h7.AddItem(sNumber, sName);
			}
		}
		i += 1;
	}

	h7.ExitBackButton = true;
	h7.Display(client, 30);
}

public void HxTeleportAll(int &client)
{
	float trspos[3];
	trspos[2] += 50;
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", trspos);
	
	TE_SetupBeamRingPoint(trspos, 10.0, 500.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.3, 10.0, 0.5, {230, 230, 230, 100}, 400, 0);
	TE_SendToAll();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			float fOtherPos[3];
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", fOtherPos);
			if (GetVectorDistance(trspos, fOtherPos) < 500.0)
			{
				continue;
			}
			
			Teleport(client, i);
		}
	}
}
