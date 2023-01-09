#define PLUGIN_VERSION "2.7"

#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define GAMEDATA			"l4d_incapped_pills_pop"
#define SOUND_HEARTBEAT	 	"player/heartbeatloop.wav"
#define STANDUP_SOUND 		"player/items/pain_pills/pills_use_1.wav"

#define CVAR_FLAGS			FCVAR_NOTIFY

enum ITEM_TYPE (<<= 1)
{
	ITEM_MEDKIT = 1,
	ITEM_PILLS,
	ITEM_ADRENALINE,
	ITEM_NONE = 0
}

bool g_bIsBeingRevived[MAXPLAYERS+1];
bool g_bIncapDelay[MAXPLAYERS+1];
bool g_bMapStarted;
bool g_bForbidInReviving;
bool g_bDisableHeartbeat;
bool g_bLeft4dead2;
bool g_bHeartbeatPlugin;
bool g_bAllowAdrenaline;
bool g_bAllowMedkit;
bool g_bAllowPills;
bool g_bEnabled;
int g_iIncapCountOffset;
int g_iTempHpOffset;
int g_iMaxIncaps;
int g_iIncapCount[MAXPLAYERS+1];
int g_iUseButton;
ConVar g_hCvarDelaySetting;
ConVar g_hCvarForbidInReviving;
ConVar g_hCvarReviveHealth;
ConVar g_hCvarDisableHeartbeat;
ConVar g_hCvarMaxIncap;
ConVar g_hCvarMusicManager;
ConVar g_hCvarAllowMedkit;
ConVar g_iCvarButton;
ConVar g_hCvarAllowAdrenaline;
ConVar g_hCvarAllowPills;
ConVar g_hCvarEnable;
ConVar g_hCvarAllowKill;
float g_fDelaySetting;
float g_fReviveTempHealth = 30.0;
float g_fPressTime[MAXPLAYERS+1];
ITEM_TYPE g_eAllowKill;

DynamicDetour hDetour_OnLedgeGrabbed;

public Plugin myinfo = 
{
	name = "[L4D1 & L4D2] Incapped Pills Pop",
	author = "AtomicStryker (Fork by Dragokas)",
	description = "You can press the button while incapped to pop your pills / adrenaline and revive yourself",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=332094"
}

native void Heartbeat_SetRevives(int client, int reviveCount, bool reviveLogic = true);
native int Heartbeat_GetRevives(int client);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2)
	{
		g_bLeft4dead2 = true;
	}
	else if (test != Engine_Left4Dead)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	MarkNativeAsOptional("Heartbeat_SetRevives");
	MarkNativeAsOptional("Heartbeat_GetRevives");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("l4d_incappedpillspop.phrases");

	CreateConVar("l4d_incappedpillspop_version2", PLUGIN_VERSION, "Plugin version", CVAR_FLAGS | FCVAR_DONTRECORD);

	g_hCvarEnable			= CreateConVar("l4d_incappedpillspop_enable", 				"1", 	"Enable this plugin? (1 - Yes, 0 - No)", CVAR_FLAGS);
	g_hCvarDelaySetting 	= CreateConVar("l4d_incappedpillspop_delaytime", 			"0.2", 	"How long before an Incapped Survivor can use pills/adrenaline", CVAR_FLAGS);
	g_hCvarForbidInReviving = CreateConVar("l4d_incappedpillspop_forbid_when_reviving", "0", 	"Forbid self-help when somebody reviving you (1 - Yes / 0 - No)", CVAR_FLAGS);
	g_hCvarDisableHeartbeat = CreateConVar("l4d_disable_heartbeat", 					"0", 	"Disable heartbeat sound in game at all (1 - Disable / 0 - Do nothing)", CVAR_FLAGS);
	g_iCvarButton 			= CreateConVar("l4d_incappedpillspop_button", 				"2", 	"What button to press for self-help? 2 - Jump, 4 - Duck, 32 - Use. You can combine.", CVAR_FLAGS);
	g_hCvarAllowAdrenaline	= CreateConVar("l4d_incappedpillspop_allow_adrenaline",		"1", 	"(L4D2 only) Allow pop adrenaline? (1 - Yes / 0 - No)", CVAR_FLAGS);
	g_hCvarAllowMedkit		= CreateConVar("l4d_incappedpillspop_allow_medkit",			"0", 	"Allow stand-up with first aid kit? (1 - Yes / 0 - No)", CVAR_FLAGS);
	g_hCvarAllowPills		= CreateConVar("l4d_incappedpillspop_allow_pills",			"0", 	"Allow pop pills? (1 - Yes / 0 - No)", CVAR_FLAGS);
	g_hCvarAllowKill		= CreateConVar("l4d_incappedpillspop_allow_kill",			"4", 	"Allow to kill special zombies which grabbed you? (0 - No, 1 - by Medkit, 2 - by Pills, 4 - by Adrenaline, 7 - by All)", CVAR_FLAGS);
	
	g_hCvarMusicManager = FindConVar("music_manager"); // Thanks to Re:Creator for the method of fixing the sound
	g_hCvarReviveHealth = FindConVar("survivor_revive_health");
	g_hCvarMaxIncap = FindConVar("survivor_max_incapacitated_count");
	
	g_iIncapCountOffset = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
	g_iTempHpOffset = FindSendPropInfo("CTerrorPlayer","m_healthBuffer");
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	
	GameData hGameData = LoadGameConfigFile(GAMEDATA);
	if (hGameData == null)
	{
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	}
	
	SetupDetour(hGameData);
	delete hGameData;
	
	GetCvars();
	
	g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDelaySetting.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarForbidInReviving.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDisableHeartbeat.AddChangeHook(ConVarChanged_Cvars);
	g_iCvarButton.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarAllowAdrenaline.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxIncap.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarReviveHealth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarAllowMedkit.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarAllowPills.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarAllowKill.AddChangeHook(ConVarChanged_Cvars);
}

