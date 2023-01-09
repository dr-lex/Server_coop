#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"

int incap_replace[MAXPLAYERS+1];
ConVar incap_mode;

public Plugin myinfo =
{
	name = "Incapped Magnum",
	author = "Oshroth",
	description = "Gives incapped players a magnum or dual pistols.",
	version = "1.4",
	url = "<- URL ->"
}

public void OnPluginStart()
{
	HookEvent("player_incapacitated", Event_Incap);
	HookEvent("player_incapacitated_start", Event_MeleeCheck);
	HookEvent("revive_success", Event_Revive);
	
	incap_mode = CreateConVar("sm_incapmagnum_mode", "1", "Incap Mode - 0 disables plugin, 1 replaces melee with magnum, 2 replaces melee with dual pistols, 3 replaces pistols and melee with magnum, 4 replaces pistols and melee with dual pistols.", FCVAR_REPLICATED|FCVAR_NOTIFY, true, 0.0, true, 4.0);
}

public Action Event_MeleeCheck(Event event, const char[] name, bool dontBroadcast)
{
	int userId = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userId);
	int slot;
	char weapon[64];
	int mode = GetConVarInt(incap_mode);
	if (mode == 0)
	{
		return Plugin_Continue;
	}
	
	slot = GetPlayerWeaponSlot(client, 1);
	if (slot > -1)
	{
		GetEdictClassname(slot, weapon, sizeof(weapon));
		if (StrContains(weapon, "melee", false) != -1)
		{
			incap_replace[client] = 1;
		}
		if (StrContains(weapon, "chainsaw", false) != -1)
		{
			incap_replace[client] = 1;
		}
		if (StrContains(weapon, "pistol", false) != -1)
		{
			incap_replace[client] = 2;
		}
		if (StrContains(weapon, "pistol_magnum", false) != -1)
		{
			incap_replace[client] = 3;
		}
	}
	else
	{
		incap_replace[client] = 0;
	}
	return Plugin_Continue;
}

public Action Event_Incap(Event event, const char[] name, bool dontBroadcast)
{
	int userId = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userId);
	int weapon = GetPlayerWeaponSlot(client, 1);
	int mode = GetConVarInt(incap_mode);
	char edict[64];
	
	if (mode == 0)
	{
		return Plugin_Continue;
	}
	if (!IsClientConnected(client) || !IsClientInGame(client) || !(GetClientTeam(client) == 2))
	{
		return Plugin_Continue;
	}
	if ((incap_replace[client] != 1) && (mode == 1 || mode == 2))
	{
		return Plugin_Continue;
	}
	
	if (weapon > -1)
	{
		GetEdictClassname(weapon, edict, sizeof(edict));
		if (incap_replace[client] == 1)
		{
			if (StrContains(edict, "pistol", false) != -1)
			{
				RemovePlayerItem(client, weapon);
			}
			else
			{
				return Plugin_Continue;
			}
		}
		else
		{
			RemovePlayerItem(client, weapon);
		}
	}
	switch (mode)
	{
		case 1:
		{
			if (incap_replace[client] == 1)
			{
				HxFakeCHEAT(client, "give", "pistol_magnum");
			}
		}
		case 2:
		{
			if (incap_replace[client] == 1)
			{
				HxFakeCHEAT(client, "give", "pistol");
				HxFakeCHEAT(client, "give", "pistol");
			}
		}
		case 3: HxFakeCHEAT(client, "give", "pistol_magnum");
		case 4:
		{
			HxFakeCHEAT(client, "give", "pistol");
			HxFakeCHEAT(client, "give", "pistol");
		}
		default: HxFakeCHEAT(client, "give", "pistol");
	}
	return Plugin_Continue;
}

public Action Event_Revive(Event event, const char[] name, bool dontBroadcast)
{
	int userId = GetEventInt(event, "subject");
	int client = GetClientOfUserId(userId);
	int weapon = GetPlayerWeaponSlot(client, 1);
	int mode = GetConVarInt(incap_mode);
	int hang = GetEventBool(event, "ledge_hang");
	
	if (mode == 0 || mode == 1 || mode == 2 || incap_replace[client] == 1 || hang)
	{
		incap_replace[client] = 0;
		if (weapon == -1)
		{
			HxFakeCHEAT(client, "give", "pistol");
			HxFakeCHEAT(client, "give", "pistol");
		}
		return Plugin_Continue;
	}
	if (!IsClientConnected(client) || !IsClientInGame(client) || !(GetClientTeam(client) == 2))
	{
		return Plugin_Continue;
	}
	
	if (weapon > -1)
	{
		RemovePlayerItem(client, weapon);
	}
	if (incap_replace[client] == 2)
	{
		HxFakeCHEAT(client, "give", "pistol");
		HxFakeCHEAT(client, "give", "pistol");
	}
	if (incap_replace[client] == 3)
	{
		HxFakeCHEAT(client, "give", "pistol_magnum");
	}
	weapon = GetPlayerWeaponSlot(client, 1);
	if (weapon == -1)
	{
		HxFakeCHEAT(client, "give", "pistol");
		HxFakeCHEAT(client, "give", "pistol");
	}
	incap_replace[client] = 0;
	return Plugin_Continue;
}

stock void HxFakeCHEAT(int &client, const char[] sCmd, const char[] sArg)
{
	int iFlags = GetCommandFlags(sCmd);
	SetCommandFlags(sCmd, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", sCmd, sArg);
	SetCommandFlags(sCmd, iFlags);
}