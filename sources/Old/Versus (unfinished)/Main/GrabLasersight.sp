#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

#define L4D2_WEPUPGFLAG_LASER     (1 << 2)

public Plugin myinfo =
{
    name = "Auto grab laser sight",
    author = "WolfGang",
    description = "Laser Sight on weapon pickup",
    version = "1.1.1",
    url = ""
}

public void OnAllPluginsLoaded()
{
	/* For plugin reloading in mid game */
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsClientAuthorized(client))
		{
			continue;
		}
		
		SDKHook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
		SDKHook(client, SDKHook_WeaponDropPost, OnClientWeaponDrop);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (client <= 0)
	{
		return;
	}

	SDKHook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
	SDKHook(client, SDKHook_WeaponDropPost, OnClientWeaponDrop);
}

public void OnClientDisconnect(int client)
{
	if (client <= 0)
	{
		return;
	}

	SDKUnhook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
	SDKUnhook(client, SDKHook_WeaponDropPost, OnClientWeaponDrop);
}

public void OnClientWeaponEquip(int client, int weapon)
{
	if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
	{
		return; // Invalid survivor, return
	}

	int priWeapon = GetPlayerWeaponSlot(client, 0); // Get primary weapon
	if (priWeapon <= 0 || !IsValidEntity(priWeapon))
	{
		return; // Invalid weapon, return
	}

	char netclass[128];
	GetEntityNetClass(priWeapon, netclass, 128);
	if (FindSendPropInfo(netclass, "m_upgradeBitVec") < 1)
	{
		return; // This weapon does not support upgrades
	}

	int upgrades = L4D2_GetWeaponUpgrades(priWeapon); // Get upgrades of primary weapon
	if (upgrades & L4D2_WEPUPGFLAG_LASER)
	{
		return; // Primary weapon already have laser sight, return
	}
	
	L4D2_SetWeaponUpgrades(priWeapon, upgrades | L4D2_WEPUPGFLAG_LASER); // Add laser sight to primary weapon
}

public void OnClientWeaponDrop(int client, int weapon)
{
	if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return; // Invalid survivor, return
	}

	if (weapon <= 0 || !IsValidEntity(weapon))
	{
		return; // Invalid weapon, return
	}

	char netclass[128];
	GetEntityNetClass(weapon, netclass, 128);
	if (FindSendPropInfo(netclass, "m_upgradeBitVec") < 1)
	{
		return; // This weapon does not support upgrades
	}

	int upgrades = L4D2_GetWeaponUpgrades(weapon); // Get upgrades of dropped weapon
	if (!(upgrades & L4D2_WEPUPGFLAG_LASER))
	{
		return; // Weapon did not have laser sight, return
	}

	L4D2_SetWeaponUpgrades(weapon, upgrades ^ L4D2_WEPUPGFLAG_LASER); // Remove laser sight from weapon
}

/**
 * Returns weapon upgrades of weapon.
 *
 * @param weapon		Weapon entity index.
 * @return				Weapon upgrade bits.
 * @error				Invalid entity index.
 */
stock int L4D2_GetWeaponUpgrades(int weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
}

/**
 * Set weapon upgrades for weapon.
 *
 * @param weapon		Weapon entity index.
 * @param upgrades		Weapon upgrade bits.
 * @noreturn
 * @error				Invalid entity index.
 */
stock int L4D2_SetWeaponUpgrades(int weapon, int upgrades)
{
	SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", upgrades);
	return 0;
}