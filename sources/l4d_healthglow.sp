/**
 * =============================================================================
 * L4D Health Glow (C)2011 Buster "Mr. Zero" Nielsen
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License, version 3.0, as 
 * published by the Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along 
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2,"
 * the "Source Engine," the "SourcePawn JIT," and any Game MODs that run on 
 * software by the Valve Corporation.  You must obey the GNU General Public
 * License in all respects for all other code used.  Additionally, 
 * AlliedModders LLC grants this exception to all derivative works.  
 * AlliedModders LLC defines further exceptions, found in LICENSE.txt 
 * (as of this writing, version JULY-31-2007), or 
 * <http://www.sourcemod.net/license.php>.
 */

/*
 * ==================================================
 *                    Preprocessor
 * ==================================================
 */

/* Parser settings */
#pragma semicolon 1
#pragma tabsize 4

/* Plugin information */
#define PLUGIN_FULLNAME                 "L4D2 Health Glows"                  // Used when printing the plugin name anywhere
#define PLUGIN_SHORTNAME                "l4d2healthglows"                    // Shorter version of the full name, used in file paths, and other things
#define PLUGIN_AUTHOR                   "Buster \"Mr. Zero\" Nielsen"       // Author of the plugin
#define PLUGIN_DESCRIPTION              "Gives the Survivors a health glow around them." // Description of the plugin
#define PLUGIN_VERSION                  "1.0.1"                             // Version of the plugin
#define PLUGIN_URL                      "mrzerodk@gmail.com"                // URL associated with the project
#define PLUGIN_CVAR_PREFIX              "l4d2_healthglows"                   // Prefix for plugin cvars
#define PLUGIN_CMD_PREFIX               "l4d2_healthglows"                   // Prefix for plugin commands
#define PLUGIN_TAG                      "HealthGlow"                        // Plugin tag for chat prints
#define PLUGIN_CMD_GROUP                PLUGIN_SHORTNAME                    // Command group for plugin commands

/* Precompile plugin settings */
#define CREATE_TRACKING_CVAR            // Whether plugin will create a tracking cvar containing the version number of the plugin

#define GLOW_HEALTH_HIGH 100 // Not used but just for completeness sake
#define GLOW_HEALTH_MED 39
#define GLOW_HEALTH_LOW 24

/*
 * L4D2_IsSurvivorGlowDisabled is used to "detect" whether realism mode is active.
 * As in no survivor glows in realism, means "less health glows" by this plugin.
 *
 * Minimum range ensures that glows are not shown when survivors are inside each other.
 * Also hides the players own glow from themself when in third person shoulder mode.
 */

#define GLOW_HEALTH_HIGH_TYPE L4D2_IsSurvivorGlowDisabled() ? L4D2Glow_None : L4D2Glow_OnUse
#define GLOW_HEALTH_HIGH_RANGE 64
#define GLOW_HEALTH_HIGH_MINRANGE 22
#define GLOW_HEALTH_HIGH_COLOR_R 0
#define GLOW_HEALTH_HIGH_COLOR_G 100
#define GLOW_HEALTH_HIGH_COLOR_B 0
#define GLOW_HEALTH_HIGH_FLASHING false

#define GLOW_HEALTH_MED_TYPE L4D2Glow_OnUse
#define GLOW_HEALTH_MED_RANGE L4D2_IsSurvivorGlowDisabled() ? 64 : 80
#define GLOW_HEALTH_MED_MINRANGE 22
#define GLOW_HEALTH_MED_COLOR_R 95
#define GLOW_HEALTH_MED_COLOR_G 95
#define GLOW_HEALTH_MED_COLOR_B 0
#define GLOW_HEALTH_MED_FLASHING false

#define GLOW_HEALTH_LOW_TYPE L4D2Glow_OnUse
#define GLOW_HEALTH_LOW_RANGE L4D2_IsSurvivorGlowDisabled() ? 64 : 96
#define GLOW_HEALTH_LOW_MINRANGE 22
#define GLOW_HEALTH_LOW_COLOR_R 135
#define GLOW_HEALTH_LOW_COLOR_G 0
#define GLOW_HEALTH_LOW_COLOR_B 0
#define GLOW_HEALTH_LOW_FLASHING false

