#include "td.qh"

#ifdef GAMEQC
bool td_badplacement(entity this, Turret tur, vector org)
{
	// check for nearby turrets/towers/spawns
	bool bad = false;
	FOREACH_ENTITY_RADIUS(org, vlen(tur.m_mins - tur.m_maxs) + 64, true,
	{
		if(it.turretdef || it.classname == "td_chest" || it.classname == "td_tower" || it.classname == "td_spawnpoint")
		{
			// skip non-solid turrets if they're not matching
			if(it.turretdef != tur && (it.solid != SOLID_BBOX || (tur.spawnflags & TUR_FLAG_NONSOLID)))
				continue;

			vector extrasize = '0 0 0';
			if(it.classname == "td_tower")
				extrasize = '256 256 256'; // not close thank you
			else if(it.classname == "td_spawnpoint")
				extrasize = '512 512 512'; // spawnpoints have no size
			if(boxesoverlap(org + tur.m_mins, org + tur.m_maxs, it.absmin - extrasize, it.absmax + extrasize))
			{
				bad = true;
				break;
			}
		}
	});
	return bad;
}
#endif
