#define PLUGIN_VERSION 		"1.1"

//#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif
#pragma newdecls required

#define CVAR_FLAGS			FCVAR_NONE|FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Cola\x04] \x01"
#define CONFIG_SPAWNS		"data/l4d2_cola.cfg"
#define MAX_COLAS			32

#define MODEL_COLA			"models/w_models/weapons/w_cola.mdl"


ConVar g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarAllow, g_hCvarGlow, g_hCvarGlowCol, g_hCvarHeal, g_hCvarRandom, g_hCvarSafe, g_hCvarTemp, g_hCvarRate, g_hCvarDecayRate;
bool g_bCvarAllow, g_bLoaded;
int g_iCvarGlow, g_iCvarGlowCol, g_iMap, g_iCvarHeal, g_iCvarRandom, g_iCvarSafe, g_iCvarTemp, g_iPlayerSpawn, g_iRoundStart, g_iColaCount, g_iColas[MAX_COLAS][2], g_iCola[MAXPLAYERS+1];
Handle g_hTimerHeal;
Menu g_hMenuAng, g_hMenuPos;
float g_fCvarDecayRate, g_fCvarRate, g_fHealTime[MAXPLAYERS+1];

// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Healing Cola",
	author = "SilverShot",
	description = "Heals players with temporary or main health when they hold the Cola.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=181518"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if (strcmp(sGameName, "left4dead2", false))
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d2_cola_allow",		"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarGlow =		CreateConVar(	"l4d2_cola_glow",		"200",			"0=Off, Sets the max range at which the cola glows.", CVAR_FLAGS );
	g_hCvarGlowCol =	CreateConVar(	"l4d2_cola_glow_color",	"255 0 0",		"0=Default glow color. Three values between 0-255 separated by spaces. RGB: Red Green Blue.", CVAR_FLAGS );
	g_hCvarHeal =		CreateConVar(	"l4d2_cola_heal",		"1",			"0=Off, 1=Heal players holding the cola.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d2_cola_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d2_cola_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d2_cola_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRandom =		CreateConVar(	"l4d2_cola_random",		"-1",			"-1=All, 0=None. Otherwise randomly select this many colas to spawn from the maps confg.", CVAR_FLAGS );
	g_hCvarRate =		CreateConVar(	"l4d2_cola_rate",		"1.5",			"The rate at which players are healed. HP per second.", CVAR_FLAGS );
	g_hCvarSafe =		CreateConVar(	"l4d2_cola_safe",		"0",			"On round start spawn the cola: 0=Off, 1=In the saferoom, 2=Equip to random player.", CVAR_FLAGS );
	g_hCvarTemp =		CreateConVar(	"l4d2_cola_temp",		"80",			"-1=Add temporary health, 0=Add to main health. Values between 1 and 100 creates a chance to give main health, else temp health.", CVAR_FLAGS );
	CreateConVar(						"l4d2_cola_version",	PLUGIN_VERSION, "Healing Cola plugin version.", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d2_cola");

	g_hCvarDecayRate = FindConVar("pain_pills_decay_rate");
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hCvarMPGameMode,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesTog,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarHeal,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarRandom,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarRate,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarSafe,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarTemp,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarDecayRate,		ConVarChanged_Cvars);

	RegAdminCmd("sm_cola",			CmdColaTemp,		ADMFLAG_ROOT, 	"Spawns a temporary cola at your crosshair.");
	RegAdminCmd("sm_colasave",		CmdColaSave,		ADMFLAG_ROOT, 	"Spawns a cola at your crosshair and saves to config.");
	RegAdminCmd("sm_coladel",		CmdColaDelete,		ADMFLAG_ROOT, 	"Removes the cola you are pointing at and deletes from the config if saved.");
	RegAdminCmd("sm_colawipe",		CmdColaWipe,		ADMFLAG_ROOT, 	"Removes all colas from the current map and deletes them from the config.");
	RegAdminCmd("sm_colaglow",		CmdColaGlow,		ADMFLAG_ROOT, 	"Toggle to enable glow on all colas to see where they are placed.");
	RegAdminCmd("sm_colalist",		CmdColaList,		ADMFLAG_ROOT, 	"Display a list cola positions and the total number of.");
	RegAdminCmd("sm_colatele",		CmdColaTele,		ADMFLAG_ROOT, 	"Teleport to a cola (Usage: sm_colatele <index: 1 to MAX_COLAS>).");
	RegAdminCmd("sm_colaang",		CmdColaAng,			ADMFLAG_ROOT, 	"Displays a menu to adjust the cola angles your crosshair is over.");
	RegAdminCmd("sm_colapos",		CmdColaPos,			ADMFLAG_ROOT, 	"Displays a menu to adjust the cola origin your crosshair is over.");
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	PrecacheModel(MODEL_COLA, true);
}

