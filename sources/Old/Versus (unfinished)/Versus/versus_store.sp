#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

int ig_slots0[MAXPLAYERS+1];
int ig_slots1[MAXPLAYERS+1];
int ig_slots2[MAXPLAYERS+1];
int ig_slots3[MAXPLAYERS+1];
int ig_slots4[MAXPLAYERS+1];

char sBuffer[64];

public Plugin myinfo = 
{
	name = "[L4D2] Store Versus",
	author = "dr_lex",
	description = "",
	version = "1.0",
	url = "https://steamcommunity.com/id/dr_lex/"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_gun", CMD_Gun);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_team", Event_PlayerTeam);
}

public void OnMapStart() 
{ 
	CheckPrecacheModel("models/weapons/melee/v_bat.mdl");
	CheckPrecacheModel("models/weapons/melee/w_bat.mdl");
	CheckPrecacheModel("models/weapons/melee/v_cricket_bat.mdl");
	CheckPrecacheModel("models/weapons/melee/w_cricket_bat.mdl");
	CheckPrecacheModel("models/weapons/melee/v_crowbar.mdl");
	CheckPrecacheModel("models/weapons/melee/w_crowbar.mdl");
	CheckPrecacheModel("models/weapons/melee/v_electric_guitar.mdl");
	CheckPrecacheModel("models/weapons/melee/w_electric_guitar.mdl");
	CheckPrecacheModel("models/weapons/melee/v_fireaxe.mdl");
	CheckPrecacheModel("models/weapons/melee/w_fireaxe.mdl");
	CheckPrecacheModel("models/weapons/melee/v_frying_pan.mdl");	
	CheckPrecacheModel("models/weapons/melee/w_frying_pan.mdl");
	CheckPrecacheModel("models/weapons/melee/v_golfclub.mdl");	
	CheckPrecacheModel("models/weapons/melee/w_golfclub.mdl");
	CheckPrecacheModel("models/weapons/melee/v_katana.mdl");
	CheckPrecacheModel("models/weapons/melee/w_katana.mdl");
	CheckPrecacheModel("models/v_models/v_knife_t.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_knife_t.mdl");
	CheckPrecacheModel("models/weapons/melee/v_machete.mdl");
	CheckPrecacheModel("models/weapons/melee/w_machete.mdl");
	CheckPrecacheModel("models/weapons/melee/v_tonfa.mdl");	
	CheckPrecacheModel("models/weapons/melee/w_tonfa.mdl");
	CheckPrecacheModel("models/weapons/melee/v_pitchfork.mdl");
	CheckPrecacheModel("models/weapons/melee/w_pitchfork.mdl");
	CheckPrecacheModel("models/weapons/melee/v_shovel.mdl");	
	CheckPrecacheModel("models/weapons/melee/w_shovel.mdl");
	
	CheckPrecacheModel("models/v_models/v_pistola.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_pistol_a.mdl");
	CheckPrecacheModel("models/v_models/v_dual_pistola.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_pistol_b.mdl");
	CheckPrecacheModel("models/v_models/v_desert_eagle.mdl");
	CheckPrecacheModel("models/w_models/weapons/w_desert_eagle.mdl");
	
	int i = 1;
	while (i < MaxClients)
	{
		ig_slots0[i] = 0;
		ig_slots1[i] = 0;
		ig_slots2[i] = 0;
		ig_slots3[i] = 0;
		ig_slots4[i] = 0;
		i += 1;
	}
}

