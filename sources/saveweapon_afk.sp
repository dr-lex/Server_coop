//#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif
#pragma newdecls required

#define MAX_LINE_WIDTH		64
#define CHECK_TIME			5.0

ConVar sm_afk_status;

char slotPrimary[MAXPLAYERS + 1][2][MAX_LINE_WIDTH];
int priAmmo[MAXPLAYERS + 1][2];
int priClip[MAXPLAYERS + 1][2];
int priUpgrade[MAXPLAYERS + 1][2];
int priUpgrAmmo[MAXPLAYERS + 1][2];
float preheal_temp[MAXPLAYERS + 1];
int preheal_perm[MAXPLAYERS + 1];
int incap_count[MAXPLAYERS + 1];
bool ClientGoToAFK[MAXPLAYERS + 1];
bool ClientWaitAFK[MAXPLAYERS + 1];
bool g_bTransitioned[MAXPLAYERS+1];
char slotMedkit[MAXPLAYERS + 1][2][MAX_LINE_WIDTH];
char slotThrowable[MAXPLAYERS + 1][2][MAX_LINE_WIDTH];
char slotPills[MAXPLAYERS + 1][2][MAX_LINE_WIDTH];
char slotSecondary[MAXPLAYERS + 1][2][MAX_LINE_WIDTH];
char slotMelee[MAXPLAYERS + 1][MAX_LINE_WIDTH];

Handle g_hGameConf = null;
Handle sdkRevive = null;

float g_iCvarSpecT = 60.0;
static float g_fButtonTime[MAXPLAYERS+1];
static bool g_bTempBlock[MAXPLAYERS+1];
ConVar sm_defib_fix_weapon;
int ammoOffset;

public Plugin myinfo =
{
	name = "l4d2 saveweapon for spectators",
	author = "TY (edited by SupermenCJ)",
	description = "l4d2_saveweapon",
	version = "2.3",
	url = "http://www.zambiland.ru/"
};

public void OnPluginStart()
{
	char temp[12];
	FloatToString(g_iCvarSpecT, temp, sizeof(temp)); HookConVarChange(CreateConVar("l4d2_spec_time", temp, "Time before idle player will be moved to spectator in seconds."), convar_AfkSpecTime);

	sm_defib_fix_weapon = CreateConVar("sm_defib_fix_weapon", "0", "", FCVAR_NONE);
	sm_afk_status = CreateConVar("sm_afk_status", "0", "", FCVAR_NONE);
	
	HookEvent("map_transition", Event_maptransition, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_win", Event_FinalWin);
	HookEvent("finale_escape_start", Event_FinaleEscapeStart);
	HookEvent("item_pickup", Event_PickUp);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_say",	Event_PlayerSay);
	HookEvent("defibrillator_used", Event_PlayerDefibed);
	HookEvent("survivor_rescued", Event_SurvivorRescued, EventHookMode_Pre);

	RegConsoleCmd("go_away_from_keyboard", Cmd_AFK);
	RegConsoleCmd("sm_afk", Command_AFK);
	RegConsoleCmd("sm_idle", Command_AFK);
	RegConsoleCmd("sm_spectate", Command_AFK);
	
	ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	
	g_hGameConf = LoadGameConfigFile("hardmod");
	if(g_hGameConf == null)
	{
		SetFailState("Couldn't find the offsets and signatures file. Please, check that it is installed correctly.");
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnRevived");
	sdkRevive = EndPrepSDKCall();
	if(sdkRevive == null)
	{
		SetFailState("Unable to find the \"CTerrorPlayer::OnRevived(void)\" signature, check the file version!");
	}
	
	CreateTimer(CHECK_TIME, SAM_t_CheckIdles, _, TIMER_REPEAT);
}

public Action Cmd_AFK(int client, int args)
{
	Command_AFK(client, 0);
	return Plugin_Handled;
}

public Action Command_AFK(int client, int args)
{
	if (!client) return Plugin_Handled;
	if (IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			if (GetClientTeam(client) == 2)
			{
				if (IsPlayerAlive(client))
				{
					if (!IsPlayerIncapped(client) && GetHealth(client) > 1)
					{
						if (!ClientWaitAFK[client])
						{
							if (IsTankAlive())
							{
								PrintHintText(client, "You can't join spectator team with a good weapon and a live tank");
								return Plugin_Handled;
							}
							else
							{
								if (sm_afk_status.IntValue == 0)
								{
									PrintHintText(client, "You can't join spectator team with a good weapon and a live tank");
								}
								if (sm_afk_status.IntValue == 1)
								{
									PrintHintText(client, "You will be moved to the Spectators in 15 seconds");
									CreateTimer(20.0, movetospec1, client);
									ClientWaitAFK[client] = true;
								}
								return Plugin_Handled;
							}
						}
						return Plugin_Continue;
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action movetospec1(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			if (GetClientTeam(client) == 2)
			{
				if (IsPlayerAlive(client))
				{
					if (!IsPlayerIncapped(client))
					{
						SaveWeapons(client);
						FakeClientCommand(client, "sm_louis");
						without_aura(client);
						CreateTimer(0.5, movetospec2, client);
					}
				}
			}
		}
		ClientWaitAFK[client] = false;
	}
	return Plugin_Stop;
}

public Action movetospec2(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			if (GetClientTeam(client) == 2)
			{
				if (IsPlayerAlive(client))
				{
					ChangeClientTeam(client, 1);
					ClientGoToAFK[client] = true;
					g_bTransitioned[client] = false;
					PrintToChatAll("[AFK] Player %N was moved to Spectator team.", client);
				}
			}
		}
	}
	return Plugin_Stop;
}

public Action Event_PlayerDefibed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (!client) return;
	if (GetConVarInt(sm_defib_fix_weapon) < 1) return;
	if (IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			CreateTimer(1.1, ClientDefibed, client);
		}
	}
}

public Action ClientDefibed(Handle timer, any client)
{
	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		if (!StrEqual(slotMelee[client], "", false))
		{
			Give(client, "give", slotMelee[client]);
		}
	}
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (GetEventBool(event, "disconnect")) return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && ClientGoToAFK[client])
	{
		CreateTimer(1.0, ClientChangeTeam, client);	 
	}
	
	if (client && !IsFakeClient(client) && event.GetInt("team") != 1)
	{
		SetEngineTime(client);
	}
}