public void OnPluginEnd()
{
	if (!hDetour_OnLedgeGrabbed.Disable(Hook_Pre, OnLedgeGrabbed))
	{
		SetFailState("Failed to disable detour \"CTerrorPlayer::OnLedgeGrabbed\".");
	}
}

void SetupDetour(GameData hGameData)
{
	hDetour_OnLedgeGrabbed = DynamicDetour.FromConf(hGameData, "CTerrorPlayer::OnLedgeGrabbed");
	if (!hDetour_OnLedgeGrabbed)
	{
		SetFailState("Failed to find \"CTerrorPlayer::OnLedgeGrabbed\" signature.");
	}
	if (!hDetour_OnLedgeGrabbed.Enable(Hook_Pre, OnLedgeGrabbed))
	{
		SetFailState("Failed to start detour \"CTerrorPlayer::OnLedgeGrabbed\".");
	}
}

public MRESReturn OnLedgeGrabbed(int pThis, DHookParam hParams)
{
	StopHangSound();
	return MRES_Ignored;
}

public void OnAllPluginsLoaded()
{
	if (GetFeatureStatus(FeatureType_Native, "Heartbeat_SetRevives") == FeatureStatus_Available)
	{
		g_bHeartbeatPlugin = true;
	}
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_hCvarEnable.BoolValue;
	g_fDelaySetting = g_hCvarDelaySetting.FloatValue;
	g_bForbidInReviving = g_hCvarForbidInReviving.BoolValue;
	g_bDisableHeartbeat = g_hCvarDisableHeartbeat.BoolValue;
	g_fReviveTempHealth = g_hCvarReviveHealth.FloatValue;
	g_iMaxIncaps = g_hCvarMaxIncap.IntValue;
	g_iUseButton = g_iCvarButton.IntValue;
	g_bAllowAdrenaline = g_hCvarAllowAdrenaline.BoolValue;
	g_bAllowMedkit = g_hCvarAllowMedkit.BoolValue;
	g_bAllowPills = g_hCvarAllowPills.BoolValue;
	g_eAllowKill = view_as<ITEM_TYPE>(g_hCvarAllowKill.IntValue);
	
	InitHook();
}

