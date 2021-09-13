/**
 * =============================================================================
 * 1 week gag & mute & ban
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
#include <sourcemod>
#include <adminmenu>
#pragma newdecls required

#define HX_DELETE 1

TopMenu hTopMenu;
TopMenu hTopMenuHandle;

char sg_file[160];
char sg_log[160];

int ig_minutes;

/*
 * native int HxSetClientBan(int client, int iTime);
*/

static char sMemu_Time[][][] =
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

public Plugin myinfo =
{
	name = "GagMuteBan",
	author = "MAKS & dr lex",
	description = "gag & mute & ban",
	version = "2.0.3",
	url = "https://forums.alliedmods.net/showthread.php?p=2757254"
};

public void OnPluginStart()
{
	ig_minutes = 1;
	RegAdminCmd("sm_addban", CMD_addbanmenu, ADMFLAG_BAN, "sm_addban <name> <minutes> or sm_addban to open Ban menu");
	RegAdminCmd("sm_addgag", CMD_addgagmenu, ADMFLAG_CHAT, "sm_addgag <name> <minutes> or sm_addgag to open AddGag menu");
	RegAdminCmd("sm_addmute", CMD_addmutemenu, ADMFLAG_CHAT, "sm_addmute <name> <minutes> or sm_addmute to open AddMute menu");
	RegAdminCmd("sm_bansteamid",  CMD_bansteamid,  ADMFLAG_BAN,  "sm_bansteamid <minutes> <STEAM_ID>");
	RegAdminCmd("sm_unban", CMD_unban, ADMFLAG_CHAT, "sm_unban <STEAM_ID>");

	BuildPath(Path_SM, sg_file, sizeof(sg_file)-1, "data/GagMuteBan.txt");
	BuildPath(Path_SM, sg_log, sizeof(sg_log)-1, "logs/GagMuteBan.log");
	
	TopMenu hTop_Menu;
	if (LibraryExists("adminmenu") && ((hTop_Menu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(hTop_Menu);
	}
	
	HookEvent("round_start", Event_RoundStart);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gagmuteban");
	CreateNative("HxSetClientBan", Native_HxSetClientBan);
	return APLRes_Success;
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		HxClientGagMuteBanEx(client);
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(5.0, CheckStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action CheckStart(Handle timer)
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			HxClientGagMuteBanEx(i);
		}
		i += 1;
	}
	return Plugin_Stop;
}

public void OnAdminMenuReady(Handle topmenu)
{
	if (topmenu == hTopMenuHandle)
	{
		return;
	}
	
	hTopMenuHandle = view_as<TopMenu>(topmenu);
	TopMenuObject MCategory = hTopMenuHandle.AddCategory("Gag/Mute/Ban - For a while", Category_Handler);
	if (MCategory != INVALID_TOPMENUOBJECT)
	{
		hTopMenuHandle.AddItem("sm_banadmin", AdminMenu_Ban, MCategory, "sm_banadmin", ADMFLAG_BAN);
		hTopMenuHandle.AddItem("sm_muteadmin", AdminMenu_Mute, MCategory, "sm_muteadmin", ADMFLAG_BAN);
		hTopMenuHandle.AddItem("sm_gagadmin", AdminMenu_Gag, MCategory, "sm_muteadmin", ADMFLAG_BAN);
	}
}

public void Category_Handler(TopMenu Top_Menu, TopMenuAction action, TopMenuObject object_id, int param, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayTitle: Format(sBuffer, maxlength, "Select an option");
		case TopMenuAction_DisplayOption: Format(sBuffer, maxlength, "Gag/Mute/Ban");
	}
}

public void AdminMenu_Ban(TopMenu Top_Menu, TopMenuAction action, TopMenuObject object_id, int param, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(sBuffer, maxlength, "Ban Player");
		case TopMenuAction_SelectOption: CMD_addbanmenu(param, 0);
	}
}

public void AdminMenu_Mute(TopMenu Top_Menu, TopMenuAction action, TopMenuObject object_id, int param, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(sBuffer, maxlength, "Mute Player");
		case TopMenuAction_SelectOption: CMD_addmutemenu(param , 0);
	}
}

public void AdminMenu_Gag(TopMenu Top_Menu, TopMenuAction action, TopMenuObject object_id, int param, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(sBuffer, maxlength, "Gag Player");
		case TopMenuAction_SelectOption: CMD_addgagmenu(param , 0);
	}
}