public Action ClientChangeTeam(Handle timer, any client)
{
	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{ 
		if (GetClientTeam(client) == 2)
		{			
			if (IsPlayerAlive(client))
			{
				GiveWeapon(client);
			}
		}
	}
}

public Action Event_PickUp(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client) return;
	if (IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			if (GetClientTeam(client) == 2)
			{
				if (!(GetPlayerWeaponSlot(client, 1) == -1)) 
				{
					char modelname[128];
					GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_ModelName", modelname, 128);
					if (StrEqual(modelname, "models/weapons/melee/v_fireaxe.mdl", false)) slotMelee[client] = "fireaxe";
					else if (StrEqual(modelname, "models/weapons/melee/v_crowbar.mdl", false)) slotMelee[client] = "crowbar";
					else if (StrEqual(modelname, "models/weapons/melee/v_cricket_bat.mdl", false)) slotMelee[client] = "cricket_bat";
					else if (StrEqual(modelname, "models/weapons/melee/v_katana.mdl", false)) slotMelee[client] = "katana";
					else if (StrEqual(modelname, "models/weapons/melee/v_bat.mdl", false)) slotMelee[client] = "baseball_bat";
					else if (StrEqual(modelname, "models/v_models/v_knife_t.mdl", false)) slotMelee[client] = "knife";
					else if (StrEqual(modelname, "models/weapons/melee/v_electric_guitar.mdl", false)) slotMelee[client] = "electric_guitar";
					else if (StrEqual(modelname, "models/weapons/melee/v_frying_pan.mdl", false)) slotMelee[client] = "frying_pan";
					else if (StrEqual(modelname, "models/weapons/melee/v_machete.mdl", false)) slotMelee[client] = "machete";
					else if (StrEqual(modelname, "models/weapons/melee/v_golfclub.mdl", false)) slotMelee[client] = "golfclub";
					else if (StrEqual(modelname, "models/weapons/melee/v_tonfa.mdl", false)) slotMelee[client] = "tonfa";
					else if (StrEqual(modelname, "models/weapons/melee/v_riotshield.mdl", false)) slotMelee[client] = "riotshield";
					else GetEdictClassname(GetPlayerWeaponSlot(client, 1), slotMelee[client], MAX_LINE_WIDTH);
				}
			}
		}
	}
}

