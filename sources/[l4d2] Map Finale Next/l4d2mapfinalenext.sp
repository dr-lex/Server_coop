#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#tryinclude <l4d2_changelevel>

char sg_Map[54];
int round_end_repeats;
int IsRoundStarted = 0;
char NextCampaignVote[32];
int seconds;
char NextCampaign[53];
char sMapName[40];

#define FIX_ENABLED 1
#if FIX_ENABLED
	Handle hResetTransitioned = null;
#endif

public Plugin myinfo = 
{
	name = "[l4d2] Map Finale Next",
	author = "dr.lex (Exclusive Coop-17)",
	description = "Rotation of companies in the list, full loading of players when changing cards",
	version = "2.9.1",
	url = "https://steamcommunity.com/id/dr_lex/"
};

public void OnPluginStart()
{
	LoadTranslations("l4d2mapfinalenext.phrases");
	RegConsoleCmd("sm_next", Command_Next);
	
	HookEvent("finale_win", Event_FinalWin);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	HookUserMessage(GetUserMessageId("DisconnectToLobby"), OnDisconnectToLobby, true);
	
#if FIX_ENABLED
	Handle hConf = LoadGameConfigFile("l4d2mapfinalenext");
	if (hConf)
	{
		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "ResetTransitioned");
		hResetTransitioned = EndPrepSDKCall();
		if (!hResetTransitioned)
		{
			SetFailState("error l4d2mapfinalenext.txt");
		}

		delete hConf;
	}
#endif
}

public Action OnDisconnectToLobby(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	int iVoteController = FindEntityByClassname(-1, "vote_controller");
	if (!IsValidEntity(iVoteController) || GetEntProp(iVoteController, Prop_Send, "m_activeIssueIndex") == 4)
	{
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

stock void NextMission()
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
		NextCampaign = "Random";
		NextCampaignVote = "RANDOM";
	}
}

public void OnMapStart()
{
	GetCurrentMap(sg_Map, sizeof(sg_Map)-1);
	round_end_repeats = 0;
	seconds = 5;
	
#if FIX_ENABLED
	CreateTimer(30.0, HxTimer, _, TIMER_FLAG_NO_MAPCHANGE);
#endif
}

#if FIX_ENABLED
public Action HxTimer(Handle timer)
{
	SDKCall(hResetTransitioned);
	return Plugin_Stop;
}
#endif

public void Event_FinalWin(Event event, const char[] name, bool dontBroadcast)
{
	PrintNextCampaign();
	CreateTimer(10.0, ChangeCampaign, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
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
	return Plugin_Stop;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!IsRoundStarted)
	{
		return;
	}
	round_end_repeats++;
}

public void ChangeCampaignEx()
{
	NextMission();
	if (StrEqual(NextCampaignVote, "L4D2C1", false))
	{
		sMapName = "c1m1_hotel";
	}
	if (StrEqual(NextCampaignVote, "L4D2C2", false))
	{
		sMapName = "c2m1_highway";
	}
	if (StrEqual(NextCampaignVote, "L4D2C3", false))
	{
		sMapName = "c3m1_plankcountry";
	}
	if (StrEqual(NextCampaignVote, "L4D2C4", false))
	{
		sMapName = "c4m1_milltown_a";
	}
	if (StrEqual(NextCampaignVote, "L4D2C5", false))
	{
		sMapName = "c5m1_waterfront";
	}
	if (StrEqual(NextCampaignVote, "L4D2C6", false))
	{
		sMapName = "c6m1_riverbank";
	}
	if (StrEqual(NextCampaignVote, "L4D2C7", false))
	{
		sMapName = "c7m1_docks";
	}
	if (StrEqual(NextCampaignVote, "L4D2C8", false))
	{
		sMapName = "c8m1_apartment";
	}
	if (StrEqual(NextCampaignVote, "L4D2C9", false))
	{
		sMapName = "c9m1_alleys";
	}
	if (StrEqual(NextCampaignVote, "L4D2C10", false))
	{
		sMapName = "c10m1_caves";
	}
	if (StrEqual(NextCampaignVote, "L4D2C11", false))
	{
		sMapName = "c11m1_greenhouse";
	}
	if (StrEqual(NextCampaignVote, "L4D2C12", false))
	{
		sMapName = "c12m1_hilltop";
	}
	if (StrEqual(NextCampaignVote, "L4D2C13", false))
	{
		sMapName = "c13m1_alpinecreek";
	}
	if (StrEqual(NextCampaignVote, "L4D2C14", false))
	{
		sMapName = "c14m1_junkyard";
	}
	if (StrEqual(NextCampaignVote, "RANDOM", false))
	{
		switch(GetRandomInt(1, 14))
		{
			case 1: sMapName = "c1m1_hotel";
			case 2: sMapName = "c2m1_highway";
			case 3: sMapName = "c3m1_plankcountry";
			case 4: sMapName = "c4m1_milltown_a";
			case 5: sMapName = "c5m1_waterfront";
			case 6: sMapName = "c6m1_riverbank";
			case 7: sMapName = "c7m1_docks";
			case 8: sMapName = "c8m1_apartment";
			case 9: sMapName = "c9m1_alleys";
			case 10: sMapName = "c10m1_caves";
			case 11: sMapName = "c11m1_greenhouse";
			case 12: sMapName = "c12m1_hilltop";
			case 13: sMapName = "c13m1_alpinecreek";
			case 14: sMapName = "c14m1_junkyard";
		}
	}
	
#if defined _l4d2_changelevel_included
	L4D2_ChangeLevel(sMapName);
#else
	ServerCommand("changelevel %s", sMapName);
#endif
}

stock void PrintNextCampaign(int client = 0)
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