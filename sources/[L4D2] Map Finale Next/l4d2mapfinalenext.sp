#include <sourcemod>
#pragma newdecls required

char sg_Map[54];
int ig_round_end_repeats;
bool bg_RoundStarted = false;
int ig_nextcampaign;
int seconds;
char NextCampaign[53];

public Plugin myinfo = 
{
	name = "[l4d2] Map Finale Next",
	author = "dr.lex (Exclusive Coop-17)",
	description = "Map rotating (coop & versus)",
	version = "2.8",
	url = ""
};

public void OnPluginStart()
{
	char mode[32];
	ConVar g_Mode = FindConVar("mp_gamemode");
	GetConVarString(g_Mode, mode, sizeof(mode));
	
	RegConsoleCmd("sm_next", Command_Next);
	
	if (strcmp(mode, "coop") || strcmp(mode, "realism") == 0)
	{
		HookEvent("finale_win", Event_FinalWin);
		HookEvent("round_start", Event_RoundStart);
		HookEvent("round_end", Event_RoundEnd);
	}
	if (strcmp(mode, "versus") == 0)
	{
		HookEvent("versus_match_finished", Event_FinalWin, EventHookMode_PostNoCopy);
	}
}

stock int NextMission()
{
	if (StrEqual(sg_Map, "c1m1_hotel", false) || StrEqual(sg_Map, "c1m2_streets", false) || StrEqual(sg_Map, "c1m3_mall", false) || StrEqual(sg_Map, "c1m4_atrium", false))
	{
		NextCampaign = "The Passing";
		ig_nextcampaign = 6;
	}
	else if (StrEqual(sg_Map, "c2m1_highway", false) || StrEqual(sg_Map, "c2m2_fairgrounds", false) || StrEqual(sg_Map, "c2m3_coaster", false) || StrEqual(sg_Map, "c2m4_barns", false) || StrEqual(sg_Map, "c2m5_concert", false))
	{
		NextCampaign = "Swamp Fever";
		ig_nextcampaign = 3;
	}
	else if (StrEqual(sg_Map, "c3m1_plankcountry", false) || StrEqual(sg_Map, "c3m2_swamp", false) || StrEqual(sg_Map, "c3m3_shantytown", false) || StrEqual(sg_Map, "c3m4_plantation", false))
	{
		NextCampaign = "Hard Rain";
		ig_nextcampaign = 4;
	}
	else if (StrEqual(sg_Map, "c4m1_milltown_a", false) || StrEqual(sg_Map, "c4m2_sugarmill_a", false) || StrEqual(sg_Map, "c4m3_sugarmill_b", false) || StrEqual(sg_Map, "c4m4_milltown_b", false) || StrEqual(sg_Map, "c4m5_milltown_escape", false))
	{
		NextCampaign = "The Parish";
		ig_nextcampaign = 5;
	}
	else if (StrEqual(sg_Map, "c5m1_waterfront", false) || StrEqual(sg_Map, "c5m2_park", false) || StrEqual(sg_Map, "c5m3_cemetery", false) || StrEqual(sg_Map, "c5m4_quarter", false) || StrEqual(sg_Map, "c5m5_bridge", false))
	{
		NextCampaign = "The Sacrifice";
		ig_nextcampaign = 7;
	}
	else if (StrEqual(sg_Map, "c6m1_riverbank", false) || StrEqual(sg_Map, "c6m2_bedlam", false) || StrEqual(sg_Map, "c6m3_port", false))
	{
		NextCampaign = "Dark Carnival";
		ig_nextcampaign = 2;
	}
	else if (StrEqual(sg_Map, "c7m1_docks", false) || StrEqual(sg_Map, "c7m2_barge", false) || StrEqual(sg_Map, "c7m3_port", false))
	{
		NextCampaign = "No Mercy";
		ig_nextcampaign = 8;
	}
	else if (StrEqual(sg_Map, "c8m1_apartment", false) || StrEqual(sg_Map, "c8m2_subway", false) || StrEqual(sg_Map, "c8m3_sewers", false) || StrEqual(sg_Map, "c8m4_interior", false) || StrEqual(sg_Map, "c8m5_rooftop", false))
	{
		NextCampaign = "Crash Course";
		ig_nextcampaign = 9;
	}
	else if (StrEqual(sg_Map, "c9m1_alleys", false) || StrEqual(sg_Map, "c9m2_lots", false))
	{
		NextCampaign = "Death Toll";
		ig_nextcampaign = 10;
	}
	else if (StrEqual(sg_Map, "c10m1_caves", false) || StrEqual(sg_Map, "c10m2_drainage", false) || StrEqual(sg_Map, "c10m3_ranchhouse", false) || StrEqual(sg_Map, "c10m4_mainstreet", false) || StrEqual(sg_Map, "c10m5_houseboat", false))
	{
		NextCampaign = "The Last Stand";
		ig_nextcampaign = 14;
	}
	else if (StrEqual(sg_Map, "c11m1_greenhouse", false) || StrEqual(sg_Map, "c11m2_offices", false) || StrEqual(sg_Map, "c11m3_garage", false) || StrEqual(sg_Map, "c11m4_terminal", false) || StrEqual(sg_Map, "c11m5_runway", false))
	{
		NextCampaign = "Blood Harvest";
		ig_nextcampaign = 12;
	}
	else if (StrEqual(sg_Map, "c12m1_hilltop", false) || StrEqual(sg_Map, "c12m2_traintunnel", false) || StrEqual(sg_Map, "c12m3_bridge", false) || StrEqual(sg_Map, "c12m4_barn", false) || StrEqual(sg_Map, "c12m5_cornfield", false))
	{
		NextCampaign = "Cold Stream";
		ig_nextcampaign = 13;
	}
	else if (StrEqual(sg_Map, "c13m1_alpinecreek", false) || StrEqual(sg_Map, "c13m2_southpinestream", false) || StrEqual(sg_Map, "c13m3_memorialbridge", false) || StrEqual(sg_Map, "c13m4_cutthroatcreek", false))
	{
		NextCampaign = "Dead Center";
		ig_nextcampaign = 1;
	}
	else if (StrEqual(sg_Map, "c14m1_junkyard", false) || StrEqual(sg_Map, "c14m2_lighthouse", false))
	{
		NextCampaign = "Dead Air";
		ig_nextcampaign = 11;
	}
	else
	{
		NextCampaign = "Dead Center";
		ig_nextcampaign = 1;
	}
}