stock int Give(int client, char[] command, char[] arguments = "")
{
	if (client)
	{
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
	}
}

public Action Event_FinalWin(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				g_bTransitioned[i] = false;
				ClearWeapons(i);
			}
		}
	}
}

public Action Event_FinaleEscapeStart(Event event, const char[] name, bool dontBroadcast)
{
	
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, PrecacheItems);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				ClientGoToAFK[i] = false;
				
				if (GetClientTeam(i) == 2 && IsPlayerAlive(i) && g_bTransitioned[i])
				{
					CreateTimer(2.0 , RetryRestore, i);
				}
			}
		}
	}
}

public Action RetryRestore(Handle timer, any client)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !g_bTransitioned[client]) return;
	GiveWeapon(client, 1);
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				SetEngineTime(i);
			}
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	ClientGoToAFK[client] = false;
	ClientWaitAFK[client] = false;
}

public void OnClientDisconnect(int client)
{
	ClientGoToAFK[client] = false;
	ClientWaitAFK[client] = false;
}

int ClearWeapons(int client)
{
	if (client)
	{
		slotPrimary[client][0] = "";
		slotSecondary[client][0] = "pistol";
		slotMedkit[client][0] = "";
		slotThrowable[client][0] = "";
		slotPills[client][0] = "";
		slotMelee[client] = "";
	}
}

public void OnClientPutInServer(int client)
{
	if (!client) return;
	if (IsFakeClient(client)) return;

	ClearWeapons(client);
}

