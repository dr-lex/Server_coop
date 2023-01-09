//https://forums.alliedmods.net/showthread.php?t=304043

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK 8

int propinfoGhost;

bool Hooked[MAXPLAYERS];
char sg_buf3[40];

public Plugin myinfo =
{
	name = "Versus Pack",
	author = "dr lex",
	description = "",
	version = "0.0.9",
	url = "http://steamcommunity.com/id/dr_lex"
}

public void OnPluginStart()
{
	ConVar h_gameMode = FindConVar("sb_all_bot_game");
	h_gameMode.AddChangeHook(ConVarChange_GameMode);
	SetConVarString(h_gameMode, "1");
	
	ConVar h_ghost_spawn_distance = FindConVar("z_ghost_spawn_distance");
	h_ghost_spawn_distance.AddChangeHook(ConVarChange_Ghost_spawn_distance);
	SetConVarString(h_ghost_spawn_distance, "150");
	
	ConVar h_ghost_ahead_flow = FindConVar("z_ghost_ahead_flow");
	h_ghost_ahead_flow.AddChangeHook(ConVarChange_Ghost_ahead_flow);
	SetConVarString(h_ghost_ahead_flow, "250");
	
	propinfoGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	
	HookEvent("pills_used", Event_PillsUsed);
	HookEvent("adrenaline_used", Event_AdrenalineUsed);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("weapon_reload", Event_WeaponReload);
	HookEvent("player_incapacitated", Event_PlayerIncap);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
}

public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)
{
	int val = retVal;
	if (StrEqual(key, "ZombieSpawnRange"))
	{
		val = 150;
	}

	if (val != retVal)
	{
		retVal = val;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void ConVarChange_GameMode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp("1", newValue) != 0)
	{
		SetConVarString(convar, "1");
	}
}

public void ConVarChange_Ghost_spawn_distance(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp("150", newValue) != 0)
	{
		SetConVarString(convar, "150");
	}
}

public void ConVarChange_Ghost_ahead_flow (ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp("250", newValue) != 0)
	{
		SetConVarString(convar, "250");
	}
}

public void OnMapStart()
{
	FindConVar("adrenaline_duration").SetInt(120);//длительность действия от укола адреналина
	FindConVar("adrenaline_run_speed").SetInt(320);//скорость бега от адреналина
	FindConVar("adrenaline_health_buffer").SetInt(0);//временное здоровье от адреналина
	FindConVar("pain_pills_health_value").SetInt(0);//временное здоровье от таблеток
	FindConVar("survivor_revive_health").SetInt(0);
	
	FindConVar("z_mega_mob_size").SetInt(80);// кол-во зомби при тревогах
	FindConVar("z_mob_spawn_max_size").SetInt(90);// макс ко-во зомби за 1 раз
	FindConVar("z_mob_spawn_min_size").SetInt(30);// мин кол-во зомби за 1 раз
	FindConVar("z_mob_spawn_finale_size").SetInt(50);// макс кол-во зомби в толпе в финале
	
	FindConVar("z_mob_spawn_max_interval_easy").SetInt(120); // макс интервал зомби на уровне легко
	FindConVar("z_mob_spawn_max_interval_normal").SetInt(120); // макс интервал зомби на уровне средне
	FindConVar("z_mob_spawn_max_interval_hard").SetInt(120); // макс интервал зомби на уровне сложно
	FindConVar("z_mob_spawn_max_interval_expert").SetInt(120); // макс интервал зомби на уровне эксперт
	FindConVar("z_mob_spawn_min_interval_easy").SetInt(60); // мин интервал зомби на уровне легко
	FindConVar("z_mob_spawn_min_interval_normal").SetInt(60); // мин интервал зомби на уровне средне
	FindConVar("z_mob_spawn_min_interval_hard").SetInt(60); // мин интервал зомби на уровне сложно
	FindConVar("z_mob_spawn_min_interval_expert").SetInt(60);// мин интервал зомби на уровне эксперт
	
	FindConVar("first_aid_kit_use_duration").SetInt(5);//время лечения аптекой
	FindConVar("survivor_revive_duration").SetInt(3);//время поднятия игрока
	FindConVar("defibrillator_use_duration").SetInt(3);//время оживления дефибриллятором
	FindConVar("survivor_limp_health").SetInt(40);//ниже данного числа игрок хромает
	
	FindConVar("z_vomit_fatigue").SetInt(0);//Пенальти усталости во время блевания, более низкие значения позволят двигатся во время блевания.
	
	FindConVar("z_respawn_interval").SetInt(5);
	FindConVar("z_respawn_distance").SetInt(50);
}

