#define PLUGIN_VERSION "1.4.1"
//#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif
#pragma newdecls required
#define sdk_hooks_edition 1
#if sdk_hooks_edition	
#include <sdkhooks>	
#endif
 
int MODEL_DEFIB;
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
	"weapon_rifle_m60", //0-16
	"weapon_pistoll",
	"weapon_pistoll_magnum",
	"weapon_chainssaw",
	"weapon_mellee", //17-20
	"weapon_pipe_bombb",
	"weapon_molotovv",
	"weapon_vomitjarr", //21-23
	"weapon_first_aid_kit",
	"weapon_defibrillator",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary", //24-27
	"weapon_pain_pills",
	"weapon_adrenaline", //28-29
	"weapon_gascan",
	"weapon_propanetank",
	"weapon_oxygentank",
	"weapon_gnome",
	"weapon_cola_bottles",
	"weapon_fireworkcrate" //30-35
}

public Plugin myinfo = 
{
	name = "[L4D2] Weapon Drop",
	author = "Machine, dcx2",
	description = "Allows players to drop the weapon they are holding",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_drop", Command_Drop);
	CreateConVar("sm_drop_version", PLUGIN_VERSION, "[L4D2] Weapon Drop Version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	LoadTranslations("common.phrases");
}

public void OnMapStart()
{
	MODEL_DEFIB = PrecacheModel("models/w_models/weapons/w_eq_defibrillator.mdl", true);
}

public Action Command_Drop(int client, int args)
{
	if (args == 1 || args > 2)
	{
		if (GetAdminFlag(GetUserAdmin(client), Admin_Root)) ReplyToCommand(client, "[SM] Usage: sm_drop <#userid|name> <slot to drop>");
	}
	else if (args < 1)
	{
		int slot;
		char weapon[32];
		GetClientWeapon(client, weapon, sizeof(weapon));
		for (int count = 0; count <= 35; count++)
		{
			switch(count)
			{
				case 17: slot = 1;
				case 21: slot = 2;
				case 24: slot = 3;
				case 28: slot = 4;
				case 30: slot = 5;
			}
			if (StrEqual(weapon, WeaponNames[count]))
			{
				DropSlot(client, slot);
			}
		}
	}
	else if (args == 2)
	{
		if (GetAdminFlag(GetUserAdmin(client), Admin_Root))
		{
			char target[MAX_TARGET_LENGTH], arg[8];
			GetCmdArg(1, target, sizeof(target));
			GetCmdArg(2, arg, sizeof(arg));
			int slot = StringToInt(arg);

			int targetid = StringToInt(target);
			if (targetid > 0 && IsClientInGame(targetid))
			{
				DropSlot(targetid, slot);
				return Plugin_Handled;
			}

			char target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
	
			if ((target_count = ProcessTargetString(
				target,
				client,
				target_list,
				MAXPLAYERS,
				0,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			for (int i = 0; i < target_count; i++)
			{
				DropSlot(target_list[i], slot);
			}
		}
	}
	return Plugin_Handled;
}

public int DropSlot(int client, int slot)
{
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		if (GetPlayerWeaponSlot(client, slot) > 0)
		{
			int weapon = GetPlayerWeaponSlot(client, slot);
			SDKCallWeaponDrop(client, weapon);
		}
	}
}

stock int SDKCallWeaponDrop(int client, int weapon)
{
    #if !sdk_hooks_edition		
	static Handle hWeaponDrop = null;
	if (hWeaponDrop == null)
	{
		Handle hConf = LoadGameConfigFile("l4d2_weapon_drop");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "WeaponDrop");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		hWeaponDrop = EndPrepSDKCall();
		CloseHandle(hConf);
		if (hWeaponDrop == null)
		{
			SetFailState("Can't initialize WeaponDrop SDKCall!");
			return;
		}            
	}
	#endif		
	
	char classname[32]; 
	float vecAngles[3], vecTarget[3], vecVelocity[3];
	if (GetPlayerEye(client, vecTarget))
	{
		GetClientEyeAngles(client, vecAngles);
		GetAngleVectors(vecAngles, vecVelocity, NULL_VECTOR, NULL_VECTOR);
		vecVelocity[0] *= 300.0;
		vecVelocity[1] *= 300.0;
		vecVelocity[2] *= 300.0;
    		
		#if sdk_hooks_edition	
		SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
		#else		
		SDKCall(hWeaponDrop, client, weapon);
		#endif	
		
		
		TeleportEntity(weapon, NULL_VECTOR, NULL_VECTOR, vecVelocity);
		GetEdictClassname(weapon, classname, sizeof(classname));
		if (StrEqual(classname,"weapon_defibrillator"))
		{
			SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", MODEL_DEFIB);
		}
	}
}

stock bool GetPlayerEye(int client, float vecTarget[3]) 
{
	float Origin[3], Angles[3];
	GetClientEyePosition(client, Origin);
	GetClientEyeAngles(client, Angles);

	Handle trace = TR_TraceRayFilterEx(Origin, Angles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if (TR_DidHit(trace)) 
	{
		TR_GetEndPosition(vecTarget, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > GetMaxClients() || !entity;
}