int GiveWeapon(int client, int slot = 0)
{
	if (!IsClientInGame(client)) return;
	if (GetClientTeam(client) != 2) return;
	if (!IsPlayerAlive(client)) return;
	
	if (GetPlayerWeaponSlot(client, 0) > -1) RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
	if (GetPlayerWeaponSlot(client, 1) > -1) RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
	if (GetPlayerWeaponSlot(client, 2) > -1) RemovePlayerItem(client, GetPlayerWeaponSlot(client, 2));
	if (GetPlayerWeaponSlot(client, 3) > -1) RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
	if (GetPlayerWeaponSlot(client, 4) > -1) RemovePlayerItem(client, GetPlayerWeaponSlot(client, 4));

	if (IsFakeClient(client))
	{
		Give(client, "give", "pistol");
		return;
	}

	if (!StrEqual(slotPrimary[client][slot], "", false))
	{
		Give(client, "give", slotPrimary[client][slot]);
		
		if (StrEqual(slotPrimary[client][slot], "weapon_rifle") || StrEqual(slotPrimary[client][slot], "weapon_rifle_sg552") || StrEqual(slotPrimary[client][slot], "weapon_rifle_desert") || StrEqual(slotPrimary[client][slot], "weapon_rifle_ak47"))
		{
			SetEntData(client, ammoOffset+(12), priAmmo[client][slot]);
		}
		else if (StrEqual(slotPrimary[client][slot], "weapon_smg") || StrEqual(slotPrimary[client][slot], "weapon_smg_silenced") || StrEqual(slotPrimary[client][slot], "weapon_smg_mp5"))
		{
			SetEntData(client, ammoOffset+(20), priAmmo[client][slot]);
		}
		else if (StrEqual(slotPrimary[client][slot], "weapon_pumpshotgun") || StrEqual(slotPrimary[client][slot], "weapon_shotgun_chrome"))
		{
			SetEntData(client, ammoOffset+(28), priAmmo[client][slot]);
		}
		else if (StrEqual(slotPrimary[client][slot], "weapon_autoshotgun") || StrEqual(slotPrimary[client][slot], "weapon_shotgun_spas"))
		{
			SetEntData(client, ammoOffset+(32), priAmmo[client][slot]);
		}
		else if (StrEqual(slotPrimary[client][slot], "weapon_hunting_rifle"))
		{
			SetEntData(client, ammoOffset+(36), priAmmo[client][slot]);
		}
		else if (StrEqual(slotPrimary[client][slot], "weapon_sniper_scout") || StrEqual(slotPrimary[client][slot], "weapon_sniper_military") || StrEqual(slotPrimary[client][slot], "weapon_sniper_awp"))
		{
			SetEntData(client, ammoOffset+(40), priAmmo[client][slot]);
		}
		else if (StrEqual(slotPrimary[client][slot], "weapon_grenade_launcher"))
		{
			SetEntData(client, ammoOffset+(68), priAmmo[client][slot]);
		}
		//SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iExtraPrimaryAmmo", priAmmo[client][slot], 4);
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", priClip[client][slot], 4);
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_upgradeBitVec", priUpgrade[client][slot], 4);
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", priUpgrAmmo[client][slot], 4);
	}

	if (StrEqual(slotSecondary[client][slot], "", false)) Give(client, "give", "pistol");
	else 
	{
		if (StrEqual(slotSecondary[client][slot], "dual_pistol", false)) 
		{
			Give(client, "give", "pistol");
			Give(client, "give", "pistol");
		}
		else Give(client, "give", slotSecondary[client][slot]);
	}

	if (!StrEqual(slotMedkit[client][slot], "", false)) Give(client, "give", slotMedkit[client][slot]);
	if (!StrEqual(slotThrowable[client][slot], "", false)) Give(client, "give", slotThrowable[client][slot]);
	if (!StrEqual(slotPills[client][slot], "", false)) Give(client, "give", slotPills[client][slot]);
	
	if (slot == 0)
	{
		if (incap_count[client] == GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
		{
			BlackAndWhite(client);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_currentReviveCount", incap_count[client]);
		}
		SetEntityHealth(client, preheal_perm[client]);
		SetSurvivorTempHealth(client);
	}
	else
	{
		ServerCommand("keep_save_weapons #%d", GetClientUserId(client));
		g_bTransitioned[client] = false;
	}
		
	ClientGoToAFK[client] = false;
}

int SaveWeaponsAfk(int client)
{
	strcopy(slotPrimary[client][1], 64, slotPrimary[client][0]);
	priAmmo[client][1] = priAmmo[client][0];
	priClip[client][1] = priClip[client][0];
	priUpgrade[client][1] = priUpgrade[client][0];
	priUpgrAmmo[client][1] = priUpgrAmmo[client][0];
	strcopy(slotSecondary[client][1], 64, slotSecondary[client][0]);
	strcopy(slotMedkit[client][1], 64, slotMedkit[client][0]);
	strcopy(slotThrowable[client][1], 64, slotThrowable[client][0]);
	strcopy(slotPills[client][1], 64, slotPills[client][0]);
}

int SetSurvivorTempHealth(int client)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", preheal_temp[client]);
}

int SetTempHealth(int client, int hp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	float newOverheal = hp * 1.0;
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newOverheal);
}