public Action CMD_Gun(int client, int args)
{
	if (client)
	{
		MenuBuy(client);
	}
	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client) 
{ 
	if (client)
	{
		ig_slots0[client] = 0;
		ig_slots1[client] = 0;
		ig_slots2[client] = 0;
		ig_slots3[client] = 0;
		ig_slots4[client] = 0;
	}
} 

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{ 
	int i = 1;
	while (i < MaxClients)
	{
		ig_slots0[i] = 0;
		ig_slots1[i] = 0;
		ig_slots2[i] = 0;
		ig_slots3[i] = 0;
		ig_slots4[i] = 0;
		i += 1;
	}
	return Plugin_Continue;
} 

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client)
	{
		int iTeam = event.GetInt("team");
		if (iTeam == 1)
		{
			PrintToChat(client, "\x05Team: Spectator");
		}
		if (iTeam == 2)
		{
			PrintToChat(client, "\x05Team: Survivor");
			CreateTimer(5.0, HxTimerClientPost, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		if (iTeam == 3)
		{
			PrintToChat(client, "\x05Team: Infected");
		}
		
	}
}

public Action HxTimerClientPost(Handle timer, any client)
{
	if (IsFakeClient(client))
	{
		BotAmmo(client);
	}
	else
	{
		MenuBuy(client);
	}
	return Plugin_Stop;
}

public void BotAmmo(int client) 
{
	char Slot1[64];
	char Slot2[64];
	char Slot3[64];
	char Slot4[64];
	char Slot5[64];
	
	switch(GetRandomInt(1, 6))
	{
		case 1: Slot1 = "rifle";
		case 2: Slot1 = "rifle_desert";
		case 3: Slot1 = "rifle_sg552";
		case 4: Slot1 = "rifle_ak47";
		case 5: Slot1 = "autoshotgun";
		case 6: Slot1 = "shotgun_spas";
	}
	
	switch(GetRandomInt(1, 9))
	{
		case 1: Slot2 = "cricket_bat";
		case 2: Slot2 = "cricket_bat";
		case 3: Slot2 = "crowbar";
		case 4: Slot2 = "electric_guitar";
		case 5: Slot2 = "chainsaw";
		case 6: Slot2 = "shovel";
		case 7: Slot2 = "katana";
		case 8: Slot2 = "knife";
		case 9: Slot2 = "pistol_magnum";
	}
	
	switch(GetRandomInt(1, 3))
	{
		case 1: Slot3 = "molotov";
		case 2: Slot3 = "vomitjar";
		case 3: Slot3 = "pipe_bomb";
	}
	
	switch(GetRandomInt(1, 2))
	{
		case 1: Slot4 = "upgradepack_explosive";
		case 2: Slot4 = "upgradepack_incendiary";
	}
	
	switch(GetRandomInt(1, 2))
	{
		case 1: Slot5 = "pain_pills";
		case 2: Slot5 = "adrenaline";
	}
	
	HxFakeCHEAT(client, "give", Slot1);
	HxFakeCHEAT(client, "give", Slot2);
	HxFakeCHEAT(client, "give", Slot3);
	HxFakeCHEAT(client, "give", Slot4);
	HxFakeCHEAT(client, "give", Slot5);
}

public Action MenuBuy(int client) 
{
	if (HxValidClient(client))
	{
		Menu menu = new Menu(MenuHandler);
		Format(sBuffer, sizeof(sBuffer), "Menu");
		menu.SetTitle(sBuffer);
		if (!ig_slots0[client])
		{
			Format(sBuffer, sizeof(sBuffer), "Weapons");
			menu.AddItem("1", sBuffer);
		}
		if (!ig_slots1[client])
		{
			Format(sBuffer, sizeof(sBuffer), "Melee/Pistols");
			menu.AddItem("2", sBuffer);
		}
		if (!ig_slots2[client])
		{
			Format(sBuffer, sizeof(sBuffer), "Boxes");
			menu.AddItem("3", sBuffer);
		}
		if (!ig_slots3[client])
		{
			Format(sBuffer, sizeof(sBuffer), "Explosives");
			menu.AddItem("4", sBuffer);
		}
		if (!ig_slots4[client])
		{
			Format(sBuffer, sizeof(sBuffer), "Medicines");
			menu.AddItem("5", sBuffer);
		}
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled; 
}

stock int MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(itemNum, info, sizeof(info));
			if (strcmp(info,"1") == 0)
			{
				MenuWeapons(client);
			}
			if (strcmp(info,"2") == 0)
			{
				MenuMeleePistols(client);
			}		
			if (strcmp(info,"3") == 0)
			{
				MenuBoxesAmmo(client);
			}
			if (strcmp(info,"4") == 0)
			{
				MenuExplosives(client);
			}
			if (strcmp(info,"5") == 0)
			{
				MenuMedicines(client);
			}
		}
	}
	return 0;
}

