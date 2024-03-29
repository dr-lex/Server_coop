#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <geoip>
#pragma newdecls required

char sg_log[160];

static char sCountryBlock[][] =
{
	"Argentina",
	"Australia",
	"Bangladesh",
	"Bolivia",
	"Brazil",
	"Chile",
	"China",
	"Colombia",
	"Costa Rica",
	"Djibouti",
	"Dominican Republic",
	"Ecuador",
	"Hong Kong",
	"Indonesia",
	"Japan",
	"Macao",
	"Malaysia",
	"Nicaragua",
	"Paraguay",
	"Peru",
	"Philippines",
	"Singapore",
	"South Africa",
	"South Korea",
	"Taiwan",
	"Thailand",
	"United Arab Emirates",
	"Venezuela",
	"Vietnam",
	"Zimbabwe"
};

static char sCountry[][] =
{
	"Åland",
	"Albania",
	"Algeria",
	"Armenia",
	"Austria",
	"Azerbaijan",
	"Bahrain",
	"Belarus",
	"Belgium",
	"Bosnia and Herzegovina",
	"Bulgaria",
	"Canada",
	"Croatia",
	"Cyprus",
	"Czechia",
	"Denmark",
	"Egypt",
	"El Salvador",
	"Estonia",
	"Finland",
	"France",
	"Georgia",
	"Germany",
	"Ghana",
	"Greece",
	"Guatemala",
	"Hashemite Kingdom of Jordan",
	"Honduras",
	"Hungary",
	"India",
	"Iran",
	"Iraq",
	"Isle of Man",
	"Ireland",
	"Israel",
	"Italy",
	"Kazakhstan",
	"Kuwait",
	"Kyrgyzstan",
	"Latvia",
	"Libya",
	"Malta",
	"Mexico",
	"Mongolia",
	"Montenegro",
	"Morocco",
	"Netherlands",
	"Nigeria",
	"Norway",
	"Oman",
	"Panama",
	"Palestine",
	"Pakistan",
	"Poland",
	"Portugal",
	"Puerto Rico",
	"Qatar",
	"Republic of Lithuania",
	"Republic of Moldova",
	"Romania",
	"Russia",
	"Saudi Arabia",
	"Serbia",
	"Syria",
	"Slovakia",
	"Slovenia",
	"Spain",
	"Sweden",
	"Switzerland",
	"Tajikistan",
	"Tunisia",
	"Turkey",
	"Ukraine",
	"United Kingdom",
	"United States",
	"Uzbekistan",
	"North Macedonia",
	"New Zealand"
};

public Plugin myinfo = 
{
	name = "[ANY] Blocks Region",
	author = "dr lex",
	description = "Blocks countries by region",
	version = "1.0.8",
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
		char IP[16], Country[128];
		GetClientIP(client, IP, sizeof(IP), true);
		GeoipCountry(IP, Country, sizeof(Country));
		for (int count = 0; count <= 29; count++)
		{
			if (StrEqual(Country, sCountryBlock[count]))
			{
				Format(rejectmsg, maxlen, "The server is not available in your region =( \n Ping > 200");
				return false;
			}
		}
		
		for (int count = 0; count <= 77; count++)
		{
			if (StrEqual(Country, sCountry[count]))
			{
				return true;
			}
		}
		
		if (!StrEqual(Country, ""))
		{
			LogToFileEx(sg_log, "[New] %s (%N) ip %s", Country, client, IP);
		}
	}
	return true;
}