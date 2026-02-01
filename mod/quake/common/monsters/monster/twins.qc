#include "twins.qh"

// NOTE: this is a "fake" monster and a massive hack!
// unfortunately it's the only way currently to create a multi-boss...

#include "retinazer.qh"
#include "spazmatism.qh"

#ifdef SVQC
spawnfunc(monster_twins)
{
	monster_start(this, true, MON_TWINS);
}
#endif // SVQC

#ifdef SVQC
METHOD(Twins, mr_setup, bool(Twins this, entity actor))
{
	TC(Twins, this);

	entity spaz = controller_create(actor, spawn(), MON_SPAZMATISM);
	entity ret = controller_create(actor, spawn(), MON_RETINAZER);

	// for access to the tether
	spaz.buddy = ret;
	ret.buddy = spaz;

	tether_setup(spaz, ret, TETHER_FLESH, 9);

	return true;
}
#endif
