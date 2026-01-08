#include "instateleport.qh"

#include "teleport.qh"

#ifdef SVQC
//const int PLAYER_ONLY = 1;
//const int SILENT = 2;
const int TELE_STEALTH = 4;
//const int TELE_MONSTER_ONLY = 8;
const int TELE_PLAYERTRIGGERED = 16;

//const int TELEPORT_STYLE_FIRST = 0;
//const int TELEPORT_STYLE_RANDOM = 1;
//const int TELEPORT_STYLE_CYCLE = 2;

const int TELEDEST_KEEPANGLE = 1;
const int TELEDEST_KEEPPITCH = 2;
const int TELEDEST_STEALTH = 4;
const int TELEDEST_KEEPVELOCITY = 8;
const int TELEDEST_KEEPANGLE_NOOFFSET = 16;
const int TELEDEST_DONTDROP = 32;

const int TELEDEST_STYLE_NORMAL = 0;
const int TELEDEST_STYLE_INSTANT = 1;

// high precision vectoyaw/atan2
float vectoyaw2(vector vec)
{
	float b = 0.596227;

	// Extract the sign bits
	float ux_s = vec.x < 0 ? -1 : 1;
	float uy_s = vec.y < 0 ? -1 : 1;

	// Determine the quadrant offset
	float q;
	if(ux_s >= 0 && uy_s >= 0)
		q = 0;
	else if(ux_s < 0 && uy_s >= 0)
		q = 1;
	else if(ux_s < 0 && uy_s < 0)
		q = 2;
	else
		q = 3;

	// Calculate the arctangent in the first quadrant
	float bxy_a = fabs(b * vec.x * vec.y);
	float num = bxy_a + vec.y * vec.y;
	float atan_1q =  num / (vec.x * vec.x + bxy_a + num);

	// Translate it to the proper quadrant
	float uatan_2q = ux_s < 0 ? 1 - atan_1q : atan_1q;
	if(q >= 2)
		uatan_2q = 1 - uatan_2q;
	return (q + uatan_2q) * 90;
}

// high precision vectoangles
vector vectoangles_precise(vector vec)
{
	float yaw, forward, pitch;
	
	if(vec.x == 0 && vec.y == 0)
	{
		yaw = 0;
		if(vec.z > 0)
			pitch = 90;
		else
			pitch = 270;
	}
	else
	{
		yaw = vectoyaw2(vec);
		forward = vlen(vec2(vec));
		pitch = vectoyaw2(vec3(forward, vec.z, 0));
	}
	return vec3(pitch, yaw, 0);
}

//=================================================================================================

void instateleport_use(entity this, entity actor, entity trigger);

