#include <sourcemod>
#pragma newdecls required

bool NoSpam[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "No spawn near safe room door.",
	author = "Eyal282 ( FuckTheSchool )",
	description = "To prevent a player breaching safe room door with a bug, prevents him from spawning near safe room door. The minimum distance is proportionate to his speed ",
	version = "1.3",
	url = "https://forums.alliedmods.net/showthread.php?p=2520740"
}

public void OnClientPutInServer(int client)
{
	NoSpam[client] = false;
}

public Action OnPlayerRunCmd(int SInfected, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	// Player is not attacking.
	if (!(buttons & IN_ATTACK))
	{
		return Plugin_Continue;
	}
	
	// Player is either a bot, not infected or not a ghost.
	if (GetClientTeam(SInfected) != 3 || IsFakeClient(SInfected) || GetEntProp(SInfected, Prop_Send, "m_isGhost") != 1)
	{
		return Plugin_Continue;
	}

	// Being a ghost, the player can not spawn ( seen / close / blocked etc... )
	if (GetEntProp(SInfected, Prop_Send, "m_ghostSpawnState") != 0)
	{
		return Plugin_Continue;
	}
	
	int EntityCount = GetEntityCount();
	for (int Door = MaxClients; Door < EntityCount; Door++) // https://forums.alliedmods.net/showpost.php?p=2502446&postcount=2
	{
		if (IsValidEntity(Door) && IsValidEdict(Door))
		{
			char Classname[100];
			GetEdictClassname(Door, Classname, sizeof(Classname));
			if (strcmp(Classname, "prop_door_rotating_checkpoint") != 0 ) // Found the classname from l4d_loading: https://forums.alliedmods.net/showthread.php?p=836849
			{
				continue;
			}
			
			float SInfectedOrigin[3], DoorOrigin[3], SInfectedVelocity[3];
			GetEntPropVector(SInfected, Prop_Send, "m_vecOrigin", SInfectedOrigin);
			GetEntPropVector(Door, Prop_Send, "m_vecOrigin", DoorOrigin);
			GetEntPropVector(SInfected, Prop_Data, "m_vecVelocity", SInfectedVelocity);
			float Speed = GetVectorLength(SInfectedVelocity);
			float Distance = GetVectorDistance(SInfectedOrigin, DoorOrigin);
			
			// Player has too much speed vs distance from door.
			if (Distance < Speed / 1.5) // Tested and the 1.5 division will not assist the use of the bug.
			{
				if (!NoSpam[SInfected])
				{
					PrintToChat(SInfected, "You can't spawn near safe room doors.");
					NoSpam[SInfected] = true;
					CreateTimer(2.5, AllowMessageAgain, GetClientUserId(SInfected));
				}
				buttons &= ~IN_ATTACK;
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}

public Action AllowMessageAgain(Handle Timer, int UserId)
{
	int SInfected = GetClientOfUserId(UserId);
	
	if (!IsClientInGame(SInfected))
	{
		return Plugin_Continue;
	}
	NoSpam[SInfected] = false;
	return Plugin_Continue;
}