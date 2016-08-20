//#pragma semicolon 1
#include <sourcemod>
#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif
#pragma newdecls required

#define CITY17L4D2_ENABLED true
#define DIESCRAPER35_ENABLED true
#define WARCELONA_ENABLED true
#define DEADDESTINATION_ENABLED true
#define GASFEVER_ENABLED false
#define FRFLDFLLN_ENABLED false
#define FALLINDEATH_ENABLED true
#define URBANFLIGHT_ENABLED true
#define RED_ENABLED true
#define PRECINCT84_ENABLED true
#define DEADBEATESCAPE_ENABLED false
#define FATALFREIGHT_ENABLED true
#define DEATHROW_ENABLED true
#define BLOODTRACKS_ENABLED true
#define ENERGYCRISIS_ENABLED true
#define WHITEFOREST_ENABLED true

char current_map[53];
int round_end_repeats;
int IsRoundStarted = false;
char NextCampaignVote[32];
int seconds;
char NextCampaign[53];

public Plugin myinfo = 
{
	name = "Next Campaign",
	author = "dr.lex (Exclusive Coop-17)",
	description = "",
	version = "2.6.7",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_next", Command_Next);
	RegConsoleCmd("callvote", Callvote_Handler);
	HookEvent("finale_win", Event_FinalWin);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

int NextMission()
{
	if (StrEqual(current_map, "c1m1_hotel", false) || StrEqual(current_map, "c1m2_streets", false) || StrEqual(current_map, "c1m3_mall", false) || StrEqual(current_map, "c1m4_atrium", false))
	{
		NextCampaign = "The Passing";
		NextCampaignVote = "L4D2C6";
	}
	else if (StrEqual(current_map, "c2m1_highway", false) || StrEqual(current_map, "c2m2_fairgrounds", false) || StrEqual(current_map, "c2m3_coaster", false) || StrEqual(current_map, "c2m4_barns", false) || StrEqual(current_map, "c2m5_concert", false))
	{
		NextCampaign = "Swamp Fever";
		NextCampaignVote = "L4D2C3";
	}
	else if (StrEqual(current_map, "c3m1_plankcountry", false) || StrEqual(current_map, "c3m2_swamp", false) || StrEqual(current_map, "c3m3_shantytown", false) || StrEqual(current_map, "c3m4_plantation", false))
	{
		NextCampaign = "Hard Rain";
		NextCampaignVote = "L4D2C4";
	}
	else if (StrEqual(current_map, "c4m1_milltown_a", false) || StrEqual(current_map, "c4m2_sugarmill_a", false) || StrEqual(current_map, "c4m3_sugarmill_b", false) || StrEqual(current_map, "c4m4_milltown_b", false) || StrEqual(current_map, "c4m5_milltown_escape", false))
	{
		NextCampaign = "The Parish";
		NextCampaignVote = "L4D2C5";
	}
	else if (StrEqual(current_map, "c5m1_waterfront", false) || StrEqual(current_map, "c5m2_park", false) || StrEqual(current_map, "c5m3_cemetery", false) || StrEqual(current_map, "c5m4_quarter", false) || StrEqual(current_map, "c5m5_bridge", false))
	{
		NextCampaign = "The Sacrifice";
		NextCampaignVote = "L4D2C7";
	}
	else if (StrEqual(current_map, "c6m1_riverbank", false) || StrEqual(current_map, "c6m2_bedlam", false) || StrEqual(current_map, "c6m3_port", false))
	{
		NextCampaign = "Dark Carnival";
		NextCampaignVote = "L4D2C2";
	}
	else if (StrEqual(current_map, "c7m1_docks", false) || StrEqual(current_map, "c7m2_barge", false) || StrEqual(current_map, "c7m3_port", false))
	{
		NextCampaign = "No Mercy";
		NextCampaignVote = "L4D2C8";
	}
	else if (StrEqual(current_map, "c8m1_apartment", false) || StrEqual(current_map, "c8m2_subway", false) || StrEqual(current_map, "c8m3_sewers", false) || StrEqual(current_map, "c8m4_interior", false) || StrEqual(current_map, "c8m5_rooftop", false))
	{
		NextCampaign = "Crash Course";
		NextCampaignVote = "L4D2C9";
	}
	else if (StrEqual(current_map, "c9m1_alleys", false) || StrEqual(current_map, "c9m2_lots", false))
	{
		NextCampaign = "Death Toll";
		NextCampaignVote = "L4D2C10";
	}
	else if (StrEqual(current_map, "c10m1_caves", false) || StrEqual(current_map, "c10m2_drainage", false) || StrEqual(current_map, "c10m3_ranchhouse", false) || StrEqual(current_map, "c10m4_mainstreet", false) || StrEqual(current_map, "c10m5_houseboat", false))
	{
		NextCampaign = "Dead Air";
		NextCampaignVote = "L4D2C11";
	}
	else if (StrEqual(current_map, "c11m1_greenhouse", false) || StrEqual(current_map, "c11m2_offices", false) || StrEqual(current_map, "c11m3_garage", false) || StrEqual(current_map, "c11m4_terminal", false) || StrEqual(current_map, "c11m5_runway", false))
	{
		NextCampaign = "Blood Harvest";
		NextCampaignVote = "L4D2C12";
	}
	else if (StrEqual(current_map, "c12m1_hilltop", false) || StrEqual(current_map, "c12m2_traintunnel", false) || StrEqual(current_map, "c12m3_bridge", false) || StrEqual(current_map, "c12m4_barn", false) || StrEqual(current_map, "c12m5_cornfield", false))
	{
		NextCampaign = "Cold Stream";
		NextCampaignVote = "L4D2C13";
	}
	else if (StrEqual(current_map, "c13m1_alpinecreek", false) || StrEqual(current_map, "c13m2_southpinestream", false) || StrEqual(current_map, "c13m3_memorialbridge", false) || StrEqual(current_map, "c13m4_cutthroatcreek", false))
	{
		NextCampaign = "Dead Center";
		NextCampaignVote = "L4D2C1";
	}
	else
	{
		NextCampaign = "Dead Center";
		NextCampaignVote = "L4D2C1";
	}
}

public Action Callvote_Handler(int client, int args)
{
	char voteName[32];
	char voteValue[128];
	GetCmdArg(1, voteName, sizeof(voteName));
	GetCmdArg(2, voteValue, sizeof(voteValue));
	
	if (StrEqual(voteName, "ChangeMission", false) || StrEqual(voteName, "ChangeChapter", false))
	{
		int flags = GetUserFlagBits(client);
		if (flags & ADMFLAG_VOTE || flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION || flags & ADMFLAG_CUSTOM1 || flags & ADMFLAG_CUSTOM2 || flags & ADMFLAG_CUSTOM3 || flags & ADMFLAG_CUSTOM4 || flags & ADMFLAG_CUSTOM5 || flags & ADMFLAG_CUSTOM6 || flags & ADMFLAG_GENERIC)
		{
			return Plugin_Continue;
		}
		else if (round_end_repeats > 3)
		{
			return Plugin_Handled;
		}
		else if (round_end_repeats > 1)
		{
			NextMission();
			
			if (StrEqual(voteValue, NextCampaignVote, false))
			{
				return Plugin_Continue;
			}
			else
			{
				PrintToChat(client, "\x05Next campaign to vote: \x04%s", NextCampaign);
				return Plugin_Handled;
			}
		}
		else
		{
			PrintToChat(client, "\x05Mission failed \x01%d\x05 of \x01%d\x05 times. Vote cancelled.", round_end_repeats, 4);
			return Plugin_Handled;
		}
	}
	if (StrEqual(voteName, "RestartGame", false))
	{
		int flags = GetUserFlagBits(client);
		if (flags & ADMFLAG_VOTE || flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION || flags & ADMFLAG_GENERIC)
		{
			return Plugin_Continue;
		}
		else
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void OnMapStart()
{
	GetCurrentMap(current_map, 52);
	round_end_repeats = 0;
	seconds = 5;
}

public Action Event_FinalWin(Event event, const char[] name, bool dontBroadcast)
{
	PrintNextCampaign();
	CreateTimer(10.0, ChangeCampaign, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	IsRoundStarted = true;
	if (round_end_repeats > 5)
	{
		CreateTimer(1.0, TimerInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		PrintNextCampaign();
	}
	else if (round_end_repeats > 0) PrintToChatAll("\x05Mission failed \x01%d\x05 of \x01%d\x05 times", round_end_repeats, 6);
	return Plugin_Continue;
}

public Action TimerInfo(Handle timer)
{
	PrintHintTextToAll("Change campaign through %i seconds!", seconds);
	if (seconds <= 0)
	{
		PrintHintTextToAll("Change campaign on %s", NextCampaign);
		ServerCommand("sm_hm_noweapon");
		CreateTimer(5.0, ChangeCampaign, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
	seconds--;
	return Plugin_Continue;
}

public Action ChangeCampaign(Handle timer, any client)
{
	ChangeCampaignEx();
	round_end_repeats = 0;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!IsRoundStarted) return;
	round_end_repeats++;
}

public void ChangeCampaignEx()
{
	NextMission();
	
	if (StrEqual(NextCampaignVote, "L4D2C1", false)) ServerCommand("changelevel c1m1_hotel");
	else if (StrEqual(NextCampaignVote, "L4D2C2", false)) ServerCommand("changelevel c2m1_highway");
	else if (StrEqual(NextCampaignVote, "L4D2C3", false)) ServerCommand("changelevel c3m1_plankcountry");
	else if (StrEqual(NextCampaignVote, "L4D2C4", false)) ServerCommand("changelevel c4m1_milltown_a");
	else if (StrEqual(NextCampaignVote, "L4D2C5", false)) ServerCommand("changelevel c5m1_waterfront");
	else if (StrEqual(NextCampaignVote, "L4D2C6", false)) ServerCommand("changelevel c6m1_riverbank");
	else if (StrEqual(NextCampaignVote, "L4D2C7", false)) ServerCommand("changelevel c7m1_docks");
	else if (StrEqual(NextCampaignVote, "L4D2C8", false)) ServerCommand("changelevel c8m1_apartment");
	else if (StrEqual(NextCampaignVote, "L4D2C9", false)) ServerCommand("changelevel c9m1_alleys");
	else if (StrEqual(NextCampaignVote, "L4D2C10", false)) ServerCommand("changelevel c10m1_caves");
	else if (StrEqual(NextCampaignVote, "L4D2C11", false)) ServerCommand("changelevel c11m1_greenhouse");
	else if (StrEqual(NextCampaignVote, "L4D2C12", false)) ServerCommand("changelevel c12m1_hilltop");
	else if (StrEqual(NextCampaignVote, "L4D2C13", false)) ServerCommand("changelevel c13m1_alpinecreek");
	else ServerCommand("changelevel c1m1_hotel");
}

void PrintNextCampaign(int client = 0)
{
	NextMission();

	if (client)
	{
		PrintToChat(client, "\x05Next campaign: \x04%s", NextCampaign);
		PrintToChat(client, "\x05Mission failed \x01%d\x05 of \x01%d\x05 times", round_end_repeats, 6);
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