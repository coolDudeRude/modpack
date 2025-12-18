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
#endif
