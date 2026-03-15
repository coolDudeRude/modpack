#include "gametypes.qh"

#ifdef SVQC
void SetGametype()
{
	gametype = GAMETYPE_NONE;

	// HACK: abuse the spawn queue to tell if horde entities exist this early
	bool found_horde = false;
	bool found_td = false;
	IL_EACH(g_spawn_queue, true,
	{
		if(it.__spawnfunc_classname == "horde_manager" || it.__spawnfunc_classname == "info_qonquer")
			found_horde = true;
		if(it.__spawnfunc_classname == "td_manager")
			found_td = true;
	});

	if(found_horde && !deathmatch)
	{
		// return outside the loop to prevent issues
		gametype = GAMETYPE_HORDE;
		return;
	}
	else if(found_td)
	{
		gametype = GAMETYPE_TD;
		return;
	}
	else if(world.worldtype == WORLDTYPE_SKATE)
	{
		gametype = GAMETYPE_SKATE;
		return;
	}
	else if(world.worldtype == WORLDTYPE_DODGEBALL)
	{
		gametype = GAMETYPE_DODGEBALL;
		return;
	}
	else if(world.worldtype == WORLDTYPE_SLIDE)
	{
		gametype = GAMETYPE_SLIDE;
		return;
	}
	else if(world.model == "maps/map2.bsp")
	{
		gametype = GAMETYPE_JUMPSDONEWELL;
		return;
	}
	else if(deathmatch && autocvar_skill == 3)
	{
		// deathmatch itself doesn't have a gametype
		// as it may be enabled as a pvp option
		gametype = GAMETYPE_INSTAGIB;
		return;
	}
}
#endif
