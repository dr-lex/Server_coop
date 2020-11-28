#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

int target_list[MAXPLAYERS];

char WeaponNames[][] =
{
	"weapon_pumpshotgun",
	"weapon_autoshotgun",
	"weapon_rifle",
	"weapon_smg",
	"weapon_hunting_rifle",
	"weapon_sniper_scout",
	"weapon_sniper_military",
	"weapon_sniper_awp",
	"weapon_smg_silenced",
	"weapon_smg_mp5",
	"weapon_shotgun_spas",
	"weapon_shotgun_chrome",
	"weapon_rifle_sg552",
	"weapon_rifle_desert",
	"weapon_rifle_ak47",
	"weapon_grenade_launcher",
	"weapon_rifle_m60",
	"weapon_first_aid_kit",
	"weapon_defibrillator",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary",
	"weapon_pain_pills",
	"weapon_adrenaline"
}

public Plugin myinfo =
{
	name = "[L4D2] Weapon Drop",
	author = "dr lex",
	description = "Allows players to drop the weapon they are holding",
	version = "1.2.2",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_drop", Command_Drop);
}

public Action Command_Drop(int client, int args)
{
	int slot;
	char weapon[32];
	GetClientWeapon(client, weapon, sizeof(weapon));
	for (int count=0; count<=22; count++)
	{
		switch(count)
		{
			case 17: slot = 3;
			case 21: slot = 4;
		}
		if (StrEqual(weapon, WeaponNames[count]))
		{
			DropSlot(client, slot);
		}
	}

	return Plugin_Handled;
}

public int DropSlot(int client, int slot)
{
	if (client > 0)
	{
		if (HxValidClient(client))
		{
			if (GetPlayerWeaponSlot(client, slot) == 0)
			{
				DropActiveWeapon(target_list[client]);
			}
			if (GetPlayerWeaponSlot(client, slot) > 3)
			{
				int weapon = GetPlayerWeaponSlot(client, slot);
				DropWeapon(client, weapon);
			}
		}
	}
}

void DropActiveWeapon(int client)
{
	int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (IsValidEnt(weapon))
	{
		DropWeapon(client, weapon);
	}
}

void DropWeapon(int client, int weapon)
{
	int ammo = GetPlayerReserveAmmo(client, weapon);
	SDKHooks_DropWeapon(client, weapon);
	SetPlayerReserveAmmo(client, weapon, 0);
	SetEntProp(weapon, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
	
	char classname[32];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if (StrEqual(classname, "weapon_defibrillator"))
	{
		int modelindex = GetEntProp(weapon, Prop_Data, "m_nModelIndex");
		SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", modelindex);
	}
	if (StrEqual(classname, "weapon_rifle_m60"))
	{
		if (GetEntProp(weapon, Prop_Data, "m_iClip1") == 0)
		{
			SetEntProp(weapon, Prop_Send, "m_iClip1", 1);
		}
	}
}

stock void SetPlayerReserveAmmo(int client, int weapon, int ammo)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype >= 0)
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
		ChangeEdictState(client, FindDataMapInfo(client, "m_iAmmo"));
	}
}

stock int GetPlayerReserveAmmo(int client, int weapon)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype >= 0)
	{
		return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
	}
	return 0;
}

int HxValidClient(int &i)
{
	if (IsClientInGame(i))
	{
		if (!IsFakeClient(i))
		{
			if (GetClientTeam(i) == 2)
			{
				if (IsPlayerAlive(i) && !IsPlayerIncapped(i))
				{
					return 1;
				}
			}
		}
	}

	return 0;
}

stock bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
	{
		return true;
	}
	return false;
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && entity > MaxClients  && IsValidEntity(entity) && entity != INVALID_ENT_REFERENCE);
}  