int SaveWeapons(int client, int slot = 0) 
{
	if (!IsClientInGame(client)) return;
	if (GetClientTeam(client) != 2) return;
	if (IsFakeClient(client)) return;
	if (!IsPlayerAlive(client)) return;

	preheal_temp[client] = GetSurvivorTempHealth(client);
	//preheal_perm[client] = GetSurvivorPermanentHealth(client);
	preheal_perm[client] = GetClientHealth(client);
	incap_count[client] = GetEntProp(client, Prop_Send, "m_currentReviveCount");

	if (!(GetPlayerWeaponSlot(client, 0) == -1)) 
	{
		char entity;
		entity = GetPlayerWeaponSlot(client, 0);
		char weapon[64];
		if (entity > 0)
		{
			GetEntityClassname(entity, weapon, 64);
		}
		//int ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
		{
			priAmmo[client][slot] = GetEntData(client, ammoOffset+(12));
		}
		else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
		{
			priAmmo[client][slot] = GetEntData(client, ammoOffset+(20));
		}
		else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
		{
			priAmmo[client][slot] = GetEntData(client, ammoOffset+(28));
		}
		else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
		{
			priAmmo[client][slot] = GetEntData(client, ammoOffset+(32));
		}
		else if (StrEqual(weapon, "weapon_hunting_rifle"))
		{
			priAmmo[client][slot] = GetEntData(client, ammoOffset+(36));
		}
		else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
		{
			priAmmo[client][slot] = GetEntData(client, ammoOffset+(40));
		}
		else if (StrEqual(weapon, "weapon_grenade_launcher"))
		{
			priAmmo[client][slot] = GetEntData(client, ammoOffset+(68));
		}
		GetWeaponNameAtSlot(client, 0, slotPrimary[client][slot], MAX_LINE_WIDTH);
		if (slotPrimary[client][slot][0] != 0) 
		{
			//priAmmo[client][slot] = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iExtraPrimaryAmmo", 4);
			priClip[client][slot] = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", 4);
			priUpgrade[client][slot] = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_upgradeBitVec", 4);
			priUpgrAmmo[client][slot] = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);
		}
	}
	else
	{
		slotPrimary[client][slot] = "";
	}

	if (!(GetPlayerWeaponSlot(client, 1) == -1)) 
	{
		GetWeaponNameAtSlot(client, 1, slotSecondary[client][slot], MAX_LINE_WIDTH);

		char modelname[128];
		GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_ModelName", modelname, 128);
		if (StrEqual(modelname, "models/weapons/melee/v_fireaxe.mdl", false)) slotSecondary[client][slot] = "fireaxe";
		else if (StrEqual(modelname, "models/weapons/melee/v_crowbar.mdl", false)) slotSecondary[client][slot] = "crowbar";
		else if (StrEqual(modelname, "models/weapons/melee/v_cricket_bat.mdl", false)) slotSecondary[client][slot] = "cricket_bat";
		else if (StrEqual(modelname, "models/weapons/melee/v_katana.mdl", false)) slotSecondary[client][slot] = "katana";
		else if (StrEqual(modelname, "models/weapons/melee/v_bat.mdl", false)) slotSecondary[client][slot] = "baseball_bat";
		else if (StrEqual(modelname, "models/v_models/v_knife_t.mdl", false)) slotSecondary[client][slot] = "knife";
		else if (StrEqual(modelname, "models/weapons/melee/v_electric_guitar.mdl", false)) slotSecondary[client][slot] = "electric_guitar";
		else if (StrEqual(modelname, "models/weapons/melee/v_frying_pan.mdl", false)) slotSecondary[client][slot] = "frying_pan";
		else if (StrEqual(modelname, "models/weapons/melee/v_machete.mdl", false)) slotSecondary[client][slot] = "machete";
		else if (StrEqual(modelname, "models/weapons/melee/v_golfclub.mdl", false)) slotSecondary[client][slot] = "golfclub";
		else if (StrEqual(modelname, "models/weapons/melee/v_tonfa.mdl", false)) slotSecondary[client][slot] = "tonfa";
		else if (StrEqual(modelname, "models/weapons/melee/v_riotshield.mdl", false)) slotSecondary[client][slot] = "riotshield";
		else if (StrEqual(modelname, "models/v_models/v_dual_pistolA.mdl", false)) slotSecondary[client][slot] = "dual_pistol";
		else GetEdictClassname(GetPlayerWeaponSlot(client, 1), slotSecondary[client][slot], MAX_LINE_WIDTH);
	}
	else
	{
		slotSecondary[client][slot] = "pistol";
	}
	
	if (!(GetPlayerWeaponSlot(client, 2) == -1)) GetWeaponNameAtSlot(client, 2, slotMedkit[client][slot], MAX_LINE_WIDTH);
	else slotMedkit[client][slot] = "";

	if (!(GetPlayerWeaponSlot(client, 3) == -1)) GetWeaponNameAtSlot(client, 3, slotThrowable[client][slot], MAX_LINE_WIDTH);
	else slotThrowable[client][slot] = "";

	if (!(GetPlayerWeaponSlot(client, 4) == -1)) GetWeaponNameAtSlot(client, 4, slotPills[client][slot], MAX_LINE_WIDTH);
	else slotPills[client][slot] = "";


	if (GetPlayerWeaponSlot(client, 0) > -1) RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
	//if (GetPlayerWeaponSlot(client, 1) > -1) RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
	if (GetPlayerWeaponSlot(client, 2) > -1) RemovePlayerItem(client, GetPlayerWeaponSlot(client, 2));
	if (GetPlayerWeaponSlot(client, 3) > -1) RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
	if (GetPlayerWeaponSlot(client, 4) > -1) RemovePlayerItem(client, GetPlayerWeaponSlot(client, 4));
}

