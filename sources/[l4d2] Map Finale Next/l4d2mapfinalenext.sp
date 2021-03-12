#include <sourcemod>
#pragma newdecls required

#define HX_FIXES_LUX 1
#if HX_FIXES_LUX
#include <l4d2_changelevel>
#endif

char sg_Map[54];
int round_end_repeats;
//int round_start;
int IsRoundStarted = 0;
char NextCampaignVote[32];
int seconds;
//int seconds2;
char NextCampaign[53];

public Plugin myinfo = 
{
	name = "[l4d2] Map Finale Next",
	author = "dr.lex (Exclusive Coop-17)",
	description = "Rotation of companies in the list, full loading of players when changing cards",
	version = "2.7.5",
	url = ""
};

public void OnPluginStart()
{
	LoadTranslations("l4d2mapfinalenext.phrases");
	RegConsoleCmd("sm_next", Command_Next);
	
	HookEvent("finale_win", Event_FinalWin);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

int NextMission()
{
	if (StrEqual(sg_Map, "c1m1_hotel", false) || StrEqual(sg_Map, "c1m2_streets", false) || StrEqual(sg_Map, "c1m3_mall", false) || StrEqual(sg_Map, "c1m4_atrium", false))
	{
		NextCampaign = "The Passing";
		NextCampaignVote = "L4D2C6";
	}
	else if (StrEqual(sg_Map, "c2m1_highway", false) || StrEqual(sg_Map, "c2m2_fairgrounds", false) || StrEqual(sg_Map, "c2m3_coaster", false) || StrEqual(sg_Map, "c2m4_barns", false) || StrEqual(sg_Map, "c2m5_concert", false))
	{
		NextCampaign = "Swamp Fever";
		NextCampaignVote = "L4D2C3";
	}
	else if (StrEqual(sg_Map, "c3m1_plankcountry", false) || StrEqual(sg_Map, "c3m2_swamp", false) || StrEqual(sg_Map, "c3m3_shantytown", false) || StrEqual(sg_Map, "c3m4_plantation", false))
	{
		NextCampaign = "Hard Rain";
		NextCampaignVote = "L4D2C4";
	}
	else if (StrEqual(sg_Map, "c4m1_milltown_a", false) || StrEqual(sg_Map, "c4m2_sugarmill_a", false) || StrEqual(sg_Map, "c4m3_sugarmill_b", false) || StrEqual(sg_Map, "c4m4_milltown_b", false) || StrEqual(sg_Map, "c4m5_milltown_escape", false))
	{
		NextCampaign = "The Parish";
		NextCampaignVote = "L4D2C5";
	}
	else if (StrEqual(sg_Map, "c5m1_waterfront", false) || StrEqual(sg_Map, "c5m2_park", false) || StrEqual(sg_Map, "c5m3_cemetery", false) || StrEqual(sg_Map, "c5m4_quarter", false) || StrEqual(sg_Map, "c5m5_bridge", false))
	{
		NextCampaign = "The Sacrifice";
		NextCampaignVote = "L4D2C7";
	}
	else if (StrEqual(sg_Map, "c6m1_riverbank", false) || StrEqual(sg_Map, "c6m2_bedlam", false) || StrEqual(sg_Map, "c6m3_port", false))
	{
		NextCampaign = "Dark Carnival";
		NextCampaignVote = "L4D2C2";
	}
	else if (StrEqual(sg_Map, "c7m1_docks", false) || StrEqual(sg_Map, "c7m2_barge", false) || StrEqual(sg_Map, "c7m3_port", false))
	{
		NextCampaign = "No Mercy";
		NextCampaignVote = "L4D2C8";
	}
	else if (StrEqual(sg_Map, "c8m1_apartment", false) || StrEqual(sg_Map, "c8m2_subway", false) || StrEqual(sg_Map, "c8m3_sewers", false) || StrEqual(sg_Map, "c8m4_interior", false) || StrEqual(sg_Map, "c8m5_rooftop", false))
	{
		NextCampaign = "Crash Course";
		NextCampaignVote = "L4D2C9";
	}
	else if (StrEqual(sg_Map, "c9m1_alleys", false) || StrEqual(sg_Map, "c9m2_lots", false))
	{
		NextCampaign = "Death Toll";
		NextCampaignVote = "L4D2C10";
	}
	else if (StrEqual(sg_Map, "c10m1_caves", false) || StrEqual(sg_Map, "c10m2_drainage", false) || StrEqual(sg_Map, "c10m3_ranchhouse", false) || StrEqual(sg_Map, "c10m4_mainstreet", false) || StrEqual(sg_Map, "c10m5_houseboat", false))
	{
		NextCampaign = "The Last Stand";
		NextCampaignVote = "L4D2C14";
	}
	else if (StrEqual(sg_Map, "c11m1_greenhouse", false) || StrEqual(sg_Map, "c11m2_offices", false) || StrEqual(sg_Map, "c11m3_garage", false) || StrEqual(sg_Map, "c11m4_terminal", false) || StrEqual(sg_Map, "c11m5_runway", false))
	{
		NextCampaign = "Blood Harvest";
		NextCampaignVote = "L4D2C12";
	}
	else if (StrEqual(sg_Map, "c12m1_hilltop", false) || StrEqual(sg_Map, "c12m2_traintunnel", false) || StrEqual(sg_Map, "c12m3_bridge", false) || StrEqual(sg_Map, "c12m4_barn", false) || StrEqual(sg_Map, "c12m5_cornfield", false))
	{
		NextCampaign = "Cold Stream";
		NextCampaignVote = "L4D2C13";
	}
	else if (StrEqual(sg_Map, "c13m1_alpinecreek", false) || StrEqual(sg_Map, "c13m2_southpinestream", false) || StrEqual(sg_Map, "c13m3_memorialbridge", false) || StrEqual(sg_Map, "c13m4_cutthroatcreek", false))
	{
		NextCampaign = "Dead Center";
		NextCampaignVote = "L4D2C1";
	}
	else if (StrEqual(sg_Map, "c14m1_junkyard", false) || StrEqual(sg_Map, "c14m2_lighthouse", false))
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
	GetCurrentMap(sg_Map, sizeof(sg_Map)-1);
	round_end_repeats = 0;
	seconds = 5;
	
	//round_start = 1;
	//seconds2 = 30;
	
	//CreateTimer(1.0, TimerRoundEnd, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

stock Action TimerRoundEnd(Handle timer)
{
	PrintHintTextToAll("%t", "The mission will start in", seconds2);
	if (seconds2 <= 0)
	{
		PrintHintTextToAll("%t", "Start of the mission");
		HxFakeCHEATDev("scenario_end");
		return Plugin_Stop;
	}
	seconds2--;
	return Plugin_Continue;
}

stock void HxFakeCHEATDev(char[] sCmd)
{
	int iFlags = GetCommandFlags(sCmd);
	SetCommandFlags(sCmd, iFlags & ~(FCVAR_CHEAT|FCVAR_DEVELOPMENTONLY));
	ServerCommand("%s", sCmd);
	ServerExecute();
	SetCommandFlags(sCmd, iFlags);
}

public Action Event_FinalWin(Event event, const char[] name, bool dontBroadcast)
{
	PrintNextCampaign();
	CreateTimer(10.0, ChangeCampaign, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	IsRoundStarted = 1;
	if (round_end_repeats > 5)
	{
		CreateTimer(1.0, TimerInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		PrintNextCampaign();
	}
	else
	{
		if (round_end_repeats > 0)
		{
			PrintToChatAll("\x05%t", "Mission failed 1 of 2 times", round_end_repeats, 6);
		}
		else
		{
			PrintToChatAll("\x05%t", "The mission begins!");
		}
	}
	return Plugin_Continue;
}

public Action TimerInfo(Handle timer)
{
	PrintHintTextToAll("%t", "Change campaign through", seconds);
	if (seconds <= 0)
	{
		PrintHintTextToAll("%t %s", "Next campaign", NextCampaign);
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
	if (!IsRoundStarted)
	{
		return;
	}
	
	//if (round_start)
	//{
	//	round_start = 0;
	//}
	//else
	//{
	round_end_repeats++;
	//}
}

public void ChangeCampaignEx()
{
	NextMission();
	
	if (StrEqual(NextCampaignVote, "L4D2C1", false))
	{
	#if HX_FIXES_LUX
		L4D2_ChangeLevel("c1m1_hotel");
	#else
		ServerCommand("changelevel c1m1_hotel");
	#endif
	}
	else if (StrEqual(NextCampaignVote, "L4D2C2", false))
	{
	#if HX_FIXES_LUX
		L4D2_ChangeLevel("c2m1_highway");
	#else
		ServerCommand("changelevel c2m1_highway");
	#endif
	}
	else if (StrEqual(NextCampaignVote, "L4D2C3", false))
	{
	#if HX_FIXES_LUX
		L4D2_ChangeLevel("c3m1_plankcountry");
	#else
		ServerCommand("changelevel c3m1_plankcountry");
	#endif
	}
	else if (StrEqual(NextCampaignVote, "L4D2C4", false))
	{
	#if HX_FIXES_LUX
		L4D2_ChangeLevel("c4m1_milltown_a");
	#else
		ServerCommand("changelevel c4m1_milltown_a");
	#endif
	}
	else if (StrEqual(NextCampaignVote, "L4D2C5", false))
	{
	#if HX_FIXES_LUX
		L4D2_ChangeLevel("c5m1_waterfront");
	#else
		ServerCommand("changelevel c5m1_waterfront");
	#endif
	}
	else if (StrEqual(NextCampaignVote, "L4D2C6", false))
	{
	#if HX_FIXES_LUX
		L4D2_ChangeLevel("c6m1_riverbank");
	#else
		ServerCommand("changelevel c6m1_riverbank");
	#endif
	}
	else if (StrEqual(NextCampaignVote, "L4D2C7", false))
	{
	#if HX_FIXES_LUX
		L4D2_ChangeLevel("c7m1_docks");
	#else
		ServerCommand("changelevel c7m1_docks");
	#endif
	}
	else if (StrEqual(NextCampaignVote, "L4D2C8", false))
	{
	#if HX_FIXES_LUX
		L4D2_ChangeLevel("c8m1_apartment");
	#else
		ServerCommand("changelevel c8m1_apartment");
	#endif
	}
	else if (StrEqual(NextCampaignVote, "L4D2C9", false))
	{
	#if HX_FIXES_LUX
		L4D2_ChangeLevel("c9m1_alleys");
	#else
		ServerCommand("changelevel c9m1_alleys");
	#endif
	}
	else if (StrEqual(NextCampaignVote, "L4D2C10", false))
	{
	#if HX_FIXES_LUX
		L4D2_ChangeLevel("c10m1_caves");
	#else
		ServerCommand("changelevel c10m1_caves");
	#endif
	}
	else if (StrEqual(NextCampaignVote, "L4D2C11", false))
	{
	#if HX_FIXES_LUX
		L4D2_ChangeLevel("c11m1_greenhouse");
	#else
		ServerCommand("changelevel c11m1_greenhouse");
	#endif
	}
	else if (StrEqual(NextCampaignVote, "L4D2C12", false))
	{
	#if HX_FIXES_LUX
		L4D2_ChangeLevel("c12m1_hilltop");
	#else
		ServerCommand("changelevel c12m1_hilltop");
	#endif
	}
	else if (StrEqual(NextCampaignVote, "L4D2C13", false))
	{
	#if HX_FIXES_LUX
		L4D2_ChangeLevel("c13m1_alpinecreek");
	#else
		ServerCommand("changelevel c13m1_alpinecreek");
	#endif
	}
	else if (StrEqual(NextCampaignVote, "L4D2C14", false))
	{
	#if HX_FIXES_LUX
		L4D2_ChangeLevel("c14m1_junkyard");
	#else
		ServerCommand("changelevel c14m1_junkyard");
	#endif
	}
	else
	{
	#if HX_FIXES_LUX
		L4D2_ChangeLevel("c1m1_hotel");
	#else
		ServerCommand("changelevel c1m1_hotel");
	#endif
	}
}

void PrintNextCampaign(int client = 0)
{
	NextMission();

	if (client)
	{
		PrintToChat(client, "\x05%t: \x04%s", "Next campaign", NextCampaign);
		PrintToChat(client, "\x05%t", "Mission failed 1 of 2 times", round_end_repeats, 6);
	}
	else
	{
		PrintToChatAll("\x05%t: \x04%s", "Next campaign", NextCampaign);
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