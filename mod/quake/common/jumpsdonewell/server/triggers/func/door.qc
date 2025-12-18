#include "door.qh"

#ifdef SVQC
void JDW_func_door(entity this)
{
	this.solid = SOLID_BSP;
	_setmodel(this, this.model);
}
#endif