int GetWeaponNameAtSlot(int client, int slot, char[] weaponName, int maxlen) 
{
	int wIdx = GetPlayerWeaponSlot(client, slot);
	if (wIdx < 0)
	{
		weaponName[0] = 0;
		return;
	}

	GetEdictClassname(wIdx, weaponName, maxlen);
}

public Action Event_maptransition(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				if (!ClientGoToAFK[i])
				{
					g_bTransitioned[i] = false;
					ClearWeapons(i);
				}
				else
				{
					g_bTransitioned[i] = true;
					SaveWeaponsAfk(i);
				}
			}
		}
	}
}

stock bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

float GetSurvivorTempHealth(int client)
{
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate"));
	return fHealth < 0.0 ? 0.0 : fHealth;
}

/*stock int GetSurvivorTempHealth(int client)
{
	int temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
	return temphp > 0 ? temphp : 0;
}

stock int GetSurvivorPermanentHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}*/

stock int BlackAndWhite(int client)
{
	if (client > 0 && IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		SetEntProp(client, Prop_Send, "m_currentReviveCount", GetConVarInt(FindConVar("survivor_max_incapacitated_count"))-1);
		SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
		SDKCall(sdkRevive, client);
		SetEntityHealth(client, 1);
		SetTempHealth(client, 45);
		white_aura(client);
	}
}

/*stock int SwitchHealth(int client)
{
	int float iTempHealth = GetClientTempHealth(client) * 1.0;
	int float iPermHealth = GetClientHealth(client) * 1.0;
	int float flTotal = iTempHealth + iPermHealth;
	SetEntityHealth(client, 1);
	RemoveTempHealth(client);
	SetTempHealth(client, RoundToZero(flTotal));
}*/

stock int GetClientTempHealth(int client)
{
	if (!client || !IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsClientObserver(client) || GetClientTeam(client) != 2)
	{
		return -1;
	}
	
	int float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	int float TempHealth;
	
	if (buffer <= 0.0)
	{
		TempHealth = 0.0;
	}
	else
	{
		int float difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		int float decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
		int float constant = 1.0/decay;
		TempHealth = buffer - (difference / constant);
	}
	
	if (TempHealth < 0.0)
	{
		TempHealth = 0.0;
	}
	
	return RoundToFloor(TempHealth);
}

stock int RemoveTempHealth(int client)
{
	if (!client || !IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsClientObserver(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	SetTempHealth(client, 0);
}

public int convar_AfkSpecTime(Handle convar, const char[] oldValue, const char[] newValue) 
{
	g_iCvarSpecT = StringToFloat(newValue);
	if (g_iCvarSpecT == 0.0 || g_iCvarSpecT <= 40.0) 
	{
		SetConVarFloat(convar, 40.0);
		return;
	}
}

public Action SAM_t_CheckIdles(Handle timer)
{
	static float fTheTime;
	fTheTime = GetEngineTime();

	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_fButtonTime[i] && (fTheTime - g_fButtonTime[i]) > g_iCvarSpecT)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				if (IsPlayerBussy(i) || IsSurvivorBussy(i))
				{
					g_fButtonTime[i] = fTheTime;
					continue;
				}

				SaveWeapons(i);
				without_aura(i);
				CreateTimer(0.5, movetospec2, i);
			}
			else g_fButtonTime[i] = 0.0;
		}
	}
}

stock bool IsPlayerBussy(int client)
{
	if (!IsPlayerAlive(client)) return true;
	if (IsPlayerIncapped(client)) return true;
	if (IsPlayerGrapEdge(client)) return true;
	return false;
}

bool IsPlayerGrapEdge(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1)) return true;
	return false;
}

bool IsSurvivorBussy(int client)
{
	return GetEntProp(client, Prop_Send, "m_tongueOwner") > 0 || GetEntProp(client, Prop_Send, "m_pounceAttacker") > 0 || (GetEntProp(client, Prop_Send, "m_pummelAttacker") > 0 || GetEntProp(client, Prop_Send, "m_jockeyAttacker") > 0);
}

int SetEngineTime(int client)
{
	g_fButtonTime[client] = GetEngineTime();
}