public void OnClientPostAdminCheck(int client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		Hooked[client] = true;
	}
}

public void OnClientConnected(int client)
{
	Hooked[client] = false;
}

public void OnClientDisconnect(int client)
{
	if (Hooked[client])
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void Event_PillsUsed(Event event, const char[] name, bool dontBroadcast)
{ /* Восстанавлние ХП */
	int iSubject = GetClientOfUserId(event.GetInt("subject"));
	if (IsClientInGame(iSubject) && (GetClientTeam(iSubject) == 2))
	{
		SetEntProp(iSubject, Prop_Send, "m_iHealth", 100);
	}
}

public void Event_AdrenalineUsed(Event event, const char[] name, bool dontBroadcast)
{ /* Восстанавлние ХП */
	int iUserid = GetClientOfUserId(event.GetInt("userid"));
	if (IsClientInGame(iUserid) && (GetClientTeam(iUserid) == 2))
	{
		int HP = GetHealth(iUserid);
		if (HP < 100)
		{
			SetEntProp(iUserid, Prop_Send, "m_iHealth", 100);
		}
	}
}

public int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

public void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{ /* Восстанавлние ХП */
	int iSubject = GetClientOfUserId(event.GetInt("subject")); /* Игрок, которого спасают */
	if (IsClientInGame(iSubject) && (GetClientTeam(iSubject) == 2))
	{
		SetEntProp(iSubject, Prop_Send, "m_iHealth", 100);
	}
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{ /* Бесконечные pistols (по мне это бред но раз просят пришлось сделать) */
	int client = GetClientOfUserId(event.GetInt("userid"));
	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	char sq_weapon[32];
	event.GetString("weapon", sq_weapon, sizeof(sq_weapon)-10);
	if (StrEqual(sq_weapon, "pistol_magnum", true))
	{
		SetEntProp(activeWeapon, Prop_Data, "m_iClip1", 9);
	}
	if (StrEqual(sq_weapon, "pistol", true))
	{
		SetEntProp(activeWeapon, Prop_Data, "m_iClip1", 31);
	}
	return Plugin_Continue;
}

public Action Event_WeaponReload(Event event, const char[] name, bool dontBroadcast)
{ /* Бесконечные патроны (опять бред)*/
	int client = GetClientOfUserId(event.GetInt("userid"));
	int slot0 = GetPlayerWeaponSlot(client, 0);
	if (slot0 > 0)
	{
		char class[60];
		GetEdictClassname(slot0, class, sizeof(class)-1);
		if (StrEqual(class, "weapon_pumpshotgun") || StrEqual(class, "weapon_shotgun_chrome"))
		{
			SetPlayerReserveAmmo(client, slot0, FindConVar("ammo_shotgun_max").IntValue);
		}
		if (StrEqual(class, "weapon_autoshotgun") || StrEqual(class, "weapon_shotgun_spas"))
		{
			SetPlayerReserveAmmo(client, slot0, FindConVar("ammo_autoshotgun_max").IntValue);
		}
		if (StrEqual(class, "weapon_rifle") || StrEqual(class, "weapon_rifle_sg552") || StrEqual(class, "weapon_rifle_desert") || StrEqual(class, "weapon_rifle_ak47"))
		{
			SetPlayerReserveAmmo(client, slot0, FindConVar("ammo_assaultrifle_max").IntValue);
		}
		if (StrEqual(class, "weapon_smg") || StrEqual(class, "weapon_smg_silenced") || StrEqual(class, "weapon_smg_mp5"))
		{
			SetPlayerReserveAmmo(client, slot0, FindConVar("ammo_smg_max").IntValue);
		}
		if (StrEqual(class, "weapon_hunting_rifle"))
		{
			SetPlayerReserveAmmo(client, slot0, FindConVar("ammo_huntingrifle_max").IntValue);
		}
		if (StrEqual(class, "weapon_sniper_scout") || StrEqual(class, "weapon_sniper_military") || StrEqual(class, "weapon_sniper_awp"))
		{
			SetPlayerReserveAmmo(client, slot0, FindConVar("ammo_sniperrifle_max").IntValue);
		}
	}
	return Plugin_Continue;
}

public Action Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{ /* Исправление танка (сокрее всего мусор после выхода DLC, но првоерять лень) */
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && IsPlayerTank(client))
	{
		CreateTimer(1.0, KillTank_tCallback);
	}
	return Plugin_Continue;
}

public Action KillTank_tCallback(Handle timer)
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsPlayerTank(i) && IsIncapitated(i))
		{
			ForcePlayerSuicide(i);
		}
		i += 1;
	}
	return Plugin_Stop;
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{ /* Исправление жокея (сокрее всего мусор после выхода DLC, но првоерять лень) */
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0 || !IsClientInGame(client) || !IsFakeClient(client) || GetClientTeam(client) != 2)
	{
		return;
	}

	int jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if (jockey != -1)
	{
		CheatCommand(jockey, "dismount");
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{ /* HP Regeneration */
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));	/* User ID который убил */
	if (iAttacker)
	{
		int iUserid = GetClientOfUserId(event.GetInt("userid"));	/* User ID который умер */
		if (iAttacker != iUserid)
		{
			if (GetClientTeam(iAttacker) == 2)
			{
				if (!IsIncapitated(iAttacker))
				{
					int HP = GetHealth(iAttacker);
					if (HP < 100)
					{
						sg_buf3[0] = '\0';
						GetEventString(event, "victimname", sg_buf3, sizeof(sg_buf3)-1);
						if (event.GetBool("headshot"))
						{
							HP += 1;
						}
						
						if (sg_buf3[0] == 'I')
						{
							HP += 1;
						}
						
						if (sg_buf3[0] == 'B')
						{
							HP += 5;
						}
						
						if (sg_buf3[0] == 'J')
						{
							HP += 5;
						}
						
						if (sg_buf3[0] == 'S')
						{
							if (sg_buf3[1] == 'm')
							{	/* Smoker */
								HP += 5;
							}
							if (sg_buf3[1] == 'p')
							{	/* Spitter */
								HP += 5;
							}
						}
						if (sg_buf3[0] == 'H')
						{
							HP += 5;
						}
						if (sg_buf3[0] == 'C')
						{
							HP += 5;
						}
						if (sg_buf3[0] == 'T')
						{
							HP += 5;
						}
						if (sg_buf3[0] == 'W')
						{
							HP += 10;
						}
						
						if (HP > 100)
						{
							SetEntProp(iAttacker, Prop_Send, "m_iHealth", 100);
						}
						else
						{
							SetEntProp(iAttacker, Prop_Send, "m_iHealth", HP);
						}
					}
				}
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{ /* Кнопоки (в разработке) */
	if (IsValidClient(client) && (buttons & IN_ZOOM))
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		switch (class)
		{
			case ZOMBIECLASS_BOOMER:
			{
				SetEntProp(client, Prop_Send, "m_iHealth", 1, true);
				IgniteEntity(client, 2.0);
			}
			case ZOMBIECLASS_SPITTER:
			{
				SetEntProp(client, Prop_Send, "m_iHealth", 1, true);
				IgniteEntity(client, 2.0);
			}
		}
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (victim > MaxClients || victim < 1)
	{
		return Plugin_Continue;
	}
	
	if (GetClientTeam(victim) != 3)
	{
		return Plugin_Continue;
	}
	
	if (!IsClientGhost(victim))
	{
		return Plugin_Continue;
	}

	damage = 0.0;
	return Plugin_Changed;
}

stock int IsValidClient(int client)
{
	if (client <= 0)
	{
		return false;
	}
		
	if (client > MaxClients)
	{
		return false;
	}

	if (!IsClientInGame(client))
	{
		return false;
	}
		
	if (GetClientTeam(client) != 3)
	{
		return false;
	}
		
	if (!IsPlayerAlive(client))
	{
		return false;
	}
		
	if (IsPlayerAGhost(client))
	{
		return false;
	}
	return true;
}

stock int IsPlayerAGhost(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost"))
	{
		return true;
	}
	return false;
}

stock bool IsClientGhost(int client)
{
	return view_as<bool>(GetEntData(client, propinfoGhost, 1));
}

stock bool IsIncapitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

stock bool IsPlayerTank(int client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		if (GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
		{
			return true;
		}
	}
	return false;
}

stock void CheatCommand(int &client, char[] sCmd)
{
	int iFlags = GetCommandFlags(sCmd);
	SetCommandFlags(sCmd, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s", sCmd);
	SetCommandFlags(sCmd, iFlags);
}

//патроны
stock void SetPlayerReserveAmmo(int client, int weapon, int ammo)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype >= 0)
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
		ChangeEdictState(client, FindDataMapInfo(client, "m_iAmmo"));
	}
}