public void OnMapEnd()
{
	g_iMap = 1;
	ResetPlugin(false);
}

int GetColor(Handle cvar)
{
	char sTemp[12], sColors[3][4];
	GetConVarString(cvar, sTemp, sizeof(sTemp));
	ExplodeString(sTemp, " ", sColors, 3, 4);

	int color;
	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);
	return color;
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
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

int GetCvars()
{
	g_iCvarGlow = GetConVarInt(g_hCvarGlow);
	g_iCvarGlowCol = GetColor(g_hCvarGlowCol);
	g_iCvarHeal = GetConVarInt(g_hCvarHeal);
	g_iCvarRandom = GetConVarInt(g_hCvarRandom);
	g_fCvarRate = GetConVarFloat(g_hCvarRate);
	g_iCvarSafe = GetConVarInt(g_hCvarSafe);
	g_iCvarTemp = GetConVarInt(g_hCvarTemp);
	g_fCvarDecayRate = GetConVarFloat(g_hCvarDecayRate);
}

int IsAllowed()
{
	bool bCvarAllow = GetConVarBool(g_hCvarAllow);
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if (g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true)
	{
		LoadColas();
		g_bCvarAllow = true;
		HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("item_pickup",		Event_ItemPickup);
	}

	else if(g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false))
	{
		ResetPlugin();
		g_bCvarAllow = false;
		UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("item_pickup",		Event_ItemPickup);
	}
}

int g_iCurrentMode;

bool IsAllowedGameMode()
{
	if (g_hCvarMPGameMode == null)
		return false;

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
	GetConVarString(g_hCvarMPGameMode, sGameMode, sizeof(sGameMode));
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



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin(false);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iPlayerSpawn == 1 && g_iRoundStart == 0) CreateTimer(g_iMap == 1 ? 5.0 : 1.0, tmrStart);
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iPlayerSpawn == 0 && g_iRoundStart == 1) CreateTimer(g_iMap == 1 ? 5.0 : 1.0, tmrStart);
	g_iPlayerSpawn = 1;
}

public Action tmrStart(Handle timer)
{
	g_iMap = 0;
	ResetPlugin();
	LoadColas();

	if (g_iCvarSafe == 1)
	{
		int iClients[MAXPLAYERS+1], count;
		for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) iClients[count++] = i;

		int client = GetRandomInt(0, count-1);
		client = iClients[client];

		if (client)
		{
			float vPos[3], vAng[3];
			GetClientAbsOrigin(client, vPos);
			GetClientAbsAngles(client, vAng);
			vPos[2] += 25.0;
			CreateCola(vPos, vAng);
		}
	}
	else if( g_iCvarSafe == 2 )
	{
		int iClients[MAXPLAYERS+1], count;
		for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) iClients[count++] = i;

		int client = GetRandomInt(0, count-1);
		client = iClients[client];

		if (client)
		{
			int entity = GivePlayerItem(client, "weapon_cola_bottles");
			if (entity != -1) EquipPlayerWeapon(client, entity);
		}
	}
}

public void Event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iCvarHeal)
	{
		char sTemp[16];
		GetEventString(event, "item", sTemp, sizeof(sTemp));
		if (strcmp(sTemp, "cola_bottles") == 0)
		{
			int client = GetClientOfUserId(event.GetInt("userid"));
			g_iCola[client] = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

			if (g_hTimerHeal == null) CreateTimer(0.1, tmrHeal, _, TIMER_REPEAT);
		}
	}
}