public void HxClientGagMuteBanEx(int &client)
{
	KeyValues hGM = new KeyValues("gagmute");

	if (hGM.ImportFromFile(sg_file))
	{
	#if HX_DELETE
		int iDelete = 1;
	#endif
		char sTeamID[32];
		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);

		if (hGM.JumpToKey(sTeamID))
		{
			int iMute = hGM.GetNum("mute", 0);
			int iGag = hGM.GetNum("gag", 0);
			int iBan = hGM.GetNum("ban", 0);
			int iTime = GetTime();
			int iLeftMinute;
			int userid = GetClientUserId(client);

			if (iMute > iTime)
			{
				iLeftMinute = (iMute - iTime) /60;
				ServerCommand("sm_mute #%d", userid);
				PrintToChat(client, "\x05[\x04GMB\x05] \x04Mute \x03%d \x04minute(s)", iLeftMinute);
				#if HX_DELETE
					iDelete = 0;
				#endif
			}
			else if (iMute != 0)
			{
				ServerCommand("sm_unmute #%d", userid);
			}
			
			if (iGag > iTime)
			{
				iLeftMinute = (iGag - iTime) /60;
				ServerCommand("sm_gag #%d", userid);
				PrintToChat(client, "\x05[\x04GMB\x05] \x04ChaT \x03%d \x04minute(s)", iLeftMinute);
				#if HX_DELETE
					iDelete = 0;
				#endif
			}
			else if (iGag != 0)
			{
				ServerCommand("sm_ungag #%d", userid);
			}
			
			if (iBan > iTime)
			{
				char sTime[24];
				FormatTime(sTime, sizeof(sTime)-1, "%Y-%m-%d %H:%M:%S", iBan);
				KickClient(client,"Banned (%s)", sTime);
				#if HX_DELETE
					iDelete = 0;
				#endif
			}

			#if HX_DELETE
				if (iDelete)
				{
					hGM.DeleteThis();
					hGM.Rewind();
					hGM.ExportToFile(sg_file);
				}
			#endif
		}
	}
	delete hGM;
}

stock int Native_HxSetClientBan(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	}
	
	int iTime = GetNativeCell(2);
	if (iTime > 0)
	{
		HxClientTimeBan(client, iTime);
	}
	
	return true;
}

public int HxClientTimeBan(int &client, int iminute)
{
	if (IsClientInGame(client))
	{
		char sName[128];
		char sTeamID[32];

		KeyValues hGM = new KeyValues("gagmute");
		hGM.ImportFromFile(sg_file);

		GetClientName(client, sName, sizeof(sName)-12);
		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);

		hGM.JumpToKey(sTeamID, true);

		int iTimeBan = GetTime() + (iminute * 60);
		hGM.SetString("Name", sName);
		hGM.SetNum("ban", iTimeBan);
		hGM.Rewind();
		hGM.ExportToFile(sg_file);
		delete hGM;
		return 1;
	}
	return 0;
}

public int MenuHandler_Ban(Menu menu, MenuAction action, int param1, int param2)
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
					if (ig_minutes < 1)
					{
						ig_minutes = 1;
					}
					
					if (HxClientTimeBan(client, ig_minutes))
					{
						LogToFileEx(sg_log, "Ban: %N(Admin) -> %N -> %d minute(s)", param1, client, ig_minutes);
						PrintToChatAll("\x05[\x04GMB\x05] \x03%N\x05，\x04Ban \x03%d \x04minute(s)", client, ig_minutes);
						KickClient(client, "%d minute(s) ban.", ig_minutes);
					}
				}
			}
		}
	}
}

public Action CMD_addban(int client)
{
	if (client)
	{
		if (IsClientInGame(client))
		{
			char sName[128];
			char sNumber[8];
			int i = 1;

			Menu hMenu = new Menu(MenuHandler_Ban);
			hMenu.SetTitle("Menu Ban SteamID (player)");

			while (i <= MaxClients)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					if (client != i)
					{
						GetClientName(i, sName, sizeof(sName)-12);
						Format(sNumber, sizeof(sNumber)-1, "%d", i);
						hMenu.AddItem(sNumber, sName);
					}
				}
				i += 1;
			}

			hMenu.ExitButton = false;
			hMenu.Display(client, 20);
		}
	}
	return Plugin_Handled;
}