void instateleport_touch(entity this, entity toucher)
{
	//if(toucher.flags & FL_NEVERTELEPORT)
	//	return;

	if(toucher.solid == SOLID_BSP)
		return;

	if(this.customflags & CFL_LOCKED)
		return;
	
	if(toucher.solid == SOLID_TRIGGER)
		return;

	if(toucher.move_movetype == MOVETYPE_NOCLIP)
		return;

	if((this.spawnflags & TELEPORT_NOTRIGGER) == 0)
	if(this.targetname && this.targetname != "")
	if((this.spawnflags & TELEPORT_TRIGGER_FIRST) == 0) // not trigger first
	if(this.attack_finished < time)
		return;

	if((this.spawnflags & TELEPORT_PLAYER_ONLY) && !IS_PLAYER(toucher))
		return;
	
	if((this.spawnflags & TELEPORT_MONSTER_ONLY) && !IS_MONSTER(toucher))
		return;

	if((this.spawnflags & TELE_PLAYERTRIGGERED) && this.attack_finished < time)
	{
		if(IS_PLAYER(toucher))
			instateleport_use(this, toucher, toucher);
		return;
	}
	
	entity t = findunlockedtarget(this, NULL);//teleport_getdestination();
	if(!t)
	{
		objerror(this, "instateleporter couldn't find target");
		return;
	}


	if(t.style == TELEDEST_STYLE_NORMAL)
	{
		if(toucher.health <= 0 || toucher.solid != SOLID_SLIDEBOX)
			return;
	}

	// TODO: they never set activator here...
	SUB_UseTargets(this, toucher, toucher);

	// put a tfog where the player was
	if(!((this.spawnflags & TELE_STEALTH) || (t.spawnflags & TELEDEST_STEALTH)))
		spawn_tfog(toucher.origin);

	// teleport destination's angle offset
	vector tAngle = t.mangle;
	//tAngle_y += this.mangle_y;
	//dprint2(vtos(tAngle), "\n");

	// entity is a client, so take the angles from v_angle instead
	vector pAngle;
	if(IS_PLAYER(toucher))
		pAngle = vec3(-toucher.v_angle_x, toucher.v_angle_y, toucher.v_angle_z); // v_angle has +pitch as down instead of up
	else
		pAngle = toucher.angles;

	//pAngle_y += this.mangle_y;

	// stores the original v_angle pitch for players
	float vAngleX = toucher.v_angle_x;

	/*
	makevectors(this.mangle);
	vector s_forward = v_forward;
	vector s_right = v_right;
	vector s_up = v_up;
	*/

	makevectors(tAngle);
	vector t_forward = v_forward;
	vector t_right = v_right;
	vector t_up = v_up;

	//vector f_forward = t_forward*s_forward_x - t_right*s_forward_y + t_up*s_forward_z;
	/*
	vector f_forward = s_forward*t_forward_x - s_right*t_forward_y + s_up*t_forward_z;
	vector f_right = s_forward*t_right_x - s_right*t_right_y + s_up*t_right_z;
	vector f_up = s_forward*t_up_x - s_right*t_up_y + s_up*t_up_z;
	*/
	vector f_forward = t_forward;
	//vector f_right = t_right;
	//vector f_up = t_up;

	vector pang = pAngle;
	pang.x = -pang.x;
	makevectors(pang);
	vector p_forward = v_forward;
	//vector p_right = v_right;
	//vector p_up = v_up;

	/*dprint3("s_forward: ", vtos(s_forward*100), "\n");
	dprint3("t_forward: ", vtos(t_forward*100), "\n");
	dprint3("f_forward: ", vtos(f_forward*100), "\n");
	dprint3("p_forward: ", vtos(p_forward*100), "\n");
	*/


	// offsets the current angle by the destination's mangle,

	if(t.mangle != '0 0 0')
	{
		toucher.angles = vectoangles_precise(f_forward*p_forward_x - t_right*p_forward_y + t_up*p_forward_z);
		//toucher.angles_y = vectoyaw2(f_forward*p_forward_x - t_right*p_forward_y + t_up*p_forward_z);
	}
	else
		toucher.angles = pAngle;

	//toucher.angles_y -= this.mangle_y;

	toucher.velocity = f_forward*toucher.velocity_x - t_right*toucher.velocity_y + t_up*toucher.velocity_z;
	
	bool isProjectile = (toucher.flags & FL_PROJECTILE);

	// only players, projectiles and gibs maintain their pitch and roll angles
	// everything else gets set to what it was before
	if(!isProjectile && !IS_PLAYER(toucher))
	{
		toucher.angles_x = pAngle.x;
		toucher.angles_z = pAngle.z;
	}

	if(IS_PLAYER(toucher) || IS_MONSTER(toucher))
		spawn_tdeath(t.origin, toucher);

	// move the player and lock him down for a little while
	if(toucher.health < 1 && IS_PLAYER(toucher))
	{
		toucher.origin = t.origin;
		toucher.velocity = (p_forward * toucher.velocity_x) + (p_forward * toucher.velocity_y);
		return;
	}

	vector neworg;

	// instant teleports need a little more math

	vector teleMid = (this.absmin + this.absmax) * 0.5;
	vector destMid = (t.absmin + t.absmax) * 0.5;

	// rotates destination point around mangle
	if(tAngle)
	{
		vector offs = toucher.origin - teleMid;
		neworg = destMid + f_forward*offs_x - t_right*offs_y + t_up*offs_z;
	}
	else
		neworg = toucher.origin - teleMid + destMid;

	// if the entity is onground, move the origin upwards a bit and drop it to avoid getting stuck at the destination
	if(IS_ONGROUND(toucher) && !(t.spawnflags & TELEDEST_DONTDROP))
	{
		float frac = 1;
		traceline(neworg + vec3(0, 0, toucher.maxs_z), neworg + vec3(0, 0, toucher.maxs_z) + '0 0 32', 0, toucher);
		if(trace_fraction < frac)
			frac = trace_fraction;
		traceline(neworg + vec3(toucher.mins_x, toucher.mins_y, toucher.maxs_z), neworg + vec3(toucher.mins_x, toucher.mins_y, toucher.maxs_z) + '0 0 32', 0, toucher);
		if(trace_fraction < frac)
			frac = trace_fraction;
		traceline(neworg + vec3(toucher.maxs_x, toucher.mins_y, toucher.maxs_z), neworg + vec3(toucher.maxs_x, toucher.mins_y, toucher.maxs_z) + '0 0 32', 0, toucher);
		if(trace_fraction < frac)
			frac = trace_fraction;
		traceline(neworg + vec3(toucher.mins_x, toucher.maxs_y, toucher.maxs_z), neworg + vec3(toucher.mins_x, toucher.maxs_y, toucher.maxs_z) + '0 0 32', 0, toucher);
		if(trace_fraction < frac)
			frac = trace_fraction;
		traceline(neworg + vec3(toucher.maxs_x, toucher.maxs_y, toucher.maxs_z), neworg + vec3(toucher.maxs_x, toucher.maxs_y, toucher.maxs_z) + '0 0 32', 0, toucher);
		if(trace_fraction < frac)
			frac = trace_fraction;
		
		setorigin(toucher, neworg + '0 0 1' * (frac * 32));
		DropToFloor_QC_DelayedInit(toucher);
	}
	else
		setorigin(toucher, neworg);

	// projectiles and gibs must have their models removed for a few frames
	// toucherwise effect trails may lerp when the destination is close enough
	if(isProjectile)
		UpdateCSQCProjectile(toucher);
	
	// spawn a tfog flash in front of the destination
	if(!((this.spawnflags & TELE_STEALTH) || (t.spawnflags & TELEDEST_STEALTH)))
		spawn_tfog(toucher.origin + 32 * f_forward);
	
	if(IS_PLAYER(toucher))
	{
		//fog_setFromEnt(toucher, t);

		if(t.style == TELEDEST_STYLE_INSTANT)
			LOG_DEBUG("Player teleported to instadestination ", t.targetname);
		else
			LOG_DEBUG("Player teleported to destination ", t.targetname);

		if((t.spawnflags & TELEDEST_KEEPANGLE )|| t.style == TELEDEST_STYLE_INSTANT)
		{
			// When a changing player's angles field on a frame with fixangle set to 1,
			// the set angles get passed to the v_angle field on the next frame.
			// That means I need to invert the X component (pitch angle), because
			// +pitch in v_angle points up, and in angles points down
			toucher.angles_x *= -1;

			if(t.spawnflags & TELEDEST_KEEPPITCH)
			{
				toucher.angles_x = vAngleX;
			}
			else
			{
				// YEAH MATH
				// Calculates the roll for the player's view angle,
				// to compensate for the destination's horizontal plane 
				// potentially being at an angle.
				// At this point angles already follow the v_angle
				// convention, so no X inversion is necessary
				makevectors(toucher.angles);
				toucher.angles_z = vectoyaw2(vec2((v_up * t_up), (v_right * t_up)));
			}
		}

		if(t.spawnflags & TELEDEST_KEEPANGLE_NOOFFSET)
			toucher.angles = toucher.v_angle;

		// turn this way immediately
		toucher.fixangle = 1;

		// lock the player's controls for some time
		if(t.style != TELEDEST_STYLE_INSTANT)
			toucher.teleport_time = time + 0.7;

		if(t.style != TELEDEST_STYLE_INSTANT && !(t.spawnflags & TELEDEST_KEEPANGLE))
		{
			if(!(t.spawnflags & TELEDEST_KEEPVELOCITY))
				toucher.velocity = f_forward * 300;
			else	
				toucher.velocity = f_forward * vlen(toucher.velocity);
		}
	}
	//dprint3("After: ", vtos(other.angles),"\n");
	UNSET_ONGROUND(toucher);

	BITXOR_ASSIGN(toucher.effects, EF_TELEPORT_BIT);
}

