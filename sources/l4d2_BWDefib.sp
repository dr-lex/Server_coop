#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

public Plugin myinfo =
{
	name = "[L4D2] Black and White on Defib",
	author = "Crimson_Fox",
	description = "Defibed survivors are brought back to life with no incaps remaining.",
	version = "1.4",
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

	HookEvent("defibrillator_used", Event_PlayerDefibed);
}

public void SetTempHealth(int &client, float fHp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHp);
}

public Action Event_PlayerDefibed(Event event, const char [] strName, bool DontBroadcast)
{
	int iSubject = GetClientOfUserId(event.GetInt("subject"));
	if (iSubject)
	{
		int iM = FindConVar("survivor_max_incapacitated_count").IntValue;
		SetEntProp(iSubject, Prop_Send, "m_currentReviveCount", iM);
		SetEntProp(iSubject, Prop_Send, "m_bIsOnThirdStrike", 1);
		SetEntProp(iSubject, Prop_Send, "m_isGoingToDie", 1);
		SetEntProp(iSubject, Prop_Send, "m_iHealth", 1);
		SetTempHealth(iSubject, 30.0);
	}
	return Plugin_Continue;
}
