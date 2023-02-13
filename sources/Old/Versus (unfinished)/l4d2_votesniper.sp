/**
 * =============================================================================
 * Copyright https://steamcommunity.com/id/dr_lex/
 *
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <www.sourcemod.net/license.php>.
 *
*/

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

int ig_player_block[MAXPLAYERS+1];
int ig_player[MAXPLAYERS+1];
int ig_left_safe_area;

public Plugin myinfo =
{
	name = "[L4D2] Vote Sniper Player",
	author = "dr lex",
	description = "",
	version = "1.1",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_scout", CMD_Scout);
	RegConsoleCmd("sm_awp", CMD_Awp);
	
	HookEvent("player_left_safe_area", Event_left_safe_area);
	HookEvent("round_start", Event_RoundStart);
}

public void OnMapStart()
{
	ig_left_safe_area = 0;
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		ig_player_block[client] = 0;
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ig_left_safe_area = 0;
}

public void Event_left_safe_area(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client)
	{
		if (GetClientTeam(client) == 2)
		{
			if (IsPlayerAlive(client))
			{
				ig_left_safe_area = 1;
			}
		}
	}
}

public Action CMD_Scout(int client, int args)
{
	if (client)
	{
		if (!ig_left_safe_area)
		{
			if (!ig_player_block[client])
			{
				if (IsClientInGame(client))
				{
					if (GetClientTeam(client) == 2)
					{
						VoteSniper(client, 1);
					}
				}
			}
			else
			{
				PrintToChat(client, "\x04[!scout]\x01Have you already used this command on the map!");
			}
		}
		else
		{
			PrintToChat(client, "\x04[!scout]\x01Not available at the moment!");
		}
	}
	return Plugin_Handled;
}

public Action CMD_Awp(int client, int args)
{
	if (client)
	{
		if (!ig_left_safe_area)
		{
			if (!ig_player_block[client])
			{
				if (IsClientInGame(client))
				{
					if (GetClientTeam(client) == 2)
					{
						VoteSniper(client, 2);
					}
				}
			}
			else
			{
				PrintToChat(client, "\x04[!awp]\x01Have you already used this command on the map!");
			}
		}
		else
		{
			PrintToChat(client, "\x04[!awp]\x01Not available at the moment!");
		}
	}
	return Plugin_Handled;
}

stock int VoteSniper(int client, int iNum)
{
	char sName[32];
	switch (iNum)
	{
		case 1: sName = "scout";
		case 2: sName = "awp";
	}
	
	if (IsVoteInProgress())
	{  
		PrintToChat(client, "\x04[!%s]\x01Repeat later!", sName);
		return 0;
	}
	
	ig_player_block[client] = 1;
	
	int i_Clients[32], i_Count;
	
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) != 1)
			{
				if (client != i)
				{
					i_Clients[i_Count++] = i;
					ig_player[i] = 0;
				}
				else
				{
					ig_player[i] = 1;
				}
			}
		}
		i += 1;
	}
	
	char sNumber[32];
	Format(sNumber, sizeof(sNumber)-1, "%d", client);
	
	char sBuffer[100];
	Menu menu = new Menu(Handle_VoteMenu);
	
	Format(sBuffer, sizeof(sBuffer), "Vote %N > %s?", client, sName);
	menu.SetTitle(sBuffer);
	menu.AddItem("0", "No");
	switch (iNum)
	{
		case 1: menu.AddItem("1", "Yes");
		case 2: menu.AddItem("2", "Yes");
	}
	menu.DisplayVote(i_Clients, i_Count, 15);
	return 0;
}

stock int Handle_VoteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_VoteEnd:
		{
			char sInfo[64];
			menu.GetItem(param1, sInfo, sizeof(sInfo)-1);
			if (strcmp(sInfo,"0") == 0)
			{
				PrintToChatAll("\x04[Vote]\x01No \x03sniper");
			}
			if (strcmp(sInfo,"1") == 0)
			{
				int i = 1;
				while (i <= MaxClients)
				{
					if (ig_player[i])
					{
						GivePlayerItem(i, "sniper_scout");
					}
					i += 1;
				}
			}
			if (strcmp(sInfo,"2") == 0)
			{
				int i = 1;
				while (i <= MaxClients)
				{
					if (ig_player[i])
					{
						GivePlayerItem(i, "sniper_awp");
					}
					i += 1;
				}
			}
		}
	}
	return 0;
}