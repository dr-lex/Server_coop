#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

#tryinclude <l4d2_changelevel>

char sg_Map[54];
char NextCampaignVote[32];
char NextCampaign[53];
char sMapName[40];

public Plugin myinfo = 
{
	name = "L4D2 Map Finale Next Versus",
	author = "Accelerator",
	description = "Map rotating",
	version = "4.8",
	url = "http://core-ss.org"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_next", Command_Next);
	HookEvent("versus_match_finished", Event_FinalWin, EventHookMode_PostNoCopy);
}

stock void NextMission()
{
	if (StrContains(sg_Map, "c1m", false) != -1)
	{
		NextCampaign = "The Passing";
		NextCampaignVote = "L4D2C6";
	}
	else if (StrContains(sg_Map, "c2m", false) != -1)
	{
		NextCampaign = "Swamp Fever";
		NextCampaignVote = "L4D2C3";
	}
	else if (StrContains(sg_Map, "c3m", false) != -1)
	{
		NextCampaign = "Hard Rain";
		NextCampaignVote = "L4D2C4";
	}
	else if (StrContains(sg_Map, "c4m", false) != -1)
	{
		NextCampaign = "The Parish";
		NextCampaignVote = "L4D2C5";
	}
	else if (StrContains(sg_Map, "c5m", false) != -1)
	{
		NextCampaign = "The Sacrifice";
		NextCampaignVote = "L4D2C7";
	}
	else if (StrContains(sg_Map, "c6m", false) != -1)
	{
		NextCampaign = "Dark Carnival";
		NextCampaignVote = "L4D2C2";
	}
	else if (StrContains(sg_Map, "c7m", false) != -1)
	{
		NextCampaign = "No Mercy";
		NextCampaignVote = "L4D2C8";
	}
	else if (StrContains(sg_Map, "c8m", false) != -1)
	{
		NextCampaign = "Crash Course";
		NextCampaignVote = "L4D2C9";
	}
	else if (StrContains(sg_Map, "c9m", false) != -1)
	{
		NextCampaign = "Death Toll";
		NextCampaignVote = "L4D2C10";
	}
	else if (StrContains(sg_Map, "c10m", false) != -1)
	{
		NextCampaign = "The Last Stand";
		NextCampaignVote = "L4D2C14";
	}
	else if (StrContains(sg_Map, "c11m", false) != -1)
	{
		NextCampaign = "Blood Harvest";
		NextCampaignVote = "L4D2C12";
	}
	else if (StrContains(sg_Map, "c12m", false) != -1)
	{
		NextCampaign = "Cold Stream";
		NextCampaignVote = "L4D2C13";
	}
	else if (StrContains(sg_Map, "c13m", false) != -1)
	{
		NextCampaign = "Dead Center";
		NextCampaignVote = "L4D2C1";
	}
	else if (StrContains(sg_Map, "c14m", false) != -1)
	{
		NextCampaign = "Dead Air";
		NextCampaignVote = "L4D2C11";
	}
	else
	{
		NextCampaign = "Dead Center";
		NextCampaignVote = "L4D2C1";
	}
}

public void OnMapStart()
{
	GetCurrentMap(sg_Map, sizeof(sg_Map));
}

public void Event_FinalWin(Event event, const char[] name, bool dontBroadcast)
{
	PrintNextCampaign();
	CreateTimer(10.0, ChangeCampaign, TIMER_FLAG_NO_MAPCHANGE);
}

public Action ChangeCampaign(Handle timer, int client)
{
	ChangeCampaignEx();
	return Plugin_Stop;
}

public void ChangeCampaignEx()
{
	NextMission();
	if (StrEqual(NextCampaignVote, "L4D2C1"))
	{
		sMapName = "c1m1_hotel";
	}
	else if (StrEqual(NextCampaignVote, "L4D2C2"))
	{
		sMapName = "c2m1_highway";
	}
	else if (StrEqual(NextCampaignVote, "L4D2C3"))
	{
		sMapName = "c3m1_plankcountry";
	}
	else if (StrEqual(NextCampaignVote, "L4D2C4"))
	{
		sMapName = "c4m1_milltown_a";
	}
	else if (StrEqual(NextCampaignVote, "L4D2C5"))
	{
		sMapName = "c5m1_waterfront";
	}
	else if (StrEqual(NextCampaignVote, "L4D2C6"))
	{
		sMapName = "c6m1_riverbank";
	}
	else if (StrEqual(NextCampaignVote, "L4D2C7"))
	{
		sMapName = "c7m1_docks";
	}
	else if (StrEqual(NextCampaignVote, "L4D2C8"))
	{
		sMapName = "c8m1_apartment";
	}
	else if (StrEqual(NextCampaignVote, "L4D2C9"))
	{
		sMapName = "c9m1_alleys";
	}
	else if (StrEqual(NextCampaignVote, "L4D2C10"))
	{
		sMapName = "c10m1_caves";
	}
	else if (StrEqual(NextCampaignVote, "L4D2C11"))
	{
		sMapName = "c11m1_greenhouse";
	}
	else if (StrEqual(NextCampaignVote, "L4D2C12"))
	{
		sMapName = "c12m1_hilltop";
	}
	else if (StrEqual(NextCampaignVote, "L4D2C13"))
	{
		sMapName = "c13m1_alpinecreek";
	}
	else if (StrEqual(NextCampaignVote, "L4D2C14"))
	{
		sMapName = "c14m1_junkyard";
	}
	else
	{
		sMapName = "c1m1_hotel";
	}
	
#if defined _l4d2_changelevel_included
	L4D2_ChangeLevel(sMapName);
#else
	ServerCommand("changelevel %s", sMapName);
#endif
}

void PrintNextCampaign(int client = 0)
{
	NextMission();
	if (client)
	{
		PrintToChat(client, "\x05Next campaign: \x04%s", NextCampaign);
	}
	else
	{
		PrintToChatAll("\x05Next campaign: \x04%s", NextCampaign);
	}
}

public Action Command_Next(int client, int args)
{
	if (client)
	{
		PrintNextCampaign(client);
	}
	return Plugin_Handled;
}