#define PLUGIN_VERSION 		"1.32"

//#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif
#pragma newdecls required

#define CVAR_FLAGS			FCVAR_NONE|FCVAR_NOTIFY

#define ANIM_L4D2_NICK 631
#define ANIM_L4D2_ELLIS 636
#define ANIM_L4D2_ROCH 639
#define ANIM_L4D2_ZOEY 529
#define ANIM_L4D2_LOUIS 539
#define ANIM_L4D2_FRANCIS 542
#define ANIM_L4D2_BILL 539

ConVar g_hCvarCrawl, g_hCvarSpeed, g_hMPGameMode, g_hCvarAllow, g_hCvarGlow, g_hCvarHint, g_hCvarHintS, g_hCvarHurt, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRate, g_hCvarSpeeds, g_hCvarSpit, g_hCvarView;
Handle g_hTmrHurt;
int g_iSpeed, g_iHint, g_iHints, g_iHurt, g_iRate; 
bool g_bCvarAllow, g_bGlow, g_bSpit, g_bView, g_bTranslation, g_bRoundOver;
int g_iPlayerEnum[MAXPLAYERS], g_iClone[MAXPLAYERS], g_iDisplayed[MAXPLAYERS];

enum (<<=1)
{
	ENUM_INCAPPED = 1, ENUM_INSTART, ENUM_BLOCKED, ENUM_POUNCED, ENUM_ONLEDGE, ENUM_INREVIVE, ENUM_INSPIT
}

public Plugin myinfo =
{
	name = "[L4D2] Incapped Crawling with Animation",
	author = "SilverShot",
	description = "Allows incapped survivors to crawl and sets crawling animation.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=137381"
}

