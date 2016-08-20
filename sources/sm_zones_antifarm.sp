#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <dod_zones>
#pragma newdecls required

bool IsRoundStarted = false;

public Plugin myinfo =
{
	name        = "[L4D2] AntiFarm Zones",
	author      = "dr_lex",
	description = "",
	version     = "1.1",
	url         = ""
}

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_start", Event_FinaleStart);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	IsRoundStarted = true;
	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!IsRoundStarted) return Plugin_Continue;
	return Plugin_Continue;
}

public Action OnEnteredProtectedZone(int zone, int client, char[] prefix)
{
	ConVar ShowZones = null;
	if (!ShowZones) ShowZones = FindConVar("sm_zones_show_messages");
	if (1 <= client <= MaxClients && GetClientTeam(client) == 2)
	{
		char m_iName[MAX_NAME_LENGTH*2];
		GetEntPropString(zone, Prop_Data, "m_iName", m_iName, sizeof(m_iName));

		// Skip the first 8 characters of zone name to avoid comparing the "sm_zone " prefix.
		if (StrContains(m_iName[8], "loot", false) == 0) // включить дроп
		{
			ServerCommand("exec loot/default.cfg");
		}
		if (StrContains(m_iName[8], "noloot", false) == 0) // выключить дроп
		{
			ServerCommand("exec loot/noloot.cfg");
		}
		if (StrContains(m_iName[8], "panic", false) == 0) // паника
		{
			PanicEvent();
		}
		if (StrContains(m_iName[8], "spanic", false) == 0) // паника в конце убеги
		{
			ServerCommand("hm_autohp_zombie_max 250");
			ServerCommand("hm_autohp_hunter_max 3500");
			ServerCommand("hm_autohp_smoker_max 4500");
			ServerCommand("hm_autohp_boomer_max 1000");
			ServerCommand("hm_autohp_jockey_max 5500");
			ServerCommand("hm_autohp_charger_max 5500");
			ServerCommand("hm_autohp_spitter_max 3500");
			PanicEvent();
		}
		if (StrContains(m_iName[8], "default", false) == 0) // сброс на стандартный конфиг
		{
			PanicEvent();
		}
	}
}

stock int PanicEvent()
{
	int Director = CreateEntityByName("info_director");
	DispatchSpawn(Director);
	AcceptEntityInput(Director, "ForcePanicEvent");
	AcceptEntityInput(Director, "Kill");
}

public Action Event_FinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	ServerCommand("exec loot/default.cfg");
}