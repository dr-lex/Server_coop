#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#pragma newdecls required

char sg_log[160];

int ig_minutes;

native int HxSetClientBan(int client, int iTime);
native int HxSetClientGag(int client, int iTime);
native int HxSetClientMute(int client, int iTime);

TopMenu hTopMenu;

public Plugin myinfo =
{
	name = "[L4D2] Addition to the admin menu",
	author = "dr lex",
	description = "Add-on for the admin menu",
	version = "1.1.3",
	url = "https://steamcommunity.com/id/dr_lex/"
};

#include "hx_admin/hx_ban.inc"
#include "hx_admin/hx_gag.inc"
#include "hx_admin/hx_mute.inc"
#include "hx_admin/hx_teleport.inc"

public void OnPluginStart()
{
	LoadTranslations("hx_admin.phrases");
	ig_minutes = 1;
	
	BuildPath(Path_SM, sg_log, sizeof(sg_log)-1, "logs/GagMuteBan.log");
	
	/* Account for late loading */
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);
	
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	/* Build the "Player Commands" category */
	TopMenuObject player_commands = hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);
	
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		hTopMenu.AddItem("ban", AdminMenu_Ban, player_commands, "ban", ADMFLAG_CHAT);
		hTopMenu.AddItem("gag", AdminMenu_Gag, player_commands, "gag", ADMFLAG_CHAT);
		hTopMenu.AddItem("mute", AdminMenu_Mute, player_commands, "mute", ADMFLAG_CHAT);
		hTopMenu.AddItem("tele", AdminMenu_Tele, player_commands, "tele", ADMFLAG_CHAT);
	}
}

public void AdminMenu_Ban(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(buffer, maxlength, "[GMB] %T", "Ban Player", param);
		case TopMenuAction_SelectOption: HxAddBan(param);
	}
}

public void AdminMenu_Gag(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(buffer, maxlength, "[GMB] %T", "Gag Player", param);
		case TopMenuAction_SelectOption: HxAddGag(param);
	}
}

public void AdminMenu_Mute(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(buffer, maxlength, "[GMB] %T", "Mute Player", param);
		case TopMenuAction_SelectOption: HxAddMute(param);
	}
}

public void AdminMenu_Tele(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(buffer, maxlength, "%T", "Teleport player", param);
		case TopMenuAction_SelectOption: HxTeleport(param);
	}
}

/*
void DisplayGagPlayerMenu(int client)
{
	Menu menu = new Menu(MenuHandler_GagPlayer);
	
	char title[100];
	Format(title, sizeof(title), "%T:", "Gag/Mute player", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	AddTargetsToMenu(menu, client, true, false);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_HxAdmin(Menu menu, MenuAction action, int param1, int param2)
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
				if (IsClientInGame(param1))
				{
					if (!strcmp(sInfo, "ban", true))
					{
						HxAddBan(param1);
					}
					if (!strcmp(sInfo, "gag", true))
					{
						HxAddGag(param1);
					}
					if (!strcmp(sInfo, "mute", true))
					{
						HxAddMute(param1);
					}
				}
			}
		}
	}
	return 0;
}

void DisplayGagMuteBanPlayerMenu(int client)
{
	Menu menu = new Menu(MenuHandler_HxAdmin);
	
	char title[100];
	Format(title, sizeof(title), "%T:", "Gag/Mute/Ban player", client);
	menu.SetTitle(title);
	
	Format(title, sizeof(title), "%T", "Ban Player", client);
	menu.AddItem("ban", title);
	
	Format(title, sizeof(title), "%T", "Gag Player", client);
	menu.AddItem("gag", title);
	
	Format(title, sizeof(title), "%T", "Mute Player", client);
	menu.AddItem("mute", title);
	
	menu.ExitBackButton = true;	
	menu.Display(client, MENU_TIME_FOREVER);
}
*/