public int AddMenuBan(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[8];
			bool found = menu.GetItem(param2, info, sizeof(info)-1);
			if (found && param1)
			{
				int iTime = StringToInt(info);
				if (iTime > 0)
				{
					ig_minutes = iTime;
					CMD_addban(param1);
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
}

public Action CMD_addbanmenu(int client, int args)
{
	if (args != 2 && args != 0)
	{
		ReplyToCommand(client, "[GMB] sm_addban <name> <minutes> or sm_addban to open Ban menu");
	}
	
	if (args == 2)
	{
		char arg1[32], arg2[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		int target = FindTarget(client, arg1, true /*nobots*/, false /*immunity*/);
		if (target == -1)
		{
			return Plugin_Handled;	
		}
		
		GetCmdArg(2, arg2, sizeof(arg2));
		int minutes = StringToInt(arg2);
		if (minutes == 0)
		{
			minutes = 9999;
		}
		
		if (HxClientTimeBan(target, minutes))
		{
			if (client)
			{
				LogToFileEx(sg_log, "Ban: %N(Admin) -> %N -> %d minute(s)", client, target, minutes);
				PrintToChatAll("\x05[\x04GMB\x05] \x03%N\x05，\x04Ban \x03%d \x05minute(s)", target, minutes);
			}
			else
			{
				LogToFileEx(sg_log, "[GMB] Ban: Server ban %N for %d minute(s)", target, minutes);
			}
			KickClient(target, "%d minute(s) ban.", minutes);
		}
	}
	else
	{
		if (client == 0)
		{
			PrintToServer("[GMB] server please uses sm_addban <name> <minutes>");
			return Plugin_Handled;
		}
		
		Menu menu = new Menu(AddMenuBan);
		for(int i = 0; i < sizeof(sMemu_Time); i++)
		{
			menu.AddItem(sMemu_Time[i][0], sMemu_Time[i][1]);
		}
		menu.SetTitle("Menu Ban SteamID (Time)", client);
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public int HxClientTimeGag(int &client, int iminute)
{
	if (IsClientInGame(client))
	{
		char sName[128];
		char sTeamID[32];

		KeyValues hGM = new KeyValues("gagmute");
		hGM.ImportFromFile(sg_file);

		GetClientName(client, sName, sizeof(sName)-12);
		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);

		hGM.JumpToKey(sTeamID, true);

		int iTimeGag = GetTime() + (iminute * 60);
		hGM.SetString("Name", sName);
		hGM.SetNum("gag", iTimeGag);
		hGM.Rewind();
		hGM.ExportToFile(sg_file);
		delete hGM;
		
		ServerCommand("sm_gag #%d", GetClientUserId(client));
		return 1;
	}
	return 0;
}

public int MenuHandler_Gage(Menu menu, MenuAction action, int param1, int param2)
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
					if (ig_minutes < 1)
					{
						ig_minutes = 1;
					}
					
					if (HxClientTimeGag(client, ig_minutes))
					{
						LogToFileEx(sg_log, "Gag: %N(Admin) -> %N -> %d minute(s)", param1, client, ig_minutes);
						PrintToChatAll("\x05[\x04GMB\x05] \x03%N\x05, \x04Chat \x03%d \x04minute(s)", client, ig_minutes);
					}
				}
			}
		}
	}
}

public Action CMD_addgag(int client)
{
	if (client)
	{
		if (IsClientInGame(client))
		{
			char sName[128];
			char sNumber[8];
			int i = 1;

			Menu hMenu = new Menu(MenuHandler_Gage);
			hMenu.SetTitle("Menu Block Chat (Player)");

			while (i <= MaxClients)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					if (client != i)
					{
						GetClientName(i, sName, sizeof(sName)-12);
						Format(sNumber, sizeof(sNumber)-1, "%d", i);
						hMenu.AddItem(sNumber, sName);
					}
				}
				i += 1;
			}

			hMenu.ExitButton = false;
			hMenu.Display(client, 20);
		}
	}
	return Plugin_Handled;
}