void InitHook()
{
	static bool bHooked;
	if (g_bEnabled)
	{
		if(!bHooked)
		{
			HookEvent("player_incapacitated", 	Event_Incap);
			HookEvent("player_ledge_grab", 		Event_LedgeGrab);
			HookEvent("revive_begin", 			Event_StartRevive);
			HookEvent("revive_end", 			Event_EndRevive);
			HookEvent("revive_success", 		Event_EndRevive);
			HookEvent("heal_success", 			Event_EndRevive);
			HookEvent("player_spawn", 			Event_PlayerSpawn);
			HookEvent("round_end", 				Event_RoundEnd,		EventHookMode_PostNoCopy);
			HookEvent("round_start", 			Event_RoundStart,	EventHookMode_PostNoCopy);
			bHooked = true;
		}
	}
	else
	{
		if (bHooked)
		{
			UnhookEvent("player_incapacitated", 	Event_Incap);
			UnhookEvent("player_ledge_grab", 		Event_LedgeGrab);
			UnhookEvent("revive_begin", 			Event_StartRevive);
			UnhookEvent("revive_end", 				Event_EndRevive);
			UnhookEvent("revive_success", 			Event_EndRevive);
			UnhookEvent("heal_success", 			Event_EndRevive);
			UnhookEvent("player_spawn", 			Event_PlayerSpawn);
			UnhookEvent("round_end", 				Event_RoundEnd,		EventHookMode_PostNoCopy);
			UnhookEvent("round_start", 				Event_RoundStart,	EventHookMode_PostNoCopy);
			bHooked = false;
		}
	}
}

