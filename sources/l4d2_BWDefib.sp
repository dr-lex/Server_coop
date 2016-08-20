#pragma semicolon 1
#include <sourcemod>
#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION "1.4"

ConVar hg_Enabled;
ConVar hg_Health;
ConVar hg_TempHealth;

int ID[MAXPLAYERS+1];
Handle hzTimer[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "[L4D2] Black and White on Defib",
	author = "Crimson_Fox",
	description = "Defibed survivors are brought back to life with no incaps remaining.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1012022"
}

public void OnPluginStart()
{
	char game[24];
	GetGameFolderName(game, sizeof(game)-1);
	if (!StrEqual(game, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}

	CreateConVar("bwdefib_version", PLUGIN_VERSION, "The version of Black and White on Defib.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hg_Enabled = CreateConVar("l4d2_bwdefib", "1", "Is Black and White on Defib enabled?", FCVAR_NONE);
	hg_Health = CreateConVar("l4d2_bwdefib_health", "1.0", "Amount of health with which a defibed survivor is brought back.", FCVAR_NONE, true, 1.0, true, 100.0);
	hg_TempHealth = CreateConVar("l4d2_bwdefib_temphealth", "30.0", "Amount of temporary health with which a defibed survivor is brought back.", FCVAR_NONE, true, 0.0, true, 100.0);
	AutoExecConfig(true, "l4d2_bwdefib");

	HookEvent("defibrillator_used", Event_PlayerDefibed);
	HookEvent("defibrillator_begin", Event_DefibrillatorBegin);
	HookEvent("player_death", Event_PlayerDead);
}

public void SetTempHealth(int &client, float fHp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHp);
}

public Action Event_PlayerDefibed(Event event, const char [] strName, bool DontBroadcast)
{
	if (GetConVarInt(hg_Enabled))
	{
		int iSubject = GetClientOfUserId(GetEventInt(event, "subject"));
		if (iSubject)
		{
			int iM = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
			SetEntProp(iSubject, Prop_Send, "m_currentReviveCount", iM);
			SetEntProp(iSubject, Prop_Send, "m_bIsOnThirdStrike", 1);
			SetEntProp(iSubject, Prop_Send, "m_isGoingToDie", 1);
			SetEntProp(iSubject, Prop_Send, "m_iHealth", GetConVarInt(hg_Health));

			SetTempHealth(iSubject, GetConVarFloat(hg_TempHealth));
		}
	}
	return Plugin_Continue;
}

public Action Event_DefibrillatorBegin(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int survivorplayers = 0;
	int livesurvivorplayers = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			survivorplayers++;
		}
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			livesurvivorplayers++;
		}
	}
	
	int actualsurvivorplayers = survivorplayers - livesurvivorplayers;
	if (actualsurvivorplayers == 0)
	{
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
		GiveItem(client, "defibrillator");
		PrintToChat(client, "\x03All players is alive!");
		PrintHintText(client, "All players is alive!");
	}
	return Plugin_Continue;
}

int GiveItem(int client, char[] Item)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", Item);
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

public Action Event_PlayerDead(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client && GetClientTeam(client) == 2 && ID[client] == 0)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity , "survivor_death_model")) != -1){
			
			if (NotSavedEntity(entity))
			{
				ID[client] = entity;
				hzTimer[client] = CreateTimer(0.5, IsClientRevived, client, TIMER_REPEAT);
				break;
			}
		}	
	}
}

public Action IsClientRevived(Handle timer, any client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		ID[client] = 0;
		TimeToKill(client);
	}
}

int TimeToKill(int client)
{
	if (hzTimer[client] != null)
	{
		KillTimer(hzTimer[client]);
		hzTimer[client] = null;
	}
}

bool NotSavedEntity(int entity)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (ID[i] == entity)
		{
			return false;
		}
	}
	return true;
}