#define GLOW_HEALTH_THIRDSTRIKE_TYPE L4D2_IsSurvivorGlowDisabled() ? L4D2Glow_OnUse : L4D2Glow_Constant
#define GLOW_HEALTH_THIRDSTRIKE_RANGE L4D2_IsSurvivorGlowDisabled() ? 96 : 0
#define GLOW_HEALTH_THIRDSTRIKE_MINRANGE 22
#define GLOW_HEALTH_THIRDSTRIKE_COLOR_R 100
#define GLOW_HEALTH_THIRDSTRIKE_COLOR_G 100
#define GLOW_HEALTH_THIRDSTRIKE_COLOR_B 100
#define GLOW_HEALTH_THIRDSTRIKE_FLASHING false

/*
 * ==================================================
 *                     Includes
 * ==================================================
 */

/*
 * --------------------
 *       Globals
 * --------------------
 */
#include <sourcemod>
#include <sdktools>
//#include <sdkhooks>
#include <l4d_stocks>
/*
 * --------------------
 *       Modules
 * --------------------
 */

#include <macros.sp>
#include <helpers.sp>
#pragma newdecls required
#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif
/*
 * ==================================================
 *                     Variables
 * ==================================================
 */

/*
 * --------------------
 *       Private
 * --------------------
 */

bool g_isInGame[MAXPLAYERS + 1];
bool g_isGlowing[MAXPLAYERS + 1];
bool g_isIT[MAXPLAYERS + 1];

int g_maxIncaps = 2;
bool g_isGlowDisabled = false;
bool g_isPluginEnding = false;

/*
 * ==================================================
 *                     Forwards
 * ==================================================
 */

public Plugin myinfo = 
{
    name           = PLUGIN_FULLNAME,
    author         = PLUGIN_AUTHOR,
    description    = PLUGIN_DESCRIPTION,
    version        = PLUGIN_VERSION,
    url            = PLUGIN_URL
}

/**
 * Called on pre plugin start.
 *
 * @param myself        Handle to the plugin.
 * @param late          Whether or not the plugin was loaded "late" (after map load).
 * @param error         Error message buffer in case load failed.
 * @param err_max       Maximum number of characters for error message buffer.
 * @return              APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if (!IsDedicatedServer())
    {
        strcopy(error, err_max, "Plugin only support dedicated servers");
        return APLRes_Failure; // Plugin does not support client listen servers, return
    }

    char buffer[128];
    GetGameFolderName(buffer, 128);
    if (!StrEqual(buffer, "left4dead2", false))
    {
        strcopy(error, err_max, "Plugin only support Left 4 Dead 2");
        return APLRes_Failure; // Plugin does not support this game, return
    }

    return APLRes_Success;
}

/**
 * Called on plugin start.
 *
 * @noreturn
 */
public void OnPluginStart()
{
    /* Plugin start up routine */
    CreateTrackingConVar();

    HookConVarChange(FindConVar("survivor_max_incapacitated_count"), OnIncapMax_ConVarChange);
    HookConVarChange(FindConVar("sv_disable_glow_survivors"), OnGlowDisable_ConVarChange);

    /* SI grab events */
    HookEvent("pounce_end", UpdateGlow_Victim_Event);
    HookEvent("tongue_release", UpdateGlow_Victim_Event);
    HookEvent("jockey_ride_end", UpdateGlow_Victim_Event);
    HookEvent("charger_carry_end", UpdateGlow_Victim_Event);
    HookEvent("charger_pummel_end", UpdateGlow_Victim_Event);

    HookEvent("lunge_pounce", UpdateGlow_Victim_Event);
    HookEvent("tongue_grab", UpdateGlow_Victim_Event);
    HookEvent("jockey_ride", UpdateGlow_Victim_Event);
    HookEvent("charger_carry_start", UpdateGlow_Victim_Event);
    HookEvent("charger_pummel_start", UpdateGlow_Victim_Event);

    /* SI Boomer events */
    HookEvent("player_now_it", UpdateGlow_NowIT_Event);
    HookEvent("player_no_longer_it", UpdateGlow_NoLongerIt_Event);

    /* Survivor related events */
    HookEvent("revive_success", UpdateGlow_Subject_Event);
    HookEvent("heal_success", UpdateGlow_Subject_Event);
    HookEvent("player_incapacitated_start", UpdateGlow_UserId_Event);
    HookEvent("player_ledge_grab", UpdateGlow_UserId_Event);
    HookEvent("player_death", UpdateGlow_UserId_Event);
    HookEvent("defibrillator_used", UpdateGlow_Subject_Event);
    HookEvent("player_hurt", UpdateGlow_UserId_Event);

    HookEvent("player_bot_replace", UpdateGlow_Idle_Event);
    HookEvent("bot_player_replace", UpdateGlow_Idle_Event);
}

