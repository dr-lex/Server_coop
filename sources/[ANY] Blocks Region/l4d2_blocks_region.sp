#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <geoip>
#pragma newdecls required

char sg_log[160];

static char sCountryBlock[][] =
{
	"Argentina", 
	"Chile", 
	"South Korea", 
	"Ecuador", 
	"Colombia", 
	"Peru", 
	"Malaysia", 
	"China", 
	"Taiwan",
	"Hong Kong",
	"Indonesia",
	"Vietnam",
	"Thailand",
	"Philippines",
	"United Arab Emirates", 
	"Singapore", 
	"Brazil", 
	"Australia", 
	"Japan", 
	"Bolivia", 
	"Macao", 
	"Venezuela", 
	"South Africa", 
	"Zimbabwe"
};

static char sCountry[][] =
{
	"Belarus", 
	"Russia", 
	"Turkey", 
	"United States", 
	"United Kingdom", 
	"Ukraine", 
	"Republic of Lithuania", 
	"Latvia", 
	"Bulgaria", 
	"Slovenia", 
	"Finland", 
	"France", 
	"Germany", 
	"Kazakhstan", 
	"Ireland", 
	"Portugal", 
	"Serbia", 
	"Sweden", 
	"Israel", 
	"Egypt", 
	"Romania", 
	"Iran", 
	"Iraq", 
	"Uzbekistan", 
	"Tunisia", 
	"Poland", 
	"Denmark", 
	"Italy", 
	"Austria", 
	"Canada", 
	"Kyrgyzstan", 
	"Estonia", 
	"Spain", 
	"Czechia", 
	"Mexico", 
	"Pakistan", 
	"Mongolia", 
	"Belgium", 
	"India", 
	"Republic of Moldova", 
	"Azerbaijan", 
	"Netherlands", 
	"Qatar", 
	"Kuwait", 
	"Morocco", 
	"Malta", 
	"Georgia", 
	"Algeria", 
	"Saudi Arabia", 
	"Hungary", 
	"Albania"
};

public Plugin myinfo = 
{
	name = "[ANY] Blocks Region",
	author = "dr lex",
	description = "Blocks countries by region",
	version = "1.0.2",
	url = ""
}

public void OnPluginStart()
{
	BuildPath(Path_SM, sg_log, sizeof(sg_log)-1, "logs/info_country.log");
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	if (!IsFakeClient(client))
	{
		char IP[16], Country[46];
		GetClientIP(client, IP, sizeof(IP), true);
		GeoipCountry(IP, Country, sizeof(Country));
		
		for (int count = 0; count <= 23; count++)
		{
			if (StrEqual(Country, sCountryBlock[count]))
			{
				Format(rejectmsg, maxlen, "The server is not available in your region =(");
				LogToFileEx(sg_log, "[Kick] %N (%s) ip %s", client, Country, IP);
				return false;
			}
		}
		
		for (int count = 0; count <= 50; count++)
		{
			if (StrEqual(Country, sCountry[count]))
			{
				return true;
			}
		}
		
		LogToFileEx(sg_log, "[New] %s (%N) ip %s", Country, client, IP);
	}
	return true;
}