public void OnMapStart()
{
	GetCurrentMap(sg_Map, sizeof(sg_Map)-1);
	ig_round_end_repeats = 0;
	seconds = 5;
}

public Action Event_FinalWin(Event event, const char[] name, bool dontBroadcast)
{
	PrintNextCampaign();
	CreateTimer(10.0, ChangeCampaign, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	bg_RoundStarted = true;
	if (ig_round_end_repeats > 5)
	{
		CreateTimer(1.0, TimerInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		PrintNextCampaign();
	}
	else if (ig_round_end_repeats > 0)
	{
		PrintToChatAll("\x05Mission failed \x01%d\x05 of \x01%d\x05 times", ig_round_end_repeats, 6);
	}
	return Plugin_Continue;
}

public Action TimerInfo(Handle timer)
{
	PrintHintTextToAll("Change campaign through %i seconds!", seconds);
	if (seconds <= 0)
	{
		PrintHintTextToAll("Change campaign on %s", NextCampaign);
		CreateTimer(5.0, ChangeCampaign, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
	seconds--;
	return Plugin_Continue;
}

public Action ChangeCampaign(Handle timer, any client)
{
	ChangeCampaignEx();
	ig_round_end_repeats = 0;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!bg_RoundStarted)
	{
		return;
	}
	ig_round_end_repeats++;
}

public void ChangeCampaignEx()
{
	NextMission();
	switch (ig_nextcampaign)
	{
		case 1: ServerCommand("changelevel c1m1_hotel");
		case 2: ServerCommand("changelevel c2m1_highway");
		case 3: ServerCommand("changelevel c3m1_plankcountry");
		case 4: ServerCommand("changelevel c4m1_milltown_a");
		case 5: ServerCommand("changelevel c5m1_waterfront");
		case 6: ServerCommand("changelevel c6m1_riverbank");
		case 7: ServerCommand("changelevel c7m1_docks");
		case 8: ServerCommand("changelevel c8m1_apartment");
		case 9: ServerCommand("changelevel c9m1_alleys");
		case 10: ServerCommand("changelevel c10m1_caves");
		case 11: ServerCommand("changelevel c11m1_greenhouse");
		case 12: ServerCommand("changelevel c12m1_hilltop");
		case 13: ServerCommand("changelevel c13m1_alpinecreek");
		case 14: ServerCommand("changelevel c14m1_junkyard");
	}
}

stock void PrintNextCampaign(int client = 0)
{
	NextMission();

	if (client)
	{
		char mode[32];
		ConVar g_Mode = FindConVar("mp_gamemode");
		GetConVarString(g_Mode, mode, sizeof(mode));
		if (strcmp(mode, "coop") || strcmp(mode, "realism") == 0)
		{
			PrintToChat(client, "\x05Next campaign: \x04%s", NextCampaign);
			PrintToChat(client, "\x05Mission failed \x01%d\x05 of \x01%d\x05 times", ig_round_end_repeats, 6);
		}
		if (strcmp(mode, "versus") == 0)
		{
			PrintToChat(client, "\x05Next campaign: \x04%s", NextCampaign);
		}
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