public Action MenuWeapons(int client)
{
	if (HxValidClient(client))
	{
		Menu menu = new Menu(MenuHandlerWeapons);
		Format(sBuffer, sizeof(sBuffer), "Menu");
		menu.SetTitle(sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Smg");
		menu.AddItem("1", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Rifles");
		menu.AddItem("2", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Shotguns");
		menu.AddItem("3", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Snipers");
		menu.AddItem("4", sBuffer);
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

stock int MenuHandlerWeapons(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(itemNum, info, sizeof(info));
			if (strcmp(info,"1") == 0)
			{
				MenuSmg(client);
			}
			if (strcmp(info,"2") == 0)
			{
				MenuRifles(client);
			}
			if (strcmp(info,"3") == 0)
			{
				MenuShotguns(client);
			}
			if (strcmp(info,"4") == 0)
			{
				MenuSnipers(client);
			}
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				MenuBuy(client);
			}
		}
	}
	return 0;
}

public Action MenuMeleePistols(int client)
{
	if (HxValidClient(client))
	{
		Menu menu = new Menu(MenuHandlerMeleePistols);
		Format(sBuffer, sizeof(sBuffer), "Menu");
		menu.SetTitle(sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Melee");
		menu.AddItem("1", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Pistols");
		menu.AddItem("2", sBuffer);
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

public int MenuHandlerMeleePistols(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(itemNum, info, sizeof(info));
			if (strcmp(info,"1") == 0)
			{
				MenuMelee(client);
			}
			if (strcmp(info,"2") == 0)
			{
				MenuPistols(client);
			}
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				MenuBuy(client);
			}
		}
	}
	return 0;
}

public Action MenuSmg(int client)
{
	if (HxValidClient(client))
	{
		Menu menu = new Menu(MenuHandlerSmg);
		Format(sBuffer, sizeof(sBuffer), "Menu");
		menu.SetTitle(sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Submachine Gun (smg)");
		menu.AddItem("1", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Silenced Submachine Gun (smg_silenced)");
		menu.AddItem("2", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "H&K MP5 (smg_mp5)");
		menu.AddItem("3", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Submachine Gun (smg) Skin #1");
		menu.AddItem("4", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Silenced Submachine Gun (smg_silenced) Skin #1");
		menu.AddItem("5", sBuffer);
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

public int MenuHandlerSmg(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			ig_slots0[client] = 1;
			char info[32];
			menu.GetItem(itemNum, info, sizeof(info));
			if (strcmp(info,"1") == 0)
			{
				HxFakeCHEAT(client, "give", "smg");
			}
			if (strcmp(info,"2") == 0)
			{
				HxFakeCHEAT(client, "give", "smg_silenced");
			}
			if (strcmp(info,"3") == 0)
			{
				HxFakeCHEAT(client, "give", "smg_mp5");
			}
			if (strcmp(info,"4") == 0)
			{
				HxFakeCHEAT(client, "give", "smg");
				int iSlot0 = GetPlayerWeaponSlot(client, 0);
				if (iSlot0 > 0)
				{
					SetEntProp(iSlot0, Prop_Send, "m_nSkin", 1, 4);
				}
			}
			if (strcmp(info,"5") == 0)
			{
				HxFakeCHEAT(client, "give", "smg_silenced");
				int iSlot0 = GetPlayerWeaponSlot(client, 0);
				if (iSlot0 > 0)
				{
					SetEntProp(iSlot0, Prop_Send, "m_nSkin", 1, 4);
				}
			}
			MenuBuy(client);
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				MenuWeapons(client);
			}
		}
	}
	return 0;
}

public Action MenuRifles(int client)
{
	if (HxValidClient(client))
	{
		Menu menu = new Menu(MenuHandlerRifles);
		Format(sBuffer, sizeof(sBuffer), "Menu");
		menu.SetTitle(sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "M-16 Assault Rifle");
		menu.AddItem("1", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Desert Rifle");
		menu.AddItem("2", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "SIG SG552");
		menu.AddItem("3", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "AK-47");
		menu.AddItem("4", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "M-16 Assault Rifle Skin #1");
		menu.AddItem("5", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "M-16 Assault Rifle Skin #2");
		menu.AddItem("6", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "AK-47 Skin #1");
		menu.AddItem("7", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "AK-47 Skin #2");
		menu.AddItem("8", sBuffer);
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

public int MenuHandlerRifles(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			ig_slots0[client] = 1;
			char info[32];
			menu.GetItem(itemNum, info, sizeof(info));
			if (strcmp(info,"1") == 0)
			{
				HxFakeCHEAT(client, "give", "rifle");
			}
			if (strcmp(info,"2") == 0)
			{
				HxFakeCHEAT(client, "give", "rifle_desert");
			}
			if (strcmp(info,"3") == 0)
			{
				HxFakeCHEAT(client, "give", "rifle_sg552");
			}
			if (strcmp(info,"4") == 0)
			{
				HxFakeCHEAT(client, "give", "rifle_ak47");
			}
			if (strcmp(info,"5") == 0)
			{
				HxFakeCHEAT(client, "give", "rifle");
				int iSlot0 = GetPlayerWeaponSlot(client, 0);
				if (iSlot0 > 0)
				{
					SetEntProp(iSlot0, Prop_Send, "m_nSkin", 1, 4);
				}
			}
			if (strcmp(info,"6") == 0)
			{
				HxFakeCHEAT(client, "give", "rifle");
				int iSlot0 = GetPlayerWeaponSlot(client, 0);
				if (iSlot0 > 0)
				{
					SetEntProp(iSlot0, Prop_Send, "m_nSkin", 2, 4);
				}
			}
			if (strcmp(info,"7") == 0)
			{
				HxFakeCHEAT(client, "give", "rifle_ak47");
				int iSlot0 = GetPlayerWeaponSlot(client, 0);
				if (iSlot0 > 0)
				{
					SetEntProp(iSlot0, Prop_Send, "m_nSkin", 1, 4);
				}
			}
			if (strcmp(info,"8") == 0)
			{
				HxFakeCHEAT(client, "give", "rifle_ak47");
				int iSlot0 = GetPlayerWeaponSlot(client, 0);
				if (iSlot0 > 0)
				{
					SetEntProp(iSlot0, Prop_Send, "m_nSkin", 2, 4);
				}
			}
			MenuBuy(client);
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				MenuWeapons(client);
			}
		}
	}
	return 0;
}

public Action MenuShotguns(int client)
{
	if (HxValidClient(client))
	{
		Menu menu = new Menu(MenuHandlerShotguns);
		Format(sBuffer, sizeof(sBuffer), "Menu");
		menu.SetTitle(sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Pump Shotgun (pumpshotgun)");
		menu.AddItem("1", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Chrome Shotgun (shotgun_chrome)");
		menu.AddItem("2", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Auto-Shotgun (autoshotgun)");
		menu.AddItem("3", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Franchi SPAS-12 (shotgun_spas)");
		menu.AddItem("4", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Pump Shotgun (pumpshotgun) Skin #1");
		menu.AddItem("5", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, " Chrome Shotgun (shotgun_chrome) Skin #1");
		menu.AddItem("6", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Auto-Shotgun (autoshotgun) Skin #1");
		menu.AddItem("7", sBuffer);
		
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

public int MenuHandlerShotguns(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			ig_slots0[client] = 1;
			char info[32];
			menu.GetItem(itemNum, info, sizeof(info));
			if (strcmp(info,"1") == 0)
			{
				HxFakeCHEAT(client, "give", "pumpshotgun");
			}
			if (strcmp(info,"2") == 0)
			{
				HxFakeCHEAT(client, "give", "shotgun_chrome");
			}
			if (strcmp(info,"3") == 0)
			{
				HxFakeCHEAT(client, "give", "autoshotgun");
			}
			if (strcmp(info,"4") == 0)
			{
				HxFakeCHEAT(client, "give", "shotgun_spas");
			}
			if (strcmp(info,"5") == 0)
			{
				HxFakeCHEAT(client, "give", "pumpshotgun");
				int iSlot0 = GetPlayerWeaponSlot(client, 0);
				if (iSlot0 > 0)
				{
					SetEntProp(iSlot0, Prop_Send, "m_nSkin", 1, 4);
				}
			}
			if (strcmp(info,"6") == 0)
			{
				HxFakeCHEAT(client, "give", "shotgun_chrome");
				int iSlot0 = GetPlayerWeaponSlot(client, 0);
				if (iSlot0 > 0)
				{
					SetEntProp(iSlot0, Prop_Send, "m_nSkin", 1, 4);
				}
			}
			if (strcmp(info,"7") == 0)
			{
				HxFakeCHEAT(client, "give", "autoshotgun");
				int iSlot0 = GetPlayerWeaponSlot(client, 0);
				if (iSlot0 > 0)
				{
					SetEntProp(iSlot0, Prop_Send, "m_nSkin", 1, 4);
				}
			}
			MenuBuy(client);
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				MenuWeapons(client);
			}
		}
	}
	return 0;
}

public Action MenuSnipers(int client)
{
	if (HxValidClient(client))
	{
		Menu menu = new Menu(MenuHandlerSnipers);
		Format(sBuffer, sizeof(sBuffer), "Menu");
		menu.SetTitle(sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Hunting Rifle");
		menu.AddItem("1", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Hunting Rifle Skin #1");
		menu.AddItem("2", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Sniper Rifle");
		menu.AddItem("3", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Steyr Scout (Scout)");
		menu.AddItem("4", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "AWSM (AWP)");
		menu.AddItem("5", sBuffer);
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

public int MenuHandlerSnipers(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			ig_slots0[client] = 1;
			char info[32];
			menu.GetItem(itemNum, info, sizeof(info));
			if (strcmp(info,"1") == 0)
			{
				HxFakeCHEAT(client, "give", "hunting_rifle");
			}
			if (strcmp(info,"2") == 0)
			{
				HxFakeCHEAT(client, "give", "hunting_rifle");
				int iSlot0 = GetPlayerWeaponSlot(client, 0);
				if (iSlot0 > 0)
				{
					SetEntProp(iSlot0, Prop_Send, "m_nSkin", 1, 4);
				}
			}
			if (strcmp(info,"3") == 0)
			{
				HxFakeCHEAT(client, "give", "sniper_military");
			}
			if (strcmp(info,"4") == 0)
			{
				HxFakeCHEAT(client, "give", "sniper_scout");
			}
			if (strcmp(info,"5") == 0)
			{
				HxFakeCHEAT(client, "give", "sniper_awp");
			}
			MenuBuy(client);
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				MenuWeapons(client);
			}
		}
	}
	return 0;
}

public Action MenuMelee(int client)
{
	if (HxValidClient(client))
	{
		Menu menu = new Menu(MenuHandlerMelee);
		Format(sBuffer, sizeof(sBuffer), "Menu");
		menu.SetTitle(sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Cricket Bat (cricket_bat)");
		menu.AddItem("1", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Cricket Bat (cricket_bat) Skin #2");
		menu.AddItem("2", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Crowbar (сrowbar)");
		menu.AddItem("3", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Crowbar (сrowbar) Skin #2");
		menu.AddItem("4", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Guitar (electric_guitar)");
		menu.AddItem("5", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Chainsaw");
		menu.AddItem("6", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Katana");
		menu.AddItem("7", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Machete");
		menu.AddItem("8", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Tonfa");
		menu.AddItem("9", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Frying Pan (frying_pan)");
		menu.AddItem("10", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Axe (fireaxe)");
		menu.AddItem("11", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Baseball Bat (baseball_bat)");
		menu.AddItem("12", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Combat Knife (knife))");
		menu.AddItem("13", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Golf Club (golfclub)");
		menu.AddItem("14", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Pitchfork (pitchfork)");
		menu.AddItem("15", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Shovel (shovel)");
		menu.AddItem("16", sBuffer);
		
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}


public int MenuHandlerMelee(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			ig_slots1[client] = 1;
			char info[32];
			menu.GetItem(itemNum, info, sizeof(info));
			if (strcmp(info,"1") == 0)
			{
				HxFakeCHEAT(client, "give", "cricket_bat");
			}
			if (strcmp(info,"2") == 0)
			{
				HxFakeCHEAT(client, "give", "cricket_bat");
				int iSlot1 = GetPlayerWeaponSlot(client, 1);
				if (iSlot1 > 0)
				{
					SetEntProp(iSlot1, Prop_Send, "m_nSkin", 1, 4);
				}
			}
			if (strcmp(info,"3") == 0)
			{
				HxFakeCHEAT(client, "give", "crowbar");
			}
			if (strcmp(info,"4") == 0)
			{
				HxFakeCHEAT(client, "give", "crowbar");
				int iSlot1 = GetPlayerWeaponSlot(client, 1);
				if (iSlot1 > 0)
				{
					SetEntProp(iSlot1, Prop_Send, "m_nSkin", 1, 4);
				}
			}
			if (strcmp(info,"5") == 0)
			{
				HxFakeCHEAT(client, "give", "electric_guitar");
			}
			if (strcmp(info,"6") == 0)
			{
				HxFakeCHEAT(client, "give", "chainsaw");
			}
			if (strcmp(info,"7") == 0)
			{
				HxFakeCHEAT(client, "give", "katana");
			}
			if (strcmp(info,"8") == 0)
			{
				HxFakeCHEAT(client, "give", "machete");
			}
			if (strcmp(info,"9") == 0)
			{
				HxFakeCHEAT(client, "give", "tonfa");
			}
			if (strcmp(info,"10") == 0)
			{
				HxFakeCHEAT(client, "give", "frying_pan");
			}
			if (strcmp(info,"11") == 0)
			{
				HxFakeCHEAT(client, "give", "fireaxe");
			}
			if (strcmp(info,"12") == 0)
			{
				HxFakeCHEAT(client, "give", "baseball_bat");
			}
			if (strcmp(info,"13") == 0)
			{
				HxFakeCHEAT(client, "give", "knife");
			}
			if (strcmp(info,"14") == 0)
			{
				HxFakeCHEAT(client, "give", "golfclub");
			}
			if (strcmp(info,"15") == 0)
			{
				HxFakeCHEAT(client, "give", "pitchfork");
			}
			if (strcmp(info,"16") == 0)
			{
				HxFakeCHEAT(client, "give", "shovel");
			}
			MenuBuy(client);
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				MenuMeleePistols(client);
			}
		}
	}
	return 0;
}

public Action MenuPistols(int client)
{
	if (HxValidClient(client))
	{
		Menu menu = new Menu(MenuHandlerPistols);
		Format(sBuffer, sizeof(sBuffer), "Menu");
		menu.SetTitle(sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Pistol");
		menu.AddItem("1", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Pistol Magnum (Desert Eagle)");
		menu.AddItem("2", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Pistol Magnum (Desert Eagle) Skin #1");
		menu.AddItem("3", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Pistol Magnum (Desert Eagle) Skin #2");
		menu.AddItem("4", sBuffer);
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

public int MenuHandlerPistols(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			ig_slots1[client] = 1;
			char info[32];
			menu.GetItem(itemNum, info, sizeof(info));
			if (strcmp(info,"1") == 0)
			{
				HxFakeCHEAT(client, "give", "pistol");
			}
			if (strcmp(info,"2") == 0)
			{
				HxFakeCHEAT(client, "give", "pistol_magnum");
			}
			if (strcmp(info,"3") == 0)
			{
				HxFakeCHEAT(client, "give", "pistol_magnum");
				int iSlot0 = GetPlayerWeaponSlot(client, 0);
				if (iSlot0 > 0)
				{
					SetEntProp(iSlot0, Prop_Send, "m_nSkin", 1, 4);
				}
			}
			if (strcmp(info,"4") == 0)
			{
				HxFakeCHEAT(client, "give", "pistol_magnum");
				int iSlot1 = GetPlayerWeaponSlot(client, 1);
				if (iSlot1 > 0)
				{
					SetEntProp(iSlot1, Prop_Send, "m_nSkin", 2, 4);
				}
			}
			MenuBuy(client);
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				MenuMeleePistols(client);
			}
		}
	}
	return 0;
}

public Action MenuBoxesAmmo(int client)
{
	if (HxValidClient(client))
	{
		Menu menu = new Menu(MenuHandlerBoxesAmmo);
		Format(sBuffer, sizeof(sBuffer), "Menu");
		menu.SetTitle(sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Explosive Ammo");
		menu.AddItem("1", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Incendiary Ammo");
		menu.AddItem("2", sBuffer);
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

public int MenuHandlerBoxesAmmo(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			ig_slots2[client] = 1;
			char info[32];
			menu.GetItem(itemNum, info, sizeof(info));
			if (strcmp(info,"1") == 0)
			{
				HxFakeCHEAT(client, "give", "upgradepack_explosive");
			}
			if (strcmp(info,"2") == 0)
			{
				HxFakeCHEAT(client, "give", "upgradepack_incendiary");
			}
			MenuBuy(client);
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				MenuBuy(client);
			}
		}
	}
	return 0;
}

public Action MenuExplosives(int client)
{
	if (HxValidClient(client))
	{
		Menu menu = new Menu(MenuHandlerExplosives);
		Format(sBuffer, sizeof(sBuffer), "Menu");
		menu.SetTitle(sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Molotov cocktail (molotov)");
		menu.AddItem("1", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Bile bomb (vomitjar)");
		menu.AddItem("2", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Pipe bomb (pipe_bomb)");
		menu.AddItem("3", sBuffer);
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

public int MenuHandlerExplosives(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			ig_slots3[client] = 1;
			char info[32];
			menu.GetItem(itemNum, info, sizeof(info));
			if (strcmp(info,"1") == 0)
			{
				HxFakeCHEAT(client, "give", "molotov");
			}
			if (strcmp(info,"2") == 0)
			{
				HxFakeCHEAT(client, "give", "vomitjar");
			}
			if (strcmp(info,"3") == 0)
			{
				HxFakeCHEAT(client, "give", "pipe_bomb");
			}
			MenuBuy(client);
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				MenuBuy(client);
			}
		}
	}
	return 0;
}

public Action MenuMedicines(int client)
{
	if (HxValidClient(client))
	{
		Menu menu = new Menu(MenuHandlerMedicines);
		Format(sBuffer, sizeof(sBuffer), "Menu");
		menu.SetTitle(sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Pain Pills");
		menu.AddItem("1", sBuffer);
		Format(sBuffer, sizeof(sBuffer)-1, "Adrenaline");
		menu.AddItem("2", sBuffer);
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

public int MenuHandlerMedicines(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			ig_slots4[client] = 1;
			char info[32];
			menu.GetItem(itemNum, info, sizeof(info));
			if (strcmp(info,"1") == 0)
			{
				HxFakeCHEAT(client, "give", "pain_pills");
			}
			if (strcmp(info,"2") == 0)
			{
				HxFakeCHEAT(client, "give", "adrenaline");
			}
			MenuBuy(client);
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				MenuBuy(client);
			}
		}
	}
	return 0;
}

stock int HxValidClient(int &i)
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

stock void HxFakeCHEAT(int &client, char[] sCmd, char[] sArg)
{
	int iFlags = GetCommandFlags(sCmd);
	SetCommandFlags(sCmd, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", sCmd, sArg);
	SetCommandFlags(sCmd, iFlags);
}

stock void CheckPrecacheModel(const char[] Model)
{
	if (!IsModelPrecached(Model))
	{
		PrecacheModel(Model);
	}
}