public void OnPluginEnd()
{
	g_isPluginEnding = true;

	int client = 1;
	while (client <= MaxClients)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == 2)
			{
				L4D2_RemoveEntityGlow(client);
			}
		}
		client +=1;
	}

//	FOR_EACH_SURVIVOR(client)
//	{
//		L4D2_RemoveEntityGlow(client);
//	}
}

public void OnAllPluginsLoaded()
{
	g_maxIncaps = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
	g_isGlowDisabled = GetConVarBool(FindConVar("sv_disable_glow_survivors"));

	FOR_EACH_CLIENT_IN_GAME(client)
	{
		g_isInGame[client] = true;
	}

//    FOR_EACH_SURVIVOR(client)
//    {
 //       UpdateSurvivorHealthGlow(client);
 //   }
	int client = 1;
	while (client <= MaxClients)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == 2)
			{
				UpdateSurvivorHealthGlow(client);
			}
		}
		client +=1;
	}

    /* For people using admin cheats and other stuff that changes survivor 
     * health */
	CreateTimer(5.0, UpdateGlows_Timer, _, TIMER_REPEAT);
}

public void OnClientPutInServer(int client)
{
    if (client == 0)
    {
        return;
    }

    g_isGlowing[client] = false;
    g_isInGame[client] = true;
}

public void OnClientDisconnect(int client)
{
    if (client == 0)
    {
        return;
    }

    g_isInGame[client] = false;
}

public void OnIncapMax_ConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
    g_maxIncaps = GetConVarInt(convar);
}

public void OnGlowDisable_ConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
    g_isGlowDisabled = GetConVarBool(convar);
}

public Action UpdateGlows_Timer(Handle timer)
{
	if (g_isPluginEnding)
	{
		return Plugin_Stop;
	}

//    FOR_EACH_SURVIVOR(client)
//    {
//        UpdateSurvivorHealthGlow(client);
//    }
	int client = 1;
	while (client <= MaxClients)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == 2)
			{
				UpdateSurvivorHealthGlow(client);
			}
		}
		client +=1;
	}

	return Plugin_Continue;
}

public void UpdateGlow_UserId_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || client > MaxClients || !g_isInGame[client] || view_as<L4DTeam>(GetClientTeam(client)) != L4DTeam_Survivor)
    {
        return;
    }

    UpdateSurvivorHealthGlow(client);
}

public void UpdateGlow_Subject_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("subject"));
    if (client <= 0 || client > MaxClients || !g_isInGame[client] || view_as<L4DTeam>(GetClientTeam(client)) != L4DTeam_Survivor)
    {
        return;
    }

    UpdateSurvivorHealthGlow(client);
}

public void UpdateGlow_Victim_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("victim"));
    if (client <= 0 || client > MaxClients || !g_isInGame[client] || view_as<L4DTeam>(GetClientTeam(client)) != L4DTeam_Survivor)
    {
        return;
    }

    UpdateSurvivorHealthGlow(client);
}

public void UpdateGlow_NowIT_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || client > MaxClients || !g_isInGame[client] || view_as<L4DTeam>(GetClientTeam(client)) != L4DTeam_Survivor)
    {
        return;
    }

    g_isIT[client] = true;
    UpdateSurvivorHealthGlow(client);
}

public void UpdateGlow_NoLongerIt_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || client > MaxClients || !g_isInGame[client] || view_as<L4DTeam>(GetClientTeam(client)) != L4DTeam_Survivor)
    {
        return;
    }

    g_isIT[client] = false;
    UpdateSurvivorHealthGlow(client);
}

public void UpdateGlow_Idle_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("player"));
    if (client <= 0 || client > MaxClients || !g_isInGame[client])
    {
        return;
    }

    int bot = GetClientOfUserId(event.GetInt("bot"));

    UpdateSurvivorHealthGlow(client);
    UpdateSurvivorHealthGlow(bot);
}

/*
 * ==================================================
 *                     Public API
 * ==================================================
 */