void instateleport_use(entity this, entity actor, entity trigger)
{
	this.attack_finished = time + 0.2;
	force_retouch = 2;		// make sure even still objects get hit
	setthink(this, func_null);
	this.nextthink = 0;
}

void instateleport_reactivate(entity this, entity actor, entity trigger)
{
	trigger_reactivate(this, actor, trigger);
	// triggerfirst + nonsilent = delayed ambientsound, so shortcut teleporters don't sound like secrets
	if((this.spawnflags & TELEPORT_TRIGGER_FIRST) && !(this.spawnflags & TELEPORT_SILENT) )
		teleport_hum(this);
	
	this.use = instateleport_use;
}

/*QUAKED trigger_instateleport (.5 .5 .5) ? PLAYER_ONLY SILENT
Any object touching this will be transported to the corresponding info_teleport_destination entity. You must set the "target" field, and create an object with a "targetname" field that matches.

If the trigger_teleport has a targetname, it will only teleport entities when it has been fired.
*/
/*FGD
@SolidClass base(Trigger, Teleport) = trigger_instateleport : "Trigger: Teleporter. 
Any object touching this will be transported to the corresponding info_teleport_destination entity.

The 'Not Triggerable' spawnflag: default behavior for a teleporter with a targetname is to only teleport what's touching it when triggered. this will preserve ordinary no-targetname behavior (if you're using the teleporter's targetname for a killtarget for example)." []
*/
spawnfunc(trigger_instateleport)
{
	InitTrigger(this);
	settouch(this, instateleport_touch);
	// find the destination 
	if(!this.target || this.target == "")
	{
		objerror(this, "trigger_instateleport: no target");
		return;
	}

	this.use = instateleport_use;

	if(!(this.spawnflags & TELEPORT_SILENT))
	{
		precache_sound("ambience/hum1.wav");
		if(!(this.spawnflags & TELEPORT_TRIGGER_FIRST))
			teleport_hum(this);
	}

	if(this.spawnflags & TELEPORT_TRIGGER_FIRST)
		this.use = instateleport_reactivate;
}