public void OnPluginStart()
{
	char sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if (strcmp(sGameName, "left4dead2", false)) SetFailState("Plugin only supports Left4Dead 2.");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "%s", "translations/incappedcrawling.phrases.txt");

	if (!FileExists(sPath)) g_bTranslation = false;
	else
	{
		LoadTranslations("incappedcrawling.phrases");
		g_bTranslation = true;
	}

	g_hCvarAllow = CreateConVar("l4d2_crawling", "1", "0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarGlow = CreateConVar("l4d2_crawling_glow", "0", "0=Disables survivor glow on crawling, 1=Enables glow if not realism.", CVAR_FLAGS);
	g_hCvarHint = CreateConVar("l4d2_crawling_hint", "2", "0=Dislables, 1=Chat text, 2=Hint box, 3=Instructor hint.", CVAR_FLAGS);
	g_hCvarHintS = CreateConVar("l4d2_crawling_hint_num", "10", "How many times to display hints or instructor hint timeout.", CVAR_FLAGS);
	g_hCvarHurt = CreateConVar("l4d2_crawling_hurt", "5", "Damage to apply every second of crawling, 0=No damage when crawling.", CVAR_FLAGS);
	g_hCvarModes = CreateConVar("l4d2_crawling_modes", "", "Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar("l4d2_crawling_modes_off", "", "Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar("l4d2_crawling_modes_tog", "0", "Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRate = CreateConVar("l4d2_crawling_rate", "15", "Sets the playback speed of the crawling animation.", CVAR_FLAGS);
	g_hCvarSpeeds = CreateConVar("l4d2_crawling_speed", "15", "Changes 'survivor_crawl_speed' cvar.", CVAR_FLAGS);
	g_hCvarSpit = CreateConVar("l4d2_crawling_spit", "1", "0=Disables crawling in spitter acid, 1=Enables crawling in spit.", CVAR_FLAGS);
	g_hCvarView = CreateConVar("l4d2_crawling_view", "1", "0=Firstperson view when crawling, 1=Thirdperson view when crawling.", CVAR_FLAGS);
	CreateConVar("l4d2_crawling_version", PLUGIN_VERSION, "Incapped Crawling plugin version.", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d2_incapped_crawling");

	g_hMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hMPGameMode, ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow, ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes, ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff, ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesTog, ConVarChanged_Allow);
	HookConVarChange(g_hCvarGlow, ConVarChanged_Cvars);
	HookConVarChange(g_hCvarHint, ConVarChanged_Cvars);
	HookConVarChange(g_hCvarHintS, ConVarChanged_Cvars);
	HookConVarChange(g_hCvarHurt, ConVarChanged_Cvars);
	HookConVarChange(g_hCvarSpit, ConVarChanged_Cvars);
	HookConVarChange(g_hCvarView, ConVarChanged_Cvars);
	HookConVarChange(g_hCvarRate, ConVarChanged_Cvars);
	HookConVarChange(g_hCvarSpeeds, ConVarChanged_Speed);

	g_hCvarCrawl = FindConVar("survivor_allow_crawling");
	g_hCvarSpeed = FindConVar("survivor_crawl_speed");

	for (int i = 0; i < MAXPLAYERS; i++) g_iClone[i] = -1;
}

public void OnPluginEnd()
{
	SetConVarInt(g_hCvarCrawl, 0);

	for (int i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && GetClientTeam(i) == 2) RemoveClone(i);
}

public void OnClientPutInServer(int client)
{
	g_iDisplayed[client] = 0;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Speed(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iSpeed = GetConVarInt(g_hCvarSpeeds);
	SetConVarInt(g_hCvarSpeed, g_iSpeed);
}

int GetCvars()
{
	g_bGlow = GetConVarBool(g_hCvarGlow);
	g_iHint = GetConVarInt(g_hCvarHint);
	g_iHints = GetConVarInt(g_hCvarHintS);
	g_iHurt = GetConVarInt(g_hCvarHurt);
	g_iRate = GetConVarInt(g_hCvarRate);
	g_iSpeed = GetConVarInt(g_hCvarSpeeds);
	g_bSpit = GetConVarBool(g_hCvarSpit);
	g_bView = GetConVarBool(g_hCvarView);
}

int IsAllowed()
{
	bool bCvarAllow = GetConVarBool(g_hCvarAllow);
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if (g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true)
	{
		g_bCvarAllow = true;
		HookEvents();
		SetConVarInt(g_hCvarCrawl, 1);
		SetConVarInt(g_hCvarSpeed, g_iSpeed);

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) == 1)
			{
				g_iPlayerEnum[i] |= ENUM_INCAPPED;
			}
		}
	}

	else if (g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false))
	{
		g_bCvarAllow = false;
		UnhookEvents();
		SetConVarInt(g_hCvarCrawl, 0);
	}
}

int g_iCurrentMode;

bool IsAllowedGameMode()
{
	if (g_hMPGameMode == null) return false;

	int iCvarModesTog = GetConVarInt(g_hCvarModesTog);
	if (iCvarModesTog != 0)
	{
		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		AcceptEntityInput(entity, "PostSpawnActivate");
		AcceptEntityInput(entity, "Kill");

		if (g_iCurrentMode == 0) return false;
		if (!(iCvarModesTog & g_iCurrentMode)) return false;
	}

	char sGameModes[64], sGameMode[64];
	GetConVarString(g_hMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	GetConVarString(g_hCvarModes, sGameModes, sizeof(sGameModes));
	if (strcmp(sGameModes, ""))
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) == -1) return false;
	}

	GetConVarString(g_hCvarModesOff, sGameModes, sizeof(sGameModes));
	if (strcmp(sGameModes, ""))
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) != -1) return false;
	}
	return true;
}

public int OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if (strcmp(output, "OnCoop") == 0) g_iCurrentMode = 1;
	else if (strcmp(output, "OnSurvival") == 0) g_iCurrentMode = 2;
	else if (strcmp(output, "OnVersus") == 0) g_iCurrentMode = 4;
	else if (strcmp(output, "OnScavenge") == 0) g_iCurrentMode = 8;
}

