#include "util.qh"

#ifdef GAMEQC
string getworldbasename()
{
#ifdef SVQC
	return cvar_string("sv_worldbasename");
#else
	return cvar_string("cl_worldbasename");
#endif
}

bool IsJumpsDoneWell()
{
	return (world.model == "maps/map2.bsp");
}

// a hack needed for map-specific content
bool is_qbj3map = false; // cached due reduce substring calls
STATIC_INIT(MapSpecific)
{
	string wname = substring(world.model, 0, 10);
	if(wname == "maps/qbj3_" || wname == "maps/qbjr_")
		is_qbj3map = true;
}

bool IsQBJ3Map()
{
	//string wname = substring(world.model, 0, 10);
	//return (wname == "maps/qbj3_" || wname == "maps/qbjr_");
	return is_qbj3map;
}
#endif
