#define PLUGIN_VERSION "1.0"

/*
	c6m3_port Карта с багом из-за персонажей первой части стоящих на мосту, имея такую же модель вы окажитесь на их месте and stuck!
	Плагин удаляет чаров из первой части с моста
*/

//#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif
#pragma newdecls required

//=================
#define debug 1

#define LOG		"logs\\crash_log.log"

#if debug
static char DEBUG[256];
#endif
//===============

public Plugin myinfo =
{
	name = "c6m3 Survivor Holdout Fix",
	author = "raziEiL [disawar1]",
	description = "blah",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

public void OnPluginStart()
{
	#if debug
		BuildPath(Path_SM, DEBUG, sizeof(DEBUG), LOG);
	#endif

	RegAdminCmd("sm_fixport", CmdFixPort, ADMFLAG_ROOT);
}

public Action CmdFixPort(int client, int agrs)
{
	CreateTimer(0.0, Sh_TimeToFix, 1);
	return Plugin_Handled;
}

public Action Event_ShRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.5, Sh_TimeToFix);
}

public Action Sh_TimeToFix(Handle timer, any cmd)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity , "info_l4d1_survivor_spawn")) != INVALID_ENT_REFERENCE)
	{
		if (cmd) PrintToChatAll("<info_l4d1_survivor_spawn> killed by fix");
		
		#if debug
			LogToFile(DEBUG, "<info_l4d1_survivor_spawn> killed by fix");
		#endif
		
		AcceptEntityInput(entity, "Kill");
	}
	
	char sEntName[64];
	
	int i = 0;
	while (i < 4096)
	{
		if (IsValidEntity(i))
		{
			GetEntPropString(i, Prop_Data, "m_iName", sEntName, sizeof(sEntName));
			if (StrEqual(sEntName, "l4d1_teleport_relay") || StrEqual(sEntName, "l4d1_survivors_relay"))
			{
				if (cmd) PrintToChatAll("<%s> killed by fix", sEntName);

				#if debug
					LogToFile(DEBUG, "<%s> killed by fix", sEntName);
				#endif

				AcceptEntityInput(i, "Kill");
			}
		}
		i += 1;
	}
}

public void OnMapEnd()
{
	char sMap[5];
	GetCurrentMap(sMap, sizeof(sMap));
	
	bool hook;
	if (strcmp(sMap, "c6m2") == 0) // Отлавливаем события до карты т.к раунд старт происходит перед OnMapStart() и будет уже поздно
		hook = true;

	HookEvents(hook);
}

static bool bEvents;

int HookEvents(bool bHook)
{
	#if debug
		LogToFile(DEBUG, "[GS] %s Events", bHook && !bEvents ? "Hook" : !bHook && bEvents ? "Unhook" : "Skip");
	#endif
	
	if (bHook && !bEvents)
	{
	
		HookEvent("round_start", Event_ShRoundStart, EventHookMode_PostNoCopy);
		bEvents = true;
	}
	else if (!bHook && bEvents)
	{
	
		UnhookEvent("round_start", Event_ShRoundStart, EventHookMode_PostNoCopy);
		bEvents = false;
	}
}