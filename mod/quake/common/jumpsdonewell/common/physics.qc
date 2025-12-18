#ifdef SVQC
	#include "../server/combat.qh"
#endif

#ifdef SVQC
void JDW_PM_UpdateButtons(entity this);
void JDW_Physics_UpdateStats(entity this)
{
	if(IS_REAL_CLIENT(this))
		JDW_PM_UpdateButtons(this);

	STAT(PL_VIEW_OFS, this) = STAT(PL_CROUCH_VIEW_OFS, this) = '0 0 48';

	STAT(PL_MIN, this) = STAT(PL_CROUCH_MIN, this) = '-16 -16 0';
	STAT(PL_MAX, this) = STAT(PL_CROUCH_MAX, this) = '16 16 64';

	if(this.mins != STAT(PL_MIN, this) || this.maxs != STAT(PL_MAX, this))
	{
		tracebox(this.origin, STAT(PL_MIN, this), STAT(PL_MAX, this), this.origin, MOVE_NORMAL, this);
		if (!trace_startsolid)
			setsize(this, STAT(PL_MIN, this), STAT(PL_MAX, this));
		else
		{
			STAT(PL_MIN, this) = STAT(PL_CROUCH_MIN, this) = this.mins;
			STAT(PL_MAX, this) = STAT(PL_CROUCH_MAX, this) = this.maxs;
		}
	}
}
#endif

void do_jump(entity this)
{
	if(STAT(JUMPS, this) <= 0)
		return;
	this.velocity.z = 420;
	SET_JUMP_HELD(this);
#ifdef SVQC
	STAT(JUMPS, this) -= 1;
	this.frame = 2;
	_sound(this, CHAN_AUTO, "jump.wav", 0.75, ATTEN_NORM);
	pointparticles(EFFECT_WEAPON_JUMP, this.origin + '0 0 16', '0 0 40', 1);
#endif
}

const float COYOTE_TIME = 0.15;
const float PRELAND_TIME = 0.15;
void JDW_PM_Main(entity this, float dt)
{
	if(PHYS_HEALTH(this) <= 0)
		return;
	
	vector forward, right, up;
	MAKE_VECTORS(vmul(PHYS_INPUT_ANGLES(this), '1 1 0'), forward, right, up);
	vector moveval;
	if(getworldbasename() == "map2")
	{
		moveval = PHYS_INPUT_MOVEVALUES(this);
		moveval.y *= -1;
	}
	else
		moveval = vec2(forward * PHYS_INPUT_MOVEVALUES(this).x + right * PHYS_INPUT_MOVEVALUES(this).y);

	//if(vdist(moveval, >, 350))
		//moveval = normalize(moveval) * 350;
	//moveval.y *= (time > STAT(ATTACK_FINISHED, this)) ? -1 : -0.4;
	if(STAT(NO_CONTROL_TIME, this) <= time)
	{
		float vel_z = this.velocity_z;
		float wishspeed = 350;
		if(STAT(ATTACK_FINISHED, this) > time && IS_ONGROUND(this))
			wishspeed *= 0.4;
		vector vel_xy = normalize(moveval) * wishspeed;
		this.velocity = vel_xy + vel_z * '0 0 1';
	}
	//this.velocity = (STAT(NO_CONTROL_TIME, this) > time) ? this.velocity : moveval + vec3(0, 0, this.velocity.z);
#ifdef SVQC
	//this.fixangle = true;
#endif

	if(PHYS_INPUT_BUTTON_JUMP(this) && !IS_JUMP_HELD(this) && time > STAT(NO_CONTROL_TIME, this))
	{
#ifdef SVQC
		if(!IS_JUMP_HELD(this))
			STAT(JUMP_PRESSED_TIME, this) = time;
#endif
		SET_JUMP_HELD(this);
		if(time - STAT(ON_GROUND_TIME, this) < COYOTE_TIME && this.velocity.z <= 0)
			do_jump(this);
		else if(STAT(JUMPS, this) > 0 && STAT(JUMPS, this) < STAT(FEATHER, this))
			do_jump(this);
	}

	if(!PHYS_INPUT_BUTTON_JUMP(this))
	{
		UNSET_JUMP_HELD(this);
#ifdef SVQC
		STAT(JUMP_PRESSED_TIME, this) = 0;
#endif
	}

	// Check ground
	if(!IS_ONGROUND(this))
	{
		// Player is not on a proper footing
#ifdef SVQC
		if(this.velocity_z <= 0 && time - STAT(ON_GROUND_TIME, this) > COYOTE_TIME) // walked from edge, take away first jump
			STAT(JUMPS, this) = min(STAT(JUMPS, this), STAT(FEATHER, this) - 1);
#endif
	}
	else if(this.velocity_z <= 0)
	{
		// Player is on ground
#ifdef SVQC
		STAT(ON_GROUND_TIME, this) = time;
		STAT(JUMPS, this) = STAT(FEATHER, this);
#endif
		
		if(time - STAT(JUMP_PRESSED_TIME, this) < PRELAND_TIME)
			do_jump(this);
	}
}

#ifdef SVQC
float turn_angle(float a, float b, float amount)
{
	a = anglemods(a);
	b = anglemods(b);
	float diff = b - a;
	
	if (fabs(diff) < amount)
	{
		return b;
	}
	
	if (diff < -180)
	{
		b += 360;	
	}
	else if (diff > 180)
	{
		b -= 360;
	}
	
	if (fabs(b - a) < amount)
	{
		return b;
	}
	if (a < b)
		return a + amount;
	else
		return a - amount;	
}

.float playery;
void CSQCPlayer_SmoothAngle(entity this)
{
	if(time < STAT(NO_CONTROL_TIME, this))
		return;

	if(vdist(vec2(this.velocity), >, 0))
	{
		vector wanted_angles = vectoangles(vec2(this.velocity));
		float framescale = ((IS_ONGROUND(this)) ? 1200 : 500);

		this.playery = turn_angle(this.playery, wanted_angles_y, PHYS_INPUT_TIMELENGTH * framescale);
	}

	this.angles.y = this.playery;
}

void JDW_PM_UpdateButtons(entity this)
{
	if(getworldbasename() != "map2")
	{
		CSQCPlayer_SmoothAngle(this);
		return;
	}

	vector moveval = this.movement;
	moveval.y *= -1;
	vector real_angles = vec3(0, this.playery, 0);
	if(vdist(moveval, >, 0))
		real_angles = vectoangles(moveval);
	this.playery = real_angles.y;
	this.v_angle = vec3(0, real_angles.y, 0);
	this.angles_y = real_angles.y;
}
#endif