public int AddMenuGag(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[8];
			bool found = menu.GetItem(param2, info, sizeof(info)-1);
			if (found && param1)
			{
				int iTime = StringToInt(info);
				if (iTime > 0)
				{
					ig_minutes = iTime;
					CMD_addgag(param1);
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
}

public Action CMD_addgagmenu(int client, int args)
{
	if (args != 2 && args != 0)
	{
		ReplyToCommand(client, "[GMB] sm_addgag <name> <minutes> or sm_addgag to open AddGag menu");
	}
	
	if (args == 2)
	{
		char arg1[32], arg2[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		int target = FindTarget(client, arg1, true /*nobots*/, false /*immunity*/);
		if (target == -1)
		{
			return Plugin_Handled;	
		}

		GetCmdArg(2, arg2, sizeof(arg2));
		int minutes = StringToInt(arg2);
		if(minutes==0) minutes = 9999;

		if (HxClientTimeGag(target, minutes))
		{
			if (client)
			{
				LogToFileEx(sg_log, "Gag: %N(Admin) -> %N -> %d minute(s)", client, target, minutes);
				PrintToChatAll("\x05[\x04GMB\x05] \x03%N\x05, \x04Chat \x03%d \x04minute(s)", target, minutes);
			}
			else
			{
				LogToFileEx(sg_log, "[GMB] Gag: Server gag %N for %d minute(s)", target, minutes);
			}
		}
	}
	else
	{
		if (client == 0)
		{
			PrintToServer("[GMB] server please uses sm_addgag <name> <minutes>");
			return Plugin_Handled;
		}

		Menu menu = new Menu(AddMenuGag);
		for (int i = 0; i < sizeof(sMemu_Time); i++)
		{
			menu.AddItem(sMemu_Time[i][0], sMemu_Time[i][1]);
		}
		menu.SetTitle("Menu Block Chat (Time)", client);
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public int HxClientTimeMute(int &client, int iminute)
{
	if (IsClientInGame(client))
	{
		char sName[128];
		char sTeamID[32];

		KeyValues hGM = new KeyValues("gagmute");
		hGM.ImportFromFile(sg_file);

		GetClientName(client, sName, sizeof(sName)-12);
		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);

		hGM.JumpToKey(sTeamID, true);

		int iTimeMute = GetTime() + (iminute * 60);
		hGM.SetString("Name", sName);
		hGM.SetNum("mute", iTimeMute);
		hGM.Rewind();
		hGM.ExportToFile(sg_file);
		delete hGM;

		ServerCommand("sm_mute #%d", GetClientUserId(client));
		return 1;
	}
	return 0;
}

public int MenuHandler_Mute(Menu menu, MenuAction action, int param1, int param2)
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
					if (ig_minutes < 1)
					{
						ig_minutes = 1;
					}
					
					if (HxClientTimeMute(client, ig_minutes))
					{
						LogToFileEx(sg_log, "Mute: %N(Admin) -> %N -> %d minute(s).", param1, client, ig_minutes);
						PrintToChatAll("\x05[\x04GMB\x05] \x03%N\x05, \x04Mute \x03%d \x04minute(s)", client, ig_minutes);
					}
				}
			}
		}
	}
}

public Action CMD_addmute(int client)
{
	if (IsClientInGame(client))
	{
		char sName[128];
		char sNumber[8];
		int i = 1;

		Menu hMenu = new Menu(MenuHandler_Mute);
		hMenu.SetTitle("Menu Block Microphone (Player)");

		while (i <= MaxClients)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				if (client != i)
				{
					GetClientName(i, sName, sizeof(sName)-12);
					Format(sNumber, sizeof(sNumber)-1, "%d", i);
					hMenu.AddItem(sNumber, sName);
				}
			}
			i += 1;
		}

		hMenu.ExitButton = false;
		hMenu.Display(client, 20);
	}
	return Plugin_Handled;
}