public Action Event_PlayerSay(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client) return;

	if (GetClientTeam(client) != 1)
	{
		SetEngineTime(client);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsClientInGame(client))
	{
		if (buttons && !g_bTempBlock[client] && !IsFakeClient(client))
		{
			switch (GetClientTeam(client))
			{
				case 2: if (IsPlayerAlive(client)) SAM_PluseTime(client);
				case 3: SAM_PluseTime(client);
			}
		}
	}
}

int SAM_PluseTime(int client)
{
	SetEngineTime(client);

	g_bTempBlock[client] = true;
	CreateTimer(CHECK_TIME, SAM_t_Unlock, client);
}

public Action SAM_t_Unlock(Handle timer, any client)
{
	g_bTempBlock[client] = false;
}

public Action white_aura(int client)
{
	if (client < 1) return;
	if (!IsValidEntity(client)) return;
	if (!IsClientInGame(client)) return;
	if (GetClientTeam(client) != 2) return;
	if (!IsPlayerAlive(client)) return;
	if (GetConVarInt(FindConVar("sv_disable_glow_survivors")) == 1)
	{
		return;
	}

	SetEntProp(client, Prop_Send, "m_iGlowType", 3);
	//SetEntProp(client, Prop_Send, "m_glowColorOverride", 16777215);
	int glowcolor = RGB_TO_INT(130, 130, 130);
	SetEntProp(client, Prop_Send, "m_glowColorOverride", glowcolor);
}

stock int RGB_TO_INT(int red, int green, int blue) 
{
	return (blue * 65536) + (green * 256) + red;
}

public Action without_aura(int client)
{
	if (client < 1) return;
	if (!IsValidEntity(client)) return;
	if (!IsClientInGame(client)) return;
	if (GetClientTeam(client) != 2) return;

	SetEntProp(client, Prop_Send, "m_iGlowType", 0);
	SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
}

public Action PrecacheItems(Handle timer, any client)
{
	PrecacheAllItems();
	return Plugin_Stop;
}

public Action PrecacheHealth()
{
	CheckPrecacheModel("models/w_models/weapons/w_eq_Medkit.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_eq_defibrillator.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_eq_painpills.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_eq_adrenaline.mdl");
}
 
public Action PrecacheMeleeWeapons()
{
	CheckPrecacheModel("models/weapons/melee/w_cricket_bat.mdl");
	CheckPrecacheModel("models/weapons/melee/w_crowbar.mdl");
	CheckPrecacheModel("models/weapons/melee/w_electric_guitar.mdl");
	CheckPrecacheModel("models/weapons/melee/w_chainsaw.mdl");
	CheckPrecacheModel("models/weapons/melee/w_katana.mdl");
	CheckPrecacheModel("models/weapons/melee/w_machete.mdl");
	CheckPrecacheModel("models/weapons/melee/w_tonfa.mdl");
	CheckPrecacheModel("models/weapons/melee/w_frying_pan.mdl");
	CheckPrecacheModel("models/weapons/melee/w_fireaxe.mdl");
	CheckPrecacheModel("models/weapons/melee/w_bat.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_knife_t.mdl");
	CheckPrecacheModel("models/weapons/melee/w_golfclub.mdl");
	CheckPrecacheModel("models/weapons/melee/w_riotshield.mdl");
}
 
public Action PrecacheWeapons()
{
	CheckPrecacheModel("models/w_models/weapons/w_pistol_B.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_desert_eagle.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_smg_uzi.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_smg_a.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_shotgun.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_pumpshotgun_A.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_shotgun_spas.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_autoshot_m4super.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_sniper_military.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_sniper_mini14.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_rifle_m16a2.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_desert_rifle.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_rifle_ak47.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_m60.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_smg_mp5.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_sniper_scout.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_sniper_awp.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_grenade_launcher.mdl");
}
 
public Action PrecacheThrowWeapons()
{
	CheckPrecacheModel("models/w_models/weapons/w_eq_pipebomb.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_eq_molotov.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_eq_bile_flask.mdl");
}
 
public Action PrecacheAmmoPacks()
{
	CheckPrecacheModel("models/w_models/weapons/w_eq_explosive_ammopack.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_eq_incendiary_ammopack.mdl");
}