int HookEvents()
{
	HookEvent("player_incapacitated", Event_Incapped); // Delay crawling by 1 second
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_ledge_grab", Event_LedgeGrab); // Stop crawling anim whilst ledge handing
	HookEvent("revive_begin", Event_ReviveStart); // Revive start/stop
	HookEvent("revive_end", Event_ReviveEnd);
	HookEvent("revive_success",	Event_ReviveSuccess); // Revived
	HookEvent("player_death", Event_Unblock); // Player died,			unblock all
	HookEvent("player_spawn", Event_Unblock); // Player spawned,		unblock all
	HookEvent("player_hurt", Event_PlayerHurt); // Apply damage in spit
	HookEvent("charger_pummel_start", Event_BlockStart); // Charger
	HookEvent("charger_carry_start", Event_BlockStart);
	HookEvent("charger_carry_end", Event_BlockEnd);
	HookEvent("charger_pummel_end",	Event_BlockEnd);
	HookEvent("lunge_pounce", Event_BlockHunter); // Hunter
	HookEvent("pounce_end", Event_BlockEndHunt);
	HookEvent("tongue_grab", Event_BlockStart); // Smoker
	HookEvent("tongue_release",	Event_BlockEnd);
}

int UnhookEvents()
{
	UnhookEvent("player_incapacitated",	Event_Incapped);
	UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	UnhookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	UnhookEvent("player_ledge_grab", Event_LedgeGrab);
	UnhookEvent("revive_begin",	Event_ReviveStart);
	UnhookEvent("revive_end", Event_ReviveEnd);
	UnhookEvent("revive_success", Event_ReviveSuccess);
	UnhookEvent("player_death", Event_Unblock);
	UnhookEvent("player_spawn",	Event_Unblock);
	UnhookEvent("player_hurt", Event_PlayerHurt);
	UnhookEvent("charger_pummel_start",	Event_BlockStart);
	UnhookEvent("charger_carry_start", Event_BlockStart);
	UnhookEvent("charger_carry_end", Event_BlockEnd);
	UnhookEvent("charger_pummel_end", Event_BlockEnd);
	UnhookEvent("lunge_pounce", Event_BlockHunter);
	UnhookEvent("pounce_end", Event_BlockEndHunt);
	UnhookEvent("tongue_grab", Event_BlockStart);
	UnhookEvent("tongue_release", Event_BlockEnd);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundOver = false;
	CreateTimer(1.0, tmrRoundStart);
}

public Action tmrRoundStart(Handle timer)
{
	g_bCvarAllow = GetConVarBool(g_hCvarAllow);

	if (g_bCvarAllow)
	{
		SetConVarInt(g_hCvarCrawl, 1);
		SetConVarInt(g_hCvarSpeed, g_iSpeed);
	}

	for (int i = 0; i < MAXPLAYERS; i++)
	{
		g_iClone[i] = -1;
		g_iPlayerEnum[i] = 0;
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundOver = true;
	SetConVarInt(g_hCvarCrawl, 0);
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bSpit && event.GetInt("type") == 263168)	// Crawling in spit not allowed & acid damage type
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (client > 0 && client <= MaxClients && !(g_iPlayerEnum[client] & ENUM_INSPIT) && !IsFakeClient(client))
		{
			g_iPlayerEnum[client] |= ENUM_INSPIT;
			CreateTimer(2.0, tmrResetSpit, client);
		}
	}
}

public Action tmrResetSpit(Handle timer, any client) 
{
	g_iPlayerEnum[client] &= ~ENUM_INSPIT;
}

public Action Event_LedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0) g_iPlayerEnum[client] |= ENUM_ONLEDGE;
}

public Action Event_ReviveStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (client > 0) g_iPlayerEnum[client] |= ENUM_INREVIVE;
}

public Action Event_ReviveEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (client > 0) g_iPlayerEnum[client] &= ~ENUM_INREVIVE;
}

public Action Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (client > 0) g_iPlayerEnum[client] = 0;
}

