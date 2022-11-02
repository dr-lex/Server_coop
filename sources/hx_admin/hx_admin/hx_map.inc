// SPDX-License-Identifier: GPL-3.0-only
#if defined _hx_map_included
 #endinput
#endif
#define _hx_map_included

/* l4d2_changelevel https://forums.alliedmods.net/showthread.php?p=2669850 */
#define HX_FIXES_LUX 1

#if HX_FIXES_LUX
#include <l4d2_changelevel>
#endif

public int MenuHandler_Map(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char sInfo[24];
		bool found = menu.GetItem(param2, sInfo, sizeof(sInfo)-1);
		if (found && param1)
		{
		#if HX_FIXES_LUX
			L4D2_ChangeLevel(sInfo);
		#else
			ServerCommand("changelevel %s", sInfo);
		#endif
		}
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

void HxMap(int &client)
{
	Menu h3 = new Menu(MenuHandler_Map);
	h3.SetTitle("Сменить карту");

	h3.AddItem("c1m1_hotel",		"Dead Center");
	h3.AddItem("c2m1_highway",		"Dark Carnival");
	h3.AddItem("c3m1_plankcountry",	"Swamp Fever");
	h3.AddItem("c4m1_milltown_a",	"Hard Rain");
	h3.AddItem("c5m1_waterfront",	"The Parish");
	h3.AddItem("c6m1_riverbank",	"The Passing");
	h3.AddItem("c7m1_docks",		"The Sacrifice");
	h3.AddItem("c8m1_apartment",	"No mercy");
	h3.AddItem("c9m1_alleys",		"Crash Course");
	h3.AddItem("c10m1_caves",		"Death Toll");
	h3.AddItem("c11m1_greenhouse",	"Dead air");
	h3.AddItem("c12m1_hilltop",		"Blood Harvest");
	h3.AddItem("c13m1_alpinecreek",	"Cold Stream");
	h3.AddItem("c14m1_junkyard",	"Last Stand");

	h3.ExitButton = true;
	h3.Display(client, 30);
}