public int AddMenuMute(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[8];
			bool found = menu.GetItem(param2, info, sizeof(info)-1);
			if (found && param1)
			{
				int iTime = StringToInt(info);
				if (iTime > 0)
				{
					ig_minutes = iTime;
					CMD_addmute(param1);
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
}

public Action CMD_addmutemenu(int client, int args)
{
	if (args != 2 && args != 0)
	{
		ReplyToCommand(client, "[GMB] sm_addmute <name> <minutes> or sm_addmute to open AddMute menu");
	}
	
	if (args == 2)
	{
		char arg1[32], arg2[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		int target = FindTarget(client, arg1, true /*nobots*/, false /*immunity*/);
		if (target == -1)
		{
			return Plugin_Handled;
		}

		GetCmdArg(2, arg2, sizeof(arg2));
		int minutes = StringToInt(arg2);
		if (minutes==0)
		{
			minutes = 9999;
		}

		if (HxClientTimeMute(target, minutes))
		{
			if (client > 0)
			{
				LogToFileEx(sg_log, "Mute: %N(Admin) -> %N -> %d minute(s).", client, target, minutes);
				PrintToChatAll("\x05[\x04GMB\x05] \x03%N\x05, \x04Mute \x03%d \x04minute(s)", target, minutes);
			}
			else
			{
				LogToFileEx(sg_log, "[GMB] Mute: Server exmute %N for %d minute(s)", target, minutes);
			}
		}
	}
	else
	{
		if (client == 0)
		{
			PrintToServer("[GMB] server please uses sm_addmute <name> <minutes>");
			return Plugin_Handled;
		}

		Menu menu = new Menu(AddMenuMute);
		for (int i = 0; i < sizeof(sMemu_Time); i++)
		{
			menu.AddItem(sMemu_Time[i][0], sMemu_Time[i][1]);
		}
		menu.SetTitle("Menu Block Microphone (Time)", client);
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public void HxClientUnBanSteam(char[] steam_id)
{
	KeyValues hGM = new KeyValues("gagmute");
	if (hGM.ImportFromFile(sg_file))
	{
		if (hGM.JumpToKey(steam_id))
		{
			hGM.DeleteThis();
			hGM.Rewind();
			hGM.ExportToFile(sg_file);
		}
	}
	delete hGM;
}

public Action CMD_unban(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_unban <STEAM_ID>");
		return Plugin_Handled;
	}
	
	char arg_string[256];
	char authid[50];
	
	GetCmdArgString(arg_string, sizeof(arg_string));
	
	/* Get steamid */
	int len, total_len;
	if ((len = BreakString(arg_string[total_len], authid, sizeof(authid))) != -1)
	{
		total_len += len;
	}
	else
	{
		total_len = 0;
		arg_string[0] = '\0';
	}
	
	/* Verify steamid */
	bool idValid = false;
	if (!strncmp(authid, "STEAM_", 6) && authid[7] == ':')
	{
		idValid = true;
	}
	
	if (!idValid)
	{
		ReplyToCommand(client, "Invalid SteamID specified");
		return Plugin_Handled;
	}
	
	HxClientUnBanSteam(authid);
	return Plugin_Handled;
}

public void HxClientTimeBanSteam(char[] steam_id, int iminute)
{
	KeyValues hGM = new KeyValues("gagmute");
	hGM.ImportFromFile(sg_file);

	if (!hGM.JumpToKey(steam_id))
	{
		hGM.JumpToKey(steam_id, true);
	}

	int iTimeBan = GetTime() + (iminute * 60);
	hGM.SetNum("ban", iTimeBan);
	hGM.Rewind();
	hGM.ExportToFile(sg_file);
	delete hGM;
}

public Action CMD_bansteamid(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_bansteamid <minutes> <STEAM_ID>");
		return Plugin_Handled;
	}
	
	char arg_string[256];
	char minute[50];
	char authid[50];
	
	GetCmdArgString(arg_string, sizeof(arg_string));
	
	int len, total_len;
	
	/* Get minute */
	if ((len = BreakString(arg_string, minute, sizeof(minute))) == -1)
	{
		ReplyToCommand(client, "Usage: sm_bansteamid <minutes> <steamid>");
		return Plugin_Handled;
	}	
	total_len += len;
	
	/* Get steamid */
	if ((len = BreakString(arg_string[total_len], authid, sizeof(authid))) != -1)
	{
		total_len += len;
	}
	else
	{
		total_len = 0;
		arg_string[0] = '\0';
	}
	
	/* Verify steamid */
	bool idValid = false;
	if (!strncmp(authid, "STEAM_", 6) && authid[7] == ':')
		idValid = true;
	
	if (!idValid)
	{
		ReplyToCommand(client, "Invalid SteamID specified (Must be STEAM_ )");
		return Plugin_Handled;
	}
	
	int minutes = StringToInt(minute);
	
	HxClientTimeBanSteam(authid, minutes);
	for (int i = 1 ; i <= MaxClients ; ++i) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			HxClientGagMuteBanEx(i);
		}
	}
	if (client != 0)
	{
		LogToFileEx(sg_log, "%N(Admin) added steamid %s in GagMuteBan list, %d minute(s) ban.", client, authid, minutes);
		PrintToChat(client, "\x05[\x04GMB\x05] \x03%s\x05(\x04SteamID\x05) \x04ban \x03%d \x04minute(s)", authid, minutes);
	}
	else
	{
		LogToFileEx(sg_log, "Server Console added steamid %s in GagMuteBan list, %d minute(s) ban.", client, authid, minutes);
	}
	return Plugin_Handled;
}