bool IsBeingPwnt(int client)
{
	if (GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
	{
		return true;
	}
	if (GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
	{
		return true;
	}
	if (g_bLeft4dead2)
	{
		if (GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0)
		{
			return true;
		}
		if (GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0)
		{
			return true;
		}
	}
	return false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (client && buttons & g_iUseButton && (GetEngineTime() - g_fPressTime[client] > 0.5) && g_bEnabled)
	{
		g_fPressTime[client] = GetEngineTime();
		if (buttons & IN_DUCK) // Prevent self-help on Ctrl + E.
		{
			if (g_iUseButton & IN_DUCK == 0)
			{
				return Plugin_Continue;
			}
		}
		
		if (!IsClientInGame(client))
		{
			return Plugin_Continue;
		}
			
		if (GetClientTeam(client) != 2)
		{
			return Plugin_Continue;
		}
		
		if (!g_bMapStarted)
		{
			return Plugin_Continue;
		}
		
		if (IsBeingPwnt(client))
		{
			if (g_eAllowKill)
			{
				if(TryGetOffInfected(client))
				{
					return Plugin_Continue;
				}
			}
			return Plugin_Continue;
		}
		
		if (g_bIncapDelay[client])
		{
			return Plugin_Continue;
		}
		
		if (!IsPlayerIncapped(client))
		{
			return Plugin_Continue;
		}
		
		if (g_bForbidInReviving)
		{
			if (GetEntPropEnt(client, Prop_Send, "m_reviveOwner") != -1) 
			{
				return Plugin_Continue;
			}
		}
		
		// Check the Pills & Medkit slots & nearby area. Revive. Remove weapon from slot.
		
		ITEM_TYPE eItem;
		bool bAllowStandup, bHanging;
		int iWeapon;
		
		bHanging = IsHanging(client);
		
		if (-1 != (iWeapon = GetPlayerWeaponSlot(client, 4)))
		{
			eItem = GetItemType(iWeapon);
			if ((g_bAllowAdrenaline && eItem == ITEM_ADRENALINE) || (g_bAllowPills && eItem == ITEM_PILLS))
			{
				bAllowStandup = true;
				RemovePlayerItem(client, iWeapon);
				RemoveEntity(iWeapon);
			}
		}
		else if (g_bAllowMedkit && -1 != (iWeapon = GetPlayerWeaponSlot(client, 3)))
		{
			bAllowStandup = true;
			RemovePlayerItem(client, iWeapon);
			RemoveEntity(iWeapon);
			eItem = ITEM_MEDKIT;
		}
		else if (!bHanging && ITEM_NONE != (eItem = FindHelperItemOnFloor(client))) // do you see item on the floor?
		{
			bAllowStandup = true;
		}
		
		if (!bAllowStandup)
		{
			char items[3][16];
			items[0] = "Dummy";
			items[1] = "Dummy";
			items[2] = "Dummy";
			if (g_bAllowPills)
			{
				items[0] = "of_pills";
			}
			if (g_bAllowAdrenaline && g_bLeft4dead2)
			{
				items[1] = "of_adrenaline";
			}
			if (g_bAllowMedkit)
			{
				items[2] = "of_medkit";
			}
			
			return Plugin_Continue;
		}
		else
		{
			EmitSoundToClient(client, STANDUP_SOUND); // add some sound

			// prevents the strange bug, when the player able to grab the pills on the table even if the pills are marked for deletion!
			CreateTimer(0.1, Timer_AdjustHealth, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action Timer_AdjustHealth(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	if (client && IsClientInGame(client))
	{
		AdjustHealth(client);
	}
	return Plugin_Continue;
}

ITEM_TYPE FindHelperItemOnFloor(int client)
{
	if (g_bAllowPills && FindItemOnFloor(client, "weapon_pain_pills") || FindItemOnFloor(client, "weapon_pain_pills_spawn"))
	{
		return ITEM_PILLS;
	}
	if (g_bAllowMedkit && FindItemOnFloor(client, "weapon_first_aid_kit") || FindItemOnFloor(client, "weapon_first_aid_kit_spawn"))
	{
		return ITEM_MEDKIT;
	}
	if (g_bLeft4dead2 && g_bAllowAdrenaline && FindItemOnFloor(client, "weapon_adrenaline") || FindItemOnFloor(client, "weapon_adrenaline_spawn"))
	{
		return ITEM_ADRENALINE;
	}
	return ITEM_NONE;
}

bool FindItemOnFloor(int client, char[] sClassname)
{
	const float ITEM_RADIUS = 25.0;
	const float PILLS_MAXDIST = 101.8;
	
	float vecEye[3], vecTarget[3], vecDir1[3], vecDir2[3], ang[3];
	float dist, MAX_ANG_DELTA, ang_delta;
	
	GetClientEyePosition(client, vecEye);
	
	int pills = -1;
	while(-1 != (pills = FindEntityByClassname(pills, sClassname)))
	{
		GetEntPropVector(pills, Prop_Data, "m_vecOrigin", vecTarget);
		
		dist = GetVectorDistance(vecEye, vecTarget);

		if (dist <= 50.0)
		{
			RemoveEntity(pills);
			return true;
		}
		
		if (dist <= PILLS_MAXDIST)
		{
			// get directional angle between eyes and target
			SubtractVectors(vecTarget, vecEye, vecDir1);
			NormalizeVector(vecDir1, vecDir1);
		
			// get directional angle of eyes view
			GetClientEyeAngles(client, ang);
			GetAngleVectors(ang, vecDir2, NULL_VECTOR, NULL_VECTOR);
			
			// get angle delta between two directional angles
			ang_delta = GetAngle(vecDir1, vecDir2); // RadToDeg
			
			MAX_ANG_DELTA = ArcTangent(ITEM_RADIUS / dist); // RadToDeg

			if (ang_delta <= MAX_ANG_DELTA)
			{
				RemoveEntity(pills);
				return true;
			}
		}
	}
	return false;
}

float GetAngle(float x1[3], float x2[3]) // by Pan XiaoHai
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}

void AdjustHealth(int client)
{
	if (g_bHeartbeatPlugin)
	{
		g_iIncapCount[client] = Heartbeat_GetRevives(client);
	}
	else
	{
		g_iIncapCount[client] = GetEntData(client, g_iIncapCountOffset, 1);
	}
	
	StopReviveAction(client);
	
	int iflags = GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"give health");
	SetCommandFlags("give", iflags);
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	SetNewHealth(client);
}

void SetNewHealth(int client)
{
	g_iIncapCount[client]++;
	
	SetEntData(client, g_iIncapCountOffset, g_iIncapCount[client], 1);
	
	if (g_bHeartbeatPlugin)
	{
		Heartbeat_SetRevives(client, g_iIncapCount[client], true);
	}
	else
	{
		if (!g_bDisableHeartbeat)
		{
			if (g_iMaxIncaps == g_iIncapCount[client])
			{
				EmitAmbientSound(SOUND_HEARTBEAT, NULL_VECTOR, client);
			}
		}
	}
	
	SetEntityHealth(client, 1);
	SetEntDataFloat(client, g_iTempHpOffset, g_fReviveTempHealth, true);
}

bool IsPlayerIncapped(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) != 0;
}

public void Event_Incap(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client)
	{
		g_bIncapDelay[client] = true;
		CreateTimer(g_fDelaySetting, Timer_AdvertisePills, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		RestoreHangSound();
	}
}

public void Event_LedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client)
	{
		g_bIncapDelay[client] = true;
		CreateTimer(g_fDelaySetting, Timer_AdvertisePills, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_AdvertisePills(Handle timer, any UserId)
{
	int client = GetClientOfUserId(UserId);
	if (client && IsClientInGame(client))
	{
		g_bIncapDelay[client] = false;
		
		int iWeapon = GetPlayerWeaponSlot(client, 4);
		if (iWeapon == -1)
		{
			iWeapon = GetPlayerWeaponSlot(client, 3);
		}
		if (iWeapon != -1)
		{
			char sKey[16] = "Dummy";
			
			if (g_iUseButton & IN_USE)
			{
				sKey = "IN_USE";
			}
			else if (g_iUseButton & IN_DUCK)
			{
				sKey = "IN_DUCK";
			}
			else if (g_iUseButton & IN_JUMP)
			{
				sKey = "IN_JUMP";
			}
		}
		else
		{
			char items[3][16];
			items[0] = "Dummy";
			items[1] = "Dummy";
			items[2] = "Dummy";
			if (g_bAllowPills)
			{
				items[0] = "of_pills";
			}
			if (g_bAllowAdrenaline && g_bLeft4dead2)
			{
				items[1] = "of_adrenaline";
			}
			if (g_bAllowMedkit)
			{
				items[2] = "of_medkit";
			}
		}
	}
	return Plugin_Continue;
}

ITEM_TYPE GetItemType(int entity)
{
	static char classname[64];
	if (entity && entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
	{
		GetEdictClassname(entity, classname, sizeof(classname));
		
		if (strcmp(classname, "weapon_pain_pills") == 0)
		{
			return ITEM_PILLS;
		}
		
		if (strcmp(classname, "weapon_first_aid_kit") == 0)
		{
			return ITEM_MEDKIT;
		}
			
		if (g_bLeft4dead2)
		{
			if (strcmp(classname, "weapon_adrenaline") == 0)
			{
				return ITEM_ADRENALINE;
			}
		}
	}
	return ITEM_NONE;
}

bool IsHanging(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") > 0;
}

public void Event_StartRevive(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	g_bIsBeingRevived[client] = true;
}

public void Event_EndRevive(Event event, const char[] name, bool dontBroadcast)
{
	int UserId = event.GetInt("subject");
	int client = GetClientOfUserId(UserId);
	
	if (client && IsClientInGame(client))
	{
		g_bIsBeingRevived[client] = false;
		
		if (g_bDisableHeartbeat)
		{
			CreateTimer(1.0, Timer_DisableHeartbeat, UserId, TIMER_FLAG_NO_MAPCHANGE); // delay, just in case
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) // to support 3-rd party plugins
{
	if (g_bDisableHeartbeat)
	{
		int UserId = event.GetInt("userid");
		int client = GetClientOfUserId(UserId);
		
		if (client && GetClientTeam(client) == 2 && !IsFakeClient(client))
		{
			CreateTimer(1.5, Timer_DisableHeartbeat, UserId, TIMER_FLAG_NO_MAPCHANGE); // 1.5 sec. should be enough for 3-rd party plugin to set required initial state
		}
	}
}

public Action Timer_DisableHeartbeat(Handle timer, any UserId)
{
	int client = GetClientOfUserId(UserId);
	if (client && IsClientInGame(client))
	{
		// player/heartbeatloop.wav Channel:0, volume:0.000000, level:0,  pitch:100, flags:4 // SNDCHAN_AUTO, SNDLEVEL_NONE, SNDPITCH_NORMAL, SND_SPAWNING
		StopSound(client, SNDCHAN_AUTO, SOUND_HEARTBEAT);
		// player/HeartbeatLoop.wav Channel:6, volume:1.000000, level:90, pitch:100, flags:0 // SNDCHAN_STATIC, SNDLEVEL_SCREAMING, SNDPITCH_NORMAL
		StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
	}
	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bMapStarted = false;
	return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bMapStarted = true;
	return Plugin_Continue;
}

public void OnMapStart()
{
	g_bMapStarted = true;
	PrecacheSound(SOUND_HEARTBEAT, true);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

void StopHangSound()
{
	g_hCvarMusicManager.SetInt(0, true, false);
}

void RestoreHangSound()
{
	g_hCvarMusicManager.SetInt(1, true, false);
}

// Prevents an accidental freezing of player who tried to revive you
//
void StopReviveAction(int client)
{
	int owner_save = -1;
	int target_save = -1;
	int owner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner"); // when you reviving somebody, this is -1. When somebody revive you, this is somebody's id
	int target = GetEntPropEnt(client, Prop_Send, "m_reviveTarget"); // when you reviving somebody, this is somebody's id. When somebody revive you, this is -1
	SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	SetEntPropEnt(client, Prop_Send, "m_reviveTarget", -1);
	if (owner != -1) // we must reset flag for both - for you, and who you revive
	{
		SetEntPropEnt(owner, Prop_Send, "m_reviveOwner", -1);
		SetEntPropEnt(owner, Prop_Send, "m_reviveTarget", -1);
		owner_save = owner;
	}
	if (target != -1)
	{
		SetEntPropEnt(target, Prop_Send, "m_reviveOwner", -1);
		SetEntPropEnt(target, Prop_Send, "m_reviveTarget", -1);
		target_save = target;
	}
	
	if (g_bLeft4dead2)
	{
		owner = GetEntPropEnt(client, Prop_Send, "m_useActionOwner");		// used when healing e.t.c.
		target = GetEntPropEnt(client, Prop_Send, "m_useActionTarget");
		SetEntPropEnt(client, Prop_Send, "m_useActionOwner", -1);
		SetEntPropEnt(client, Prop_Send, "m_useActionTarget", -1);
		if (owner != -1)
		{
			SetEntPropEnt(owner, Prop_Send, "m_useActionOwner", -1);
			SetEntPropEnt(owner, Prop_Send, "m_useActionTarget", -1);
			owner_save = owner;
		}
		if (target != -1)
		{
			SetEntPropEnt(target, Prop_Send, "m_useActionOwner", -1);
			SetEntPropEnt(target, Prop_Send, "m_useActionTarget", -1);
			target_save = target;
		}
		
		SetEntProp(client, Prop_Send, "m_iCurrentUseAction", 0);
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
		
		if (owner_save != -1)
		{
			SetEntProp(owner_save, Prop_Send, "m_iCurrentUseAction", 0);
			SetEntPropFloat(owner_save, Prop_Send, "m_flProgressBarDuration", 0.0);
		}
		if (target_save != -1)
		{
			SetEntProp(target_save, Prop_Send, "m_iCurrentUseAction", 0);
			SetEntPropFloat(target_save, Prop_Send, "m_flProgressBarDuration", 0.0);
		}
	}
	else
	{
		owner = GetEntPropEnt(client, Prop_Send, "m_healOwner");		// used when healing
		target = GetEntPropEnt(client, Prop_Send, "m_healTarget");
		SetEntPropEnt(client, Prop_Send, "m_healOwner", -1);
		SetEntPropEnt(client, Prop_Send, "m_healTarget", -1);
		if (owner != -1)
		{
			SetEntPropEnt(owner, Prop_Send, "m_healOwner", -1);
			SetEntPropEnt(owner, Prop_Send, "m_healTarget", -1);
			owner_save = owner;
		}
		if (target != -1)
		{
			SetEntPropEnt(target, Prop_Send, "m_healOwner", -1);
			SetEntPropEnt(target, Prop_Send, "m_healTarget", -1);
			target_save = target;
		}
		
		SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
		
		if (owner_save != -1)
		{
			SetEntProp(owner_save, Prop_Send, "m_iProgressBarDuration", 0);
		}
		if (target_save != -1)
		{
			SetEntProp(target_save, Prop_Send, "m_iProgressBarDuration", 0);
		}
	}
}

bool TryGetOffInfected(int client)
{
	int iWeapon;
	bool bAllowKill;
	ITEM_TYPE eItem;

	if (-1 != (iWeapon = GetPlayerWeaponSlot(client, 4)))
	{
		eItem = GetItemType(iWeapon);
		if (eItem & g_eAllowKill)
		{
			bAllowKill = true;
		}
	}
	
	if (!bAllowKill && -1 != (iWeapon = GetPlayerWeaponSlot(client, 3)))
	{
		eItem = GetItemType(iWeapon);
		
		if (eItem & g_eAllowKill)
		{
			bAllowKill = true;
		}
	}
	
	if (bAllowKill)
	{
		RemovePlayerItem(client, iWeapon);
		RemoveEntity(iWeapon);
		KillPwnInfected(client);
		return true;
	}
	return false;
}

void KillPwnInfected(int client)
{
	int attacker = GetPwnInfected(client);
	if (attacker && IsClientInGame(attacker) && IsFakeClient(attacker))
	{
		ForcePlayerSuicide(attacker);
	}
}
	
stock int GetPwnInfected(int client)
{
	int attacker;
	if ((attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker")) > 0)
	{
		return attacker;
	}
	if((attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner")) > 0)
	{
		return attacker;
	}
	if(g_bLeft4dead2)
	{
		if((attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker")) > 0)
		{
			return attacker;
		}
		if((attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker")) > 0)
		{
			return attacker;
		}
	}
	return 0;
}