public Action tmrHeal(Handle timer)
{
	int entity;
	bool healed;
	if (g_iCvarHeal)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			entity = g_iCola[i];
			if (entity)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && entity == GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon"))
				{
					HealClient(i);
					healed = true;
				}
				else g_iCola[i] = 0;
			}
		}
	}

	if (healed == false)
	{
		g_hTimerHeal = null;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

int HealClient(int client)
{
	int iHealth = GetClientHealth(client);
	if (iHealth >= 100) return;

	float fGameTime = GetGameTime();
	float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (fGameTime - fHealthTime) * g_fCvarDecayRate;

	if( g_iCvarTemp == -1 || (g_iCvarTemp != 0 && GetRandomInt(1, 100) >= g_iCvarTemp) )
	{
		if (fHealth < 0.0) fHealth = 0.0;
		float fBuff = (0.1 * g_fCvarRate);

		if (fHealth + iHealth + fBuff > 100) SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 100.1 - float(iHealth));
		else SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth + fBuff);
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
	}
	else
	{
		if (fGameTime - g_fHealTime[client] > 1.0)
		{
			g_fHealTime[client] = fGameTime;

			int iBuff = RoundToFloor(g_fCvarRate);
			iHealth += iBuff;
			if (iHealth >= 100)
			{
				iHealth = 100;
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
			}
			else if (iHealth + fHealth >= 100)
			{
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 100.1 - iHealth);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
			}

			SetEntityHealth(client, iHealth);
		}
	}
}



// ====================================================================================================
//					LOAD COLAS
// ====================================================================================================
int LoadColas()
{
	if (g_bLoaded || g_iCvarRandom == 0) return;
	g_bLoaded = true;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if (!FileExists(sPath)) return;

	// Load config
	KeyValues hFile = CreateKeyValues("colas");
	if (!FileToKeyValues(hFile, sPath))
	{
		CloseHandle(hFile);
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, 64);

	if (!KvJumpToKey(hFile, sMap))
	{
		CloseHandle(hFile);
		return;
	}

	// Retrieve how many colas to display
	int iCount = KvGetNum(hFile, "num", 0);
	if (iCount == 0)
	{
		CloseHandle(hFile);
		return;
	}

	// Spawn only a select few colas?
	int iIndexes[MAX_COLAS+1];
	if (iCount > MAX_COLAS) iCount = MAX_COLAS;


	// Spawn saved colas or create random
	int iRandom = g_iCvarRandom;
	if( iRandom == -1 || iRandom > iCount) iRandom = iCount;
	if( iRandom != -1 )
	{
		for (int i = 1; i <= iCount; i++)
			iIndexes[i] = i;

		SortIntegers(iIndexes, iCount+1, Sort_Random);
		iCount = iRandom;
	}

	// Get the cola origins and spawn
	char sTemp[10];
	float vPos[3], vAng[3];
	int index;
	for (int i = 1; i <= iCount; i++)
	{
		if (iRandom != -1) index = iIndexes[i];
		else index = i;

		IntToString(index, sTemp, sizeof(sTemp));

		if (KvJumpToKey(hFile, sTemp))
		{
			KvGetVector(hFile, "angle", vAng);
			KvGetVector(hFile, "origin", vPos);

			if (vPos[0] == 0.0 && vPos[0] == 0.0 && vPos[0] == 0.0) // Should never happen.
				LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Random=%d. Count=%d.", i, index, iRandom, iCount);
			else CreateCola(vPos, vAng, index);
			KvGoBack(hFile);
		}
	}

	CloseHandle(hFile);
}



