#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define CVAR_FLAGS FCVAR_NONE|FCVAR_NOTIFY
#define TEAM_INFECTED 3
#define SOUND_JOCKEY_DIR "./player/jockey/"

bool injump[MAXPLAYERS+1];
bool pressdelay[MAXPLAYERS+1];

ConVar cvar_rechargebar;
ConVar cvar_soundfile;

char soundfilepath[PLATFORM_MAX_PATH];

public void OnPluginStart()
{
	//cvars
	cvar_rechargebar = CreateConVar("l4d2_jockeyjump_rechargebar", "1", "Jockey jump - recharge bar enable/disable", CVAR_FLAGS);
	cvar_soundfile = CreateConVar("l4d2_jockeyjump_soundfile", "voice/attack/jockey_loudattack01_wet.wav", "Jockey jump - jockey sound file (relative to to sound/player/jockey/ - empty to disable)", CVAR_FLAGS);

	//hooking events
	HookEvent("round_start", Round_Event);
	HookEvent("jockey_ride", Ride_Event);
}

public void OnMapStart()
{
	//get string
	char cvarstring[256];
	GetConVarString(cvar_soundfile, cvarstring, sizeof(cvarstring));

	//trim string
	TrimString(cvarstring);
	
	//is string empty?
	if (strlen(cvarstring) == 0)
	{
		soundfilepath = "";
	}
	else
	{
		PrintToServer("Building path...");
	
		//check for / at the beginning
		if (cvarstring[0] == '/')
		{
			char tempstring[256];
			strcopy(tempstring, sizeof(tempstring), cvarstring[1]);
			cvarstring = tempstring;
			
			PrintToServer("/ found! new String: %s", cvarstring);
		}
		
		//add strings
		Format(soundfilepath, sizeof(soundfilepath), "%s%s", SOUND_JOCKEY_DIR, cvarstring);
	
		PrintToServer("path: %s", soundfilepath);
	
		//precatching sound
		PrefetchSound(soundfilepath);
		PrecacheSound(soundfilepath);
	}
}

public void Round_Event(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < MaxClients; i++)
	{
		injump[i] = false;
		pressdelay[i] = false;
	}
}

public Action Ride_Event(Event event, const char[] name, bool dontBroadcast)
{
	int client_jockey = GetClientOfUserId(event.GetInt("userid"));
	int client_victim = GetClientOfUserId(event.GetInt("victim"));
	
	//everybody still there?
	if (!IsClientInGame(client_jockey))
	{
		return Plugin_Continue;
	}
	if (!IsClientInGame(client_victim))
	{
		return Plugin_Continue;
	}
	
	//botjockey?
	if (IsFakeClient(client_jockey))
	{
		return Plugin_Continue;
	}
	
	//add a new jockey + victim
	injump[client_jockey] = false;
	
	//delay jumping for a second (you can get on a survivor by jumping)
	pressdelay[client_jockey] = true;
	CreateTimer(1.0, ResetPressDelay, client_jockey, TIMER_FLAG_NO_MAPCHANGE);
	
	//send notification
	PrintHintText(client_jockey, "You can jump with the survivor by pressing JUMP!");
	
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	//pressing jump?
	if (!(buttons & IN_JUMP))
	{
		return Plugin_Continue;
	}

	//delay?
	if (injump[client])
	{
		return Plugin_Continue;
	}
	
	//pressdelay?
	if (pressdelay[client])
	{
		return Plugin_Continue;
	}

	//human?
	if (IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	
	//infected?
	if (GetClientTeam(client) != TEAM_INFECTED)
	{
		return Plugin_Continue;
	}

	// Jockey? zombieClass 5 is Jockey.
	if (GetEntProp(client, Prop_Send, "m_zombieClass") != 5)
	{
		return Plugin_Continue;
	}
	
	int victim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");

	// Is he riding someone?
	if (victim == -1)
	{
		return Plugin_Continue;
	}

	//activate press delay (half second) regardless of jumping result
	pressdelay[client] = true;
	CreateTimer(0.5, ResetPressDelay, client);
	
	//jump! (if survivor is falling return => no delay)
	if (!jump(victim))
	{
		return Plugin_Continue;
	}
	
	injump[client] = true;
	
	//setdelayreset
	float delay = 3.0;
	CreateTimer(delay, ResetJump, client);
	
	//is bar enabled?
	if (GetConVarBool(cvar_rechargebar))
	{
		//display progress bar
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", delay);  
	
		PrintHintText(client, "Jockey jump recharge!");
	}
	return Plugin_Continue;
}

public Action ResetPressDelay(Handle timer, any index)
{
	//reset press delay
	pressdelay[index] = false;
	return Plugin_Continue;
}

public Action ResetJump(Handle timer, any index)
{
	//reset jump
	injump[index] = false;
	return Plugin_Continue;
}

stock bool jump(int client)
{
	//client still there?
	if (!IsClientInGame(client))
	{
		return false;
	}

	//get velocity
	float velo[3];
	velo[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
	velo[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
	velo[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
	
	//falling or jumping?
	if (velo[2] != 0)
	{
		return false;
	}

	//add only velocity in z-direction
	float vec[3];
	vec[0] = velo[0];
	vec[1] = velo[1];
	vec[2] = velo[2] + 330.0;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
	
	//play sound if set
	if (strlen(soundfilepath) > 0)
	{
		EmitSoundToAll(soundfilepath, client);
	}
	return true;
}