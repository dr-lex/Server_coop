#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#pragma newdecls required

char sg_log[160];

int ig_minutes;
int g_BeamSprite;
int g_HaloSprite;
#define SPRITE_BEAM		"materials/sprites/laserbeam.vmt"
#define SPRITE_HALO		"materials/sprites/light_glow02.vmt"//новое так как halo01.vmt уже нету

native int HxSetClientBan(int client, int iTime);
native int HxSetClientGag(int client, int iTime);
native int HxSetClientMute(int client, int iTime);

TopMenu hTopMenu;

public Plugin myinfo =
{
	name = "[L4D2] Addition to the admin menu",
	author = "dr lex",
	description = "Add-on for the admin menu",
	version = "1.1.4",
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
	
	RegAdminCmd("sm_teleport", CMD_teleport, ADMFLAG_BAN, "sm_addban <name> <minutes> or sm_addban to open Ban menu");
	
	BuildPath(Path_SM, sg_log, sizeof(sg_log)-1, "logs/GagMuteBan.log");
	
	/* Account for late loading */
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
}

public void OnMapStart()
{
	g_BeamSprite = PrecacheModel(SPRITE_BEAM);
	g_HaloSprite = PrecacheModel(SPRITE_HALO);
}

public Action CMD_teleport(int client, int args)
{
	HxTeleportAll(client);
	return Plugin_Handled;
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
	TopMenuObject server_commands = hTopMenu.FindCategory(ADMINMENU_SERVERCOMMANDS);
	
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		hTopMenu.AddItem("ban", AdminMenu_Ban, player_commands, "ban", ADMFLAG_CHAT);
		hTopMenu.AddItem("gag", AdminMenu_Gag, player_commands, "gag", ADMFLAG_CHAT);
		hTopMenu.AddItem("mute", AdminMenu_Mute, player_commands, "mute", ADMFLAG_CHAT);
		hTopMenu.AddItem("tele", AdminMenu_Tele, player_commands, "tele", ADMFLAG_CHAT);
	}
	if (server_commands != INVALID_TOPMENUOBJECT)
	{
		hTopMenu.AddItem("teleall", AdminMenu_TeleAll, server_commands, "teleall", ADMFLAG_CHAT);
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

public void AdminMenu_TeleAll(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(buffer, maxlength, "%T", "Teleport All", param);
		case TopMenuAction_SelectOption: HxTeleportAll(param);
	}
}