stock int UpdateSurvivorHealthGlow(int client)
{
    if (g_isPluginEnding || !g_isInGame[client])
    {
        return;
    }

    if (view_as<L4DTeam>(GetClientTeam(client)) != L4DTeam_Survivor || !IsPlayerAlive(client) || L4D_IsPlayerIncapacitated(client) || L4D2_GetInfectedAttacker(client) > 0 || g_isIT[client] || !L4D2_IsPlayerSurvivorGlowEnable(client))
    {
        if (g_isGlowing[client])
        {
            g_isGlowing[client] = false;
            L4D2_RemoveEntityGlow(client);
        }
        return;
    }

    int health = GetClientHealth(client);
    bool lastLife = L4D_GetPlayerReviveCount(client) >= L4D_GetMaxReviveCount();

    L4D2GlowType type;
    int color[3];
    int range;
    int minRange;
    bool flashing;
    GetHealthGlowForClient(health, lastLife, type, range, minRange, color, flashing);

    g_isGlowing[client] = true;
    L4D2_SetEntityGlow(client, type, range, minRange, color, flashing);
}

/*
 * ==================================================
 *                    Private API
 * ==================================================
 */
//static int GetHealthGlowForClient(int health, bool:lastLife, &L4D2GlowType:type, &range, &minRange, int color[3], &bool:flashing)
static int GetHealthGlowForClient(int health, bool lastLife, L4D2GlowType &type, int &range, int &minRange, int color[3], bool &flashing)
{
    if (lastLife)
    {
        type = GLOW_HEALTH_THIRDSTRIKE_TYPE;
        range = GLOW_HEALTH_THIRDSTRIKE_RANGE;
        minRange = GLOW_HEALTH_THIRDSTRIKE_MINRANGE;
        color = {GLOW_HEALTH_THIRDSTRIKE_COLOR_R, GLOW_HEALTH_THIRDSTRIKE_COLOR_G, GLOW_HEALTH_THIRDSTRIKE_COLOR_B};
        flashing = GLOW_HEALTH_THIRDSTRIKE_FLASHING;
        return;
    }

    if (health <= GLOW_HEALTH_LOW)
    {
        type = GLOW_HEALTH_LOW_TYPE;
        range = GLOW_HEALTH_LOW_RANGE;
        minRange = GLOW_HEALTH_LOW_MINRANGE;
        color = {GLOW_HEALTH_LOW_COLOR_R, GLOW_HEALTH_LOW_COLOR_G, GLOW_HEALTH_LOW_COLOR_B};
        flashing = GLOW_HEALTH_MED_FLASHING;
    }
    else if (health <= GLOW_HEALTH_MED)
    {
        type = GLOW_HEALTH_MED_TYPE;
        range = GLOW_HEALTH_MED_RANGE;
        minRange = GLOW_HEALTH_MED_MINRANGE;
        color = {GLOW_HEALTH_MED_COLOR_R, GLOW_HEALTH_MED_COLOR_G, GLOW_HEALTH_MED_COLOR_B};
        flashing = GLOW_HEALTH_MED_FLASHING;
    }
    else
    {
        type = GLOW_HEALTH_HIGH_TYPE;
        range = GLOW_HEALTH_HIGH_RANGE;
        minRange = GLOW_HEALTH_HIGH_MINRANGE;
        color = {GLOW_HEALTH_HIGH_COLOR_R, GLOW_HEALTH_HIGH_COLOR_G, GLOW_HEALTH_HIGH_COLOR_B};
        flashing = GLOW_HEALTH_HIGH_FLASHING;
    }
}

static int L4D_GetMaxReviveCount()
{
    return g_maxIncaps;
}

static bool L4D2_IsSurvivorGlowDisabled()
{
    return g_isGlowDisabled;
}

/**
 * Creates plugin tracking convar.
 *
 * @noreturn
 */
int CreateTrackingConVar()
{
#if defined CREATE_TRACKING_CVAR
    char cvarName[128];
    Format(cvarName, sizeof(cvarName), "%s_%s", PLUGIN_CVAR_PREFIX, "version");

    char desc[128];
    Format(desc, sizeof(desc), "%s SourceMod Plugin Version", PLUGIN_FULLNAME);

    ConVar cvar = CreateConVar(cvarName, PLUGIN_VERSION, desc, FCVAR_NONE | FCVAR_NOTIFY | FCVAR_DONTRECORD);
    SetConVarString(cvar, PLUGIN_VERSION);
#endif
}