// ====================================================================================================
//					CREATE COLA
// ====================================================================================================
int CreateCola(const float vOrigin[3], const float vAngles[3], int index = 0)
{
	if (g_iColaCount >= MAX_COLAS) return;

	int iColaIndex = -1;
	for (int i = 0; i < MAX_COLAS; i++)
	{
		if (g_iColas[i][0] == 0)
		{
			iColaIndex = i;
			break;
		}
	}

	if (iColaIndex == -1) return;

	int entity = CreateEntityByName("prop_physics");
	if (entity == -1) ThrowError("Failed to create cola model.");

	g_iColas[iColaIndex][0] = EntIndexToEntRef(entity);
	g_iColas[iColaIndex][1] = index;
	SetEntityModel(entity, MODEL_COLA);

	DispatchSpawn(entity);
	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);

	if (g_iCvarGlow)
	{
		SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarGlow);
		SetEntProp(entity, Prop_Send, "m_iGlowType", 1);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowCol);
		AcceptEntityInput(entity, "StartGlowing");
	}
	g_iColaCount++;
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
//					sm_cola
// ====================================================================================================
public Action CmdColaTemp(int client, int args)
{
	if (!client)
	{
		ReplyToCommand(client, "[Cola] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}
	else if (g_iColaCount >= MAX_COLAS)
	{
		PrintToChat(client, "%sError: Cannot add anymore colas. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iColaCount, MAX_COLAS);
		return Plugin_Handled;
	}

	float vPos[3], vAng[3];
	if (!SetTeleportEndPoint(client, vPos, vAng))
	{
		PrintToChat(client, "%sCannot place cola, please try again.", CHAT_TAG);
		return Plugin_Handled;
	}

	CreateCola(vPos, vAng);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_colasave
// ====================================================================================================
public Action CmdColaSave(int client, int args)
{
	if (!client)
	{
		ReplyToCommand(client, "[Cola] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}
	else if (g_iColaCount >= MAX_COLAS)
	{
		PrintToChat(client, "%sError: Cannot add anymore colas. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iColaCount, MAX_COLAS);
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if (!FileExists(sPath))
	{
		File hCfg = OpenFile(sPath, "w");
		WriteFileLine(hCfg, "");
		CloseHandle(hCfg);
	}

	// Load config
	KeyValues hFile = CreateKeyValues("colas");
	if (!FileToKeyValues(hFile, sPath))
	{
		PrintToChat(client, "%sError: Cannot read the cola config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, 64);
	if (!KvJumpToKey(hFile, sMap, true))
	{
		PrintToChat(client, "%sError: Failed to add map to cola spawn config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Retrieve how many colas are saved
	int iCount = KvGetNum(hFile, "num", 0);
	if (iCount >= MAX_COLAS)
	{
		PrintToChat(client, "%sError: Cannot add anymore colas. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_COLAS);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Save count
	iCount++;
	KvSetNum(hFile, "num", iCount);

	char sTemp[10];

	IntToString(iCount, sTemp, sizeof(sTemp));
	if (KvJumpToKey(hFile, sTemp, true))
	{
		float vPos[3], vAng[3];
		// Set player position as cola spawn location
		if (!SetTeleportEndPoint(client, vPos, vAng))
		{
			PrintToChat(client, "%sCannot place cola, please try again.", CHAT_TAG);
			CloseHandle(hFile);
			return Plugin_Handled;
		}

		// Save angle / origin
		KvSetVector(hFile, "angle", vAng);
		KvSetVector(hFile, "origin", vPos);

		CreateCola(vPos, vAng, iCount);

		// Save cfg
		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_COLAS, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	}
	else PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to save Cola.", CHAT_TAG, iCount, MAX_COLAS);

	CloseHandle(hFile);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_coladel
// ====================================================================================================
public Action CmdColaDelete(int client, int args)
{
	if (!g_bCvarAllow)
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if (!client)
	{
		ReplyToCommand(client, "[Cola] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	int entity = GetClientAimTarget(client, false);
	if (entity == -1) return Plugin_Handled;
	entity = EntIndexToEntRef(entity);

	int cfgindex, index = -1;
	for (int i = 0; i < MAX_COLAS; i++)
	{
		if (g_iColas[i][0] == entity)
		{
			index = i;
			break;
		}
	}

	if (index == -1) return Plugin_Handled;

	cfgindex = g_iColas[index][1];
	if (cfgindex == 0)
	{
		RemoveCola(index);
		return Plugin_Handled;
	}

	for (int i = 0; i < MAX_COLAS; i++)
	{
		if(g_iColas[i][1] > cfgindex) g_iColas[i][1]--;
	}

	g_iColaCount--;

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if (!FileExists(sPath))
	{
		PrintToChat(client, "%sError: Cannot find the cola config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	KeyValues hFile = CreateKeyValues("colas");
	if (!FileToKeyValues(hFile, sPath))
	{
		PrintToChat(client, "%sError: Cannot load the cola config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, 64);

	if (!KvJumpToKey(hFile, sMap))
	{
		PrintToChat(client, "%sError: Current map not in the cola config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Retrieve how many colas
	int iCount = KvGetNum(hFile, "num", 0);
	if (iCount == 0)
	{
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	bool bMove;
	char sTemp[16];

	// Move the other entries down
	for (int i = cfgindex; i <= iCount; i++)
	{
		IntToString(i, sTemp, sizeof(sTemp));
		if (KvJumpToKey(hFile, sTemp))
		{
			if (!bMove)
			{
				bMove = true;
				KvDeleteThis(hFile);
				RemoveCola(index);
			}
			else
			{
				IntToString(i-1, sTemp, sizeof(sTemp));
				KvSetSectionName(hFile, sTemp);
			}
		}

		KvRewind(hFile);
		KvJumpToKey(hFile, sMap);
	}

	if (bMove)
	{
		iCount--;
		KvSetNum(hFile, "num", iCount);

		// Save to file
		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Cola removed from config.", CHAT_TAG, iCount, MAX_COLAS);
	}
	else PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to remove Cola from config.", CHAT_TAG, iCount, MAX_COLAS);

	CloseHandle(hFile);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_colawipe
// ====================================================================================================
public Action CmdColaWipe(int client, int args)
{
	if (!client)
	{
		ReplyToCommand(client, "[Cola] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if (!FileExists(sPath))
	{
		PrintToChat(client, "%sError: Cannot find the cola config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = CreateKeyValues("colas");
	if (!FileToKeyValues(hFile, sPath))
	{
		PrintToChat(client, "%sError: Cannot load the cola config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, 64);

	if (!KvJumpToKey(hFile, sMap, false))
	{
		PrintToChat(client, "%sError: Current map not in the cola config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	KvDeleteThis(hFile);
	ResetPlugin();

	// Save to file
	KvRewind(hFile);
	KeyValuesToFile(hFile, sPath);
	CloseHandle(hFile);

	PrintToChat(client, "%s(0/%d) - All colas removed from config, add with \x05sm_colasave\x01.", CHAT_TAG, MAX_COLAS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_colaglow
// ====================================================================================================
public Action CmdColaGlow(int client, int args)
{
	bool glow;
	glow = !glow;
	PrintToChat(client, "%sGlow has been turned %s", CHAT_TAG, glow ? "on" : "off");

	VendorGlow(glow);
	return Plugin_Handled;
}

int VendorGlow(int glow)
{
	int ent;
	for (int  i = 0; i < MAX_COLAS; i++)
	{
		ent = g_iColas[i][0];
		if (IsValidEntRef(ent))
		{
			SetEntProp(ent, Prop_Send, "m_iGlowType", 3);
			SetEntProp(ent, Prop_Send, "m_glowColorOverride", 65535);
			SetEntProp(ent, Prop_Send, "m_nGlowRange", glow ? 0 : 50);
			ChangeEdictState(ent, FindSendPropInfo("prop_dynamic", "m_nGlowRange"));
		}
	}
}

// ====================================================================================================
//					sm_colalist
// ====================================================================================================
public Action CmdColaList(int client, int args)
{
	float vPos[3];
	int count;
	for (int i = 0; i < MAX_COLAS; i++)
	{
		if (IsValidEntRef(g_iColas[i][0]))
		{
			count++;
			GetEntPropVector(g_iColas[i][0], Prop_Data, "m_vecOrigin", vPos);
			PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
		}
	}
	PrintToChat(client, "%sTotal: %d.", CHAT_TAG, count);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_colatele
// ====================================================================================================
public Action CmdColaTele(int client, int args)
{
	if (args == 1)
	{
		char arg[16];
		GetCmdArg(1, arg, 16);
		int index = StringToInt(arg) - 1;
		if (index > -1 && index < MAX_COLAS && IsValidEntRef(g_iColas[index][0]))
		{
			float vPos[3];
			GetEntPropVector(g_iColas[index][0], Prop_Data, "m_vecOrigin", vPos);
			vPos[2] += 20.0;
			TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
			PrintToChat(client, "%sTeleported to %d.", CHAT_TAG, index + 1);
			return Plugin_Handled;
		}

		PrintToChat(client, "%sCould not find index for teleportation.", CHAT_TAG);
	}
	else PrintToChat(client, "%sUsage: sm_colatele <index 1-%d>.", CHAT_TAG, MAX_COLAS);
	return Plugin_Handled;
}

// ====================================================================================================
//					MENU ANGLE
// ====================================================================================================
public Action CmdColaAng(int client, int args)
{
	ShowMenuAng(client);
	return Plugin_Handled;
}

int ShowMenuAng(int client)
{
	CreateMenus();
	DisplayMenu(g_hMenuAng, client, MENU_TIME_FOREVER);
}

public int AngMenuHandler(Handle menu, MenuAction action, int client, int index)
{
	if (action == MenuAction_Select)
	{
		if( index == 6 ) SaveData(client);
		else SetAngle(client, index);
		ShowMenuAng(client);
	}
}

int SetAngle(int client, int index)
{
	int  aim = GetClientAimTarget(client, false);
	if (aim != -1)
	{
		float vAng[3];
		int entity;
		aim = EntIndexToEntRef(aim);

		for (int i = 0; i < MAX_COLAS; i++)
		{
			entity = g_iColas[i][0];

			if (entity == aim)
			{
				GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

				if (index == 0) vAng[0] += 5.0;
				else if (index == 1) vAng[1] += 5.0;
				else if (index == 2) vAng[2] += 5.0;
				else if (index == 3) vAng[0] -= 5.0;
				else if (index == 4) vAng[1] -= 5.0;
				else if (index == 5) vAng[2] -= 5.0;

				TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);

				PrintToChat(client, "%sNew angles: %f %f %f", CHAT_TAG, vAng[0], vAng[1], vAng[2]);
				break;
			}
		}
	}
}

// ====================================================================================================
//					MENU ORIGIN
// ====================================================================================================
public Action CmdColaPos(int client, int args)
{
	ShowMenuPos(client);
	return Plugin_Handled;
}

int ShowMenuPos(int client)
{
	CreateMenus();
	DisplayMenu(g_hMenuPos, client, MENU_TIME_FOREVER);
}

public int PosMenuHandler(Handle menu, MenuAction action, int client, int index)
{
	if (action == MenuAction_Select)
	{
		if (index == 6) SaveData(client);
		else SetOrigin(client, index);
		ShowMenuPos(client);
	}
}

int SetOrigin(int client, int index)
{
	int aim = GetClientAimTarget(client, false);
	if (aim != -1)
	{
		float vPos[3];
		int entity;
		aim = EntIndexToEntRef(aim);

		for (int i = 0; i < MAX_COLAS; i++)
		{
			entity = g_iColas[i][0];

			if (entity == aim)
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

				if (index == 0) vPos[0] += 0.5;
				else if (index == 1) vPos[1] += 0.5;
				else if (index == 2) vPos[2] += 0.5;
				else if (index == 3) vPos[0] -= 0.5;
				else if (index == 4) vPos[1] -= 0.5;
				else if (index == 5) vPos[2] -= 0.5;

				TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

				PrintToChat(client, "%sNew origin: %f %f %f", CHAT_TAG, vPos[0], vPos[1], vPos[2]);
				break;
			}
		}
	}
}

int SaveData(int client)
{
	int entity, index;
	int aim = GetClientAimTarget(client, false);
	if (aim == -1) return;

	aim = EntIndexToEntRef(aim);

	for (int i = 0; i < MAX_COLAS; i++)
	{
		entity = g_iColas[i][0];
		if (entity == aim)
		{
			index = g_iColas[i][1];
			break;
		}
	}

	if (index == 0) return;

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if (!FileExists(sPath))
	{
		PrintToChat(client, "%sError: Cannot find the cola config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	KeyValues hFile = CreateKeyValues("colas");
	if (!FileToKeyValues(hFile, sPath))
	{
		PrintToChat(client, "%sError: Cannot load the cola config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, 64);

	if (!KvJumpToKey(hFile, sMap))
	{
		PrintToChat(client, "%sError: Current map not in the cola config.", CHAT_TAG);
		CloseHandle(hFile);
		return;
	}

	float vAng[3], vPos[3];
	char sTemp[32];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

	IntToString(index, sTemp, sizeof(sTemp));
	if (KvJumpToKey(hFile, sTemp))
	{
		KvSetVector(hFile, "angle", vAng);
		KvSetVector(hFile, "origin", vPos);

		// Save cfg
		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		PrintToChat(client, "%sSaved origin and angles to the data config", CHAT_TAG);
	}
}

int CreateMenus()
{
	if (g_hMenuAng == null)
	{
		g_hMenuAng = CreateMenu(AngMenuHandler);
		AddMenuItem(g_hMenuAng, "", "X + 5.0");
		AddMenuItem(g_hMenuAng, "", "Y + 5.0");
		AddMenuItem(g_hMenuAng, "", "Z + 5.0");
		AddMenuItem(g_hMenuAng, "", "X - 5.0");
		AddMenuItem(g_hMenuAng, "", "Y - 5.0");
		AddMenuItem(g_hMenuAng, "", "Z - 5.0");
		AddMenuItem(g_hMenuAng, "", "SAVE");
		SetMenuTitle(g_hMenuAng, "Set Angle");
		SetMenuExitButton(g_hMenuAng, true);
	}

	if (g_hMenuPos == null)
	{
		g_hMenuPos = CreateMenu(PosMenuHandler);
		AddMenuItem(g_hMenuPos, "", "X + 0.5");
		AddMenuItem(g_hMenuPos, "", "Y + 0.5");
		AddMenuItem(g_hMenuPos, "", "Z + 0.5");
		AddMenuItem(g_hMenuPos, "", "X - 0.5");
		AddMenuItem(g_hMenuPos, "", "Y - 0.5");
		AddMenuItem(g_hMenuPos, "", "Z - 0.5");
		AddMenuItem(g_hMenuPos, "", "SAVE");
		SetMenuTitle(g_hMenuPos, "Set Position");
		SetMenuExitButton(g_hMenuPos, true);
	}
}



// ====================================================================================================
//					STUFF
// ====================================================================================================
bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE ) return true;
	return false;
}

int ResetPlugin(bool all = true)
{
	g_bLoaded = false;
	g_iColaCount = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;

	for (int i = 1; i <= MAXPLAYERS; i++) g_fHealTime[i] = 0.0;

	if( all ) for (int i = 0; i < MAX_COLAS; i++) RemoveCola(i);
}

int RemoveCola(int index)
{
	int entity = g_iColas[index][0];
	g_iColas[index][0] = 0;

	if(IsValidEntRef(entity)) AcceptEntityInput(entity, "kill");
}



// ====================================================================================================
//					POSITION
// ====================================================================================================
int SetTeleportEndPoint(int client, float vPos[3], float vAng[3])
{
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, _TraceFilter);

	if (TR_DidHit(trace))
	{
		float vNorm[3];
		TR_GetEndPosition(vPos, trace);
		TR_GetPlaneNormal(trace, vNorm);
		float angle = vAng[1];
		GetVectorAngles(vNorm, vAng);

		vPos[2] += 5.0;

		if (vNorm[2] == 1.0)
		{
			vAng[0] = 0.0;
			vAng[1] += angle;
		}
		else
		{
			vAng[0] = 0.0;
			vAng[1] += angle - 90.0;
		}
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	CloseHandle(trace);
	return true;
}

public bool _TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}