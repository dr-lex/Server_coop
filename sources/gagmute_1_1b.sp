/**
 *
 * =============================================================================
 * 2 week gag & mute
 * MAKS 	 steamcommunity.com/profiles/76561198025355822/
 * dr lex 	 steamcommunity.com/profiles/76561198008545221/
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
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
*/

#pragma semicolon 1
#include <sourcemod>
#include <adminmenu>

#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif
#pragma newdecls required

/* Информировать подключившемуся игроку об оставшемся времени гага и мута */
#define TYINFO 1
#define TEST 1

#if TEST
TopMenu hTopMenu;
#endif

char sg_fileTxt[160];
int ig_days;

public Plugin myinfo =
{
	name = "gagmute",
	author = "MAKS & dr lex",
	description = "2 week gag & mute",
	version = "1.1b",
	url = "forums.alliedmods.net/showthread.php?p=2347844"
};

public void OnPluginStart()
{
	ig_days = 1;
	LoadTranslations("gagmute.phrases");
	RegAdminCmd("sm_gm", CMD_gm, ADMFLAG_CHAT, "");
	BuildPath(Path_SM, sg_fileTxt, sizeof(sg_fileTxt)-1, "data/gagmute.txt");

#if TEST
	// Если библиотека "adminmenu" найдена, вызываем функцию "OnAdminMenuReady"
	// В качестве параметра передаем Handle главного админ-меню (еще не известно, есть ли оно)
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
#endif
}

#if TEST
// Это событие вызывается плагином adminmenu.s после того, как было создано главное админ-меню
public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);
	if (topmenu == hTopMenu)
	{
		return;
	}

	hTopMenu = topmenu;
	TopMenuObject player_commands = hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		hTopMenu.AddItem("sm_gm", AdminMenu_GM, player_commands, "sm_gm", ADMFLAG_CHAT);
	}
}
public int AdminMenu_GM(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Block Gag/Mute", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayGagPlayerMenu(param);
	}
}

void DisplayGagPlayerMenu(int client)
{
	if (client && IsClientInGame(client))
	{
		char translation[100];
		Menu hMenu = new Menu(TyMenuGM);
		hMenu.SetTitle("Menu GagMute");
		Format(translation, sizeof(translation), "%T", "1 day", client);
		hMenu.AddItem("1", translation);
		Format(translation, sizeof(translation), "%T", "2 day", client);
		hMenu.AddItem("2", translation);
		Format(translation, sizeof(translation), "%T", "4 day", client);
		hMenu.AddItem("4", translation);
		Format(translation, sizeof(translation), "%T", "7 day", client);
		hMenu.AddItem("7", translation);
		Format(translation, sizeof(translation), "%T", "14 day", client);
		hMenu.AddItem("14", translation);
		Format(translation, sizeof(translation), "%T", "28 day", client);
		hMenu.AddItem("28", translation);
		hMenu.ExitButton = false;
		hMenu.Display(client, 20);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	// Если вдруг библиотека "adminmenu" удалилась, то очищаем переменную hTopMenu
	if (StrEqual(name, "adminmenu")) hTopMenu = null;
}
#endif

#if TYINFO
public void TyPrintInfoMute(int client, int iTime)
{
	char sTime[24];
	FormatTime(sTime, sizeof(sTime)-1, "%Y-%m-%d %H:%M:%S", iTime);
	PrintToChat(client, "\x05%t %t, %t \x04%s", "Microphone", "is disabled", "up to", sTime);
}

public void TyPrintInfoGag(int client, int iTime)
{
	char sTime[24];
	FormatTime(sTime, sizeof(sTime)-1, "%Y-%m-%d %H:%M:%S", iTime);
	PrintToChat(client, "\x05%t %t, %t \x04%s", "Сhat", "is disabled", "up to", sTime);
}
#endif

public void TyClientGagMute(int client)
{
	KeyValues hGM = new KeyValues("gagmute");

	if (hGM.ImportFromFile(sg_fileTxt))
	{
		char sTeamID[24];
		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);

		if (hGM.JumpToKey(sTeamID))
		{
			int iMute = hGM.GetNum("mute", 0);
			int iGag = hGM.GetNum("gag", 0);
			delete hGM;

			int iTime = GetTime();
			if (iMute > iTime)
			{
				ServerCommand("sm_mute #%d", GetClientUserId(client));
			#if TYINFO
				TyPrintInfoMute(client, iMute);
			#endif
			}

			if (iGag > iTime)
			{
				ServerCommand("sm_gag #%d", GetClientUserId(client));
			#if TYINFO
				TyPrintInfoGag(client, iGag);
			#endif
			}
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		TyClientGagMute(client);
	}
}

public void TyClientTimeGag(int client)
{
	if (IsClientInGame(client))
	{
		char sName[32];
		char sTeamID[24];

		KeyValues hGM = new KeyValues("gagmute");
		hGM.ImportFromFile(sg_fileTxt);

		GetClientName(client, sName, sizeof(sName)-8);
		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);

		if (!hGM.JumpToKey(sTeamID))
		{
			hGM.JumpToKey(sTeamID, true);
		}

		if (ig_days < 1)
		{
			ig_days = 1;
		}

		int iTimeGag = GetTime() + (60*60*24*ig_days);
		hGM.SetString("Name", sName);
		hGM.SetNum("gag", iTimeGag);
		hGM.Rewind();
		hGM.ExportToFile(sg_fileTxt);
		delete hGM;

		ServerCommand("sm_gag #%d", GetClientUserId(client));
		PrintToChatAll("\x05%t \x04%N \x05%t %t.", "Player", client, "chat", "is disabled");
	}
}

