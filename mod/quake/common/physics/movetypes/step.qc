#include "step.qh"

void _Movetype_Physics_Step(entity this, float dt) // SV_Physics_Step
{
	// don't fall at all if fly/swim
	if((this.flags & FL_FLY) || (this.flags & FL_SWIM))
		return;

	if(IS_ONGROUND(this))
	{
		if(this.velocity_z >= (1.0 / 32.0) && UPWARD_VELOCITY_CLEARS_ONGROUND(this))
		{
			UNSET_ONGROUND(this);
			_Movetype_FlyMove(this, dt, true, false, 0);
			_Movetype_LinkEdict(this, true);
		}
	}
	else
	{
		_Movetype_FlyMove(this, dt, true, false, 0);
		_Movetype_LinkEdict(this, true);

		// TODO? movetypesteplandevent
	}

	_Movetype_CheckWaterTransition(this);
}