public Action Event_Unblock(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0) g_iPlayerEnum[client] = 0;
}

public Action Event_BlockStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client > 0) g_iPlayerEnum[client] |= ENUM_BLOCKED;
}

public Action Event_BlockEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client > 0) g_iPlayerEnum[client] &= ~ENUM_BLOCKED;
}

public Action Event_BlockHunter(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client > 0) g_iPlayerEnum[client] |= ENUM_POUNCED;
}

public Action Event_BlockEndHunt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client > 0) g_iPlayerEnum[client] &= ~ENUM_POUNCED;
}

public Action Event_Incapped(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!(g_iPlayerEnum[client] & ENUM_INSTART) && !IsFakeClient(client) && GetClientTeam(client) == 2)
	{
		g_iPlayerEnum[client] |= ENUM_INCAPPED | ENUM_INSTART;
		CreateTimer(1.5, tmrResetStart, GetClientUserId(client));
	}
}

public Action tmrResetStart(Handle timer, any client)
{
	client = GetClientOfUserId(client);
	g_iPlayerEnum[client] &= ~ENUM_INSTART;

	if (g_bRoundOver || !g_iHint || (g_iHint < 3 && g_iDisplayed[client] >= g_iHints) || !IsValidClient(client)) return;

	g_iDisplayed[client]++;
	char sBuffer[100];

	switch (g_iHint)
	{
		case 1:
		{
			if (g_bTranslation) Format(sBuffer, sizeof(sBuffer), "\x04[\x01Incapped Crawling\x04]\x01 %T", "Crawl", client);
			else Format(sBuffer, sizeof(sBuffer), "\x04[\x01Incapped Crawling\x04]\x01 Press FORWARD to crawl while incapped");
			PrintToChat(client, sBuffer);
		}

		case 2:
		{
			if (g_bTranslation) Format(sBuffer, sizeof(sBuffer), "[Incapped Crawling] %T", "Crawl", client);
			else Format(sBuffer, sizeof(sBuffer), "[Incapped Crawling] - Press FORWARD to crawl while incapped");

			PrintHintText(client, sBuffer);
		}

		case 3:
		{
			char sTemp[32];

			if (g_bTranslation) Format(sBuffer, sizeof(sBuffer), "%T", "Crawl", client);
			else Format(sBuffer, sizeof(sBuffer), "Press FORWARD to crawl while incapped!");
			ReplaceString(sBuffer, sizeof(sBuffer), "\n", " ");

			int entity = CreateEntityByName("env_instructor_hint");
			FormatEx(sTemp, sizeof(sTemp), "hint%d", client);
			DispatchKeyValue(client, "targetname", sTemp);
			DispatchKeyValue(entity, "hint_target", sTemp);
			Format(sTemp, sizeof(sTemp), "%d", g_iHints);
			DispatchKeyValue(entity, "hint_timeout", sTemp);
			DispatchKeyValue(entity, "hint_range", "0.01");
			DispatchKeyValue(entity, "hint_icon_onscreen", "icon_key_up");
			DispatchKeyValue(entity, "hint_caption", sBuffer);
			DispatchKeyValue(entity, "hint_color", "255 255 255");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "ShowHint");

			Format(sTemp, sizeof(sTemp), "OnUser1 !self:Kill::%d:1", g_iHints);
			SetVariantString(sTemp);
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!g_bCvarAllow) return Plugin_Continue;
	if (g_iPlayerEnum[client] & ENUM_INCAPPED && buttons & IN_FORWARD && !g_bRoundOver && GetClientTeam(client) == 2)
	{
		if (g_iPlayerEnum[client] & ENUM_POUNCED)
		{
			buttons &= ~IN_FORWARD;
			return Plugin_Handled;
		}

		if (g_iPlayerEnum[client] != ENUM_INCAPPED)
		{
			RestoreClient(client);
			buttons &= ~IN_FORWARD;
			return Plugin_Continue;
		}

		if (g_iClone[client] == -1)
		{
			PlayAnim(client);
		}
	}
	else
	{
		RestoreClient(client);
	}
	return Plugin_Continue;
}