public void TyClientTimeMute(int client)
{
	if (IsClientInGame(client))
	{
		char sName[32];
		char sTeamID[24];

		KeyValues hGM = new KeyValues("gagmute");
		hGM.ImportFromFile(sg_fileTxt);

		GetClientName(client, sName, sizeof(sName)-8);
		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);

		if (!hGM.JumpToKey(sTeamID))
		{
			hGM.JumpToKey(sTeamID, true);
		}

		if (ig_days < 1)
		{
			ig_days = 1;
		}

		int iTimeMute = GetTime() + (60*60*24*ig_days);
		hGM.SetString("Name", sName);
		hGM.SetNum("mute", iTimeMute);
		hGM.Rewind();
		hGM.ExportToFile(sg_fileTxt);
		delete hGM;

		ServerCommand("sm_mute #%d", GetClientUserId(client));
		PrintToChatAll("\x05%t \x04%N \x05%t %t.", "Player", client, "microphone", "is disabled");
	}
}

public int TyMenuGage(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		bool found = menu.GetItem(param2, info, sizeof(info)-1);
		if (found && param1)
		{
			int client = StringToInt(info);
			if (client > 0)
			{
				TyClientTimeGag(client);
			}
		}
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int TyMenuMute(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		bool found = menu.GetItem(param2, info, sizeof(info)-1);
		if (found && param1)
		{
			int client = StringToInt(info);
			if (client > 0)
			{
				TyClientTimeMute(client);
			}
		}
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public void TyGag(int client)
{
	if (client && IsClientInGame(client))
	{
		char sName[32];
		char sNumber[16];
		int i = 1;

		Menu hMenu = new Menu(TyMenuGage);
		hMenu.SetTitle("block chat");

		while (i <= MaxClients)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				GetClientName(i, sName, sizeof(sName)-8);
				Format(sNumber, sizeof(sNumber)-1, "%d", i);
				hMenu.AddItem(sNumber, sName);
			}
			i += 1;
		}

		hMenu.ExitButton = false;
		hMenu.Display(client, 20);
	}
}

public void TyMute(int client)
{
	if (client && IsClientInGame(client))
	{
		char sName[32];
		char sNumber[16];
		int i = 1;

		Menu hMenu = new Menu(TyMenuMute);
		hMenu.SetTitle("block microphone");

		while (i <= MaxClients)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				GetClientName(i, sName, sizeof(sName)-8);
				Format(sNumber, sizeof(sNumber)-1, "%d", i);
				hMenu.AddItem(sNumber, sName);
			}
			i += 1;
		}

		hMenu.ExitButton = false;
		hMenu.Display(client, 20);
	}
}

public int TyMenuGagMute(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		bool found = menu.GetItem(param2, info, sizeof(info)-1);
		if (found && param1)
		{
			switch (param2)
			{
				case 0: { TyGag(param1); }
				case 1: { TyMute(param1); }
			}
		}
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public void TyGagMute(int client)
{
	if (client && IsClientInGame(client))
	{
		Menu hMenu = new Menu(TyMenuGagMute);
		hMenu.SetTitle("Menu GagMute");
		hMenu.AddItem("option1", "Add Gag");
		hMenu.AddItem("option2", "Add Mute");
		hMenu.ExitButton = false;
		hMenu.Display(client, 20);
	}
}

public int TyMenuGM(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		bool found = menu.GetItem(param2, info, sizeof(info)-1);
		if (found && param1)
		{
			int iTime = StringToInt(info);
			if (iTime > 0)
			{
				ig_days = iTime;
				TyGagMute(param1);
			}
		}
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action CMD_gm(int client, int args)
{
	if (client && IsClientInGame(client))
	{
		char translation[100];
		Menu hMenu = new Menu(TyMenuGM);
		hMenu.SetTitle("Menu GagMute");
		Format(translation, sizeof(translation), "%T", "1 day", client);
		hMenu.AddItem("1", translation);
		Format(translation, sizeof(translation), "%T", "2 day", client);
		hMenu.AddItem("2", translation);
		Format(translation, sizeof(translation), "%T", "4 day", client);
		hMenu.AddItem("4", translation);
		Format(translation, sizeof(translation), "%T", "7 day", client);
		hMenu.AddItem("7", translation);
		Format(translation, sizeof(translation), "%T", "14 day", client);
		hMenu.AddItem("14", translation);
		Format(translation, sizeof(translation), "%T", "28 day", client);
		hMenu.AddItem("28", translation);
		hMenu.ExitButton = false;
		hMenu.Display(client, 20);
	}
	return Plugin_Handled;
}
