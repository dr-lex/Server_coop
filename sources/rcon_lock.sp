//#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif
#pragma newdecls required

#define VERSION "0.6.7"

public Plugin myinfo =
{
	name = "RCON Lock",
	author = "devicenull",
	description = "Locks RCON password and patches various exploitable commands",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

/* Entities that are not allowed to be created with ent_create or give */
char forbidden_ents[][] = { "point_servercommand", "point_clientcommand", "logic_timer", "logic_relay", "logic_auto", "logic_autosave", "logic_branch", "logic_case", "logic_collision_pair", "logic_compareto", "logic_lineto", "logic_measure_movement", "logic_multicompare", "logic_navigation" };

/*Strings that are not allowed to be present in ent_fire commands */
char forbidden_cmds[][] = { "quit", "quti", "restart", "sm", "admin", "ma_", "rcon", "sv_", "mp_", "meta", "alias" };

/* Commands that will have the FCVAR_CHEATS flag added, to prevent execution */
char cheat_flag[][] = { "ai_test_los", "dbghist_dump", "dump_entity_sizes", "dump_globals", "dump_terrain", "dumpcountedstrings", "dumpentityfactories", "dumpeventqueue", "es_version", "groundlist", "listmodels", "mem_dump", "mp_dump_timers", "npc_ammo_deplete", "npc_heal", "npc_speakall", "npc_thinknow", "physics_budget", "physics_debug_entity", "physics_report_active", "physics_select", "report_entities", "report_touchlinks", "snd_digital_surround", "snd_restart", "soundlist", "soundscape_flush", "wc_update_entity" };
	
/* Mani commands that will be disabled */
char block_mani[][] = { "timeleft", "nextmap", "ma_timeleft", "ma_nextmap", "listmaps", "ff" };

/* Cvars that clients are not permitted to have */
char forbidden_cvars[][] = { "sourcemod_version", "metamod_version", "mani_admin_plugin_version", "eventscripts_ver", "est_version", "bat_version", "beetlesmod_version" };

/* Plugins that will be removed if they exist */
char bad_plugins[][] = { "sourceadmin.smx", "s.smx", "boomstick.smx", "hax.smx", "sourcemod.smx" };

int cvar_pos[MAXPLAYERS];
ConVar rcon_pw;
bool rcon_set = false;
bool logging = false;
char correct_rcon_pw[256];
ConVar mintries;
ConVar maxtries;
File cmdLogFile = null;
bool bCmdLog = true;
bool bServerLog = true;

public void OnPluginStart()
{
	CreateConVar("sm_rconlock", VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AddCommandListener(Cmd_EntCreate,"ent_create");
	AddCommandListener(Cmd_EntCreate,"give");
	AddCommandListener(Cmd_EntFire,"ent_fire");
	AddCommandListener(Cmd_Log,"log");
	AddCommandListener(Cmd_Say,"say");
	AddCommandListener(Cmd_Say,"say_team");
	
	RegConsoleCmd("changelevel",Cmd_ChangeLevel);

	// Grab the rcon password to prevent changes
	rcon_pw = FindConVar("rcon_password");
	HookConVarChange(rcon_pw, rcon_changed);

	// Flag any of the exploitable commands as cheats
	ConVar curcmd;
	LogMessage("%i cheat commands",sizeof(cheat_flag));
	for (int i = 0; i < sizeof(cheat_flag); i++)
	{
		if (GetCommandFlags(cheat_flag[i]) != INVALID_FCVAR_FLAGS)
		{
			if (GetCommandFlags(cheat_flag[i])&FCVAR_CHEAT)
			{
				LogMessage("%s already has cheats flag",cheat_flag[i]);
				continue;
			}
			LogMessage("Flagging %s as cheat",cheat_flag[i]);
			SetCommandFlags(cheat_flag[i],GetCommandFlags(cheat_flag[i])|FCVAR_CHEAT);
		}
		else
		{
			LogMessage("Couldn't find %s (this may be normal)",cheat_flag[i]);
		}
	}
	
	// Figure out if Mani is loaded
	if (FindConVar("mani_admin_plugin_version") != null)
	{
		for (int i = 0; i < sizeof(block_mani); i++)
		{
			curcmd = FindConVar(block_mani[i]);
			if (curcmd != null)
			{
				SetConVarFlags(curcmd,GetConVarFlags(curcmd)|FCVAR_CHEAT);
			}
		}
	}
	
	if (FindConVar("eventscripts_ver") != null)
	{
		LogMessage("Eventscripts detected, disabling server command logging");
		bServerLog = false;
	}
	
	// Remove convar bounds so the actual rcon crash can be prevented
	mintries = FindConVar("sv_rcon_minfailures");
	maxtries = FindConVar("sv_rcon_maxfailures");
	SetConVarBounds(mintries,ConVarBound_Upper,false);
	SetConVarBounds(maxtries,ConVarBound_Upper,false);
	
	
	AddCommandListener(HalfConnected);
	
	char gamename[32];
	GetGameFolderName(gamename,sizeof(gamename));
	if (StrEqual(gamename,"left4dead",false) || StrEqual(gamename,"left4dead2",false))
	{	// Workaround for bug #4066
		HookEvent("game_start",game_start);
	}
	
	char temp[1024];
	BuildPath(Path_SM,temp,sizeof(temp),"configs/rcon_lock.cfg");
	if (FileExists(temp))
	{
		bCmdLog = false;
	}
	
	HookEvent("player_disconnect",player_disc,EventHookMode_Pre);
}

public Action Cmd_Log(int client, const char[] command, int argc)
{
	if (client != 0) return Plugin_Continue;
	if (argc == 0) return Plugin_Continue;
	
	if (logging)
	{
		PrintToServer("Cannot stop logging right now.");
		return Plugin_Stop;
	}
	
	char arg1[32];
	GetCmdArg(1,arg1,sizeof(arg1));
	
	if (StrEqual(arg1,"on",false))
	{
		logging = true;
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	cvar_pos[client] = 0;
	CreateTimer(5.0, CheckPlayer, client, TIMER_REPEAT);
	CreateTimer(5.0, StartTeleCheck, client, TIMER_REPEAT);
	OnClientSettingsChanged(client);
}

public Action CheckPlayer(Handle timer, any value)
{
	if (!IsClientInGame(value) || IsFakeClient(value)) return Plugin_Stop;
	if (value >= sizeof(cvar_pos)) return Plugin_Stop;
	if (cvar_pos[value] >= sizeof(forbidden_cvars)) return Plugin_Stop;
	
	QueryClientConVar(value, forbidden_cvars[cvar_pos[value]], ConVarDone);
	cvar_pos[value]++;
	if (cvar_pos[value] >= sizeof(forbidden_cvars))
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public int ConVarDone(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if (result != ConVarQuery_Okay && result != ConVarQuery_Protected) return;
	LogMessage("Removing client '%L' as %s=%s",client, cvarName, cvarValue);
	KickClient(client,"Please remove any plugins you are running");
}

public Action game_start(Event event, const char[] name, bool dontBroadcast)
{
	if (!rcon_set) OnConfigsExecuted();
}

public void OnConfigsExecuted()
{
	rcon_set = true;
	GetConVarString(rcon_pw, correct_rcon_pw, sizeof(correct_rcon_pw));
	if (GetConVarInt(mintries) == 5)
	{
		SetConVarInt(mintries,10000);
	}
	if (GetConVarInt(maxtries) == 10)
	{
		SetConVarInt(maxtries,10000);
	}
}

public void rcon_changed(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (rcon_set && !StrEqual(newValue,correct_rcon_pw))
	{
		LogMessage("Rcon password changed to %s, reverting",newValue);
		SetConVarString(rcon_pw,correct_rcon_pw);
	}
}

public Action Cmd_EntCreate(int client, const char[] command, int argc)
{
	char entname[128];
	GetCmdArg(1,entname,sizeof(entname));
	for (int i = 0; i < sizeof(forbidden_ents); i++)
	{
		if (StrEqual(entname,forbidden_ents[i],false))
		{
			LogMessage("Blocking ent_create from '%L', for containing %s", client, forbidden_ents[i]);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Cmd_EntFire(int client, const char[] command, int argc)
{
	char argstring[1024];
	GetCmdArgString(argstring,1024);

	for (int i = 0; i < sizeof(forbidden_cmds); i++)
	{
		if (StrContains(argstring,forbidden_cmds[i],false) != -1)
		{
			LogMessage("Blocking ent_fire from '%L': %s",client, argstring);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Cmd_ChangeLevel(int client, int args)
{
	if (client != 0)
	{
		char argstring[1024];
		GetCmdArgString(argstring,1024);
		LogMessage("Blocking changelevel from '%L': %s",client,argstring);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public void OnClientSettingsChanged(int client)
{
	if (IsFakeClient(client)) return;
	char newname[128];
	GetClientName(client,newname,sizeof(newname));
	if (strlen(newname) == 0)
	{
		LogMessage("Removing client '%L' for not having a name", client);
		KickClient(client,"Please set a name, then rejoin");
	}
	
	bool bad = false;
	for (int i = 0; i < strlen(newname); i++)
	{
		if (newname[i] < 32 || newname[i] == '%')
		{
			bad = true;
			newname[i] = 32;
		}
	}
	
	if (bad)
	{
		SetClientInfo(client,"name",newname);
		LogMessage("Removing client '%L' for having invalid characters in their name",client);
		KickClient(client,"Special characters are not permitted in your name.");
		return;
	}
}

public Action Cmd_Say(int client, const char[] command, int argc)
{
	if (client == 0) return Plugin_Continue;
	if (!IsClientInGame(client) || IsFakeClient(client)) return Plugin_Stop;
	char fulltext[2048];
	GetCmdArgString(fulltext,sizeof(fulltext));
	if (StrContains(fulltext,"\r") != -1 || StrContains(fulltext,"\n") != -1)
	{
		ReplaceString(fulltext,sizeof(fulltext),"\r","");
		ReplaceString(fulltext,sizeof(fulltext),"\n","");
		LogMessage("Client '%L' tried to send a message with newlines.  Message was: %s",client,fulltext);
		PrintToChat(client,"Newlines in messages are not permitted on this server.");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action StartTeleCheck(Handle timer, any value)
{
	if (!IsClientConnected(value) || !IsClientInGame(value)) return Plugin_Stop;
	QueryClientConVar(value, "sensitivity", TeleCheckDone);
	return Plugin_Continue;
}

public int TeleCheckDone(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if (result != ConVarQuery_Okay) return;
	float fValue = StringToFloat(cvarValue);
	if (fValue < 1000.0) return;
	
	LogMessage("Removing client '%L' as sensitivity=%f",client, fValue);
	KickClient(client,"Please lower your sensitivity");
}

public Action HalfConnected(int client, const char[] command, int argc)
{
	char fulltext[2048];
	GetCmdArgString(fulltext,sizeof(fulltext));
	if (client == 0)
	{	
		if (bCmdLog && bServerLog) CmdLog(client,"%s %s",command,fulltext);
		return Plugin_Continue;
	}
	if (StrEqual(command,"menuclosed"))
	{	// the game sends this command very early for some reason
		// it's normal, so we don't want to log it
		return Plugin_Stop;
	}
	if (!IsClientConnected(client))
	{
		LogMessage("Got half-connected command from client %i (ip unknown): %s %s",client,command,fulltext);
		if (bCmdLog) CmdLog(-client,"(half connected) %s %s",command,fulltext);

		return Plugin_Stop;
	}
	if (!IsClientInGame(client))
	{
		char ip[64];
		GetClientIP(client,ip,sizeof(ip));
		LogMessage("Got half-connected command from client %s: %s %s",ip,command,fulltext);
		if (bCmdLog) CmdLog(client,"(half connected) %s %s",command,fulltext);

		return Plugin_Stop;
	}
	if (bCmdLog) CmdLog(client,"%s %s",command,fulltext);

	return Plugin_Continue;	
}

public int CmdLog(int client, const char[] format, any ...)
{
	char log[2048], curtime[128];
	VFormat(log, sizeof(log), format, 3);
	FormatTime(curtime,sizeof(curtime),"%c");
	
	if (client >= 0)
	{
		Format(log,sizeof(log),"%s: %L executes: %s",curtime,client,log);
	}
	else
	{
		Format(log,sizeof(log),"%s: unknown<%i><unknown><> executes: %s",curtime,-client,log);
	}
	
	if (bCmdLog)
	{
		if (cmdLogFile == null)
		{
			char temp[1024];
			FormatTime(temp,sizeof(temp),"%m.%d.%y");
			BuildPath(Path_SM,temp,sizeof(temp),"logs/cmd_%s.log",temp);
			cmdLogFile = OpenFile(temp,"a");
		}
		WriteFileLine(cmdLogFile,"%s",log);
		FlushFile(cmdLogFile);
	}
}

public void OnMapStart()
{
	DeletePlugins();
}

public void OnMapEnd()
{
	DeletePlugins();
	if (cmdLogFile != null)
	{
		CloseHandle(cmdLogFile);
		cmdLogFile = null;
	}
}

int DeletePlugins()
{
	char temp[1024];
	for (int i = 0; i < sizeof(bad_plugins); i++)
	{
		BuildPath(Path_SM,temp,sizeof(temp),"plugins/%s",bad_plugins[i]);
		if (FileExists(temp))
		{
			LogMessage("Deleted malicious plugin %s",bad_plugins[i]);
			DeleteFile(temp);
		}
	}
}

public Action player_disc(Event event, const char[] name, bool dontBroadcast)
{
	SetEventString(event,"reason","");
	return Plugin_Continue;
}