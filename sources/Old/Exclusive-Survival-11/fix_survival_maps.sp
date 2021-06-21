#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

char sMap[55];

public Plugin myinfo = 
{
	name = "Fix Survival Сhangelevel",
	author = "dr lex",
	description = "Checks and changes the map if there is no survival mode",
	version = "1.0",
	url = ""
};

public void OnMapStart()
{
	GetCurrentMap(sMap, 54);
	if (StrEqual(sMap, "c1m1_hotel", false) || StrEqual(sMap, "c1m3_mall", false) || StrEqual(sMap, "c2m2_fairgrounds", false) || StrEqual(sMap, "c2m3_coaster", false) || StrEqual(sMap, "c3m2_swamp", false) || StrEqual(sMap, "c4m4_milltown_b", false) || StrEqual(sMap, "c4m5_milltown_escape", false) || StrEqual(sMap, "c8m1_apartment", false) || StrEqual(sMap, "c10m1_caves", false) || StrEqual(sMap, "c11m1_greenhouse", false) || StrEqual(sMap, "c12m1_hilltop", false) || StrEqual(sMap, "c12m4_barn", false) || StrEqual(sMap, "c13m1_alpinecreek", false) || StrEqual(sMap, "c13m2_southpinestream", false))
	{
		switch(GetRandomInt(1, 43))
		{
			case 1: ServerCommand("changelevel c1m2_streets");
			case 2: ServerCommand("changelevel c1m4_atrium");
			case 3: ServerCommand("changelevel c2m1_highway");
			case 4: ServerCommand("changelevel c2m4_barns");
			case 5: ServerCommand("changelevel c2m5_concert");
			case 6: ServerCommand("changelevel c3m1_plankcountry");
			case 7: ServerCommand("changelevel c3m3_shantytown");
			case 8: ServerCommand("changelevel c3m4_plantation");
			case 9: ServerCommand("changelevel c4m1_milltown_a");
			case 10: ServerCommand("changelevel c4m2_sugarmill_a");
			case 11: ServerCommand("changelevel c4m3_sugarmill_b");
			case 12: ServerCommand("changelevel c5m1_waterfront");
			case 13: ServerCommand("changelevel c5m2_park");
			case 14: ServerCommand("changelevel c5m3_cemetery");
			case 15: ServerCommand("changelevel c5m4_quarter");
			case 16: ServerCommand("changelevel c5m5_bridge");
			case 17: ServerCommand("changelevel c6m1_riverbank");
			case 18: ServerCommand("changelevel c6m2_bedlam");
			case 19: ServerCommand("changelevel c6m3_port");
			case 20: ServerCommand("changelevel c7m1_docks");
			case 21: ServerCommand("changelevel c7m2_barge");
			case 22: ServerCommand("changelevel c7m3_port");
			case 23: ServerCommand("changelevel c8m2_subway");
			case 24: ServerCommand("changelevel c8m3_sewers");
			case 25: ServerCommand("changelevel c8m4_interior");
			case 26: ServerCommand("changelevel c8m5_rooftop");
			case 27: ServerCommand("changelevel c9m1_alleys");
			case 28: ServerCommand("changelevel c9m2_lots");
			case 29: ServerCommand("changelevel c10m2_drainage");
			case 30: ServerCommand("changelevel c10m3_ranchhouse");
			case 31: ServerCommand("changelevel c10m4_mainstreet");
			case 32: ServerCommand("changelevel c10m5_houseboat");
			case 33: ServerCommand("changelevel c11m2_offices");
			case 34: ServerCommand("changelevel c11m3_garage");
			case 35: ServerCommand("changelevel c11m4_terminal");
			case 36: ServerCommand("changelevel c11m5_runway");
			case 37: ServerCommand("changelevel c12m2_traintunnel");
			case 38: ServerCommand("changelevel c12m3_bridge");
			case 39: ServerCommand("changelevel c12m5_cornfield");
			case 40: ServerCommand("changelevel c13m3_memorialbridge");
			case 41: ServerCommand("changelevel c13m4_cutthroatcreek");
			case 42: ServerCommand("changelevel c14m1_junkyard");
			case 43: ServerCommand("changelevel c14m2_lighthouse");
		}
	}
}