/*QUAKED trigger_instateleport_destination (.5 .5 .5) ? PRESERVE_PITCH SHOW_EFFECT DONT_FORCEDROP
Instant teleport destination. 
This ideally should match the same size and shape of the trigger_instateleport brush.

- 'mangle' field: sets an optional angle offset compared to the trigger_instateleport that entities will be turned by. This will make stuff go out at a different orientation than the teleport trigger, including pointing up/downwards, or with a side roll. Uses the 'pitch yaw roll' notation, but you can just follow Trenchbroom's white directional arrow when rotating the instadestination brush.

- 'Show teleport effect' flag: Draw the teleport fog effect (which is disabled by default for teleport instadestinations).

- 'Don't force drop to floor' flag: By default, if the player is onground when teleporting in, they'll be forced to the ground after going out at the destination, in order to avoid getting stuck. In case you deliberately want to teleport the player to a mid-air position, this flag disables this behavior.
*/
/*FGD
@SolidClass base(Trigger, Teleport) = trigger_instateleport_destination : "Instant teleport destination. 
This ideally should match the same size and shape of the trigger_instateleport brush.

- 'mangle' field: sets an optional angle offset compared to the trigger_instateleport that entities will be turned by. This will make stuff go out at a different orientation than the teleport trigger, including pointing up/downwards, or with a side roll. Uses the 'pitch yaw roll' notation, but you can just follow Trenchbroom's white directional arrow when rotating the instadestination brush.

- 'Show teleport effect' flag: Draw the teleport fog effect (which is disabled by default for teleport instadestinations).

- 'Don't force drop to floor' flag: By default, if the player is onground when teleporting in, they'll be forced to the ground after going out at the destination, in order to avoid getting stuck. In case you deliberately want to teleport the player to a mid-air position, this flag disables this behavior.
" [
	mangle(string) : "Angle offset" : : "Check detailed description below."
	spawnflags(flags) = [
		2: "Preserve pitch angle" : 0 : "Makes players maintain their original pitch view angles even when the destination has a pitch offset."
		4: "Show teleport effect" : 0 : "Draw the teleport fog effect (which is disabled by default for teleport instadestinations)."
		32: "Don't force drop to floor" : 0 : "By default, if the player is onground when teleporting in, they'll be forced to the ground after going out at the destination, in order to avoid getting stuck. In case you deliberately want to teleport the player to a mid-air position, this flag disables this behavior."
	]
]
*/

spawnfunc(trigger_instateleport_destination)
{
	if(!this.targetname || this.targetname == "")
	{
		objerror(this, "trigger_instateleport_destination: no targetname");
		return;
	}

	//this.flags |= FL_NEVERTELEPORT;
	
	this.solid = SOLID_TRIGGER;
	_setmodel(this, this.model);	// set size and link into world
	set_movetype(this, MOVETYPE_NONE);
	this.modelindex = 0;
	this.model = "";

	this.style = TELEDEST_STYLE_INSTANT;

	//SetAngles();
	//fog_fixKeys();
	if(this.mangle == '0 0 0' && this.angles != '0 0 0')
		this.mangle = this.angles;

	// flips the stealth flag
	this.spawnflags ^= TELEDEST_STEALTH;
}
#endif
