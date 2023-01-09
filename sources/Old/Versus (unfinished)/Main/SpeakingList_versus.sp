#include <sourcemod>
#include <sdktools>
#pragma newdecls required

ConVar cvar_speakerlist_type;

int iSpeakListType, iCount;

bool ClientSpeakingTime[MAXPLAYERS+1];

char SpeakingPlayers[128], sPath_VscriptHUD[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = "Voice list",
	author = "dr lex",
	description = "Voice Announce. Message who Speaking. ",
	version = "1.3.2",
	url = "http://steamcommunity.com/id/dr_lex"
}

public void OnPluginStart()
{
	cvar_speakerlist_type = CreateConVar("voice_speakerlist_type",  "1", "Speaker list type (0: Center text, 1: Hud Layout) [DEFAULT: 0]", FCVAR_NONE, true, 0.0, true, 1.0);
	RegAdminCmd("sm_runvscript", Command_RunVscript, ADMFLAG_ROOT);
	HookConVarChange(cvar_speakerlist_type, Cvar_Changed);
	char sPath[PLATFORM_MAX_PATH];
	strcopy(sPath, sizeof(sPath), "scripts/vscripts");
	if (DirExists(sPath) == false)
	{
		CreateDirectory(sPath, 511);
	}
	Format(sPath_VscriptHUD, sizeof(sPath_VscriptHUD), "scripts/vscripts/speakerhud.nut")
	if (FileExists(sPath_VscriptHUD) == false || FileSize(sPath_VscriptHUD) == 0)
	{
		SaveVscriptHUD();
	}
	CreateTimer(0.5, UpdateSpeaking, _, TIMER_REPEAT);
}

public void OnClientSpeaking(int client)
{
	ClientSpeakingTime[client] = true;
}

public void OnConfigsExecuted()
{
	GetCvars();
}

public void Cvar_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	iSpeakListType = GetConVarInt(cvar_speakerlist_type);
}

public Action Command_RunVscript(int client, int args)
{
	if (args < 1)
	{
		return Plugin_Handled;
	}
	
	char vscriptFile[40];
	GetCmdArg(1, vscriptFile, sizeof(vscriptFile));
	int entity = CreateEntityByName("logic_script");
	if (entity != -1)
	{
		DispatchKeyValue(entity, "vscripts", vscriptFile);
		DispatchSpawn(entity);
		SetVariantString("OnUser1 !self:RunScriptCode::0:-1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser1 !self:Kill::1:-1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
	return Plugin_Handled;
}

public Action UpdateSpeaking(Handle timer)
{
	iCount = 0;
	SpeakingPlayers[0] = '\0';
	for (int i = 1; i <= MaxClients; i++)
	{
		if (ClientSpeakingTime[i])
		{
			if (!IsClientInGame(i))
			{
				return Plugin_Continue;
			}
			
			if (GetClientTeam(i) == 3)
			{
				return Plugin_Continue;
			}

			if (iSpeakListType)
			{
				Format(SpeakingPlayers, sizeof(SpeakingPlayers), "%s\\n(►%N", SpeakingPlayers, i);
			}
			else
			{
				Format(SpeakingPlayers, sizeof(SpeakingPlayers), "%s\n(►%N", SpeakingPlayers, i);
			}
			iCount++;
		}
		ClientSpeakingTime[i] = false;
	}

	if (iCount > 0)
	{
		if (iSpeakListType)
		{
			UpdateDatavalHUD("%s", SpeakingPlayers);
			ServerCommand("sm_runvscript speakerhud");
		}
		else
		{
			PrintCenterTextAll("Players Speaking:%s", SpeakingPlayers);
		}
	}
	else
	{
		if (iSpeakListType)
		{
			ResetHUD();
			ServerCommand("sm_runvscript speakerhud");
		}
	}
	return Plugin_Continue;
}

void UpdateDatavalHUD(const char[] format, any ...)
{
	char buffer[200];
	VFormat(buffer, sizeof(buffer), format, 2);
	SaveVscriptHUD(buffer);
}

void ResetHUD()
{
	SaveVscriptHUD();
}

void SaveVscriptHUD(const char[] dataval = "")
{
	Handle hFile = OpenFile(sPath_VscriptHUD, "w");
	if (hFile)
	{
		WriteFileLine(hFile, "ModeHUD <-");
		WriteFileLine(hFile, "{");
		WriteFileLine(hFile, "Fields = ");
		WriteFileLine(hFile, "{");
		WriteFileLine(hFile, "logo = ");
		WriteFileLine(hFile, "{");
		WriteFileLine(hFile, "slot = g_ModeScript.HUD_FAR_RIGHT,");
		WriteFileLine(hFile, "dataval = \"Alfa Versus\",");
		WriteFileLine(hFile, "flags = g_ModeScript.HUD_FLAG_ALIGN_CENTER | g_ModeScript.HUD_FLAG_NOBG,");
		WriteFileLine(hFile, "name = \"logo\" ");
		if (!StrEqual(dataval, "", false))
		{
			WriteFileLine(hFile, "},");
			WriteFileLine(hFile, "speaker = ");
			WriteFileLine(hFile, "{");
			WriteFileLine(hFile, "slot = g_ModeScript.HUD_MID_BOX,");
			WriteFileLine(hFile, "dataval = \"%s\",", dataval);
			WriteFileLine(hFile, "flags = g_ModeScript.HUD_FLAG_ALIGN_LEFT | g_ModeScript.HUD_FLAG_NOBG,");
			WriteFileLine(hFile, "name = \"speaker\" ");
			WriteFileLine(hFile, "}");
		}
		else
		{
			WriteFileLine(hFile, "}");
		}
		WriteFileLine(hFile, "}");
		WriteFileLine(hFile, "}");
		WriteFileLine(hFile, "");
		WriteFileLine(hFile, "HUDSetLayout( ModeHUD )");
		WriteFileLine(hFile, "HUDPlace(g_ModeScript.HUD_FAR_RIGHT, 0.75 , 0.04 , 0.30 , 0.08)");
		if (!StrEqual(dataval, "", false))
		{
			WriteFileLine(hFile, "HUDPlace(g_ModeScript.HUD_MID_BOX , 0.78 , 0.63 , 0.35 , 0.2)");
		}
		WriteFileLine(hFile, "g_ModeScript");
		delete hFile;
	}
}