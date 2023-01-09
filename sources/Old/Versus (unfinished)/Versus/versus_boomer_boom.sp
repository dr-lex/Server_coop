#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required

#define ZOMBIECLASS_BOOMER 			2

Handle ConfigFile;
char GAMEDATA_FILENAME[]				= "l4d2_viciousplugins";
char VELOCITY_ENTPROP[]					= "m_vecVelocity";
float SLAP_VERTICAL_MULTIPLIER			= 1.5;
Handle sdkCallFling;

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	
	ConfigFile = LoadGameConfigFile(GAMEDATA_FILENAME);
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer_Fling");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkCallFling = EndPrepSDKCall();
	if (sdkCallFling == null)
	{
		SetFailState("Cant initialize Fling SDKCall");
		return;
	}
	delete ConfigFile;
}

public void Event_PlayerDeath(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidDeadBoomer(client))
	{
		// =================================
		// Boomer Ability: Bile Blast
		// =================================
		BoomerAbility_BileBlast(client);
	}
}

// ===========================================
// Boomer Ability: Bile Blast
// ===========================================
// Description: Due to bile and methane building up, when the Boomer dies the pressure releases causing a shockwave to damage and send Survivors flying.
void BoomerAbility_BileBlast(int client)
{
	for (int victim=1; victim <= MaxClients; victim++)
	{
		if (IsValidClient(victim) && GetClientTeam(victim) != 3  && !IsSurvivorPinned(client))
		{
			float s_pos[3];
			GetClientEyePosition(client, s_pos);
			float targetVector[3];
			float distance;
			float range1 = 150.0;//"Range the inner blast radius will extend from Bile Blast. (Def 200.0)");
			float range2 = 250.0;//"Range the outer blast radius will extend from Bile Blast. (Def 300.0)");
			GetClientEyePosition(victim, targetVector);
			distance = GetVectorDistance(targetVector, s_pos);
			if (distance < range1)
			{
				float HeadingVector[3], AimVector[3];
				float power = 200.0;//"Power behind the inner range of Bile Blast. (Def 200.0)");
				GetClientEyeAngles(client, HeadingVector);
				AimVector[0] = Cosine(DegToRad(HeadingVector[1])) * power;
				AimVector[1] = Sine(DegToRad(HeadingVector[1])) * power;
				float current[3];
				GetEntPropVector(victim, Prop_Data, VELOCITY_ENTPROP, current);
				float resulting[3];
				resulting[0] = current[0] + AimVector[0];
				resulting[1] = current[1] + AimVector[1];
				resulting[2] = power * SLAP_VERTICAL_MULTIPLIER;
				int damage = 15;//"Amount of damage caused in the inner range of Bile Blast. (Def 15)");
				DamageHook(client, victim, damage);
				float incaptime = 3.0;
				SDKCall(sdkCallFling, victim, resulting, 76, client, incaptime);
			}
			if (distance < range2 && distance > range1)
			{
				float HeadingVector[3], AimVector[3];
				float power = 100.0; //Power behind the outer range of Bile Blast. (Def 100.0)");
				GetClientEyeAngles(client, HeadingVector);
				AimVector[0] = Cosine(DegToRad(HeadingVector[1])) * power;
				AimVector[1] = Sine(DegToRad(HeadingVector[1])) * power;
				float current[3];
				GetEntPropVector(victim, Prop_Data, VELOCITY_ENTPROP, current);
				float resulting[3];
				resulting[0] = current[0] + AimVector[0];
				resulting[1] = current[1] + AimVector[1];
				resulting[2] = power * SLAP_VERTICAL_MULTIPLIER;
				int damage = 5;//"Amount of damage caused in the outer range of Bile Blast. (Def 5)");
				DamageHook(client, victim, damage);
				float incaptime = 3.0;
				SDKCall(sdkCallFling, victim, resulting, 76, client, incaptime);
			}
		}
	}
}

public void DamageHook(int victim, int attacker, int damage)
{
	char strDamage[16];
	char strDamageTarget[16];
	float victimPos[3];
	GetClientEyePosition(victim, victimPos);
	IntToString(damage, strDamage, sizeof(strDamage));
	Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", victim);
	int entPointHurt = CreateEntityByName("point_hurt");
	if (!entPointHurt)
	{
		return;
	}
	DispatchKeyValue(victim, "targetname", strDamageTarget);
	DispatchKeyValue(entPointHurt, "DamageTarget", strDamageTarget);
	DispatchKeyValue(entPointHurt, "Damage", strDamage);
	DispatchKeyValue(entPointHurt, "DamageType", "0");
	DispatchSpawn(entPointHurt);
	TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entPointHurt, "Hurt", (attacker && attacker < MaxClients && IsClientInGame(attacker)) ? attacker : -1);
	DispatchKeyValue(entPointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client));
}

bool IsValidDeadBoomer(int client)
{
	if (IsValidDeadClient(client))
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == ZOMBIECLASS_BOOMER)
		{
			return true;
		}
	}
	return false;
}

bool IsValidDeadClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsPlayerAlive(client));
}

bool IsSurvivorPinned(int client)
{
	int attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	int attacker2 = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
	int attacker3 = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	int attacker4 = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	int attacker5 = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if ((attacker > 0 && attacker != client) || (attacker2 > 0 && attacker2 != client) || (attacker3 > 0 && attacker3 != client) || (attacker4 > 0 && attacker4 != client) || (attacker5 > 0 && attacker5 != client))
	{
		return true;
	}
	return false;
}