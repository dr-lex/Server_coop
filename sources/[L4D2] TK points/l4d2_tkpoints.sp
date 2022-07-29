/**
 * =============================================================================
 * TK-Points
 * dr lex 	 steamcommunity.com/profiles/76561198008545221/
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <www.sourcemod.net/license.php>.
 *
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#tryinclude <gagmuteban>

#pragma newdecls required

native int HxSetClientBan(int client, int iTime);

char sg_file[160];
char sg_log[160];
char weapon[64];

float ig_TKPoints[MAXPLAYERS+1];

int ig_time_wp[MAXPLAYERS+1];
int ig_time_wp_turbo[MAXPLAYERS+1];
int ig_time_nospam[MAXPLAYERS+1];

#define PLUGIN_VERSION "1.7.1"

public Plugin myinfo = 
{
	name = "[L4D2] TK points",
	author = "dr_lex",
	description = "",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/dr_lex/"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_tk", CMD_Tk);
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_incapacitated", Event_PlayerIncap);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("defibrillator_used", Event_DefibrillatorUsed);
	HookEvent("finale_win", Event_MapTransition);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_PostNoCopy);
	
	BuildPath(Path_SM, sg_log, sizeof(sg_log)-1, "logs/GagMuteBan.log");
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

public void OnConfigsExecuted()
{
	char sBuf[12];
	FormatTime(sBuf, sizeof(sBuf)-1, "%Y-%U", GetTime());
	BuildPath(Path_SM, sg_file, sizeof(sg_file)-1, "data/%s_TK.txt", sBuf);
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		CreateTimer(5.0, HxTimerClientPost, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action HxTimerClientPost(Handle timer, any client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		LoadingBase(client);
	}
	return Plugin_Stop;
}

public void OnClientDisconnect(int client)
{
	if (!IsFakeClient(client))
	{
		UpDateTKPoints(client);
	}
}

public void HxEyeAngles(int &client, float dmg)
{
	float f1[3];
	GetClientEyeAngles(client, f1);
	f1[0] += dmg;
	f1[2] = 0.0;
	TeleportEntity(client, NULL_VECTOR, f1, NULL_VECTOR);
}

public void HxStaggerPlayer(int &client, int &client2)
{
	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	L4D_StaggerPlayer(client2, client, fPos);
}

public Action CMD_Tk(int client, int args)
{
	if (client)
	{
		PrintToChat(client, "\x04[!tk]\x03 %f TK-points (10.0 TK-points = Ban)", ig_TKPoints[client]);
	}
	return Plugin_Handled;
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = event.GetInt("attacker");
	if (iAttacker > 0)
	{
		int iUserid = event.GetInt("userid");
		if (iUserid > 0)
		{
			if (iAttacker != iUserid)
			{
				iAttacker = GetClientOfUserId(iAttacker);
				iUserid = GetClientOfUserId(iUserid);

				event.GetString("weapon", weapon, sizeof(weapon)-10);
				if (GetClientTeam(iAttacker) == 2)
				{
					if (!IsFakeClient(iUserid))
					{
						if (GetClientTeam(iUserid) == 2)
						{
							if (!IsPlayerBussy(iUserid))
							{
								if (StrEqual(weapon, "rifle", true) || StrEqual(weapon, "rifle_sg552", true) || StrEqual(weapon, "rifle_desert", true) || StrEqual(weapon, "rifle_ak47", true))
								{
									HxEyeAngles(iAttacker, -5.0);
									ig_TKPoints[iAttacker] += 0.2;
								}
								
								if (StrEqual(weapon, "rifle_m60", true))
								{
									HxEyeAngles(iAttacker, -8.0);
									ig_TKPoints[iAttacker] += 0.3;
								}
									
								if (StrEqual(weapon, "sniper_scout", true) || StrEqual(weapon, "sniper_military", true) || StrEqual(weapon, "sniper_awp", true))
								{
									HxEyeAngles(iAttacker, -3.0);
									ig_TKPoints[iAttacker] += 0.2;
								}
								
								if (StrEqual(weapon, "smg", true) || StrEqual(weapon, "smg_silenced", true) || StrEqual(weapon, "smg_mp5", true))
								{
									HxEyeAngles(iAttacker, -3.0);
									ig_TKPoints[iAttacker] += 0.1;
								}
								
								if (StrEqual(weapon, "pumpshotgun", true) || StrEqual(weapon, "shotgun_chrome", true))
								{
									HxEyeAngles(iAttacker, -2.0);
									ig_TKPoints[iAttacker] += 0.1;
								}
								
								if (StrEqual(weapon, "autoshotgun", true) || StrEqual(weapon, "shotgun_spas", true))
								{
									HxEyeAngles(iAttacker, -3.0);
									ig_TKPoints[iAttacker] += 0.2;
								}
								
								if (StrEqual(weapon, "hunting_rifle", true))
								{
									HxEyeAngles(iAttacker, -2.0);
									ig_TKPoints[iAttacker] += 0.1;
								}
								
								if (StrEqual(weapon, "grenade_launcher_projectile", true))
								{
									ig_TKPoints[iAttacker] += 0.150;
									//HxStaggerPlayer(iUserid, iAttacker);
								}
								
								if (StrEqual(weapon, "pistol", true))
								{
									HxEyeAngles(iAttacker, -0.5);
									ig_TKPoints[iAttacker] += 0.01;
								}
								
								if (StrEqual(weapon, "pistol_magnum", true))
								{
									HxEyeAngles(iAttacker, -2.0);
									ig_TKPoints[iAttacker] += 0.1;
								}
								
								if (StrEqual(weapon, "melee", true))
								{
									ig_TKPoints[iAttacker] += 0.0001;
								}
								
								if (StrEqual(weapon, "inferno", true))
								{
									ig_TKPoints[iAttacker] += 0.005;
								}
								
								if (StrEqual(weapon, "fire_cracker_blast", true))
								{
									ig_TKPoints[iAttacker] += 0.004;
								}
								
								if (StrEqual(weapon, "pipe_bomb", true))
								{
									ig_TKPoints[iAttacker] += 0.0025;
								}
								
								if (StrEqual(weapon, "chainsaw", true))
								{
									ig_TKPoints[iAttacker] += 0.00025;
									HxStaggerPlayer(iUserid, iAttacker);
								}
								
								//PrintCenterText(iAttacker, "TK-points: %f \n %N attacked -> %N", ig_TKPoints[iAttacker], iAttacker, iUserid);
								//PrintCenterText(iUserid, "TK-points \n %N attacked -> %N", iAttacker, iUserid);
								
								if (ig_time_nospam[iAttacker] < GetTime())
								{
									ig_time_nospam[iAttacker] = GetTime() + 3;

									DataPack hPack;
									CreateDataTimer(5.0, TK_MSG, hPack, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
									hPack.WriteCell(iAttacker);
									hPack.WriteCell(iUserid);
								}
								
								if (ig_TKPoints[iAttacker] > 10.0)
								{
									UpDateTKPoints(iAttacker);
								}
							}
						}
					}
				}
			}
		}
	}
}

stock Action TK_MSG(Handle timer, Handle hDataPack)
{
	// Преобразуем Handle в DataPack
	DataPack hPack = view_as<DataPack>(hDataPack);
	hPack.Reset();
	
	int iAttacker = hPack.ReadCell();
	int iUserid = hPack.ReadCell();
	
	if (IsClientInGame(iAttacker))
	{
		PrintToChat(iAttacker, "\x04[!tk]\x03 %f TK-points", ig_TKPoints[iAttacker]);
		if (IsClientInGame(iUserid))
		{
			PrintToChat(iAttacker, "\x04[!tk]\x03 %N \x04 attacked \x03 %N", iAttacker, iUserid);
			PrintToChat(iUserid, "\x04[!tk]\x03 %N \x04 attacked \x03 %N", iAttacker, iUserid);
		}
	}
	return Plugin_Stop;
}

public Action Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	if (iAttacker)
	{
		int iUserid = GetClientOfUserId(event.GetInt("userid"));
		if (iAttacker != iUserid)
		{
			if (!IsFakeClient(iAttacker))
			{
				if (!IsFakeClient(iUserid))
				{
					if (GetClientTeam(iAttacker) == 2)
					{
						if (GetClientTeam(iUserid) == 2)
						{
							ig_TKPoints[iAttacker] += 0.5;

							if (ig_time_wp[iAttacker] < GetTime())
							{
								ig_time_wp[iAttacker] = GetTime() + 20;
							}
							else
							{
								ig_time_wp[iAttacker] = GetTime() + 20;
								if (ig_time_wp_turbo[iAttacker] < GetTime())
								{
									ig_time_wp_turbo[iAttacker] = GetTime() + 10;
									ig_TKPoints[iAttacker] += 1.0;
									PrintToChat(iAttacker, "\x04[!tk]\x03 +1.0 TK-points");
								}
								else
								{
									ig_time_wp_turbo[iAttacker] = GetTime() + 10;
									ig_TKPoints[iAttacker] += 2.0;
									PrintToChat(iAttacker, "\x04[!tk]\x03 +2.0 TK-points");
								}
							}
							
							PrintToChat(iAttacker, "\x04[!tk]\x03 %N \x04 attacked \x03 %N", iAttacker, iUserid);
							PrintToChat(iAttacker, "\x04[!tk]\x03 %f TK-points", ig_TKPoints[iAttacker]);
							PrintToChat(iUserid, "\x04[!tk]\x03 %N \x04 attacked \x03 %N", iAttacker, iUserid);
							PrintToChat(iUserid, "\x04[!tk]\x05 %N \x03 %f TK-points", iAttacker, ig_TKPoints[iAttacker]);
							
							if (ig_TKPoints[iAttacker] > 10.0)
							{
								UpDateTKPoints(iAttacker);
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	if (iAttacker)
	{
		int iUserid = GetClientOfUserId(event.GetInt("userid"));
		if (iUserid > 0)
		{
			if (!IsFakeClient(iAttacker))
			{
				if (GetClientTeam(iAttacker) == 2)
				{
					if (!IsFakeClient(iUserid))
					{
						if (GetClientTeam(iUserid) == 2)
						{
							if (iAttacker != iUserid)
							{
								ig_TKPoints[iAttacker] += 3.0;
								if (ig_TKPoints[iAttacker] > 10.0)
								{
									UpDateTKPoints(iAttacker);
								}
								PrintToChat(iAttacker, "\x04[!tk]\x03 %f TK-points", ig_TKPoints[iAttacker]);
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int iSubject = GetClientOfUserId(event.GetInt("subject"));
	int iUserid = GetClientOfUserId(event.GetInt("userid"));
	if (iSubject != iUserid)
	{
		if (!IsFakeClient(iSubject))
		{
			if (!IsFakeClient(iUserid))
			{
				ig_TKPoints[iUserid] -= 1.0;
				if (ig_TKPoints[iUserid] < 0.0)
				{
					ig_TKPoints[iUserid] = 0.0;
				}

				PrintToChat(iUserid, "\x04[!tk]\x03 %f TK-points ", ig_TKPoints[iUserid]);
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int iSubject = GetClientOfUserId(event.GetInt("subject"));
	int iUserid = GetClientOfUserId(event.GetInt("userid"));
	if (iSubject != iUserid)
	{
		if (!IsFakeClient(iSubject))
		{
			if (!IsFakeClient(iUserid))
			{
				ig_TKPoints[iUserid] -= 0.3;
				if (ig_TKPoints[iUserid] < 0.0)
				{
					ig_TKPoints[iUserid] = 0.0;
				}
				
				PrintToChat(iUserid, "\x04[!tk]\x03 %f TK-points", ig_TKPoints[iUserid]);
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_DefibrillatorUsed(Event event, const char[] name, bool dontBroadcast)
{
	int iSubject = GetClientOfUserId(event.GetInt("subject"));
	int iUserid = GetClientOfUserId(event.GetInt("userid"));

	if (iSubject != iUserid)
	{
		if (!IsFakeClient(iSubject))
		{
			if (!IsFakeClient(iUserid))
			{
				ig_TKPoints[iUserid] -= 1.5;
				if (ig_TKPoints[iUserid] < 0.0)
				{
					ig_TKPoints[iUserid] = 0.0;
				}

				PrintToChat(iUserid, "\x04[!tk]\x03 %f TK-points ", ig_TKPoints[iUserid]);
			}
		}
	}
	return Plugin_Continue;
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				if (GetClientTeam(i) == 2)
				{
					ig_TKPoints[i] -= 1.0;
					if (ig_TKPoints[i] < 0.0)
					{
						ig_TKPoints[i] = 0.0;
					}
					UpDateTKPoints(i);
				}
			}
		}
		i += 1;
	}
}

stock void LoadingBase(int client)
{
	if (client)
	{
		KeyValues hGM = new KeyValues("data");
		if (hGM.ImportFromFile(sg_file))
		{
			char s1[32];
			GetClientAuthId(client, AuthId_Steam2, s1, sizeof(s1)-1);

			if (hGM.JumpToKey(s1))
			{
				ig_TKPoints[client] = hGM.GetFloat("Autoban", 0.0);
			}
			else
			{
				ig_TKPoints[client] = 0.0;
			}
		}
		delete hGM;
	}
}

stock void UpDateTKPoints(int client)
{
	if (client)
	{
		KeyValues hGM = new KeyValues("data");
		hGM.ImportFromFile(sg_file);
		
		char s1[32];
		GetClientAuthId(client, AuthId_Steam2, s1, sizeof(s1)-1);

		hGM.JumpToKey(s1, true);

		if (ig_TKPoints[client] > 10.0)
		{
			ig_TKPoints[client] = 0.0;
			if (HxSetClientBan(client, 60*12))
			{
				PrintToChatAll("\x04[!tk]\x05 ban: \x04%N", client);
				LogToFileEx(sg_log, "TK-Ban: %N (%s)", client, s1);
			}
			//BanClient(client, 60*12, BANFLAG_AUTO, "TK-Ban", "TK-Ban", "sm_ban", client);
		}

		if (ig_TKPoints[client] == 0.0)
		{
			hGM.DeleteThis();
		}
		else
		{
			hGM.SetFloat("Autoban", ig_TKPoints[client]);
		}

		hGM.Rewind();
		hGM.ExportToFile(sg_file);
		delete hGM;
	}
}

stock bool IsPlayerBussy(int client)
{
	if (IsPlayerIncapped(client))
	{
		return true;
	}
	if (IsSurvivorBussy(client))
	{
		return true;
	}
	return false;
}

stock bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
	{
		return true;
	}
	return false;
}

stock bool IsSurvivorBussy(int client)
{
	return GetEntProp(client, Prop_Send, "m_tongueOwner") > 0 || GetEntProp(client, Prop_Send, "m_pounceAttacker") > 0 || (GetEntProp(client, Prop_Send, "m_pummelAttacker") > 0 || GetEntProp(client, Prop_Send, "m_jockeyAttacker") > 0);
}