public Action PrecacheAmmoPile()
{
	CheckPrecacheModel("models/props_unique/spawn_apartment/coffeeammo.mdl");
	CheckPrecacheModel("models/props/terror/ammo_stack.mdl");
	CheckPrecacheModel("models/props/terror/Ammo_Can.mdl");
}
 
public Action PrecacheMisc()
{
	CheckPrecacheModel("models/props_junk/explosive_box001.mdl");
	CheckPrecacheModel("models/props_junk/gascan001a.mdl");
	CheckPrecacheModel("models/props_equipment/oxygentank01.mdl");
	CheckPrecacheModel("models/props_junk/propanecanister001a.mdl");
}
 
public Action PrecacheSurvivors()
{
	CheckPrecacheModel("models/survivors/survivor_gambler.mdl");
	CheckPrecacheModel("models/survivors/survivor_manager.mdl");
	CheckPrecacheModel("models/survivors/survivor_coach.mdl");
	CheckPrecacheModel("models/survivors/survivor_producer.mdl");
	CheckPrecacheModel("models/survivors/survivor_teenangst.mdl");
	CheckPrecacheModel("models/survivors/survivor_biker.mdl");
	CheckPrecacheModel("models/survivors/survivor_namvet.mdl");
	CheckPrecacheModel("models/survivors/survivor_mechanic.mdl");
	CheckPrecacheModel("models/infected/witch.mdl");
	CheckPrecacheModel("models/infected/witch_bride.mdl");
	CheckPrecacheModel("models/infected/hulk.mdl");
	CheckPrecacheModel("models/infected/hulk_dlc3.mdl");
}
 
public Action PrecacheAllItems()
{
	PrecacheSurvivors();
	PrecacheHealth();
	PrecacheMeleeWeapons();
	PrecacheWeapons();
	PrecacheThrowWeapons();
	PrecacheAmmoPacks();
	PrecacheMisc();
}

public Action CheckPrecacheModel(char[] Model)
{
	if (!IsModelPrecached(Model)) 
	{
		PrecacheModel(Model);
	}
}

public Action Event_SurvivorRescued(Event event, const char[] name, bool dontBroadcast)
{ 
    //int client = GetClientOfUserId(event.GetInt("rescuer"));
	int target = GetClientOfUserId(event.GetInt("victim")); 
	if (!target) return;
	if (target && !IsFakeClient(target))
	{
		g_fButtonTime[target] = (GetEngineTime() - (g_iCvarSpecT * 0.5));
	}
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client) return;
	if (client && !IsFakeClient(client) && GetClientTeam(client) == 2)
	{
		g_fButtonTime[client] = (GetEngineTime() - (g_iCvarSpecT * 0.5));
		
		if (g_bTransitioned[client]) CreateTimer(2.1 , RetryRestore, client);
	}
}

/*bool HaveKid(int client)
{
	decl String:getweapon[32];
	int KidSlot = GetPlayerWeaponSlot(client, 0);
 
	if (KidSlot != -1)
	{
		GetEdictClassname(KidSlot, getweapon, 32);
		if (StrEqual(getweapon, "weapon_sniper_scout"))
		{
			return true;
		}
		else if (StrEqual(getweapon, "weapon_sniper_awp"))
		{
			return true;
		}
		else if (StrEqual(getweapon, "weapon_rifle_ak47"))
		{
			return true;
		}
		else if (StrEqual(getweapon, "weapon_grenade_launcher"))
		{
			return true;
		}
		else if (StrEqual(getweapon, "weapon_rifle_m60"))
		{
			return true;
		}
		else if (StrEqual(getweapon, "weapon_shotgun_spas"))
		{
			return true;
		}
 	}
	return false;
}*/

stock int IsTankAlive()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (IsPlayerAlive(i))
			{
				if (GetClientZC(i) == 8 && !IsPlayerIncapped(i) && IsFakeClient(i))
				{
					return 1;
				}
			}
		}
	}
	return 0;
}

stock int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock int GetClientZC(int client)
{
	if (!IsValidEntity(client) || !IsValidEdict(client))
	{
		return 0;
	}
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}

stock bool IsRealClient(int client)
{
	if (!client) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	return true;
}