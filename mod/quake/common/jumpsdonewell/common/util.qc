#include "util.qh"

#ifdef GAMEQC
bool IsJumpsDoneWell()
{
#ifdef SVQC
	return (autocvar_sv_worldbasename == "map2");
#elif defined(CSQC)
	return (autocvar_cl_worldbasename == "map2");
#else
	return false;
#endif
}
#endif