public Action PlayAnim(int client)
{
	int iAnim;
	char sModel[42];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	if (sModel[26] == 'c') iAnim = -1;
	else if (sModel[26] == 'g') iAnim = ANIM_L4D2_NICK;
	else if (sModel[26] == 'm' && sModel[27] == 'e') iAnim = ANIM_L4D2_ELLIS;
	else if (sModel[26] == 'p') iAnim = ANIM_L4D2_ROCH;
	else if (sModel[26] == 't') iAnim = ANIM_L4D2_ZOEY;
	else if (sModel[26] == 'm' && sModel[27] == 'a') iAnim = ANIM_L4D2_LOUIS;
	else if (sModel[26] == 'b')	iAnim = ANIM_L4D2_FRANCIS;
	else if (sModel[26] == 'n') iAnim = ANIM_L4D2_BILL;
	else return;

	if (g_iHurt > 0)
	{
		HurtPlayer(client);
		if (g_hTmrHurt == null) g_hTmrHurt = CreateTimer(1.0, tmrHurt, _, TIMER_REPEAT);
	}

	if (iAnim == -1)
	{
		g_iClone[client] = 0;
		return;
	}

	int clone = CreateEntityByName("prop_dynamic");
	if (clone == -1)
	{
		LogError("Failed to create prop_dynamic '%s' (%N)", sModel, client);
		return;
	}

	SetEntityModel(clone, sModel);
	g_iClone[client] = EntIndexToEntRef(clone);

	SetVariantString("!activator");
	AcceptEntityInput(clone, "SetParent", client);
	SetVariantString("bleedout");
	AcceptEntityInput(clone, "SetParentAttachment");

	float vPos[3], vAng[3];
	vPos[0] = -2.0;
	vPos[1] = -15.0;
	vPos[2] = -10.0;
	vAng[0] = -330.0;
	vAng[1] = -100.0;
	vAng[2] = 70.0;

	TeleportEntity(clone, vPos, vAng, NULL_VECTOR);

	SetEntProp(clone, Prop_Send, "m_nSequence", iAnim);
	SetEntPropFloat(clone, Prop_Send, "m_flPlaybackRate", float(g_iRate) / 15); // Default speed = 15, normal rate = 1.0

	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, 0);

	if (!g_bGlow) SetEntProp(client, Prop_Send, "m_bSurvivorGlowEnabled", 0);
	if (g_bView) GotoThirdPerson(client);
}

public Action tmrHurt(Handle timer)
{
	bool bIsCrawling;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (g_iClone[i] != -1)
			{
				bIsCrawling = true;
				HurtPlayer(i);
			}
		}
	}
	if (!bIsCrawling)
	{
		KillTimer(g_hTmrHurt);
		g_hTmrHurt = null;
	}
}

int HurtPlayer(int client)
{
	int iHealth = (GetClientHealth(client) - g_iHurt);
	if (iHealth > 0) SetEntityHealth(client, iHealth);
}

int GotoThirdPerson(int client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
}

int GotoFirstPerson(int client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
}

public int IsValidClient(int client)
{
	if( client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 ) return true;
	return false;
}

int RestoreClient(int client)
{
	if (g_iClone[client] == -1) return;
	else if (g_iClone[client] == 0) g_iClone[client] = -1;
	else RemoveClone(client);
}

int RemoveClone(int client)
{
	int clone = g_iClone[client];
	g_iClone[client] = -1;

	if( clone && EntRefToEntIndex(clone) != INVALID_ENT_REFERENCE )
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		AcceptEntityInput(clone, "kill");
	}
	if (g_bView) GotoFirstPerson(client);
	if (!g_bGlow) SetEntProp(client, Prop_Send, "m_bSurvivorGlowEnabled", 1);
}