#define PLUGIN_VERSION "1.3.1"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <l4d_lib>

#define HAS_BIT(%0,%1,%2) (%0 && %1 & (1 << %2))
// --------------------------------------------------------------
// CONST
// --------------------------------------------------------------
const int PAIN_SOUND_LEN = 54;
static const float L4D_Z_MULT = 1.6;
static const int SOUND_MIN = 1;
static const int SOUND_MAX[SC_SIZE] = {7 ,4, 8, 6, 9, 7, 11, 5};
static const char FORMAT_PAIN_SOUND[] = "player/survivor/voice/%s/hurtcritical0%d.wav";

static const char INFECTED_CLAW[][]=
{
	"",
	"smoker_claw",
	"boomer_claw",
	"hunter_claw",
	"spitter_claw",
	"jockey_claw",
	"charger_claw"
};
// --------------------------------------------------------------
// GLOBAL VARS
// --------------------------------------------------------------
enum
{
	Ability_Shove,
	Ability_Slap,
	Ability_Size
}

int g_iCvarFlags[Ability_Size], g_iCvarIncapFlags;
float g_fCvarPower, g_fCvarZMult, g_fCvarAbilityCooldown[Ability_Size], g_fCooldownExpires[MPS];
// --------------------------------------------------------------
// CORE
// --------------------------------------------------------------
public Plugin myinfo =
{
	name = "[L4D & L4D2] Special Infected Ability",
	author = "raziEiL [disawar1]",
	description = "Provides to Special Infected the ability to slap and shove Survivors.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (IsL4DGameEx())
	{
		MarkNativeAsOptional("L4D2_CTerrorPlayer_Fling");
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar cVar = CreateConVar("l4d_si_ability_power", "300", "How much force is applied to the victim (Slap ability).", FCVAR_NOTIFY, true, 0.0);
	g_fCvarPower = cVar.FloatValue;
	cVar.AddChangeHook(OnCvarChange_Power);

	cVar = CreateConVar("l4d_si_ability_vertical_mult", "1.5", "Vertical force multiplier (Slap ability).", FCVAR_NOTIFY, true, 0.0);
	g_fCvarZMult = cVar.FloatValue;
	cVar.AddChangeHook(OnCvarChange_ZMult);

	cVar = CreateConVar("l4d_si_ability_cooldown_slap", "1.0", "0=Off, >0: Seconds before SI can slap again.", FCVAR_NOTIFY, true, 0.0);
	g_fCvarAbilityCooldown[Ability_Slap] = cVar.FloatValue;
	cVar.AddChangeHook(OnCvarChange_SlapCooldown);

	cVar = CreateConVar("l4d_si_ability_cooldown_shove", "1.0", "0=Off, >0: Seconds before SI can shove again.", FCVAR_NOTIFY, true, 0.0);
	g_fCvarAbilityCooldown[Ability_Shove] = cVar.FloatValue;
	cVar.AddChangeHook(OnCvarChange_ShoveCooldown);

	cVar = CreateConVar("l4d_si_ability_incap", "4", "Slapping incapacitating people. Add numbers together: 0=Off, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 126=All. Default: Boomer|Charger.", FCVAR_NOTIFY, true, 0.0, true, 126.0);
	g_iCvarIncapFlags = cVar.IntValue;
	cVar.AddChangeHook(OnCvarChange_IncapFlags);

	cVar = CreateConVar("l4d_si_ability_slap", "4", "Special Infected who can slap. Add numbers together: 0=Off, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 126=All. Default: Boomer|Charger.", FCVAR_NOTIFY, true, 0.0, true, 126.0);
	g_iCvarFlags[Ability_Slap] = cVar.IntValue;
	cVar.AddChangeHook(OnCvarChange_SlapFlags);

	cVar = CreateConVar("l4d_si_ability_shove", "36", "Special Infected who can shove. Add numbers together: 0=Off, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 126=All. Default: Smoker|Spitter.", FCVAR_NOTIFY, true, 0.0, true, 126.0);
	g_iCvarFlags[Ability_Shove] = cVar.IntValue;
	cVar.AddChangeHook(OnCvarChange_ShoveFlags);

	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnMapStart()
{
	char painSound[PAIN_SOUND_LEN];
	for (int i; i < SC_SIZE; i++)
	{
		for (int n = SOUND_MIN; n <= SOUND_MAX[i]; n++)
		{
			FormatEx(SZF(painSound), FORMAT_PAIN_SOUND, L4D2_LIB_SURVIVOR_CHARACTER[i], n);
			PrecacheSound(painSound, true);
		}
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	g_fCooldownExpires[CID(event.GetInt("userid"))] = 0.0;
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int slapper = CID(event.GetInt("attacker"));
	if (!IsInfectedAndInGame(slapper) || !CanSlapAgain(slapper) || IsInfectedBussy(slapper))
	{
		return;
	}

	int target = CID(event.GetInt("userid"));
	if (!IsSurvivorAndInGame(target))
	{
		return;
	}

	int class = GetPlayerClass(slapper);
	bool bIncaped = IsIncaped(target);
	int bSlap = HAS_BIT(!bIncaped, g_iCvarFlags[Ability_Slap], class) || HAS_BIT(bIncaped, g_iCvarIncapFlags, class);

	if (!(bSlap || HAS_BIT(!bIncaped, g_iCvarFlags[Ability_Shove], class)))
	{
		return;
	}

	char sWeapon[14];
	event.GetString("weapon", SZF(sWeapon));
	if (sWeapon[0] && StrEqual(sWeapon, INFECTED_CLAW[class]))
	{
		PlaySurvivorPainSound(target);

		if (bSlap)
		{
			// math code by AtomicStryker https://forums.alliedmods.net/showthread.php?t=97952
			float HeadingVector[3], resulting[3];
			GetClientEyeAngles(slapper, HeadingVector);
			GetEntPropVector(target, Prop_Data, "m_vecVelocity", resulting);

			resulting[0] += Cosine(DegToRad(HeadingVector[1])) * g_fCvarPower;
			resulting[1] += Sine(DegToRad(HeadingVector[1])) * g_fCvarPower;
			resulting[2] = g_fCvarPower * g_fCvarZMult;

			if (IsL4DGameEx())
			{
				resulting[2] *= L4D_Z_MULT;
				TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
			}
			else
			{
				L4D2_CTerrorPlayer_Fling(target, slapper, resulting);
			}
		}
		else
		{
			float fPos[3];
			GetClientAbsOrigin(slapper, fPos);
			L4D_StaggerPlayer(target, slapper, fPos);
		}

		if (g_fCvarAbilityCooldown[bSlap])
		{
			g_fCooldownExpires[slapper] = GetEngineTime() + g_fCvarAbilityCooldown[bSlap];
		}
	}
}

bool CanSlapAgain(int client)
{
	return g_fCooldownExpires[client] ? FloatCompare(GetEngineTime(), g_fCooldownExpires[client]) != -1 : true;
}

void PlaySurvivorPainSound(int target)
{
	int survIndex = GetSurvivorIndex(target);
	if (survIndex == SC_INVALID)
	{
		return;
	}

	char painSound[PAIN_SOUND_LEN];
	FormatEx(SZF(painSound), FORMAT_PAIN_SOUND, L4D2_LIB_SURVIVOR_CHARACTER[survIndex], GetRandomInt(SOUND_MIN, SOUND_MAX[survIndex]));
	EmitSoundToAll(painSound, target, _, SNDLEVEL_SCREAMING);
}

// --------------------------------------------------------------
// CONVARS
// --------------------------------------------------------------
public void OnCvarChange_Power(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
	{
		g_fCvarPower = cVar.FloatValue;
	}
}

public void OnCvarChange_ZMult(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
	{
		g_fCvarZMult = cVar.FloatValue;
	}
}

public void OnCvarChange_SlapCooldown(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
	{
		g_fCvarAbilityCooldown[Ability_Slap] = cVar.FloatValue;
	}
}

public void OnCvarChange_ShoveCooldown(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
	{
		g_fCvarAbilityCooldown[Ability_Shove] = cVar.FloatValue;
	}
}

public void OnCvarChange_IncapFlags(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
	{
		g_iCvarIncapFlags = cVar.IntValue;
	}
}

public void OnCvarChange_SlapFlags(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
	{
		g_iCvarFlags[Ability_Slap] = cVar.IntValue;
	}
}

public void OnCvarChange_ShoveFlags(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
	{
		g_iCvarFlags[Ability_Shove] = cVar.IntValue;
	}
}