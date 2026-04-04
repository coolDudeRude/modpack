#include "train_alk.qh"

#ifdef SVQC

void alk_train_next(entity this);
void alk_func_train_find(entity this);

.entity animcontroller;
.entity rotatecontroller;

.vector cmins, cmaxs;

float alk_lerp(float a, float b, float mix)
{
	if(mix <= 0) return a;
	if(mix >= 1) return b;
	return (b * mix + a * ( 1 - mix ) );
}

.vector calcmoveorigin;
.vector finaldest;
.float startspeed;
.float travelspeed;
.float finalspeed;
.float idletimer;
.float realsmdist;
.bool smoothcurve;
.float smoothdist;
void CalcMoveSmooth_Think(entity this)
{
	float localtime = this.ltime;

	float disttofinish = vlen(this.origin - this.finaldest);
	float disttostart = vlen(this.origin - this.calcmoveorigin);

	float perctostart = bound(0, disttostart/this.realsmdist, 1);
	float perctofinish = bound(0, disttofinish/this.realsmdist, 1);
	float spd;
	vector dir = normalize(this.finaldest - this.origin);

	// accelerating
	if(perctostart < perctofinish)
	{
		float lg2 = (log2(perctostart) + 7)/7;
		lg2 *= lg2;
		
		if(!this.smoothcurve)
			spd = alk_lerp(this.startspeed, this.travelspeed, lg2);
		else
			spd = alk_lerp(this.startspeed, this.travelspeed, perctostart);
	}
	//stopping
	else if(perctostart > perctofinish)
	{
		spd = alk_lerp(this.travelspeed, this.finalspeed, 1 - perctofinish);
	}
	else
	{
		spd = this.travelspeed;
	}

	spd = max(spd, this.travelspeed/50);
	vector newvel = spd * dir;

	//dprint3("Speed difference: ", ftos(vlen(newvel) - vlen(this.velocity)), "\n");
	//dprint4("perctostart: ", ftos(perctostart), ", perctofinish: ", ftos(perctofinish));
	//dprint3(", speed: ", ftos(spd), "\n");
	this.velocity = newvel;

	if(vlen2((this.origin + this.velocity * 0.025) - this.calcmoveorigin) > vlen2(this.finaldest - this.calcmoveorigin))
	{
		setthink(this, SUB_CalcMoveDone);
	}

	this.nextthink = localtime + 0.025;
}

/*
=============
SUB_CalcMoveSmooth

tdest -> destination coordinates
smdist -> smoothing distance
tspeed -> travel speed
stspeed -> starting speed
fnspeed -> final speed
===============
*/

void SUB_CalcMoveSmooth(entity this, vector tdest, float smdist, float tspeed, float stspeed, float fnspeed, void(entity) func)
{
	if(!tspeed)
	{
		objerror(this, "No speed is defined!");
		return;
	}

	float localtime = this.ltime;

	this.think1 = func;
	setthink(this, CalcMoveSmooth_Think);
	this.finaldest = tdest;
	this.calcmoveorigin = this.origin;

	vector vdestdelta = tdest - this.origin;
	float len = vlen(vdestdelta);

	if(len/2 < smdist)
	{
		this.travelspeed = tspeed*len/2/smdist;
		this.realsmdist = len/2;
	}
	else
	{
		this.travelspeed = tspeed;
		this.realsmdist = smdist;
	}

	this.startspeed = max(stspeed, this.travelspeed/50);
	this.finalspeed = max(fnspeed, this.travelspeed/50);
	if(tdest == this.origin)
	{
		this.velocity = '0 0 0';
		this.nextthink = localtime + 0.1;
		return;
	}
		
	// set destdelta to the vector needed to move
	
	//accelerating
	//t = ((v - v0)*2d)/(v² - v0²)
	// WRONG!
	float traveltime = 0;
	if(this.travelspeed != this.startspeed)
		traveltime += ((this.travelspeed - this.startspeed)*2*this.realsmdist)/(this.travelspeed*this.travelspeed - this.startspeed*this.startspeed);
	else
		traveltime += this.realsmdist/this.startspeed;

	// cruising
	traveltime += (len - this.realsmdist*2)/this.travelspeed;

	//stopping
	//t = ((v - v0)*2d)/(v² - v0²)
	if(this.finalspeed != this.travelspeed)
		traveltime += ((this.finalspeed - this.travelspeed)*2*this.realsmdist)/(this.finalspeed*this.finalspeed - this.travelspeed*this.travelspeed);
	else 
		traveltime += this.realsmdist/this.finalspeed;

	// changed from the 0.1 default
	if(traveltime < 0.025)
	{
		this.velocity = '0 0 0';
		this.nextthink = localtime + 0.025;
		return;
	}
	this.idletimer = localtime;

	this.nextthink = localtime + 0.025;

// scale the destdelta vector by the time spent traveling to get velocity
	this.velocity = normalize(vdestdelta) * this.startspeed;
}

/*
============
After rotating, set angle to exact final angle
============
*/
void SUB_CalcAngleMoveDoneController(entity this)
{
	this.owner.angles = this.finalangle;
	this.owner.avelocity = '0 0 0';
	this.nextthink = -1;
	if (this.think1)
		this.think1(this.owner);
}

/*
=============
SUB_CalcAngleMoveController

Same as SUB_CalcAngleMove, but using a separate controller entity
to not lose track of current think functions.

===============
*/

// normalizes an angle vector to the -180/+179 range
vector normalizeAngles180(vector ang)
{
	ang_x = ang_x - floor((ang_x+180)/360) * 360;
	ang_y = ang_y - floor((ang_y+180)/360) * 360;
	ang_z = ang_z - floor((ang_z+180)/360) * 360;

	/*
	while (ang_x > 180)
		ang_x = ang_x - 360;

	while (ang_x < -180)
		ang_x = ang_x + 360;

	while (ang_y > 180)
		ang_y = ang_y - 360;

	while (ang_y < -180)
		ang_y = ang_y + 360;

	while (ang_z > 180)
		ang_z = ang_z - 360;

	while (ang_z < -180)
		ang_z = ang_z + 360;
	*/
	return ang;
}

void SUB_CalcAngleMoveController_ent(entity ent, vector destangle, float tspeed, void(entity) func, entity controller)
{
	if(!tspeed)
	{
		objerror(ent, "No speed is defined!");
		return;
	}
		
	// set destdelta to the vector needed to move

	vector destdelta = normalizeAngles180(destangle - ent.angles);
	/*dprint3("destangle:   ", vtos(destangle), "\n");
	dprint3("this.angles: ", vtos( this.angles), "\n");
	dprint3("destdelta:   ", vtos(destdelta), "\n");
	*/

	// calculate length of vector
	float len = vlen (destdelta);
	
	// divide by speed to get time to reach dest
	float traveltime = len / tspeed;

	// set nextthink to trigger a think when dest is reached
	controller.nextthink = time + traveltime;

	// scale the destdelta vector by the time spent traveling to get velocity
	ent.avelocity = destdelta * (1 / traveltime);
	
	// Makes sure controller.owner points to this so it can be referenced later in the think function
	controller.owner = ent;  
	controller.think1 = func;
	controller.finalangle = destangle;
	setthink(controller, SUB_CalcAngleMoveDoneController);
}

void SUB_CalcAngleMoveController(entity this, vector destangle, float tspeed, void(entity) func, entity controller)
{
	SUB_CalcAngleMoveController_ent(this, destangle, tspeed, func, controller);
}

// Use function for when the train is stopped.
// Makes the train continue on path_corners with wait -1,
// or forces a continue if the "move on trigger" spawnflag is set.
void alk_train_use(entity this, entity actor, entity trigger)
{
	if((this.spawnflags & TRAIN_MOVEONTRIGGER) || this.wait < 0)
	{
		alk_train_next(this);
		return;
	}
	
	// Train has already moved after startup, and has no "stop on trigger" flag,
	// so ignore activation.
	if(getthink(this) != alk_func_train_find && this.cnt != TRAIN_NEXT_STOP)
		return;

	alk_train_next(this);
}

// Use function for when the train is moving.
// Forces a stop or an instant continue on the next path_corner depending on the spawnflag set
void train_moving_use(entity this, entity actor, entity trigger)
{
	if((this.spawnflags & TRAIN_MOVEONTRIGGER) || this.wait < 0)
		this.cnt = TRAIN_NEXT_CONTINUE;
	else if(this.spawnflags & TRAIN_STOPONTRIGGER)
		this.cnt = TRAIN_NEXT_STOP;
}

// path_corner has been reached, so decide what to do next
void alk_train_wait(entity this)
{
	this.use = alk_train_use; //ready to be re-triggered

	SUB_UseTargets(this.enemy, this, this);

	if(this.enemy.speed)
		this.speed2 = this.enemy.speed; // sets the speed from the current path_corner

	// copies the modeltrain animation parameters set in the path_corner, if any
	if(this.classname == "misc_modeltrain")
	{
		if(this.enemy.first_frame) this.first_frame = this.enemy.first_frame;
		if(this.enemy.last_frame) this.last_frame = this.enemy.last_frame;
		if(this.enemy.first_frame2) this.first_frame2 = this.enemy.first_frame2;
		if(this.enemy.last_frame2) this.last_frame2 = this.enemy.last_frame2;
		if(this.enemy.frtime) this.frtime = this.enemy.frtime;
		if(this.enemy.frtime2) this.frtime2 = this.enemy.frtime2;
		if(this.enemy.animtype) this.animtype = this.enemy.animtype;
		if(this.enemy.animtype2) this.animtype2 = this.enemy.animtype2;
		if(this.enemy.multiplier) this.multiplier = this.enemy.multiplier;
	}

	setthink(this, alk_train_next);

	// train is moving normally and path_corner has a wait set, so pause for that time.
	if(this.wait > 0 && this.cnt == TRAIN_NEXT_WAIT)
	{
		// state: stopped
		this.state = 0;
		if(this.classname == "misc_modeltrain" && getthink(this.animcontroller))
			getthink(this.animcontroller)(this.animcontroller);
		this.nextthink = this.ltime + this.wait;

		//play stopping sound. If path_corner has a custom sound, play that instead
		if(this.enemy.noise != "")
			_sound(this, CH_WEAPON_SINGLE, this.enemy.noise, 1, ATTN_NORM);
		else
			_sound(this, CH_TRIGGER_SINGLE, this.noise, 1, ATTN_NORM); 
	}
	// train is moving normally and path_corner has no wait time,
	// or has been forced to move instantly through a triggering.
	else if(this.cnt != TRAIN_NEXT_STOP && !this.wait) {

		//play "passing by" sound, if any. If path_corner has a custom one, play that instead
		if(this.enemy.noise2 != "")
			_sound(this, CH_WEAPON_SINGLE, this.enemy.noise2, 1, ATTN_NORM);
		else if(this.noise2 != "")
			_sound(this, CH_WEAPON_SINGLE, this.noise2, 1, ATTN_NORM);
		
		this.nextthink = -1; // move instantly
		alk_train_next(this);
	}
	// path_corner has wait -1, or train has been forced to stop through a triggering.
	else
	{
		//play stopping sound. If path_corner has a custom sound, play that instead
		if(this.enemy.noise != "")
			_sound(this, CH_WEAPON_SINGLE, this.enemy.noise, 1, ATTN_NORM);
		else
			_sound(this, CH_TRIGGER_SINGLE, this.noise, 1, ATTN_NORM); 

		// state: stopped
		this.state = 0;

		if(this.classname == "misc_modeltrain" && getthink(this.animcontroller))
			getthink(this.animcontroller)(this.animcontroller);
		this.nextthink = -1;
	}
}

// returns the first active path corner,
// or the first inactive one if no active path was found,
// or world if no path was found at all
entity getNextPath(string name)
{
	return find(NULL, targetname, name);

	// TODO: we don't have alkaline's active state system!
#if 0
	entity targ, first;

	first = targ = find(NULL, targetname, name);

	// first path is ok
	// most common case, so return early
	if(targ)
		return first;

	// found path isn't active, so search for others with the same targetname
	while(targ && targ.estate != STATE_ACTIVE)
	{
		targ = find(targ, targetname, name);
	}

	// found an active path
	if(targ && targ.estate == STATE_ACTIVE)
		return targ;

	// no active path was found with the same targetname,
	// so return the first non-active one
	// will return world if no path was found at all
	return first;
#endif
}

// searches for the next path_corner and sends the train on its way
void alk_train_next(entity this)
{
	entity targ = NULL, first = NULL;

	float prevspeed;
	if(getthink(this) == alk_func_train_find)
		prevspeed = 0;
	else if(this.cnt != TRAIN_NEXT_STOP && !this.wait)
		prevspeed = this.speed2;
	else
		prevspeed = 0;
	//if(this.cnt == TRAIN_NEXT_STOP || (this.cnt == TRAIN_NEXT_WAIT && this.wait)) prevspeed = 0;
	//else prevspeed = this.speed2;

	if(this.target == "")
		targ = this.enemy;
	else
	{
		first = targ = getNextPath(this.target);

		if(!targ && !first)
			targ = this.enemy;

		if(!targ && first)
			targ = this.enemy;
	}

	this.target = targ.target;
	
	// gets the wait time from the upcoming path_corner if set
	if(targ.wait)
	{
		// wait -2 on the path_corner forces it to continue moving (no wait),
		// even if the train has a default wait time
		if(targ.wait == -2)
			this.wait = 0;
		else
			this.wait = targ.wait;
	}
	// uses train's current wait time otherwise
	else
		this.wait = this.pausetime;

	this.enemy = targ;
	
	_sound(this, CH_TRIGGER_SINGLE, this.noise1, 1, ATTN_NORM);
	
	if(!(!this.wait && this.cnt == TRAIN_NEXT_CONTINUE))
		this.cnt = TRAIN_NEXT_WAIT;

	//store up any premature triggerings until current movement is finished
	this.use = train_moving_use; 

	if(this.classname == "misc_modeltrain")
	{
		if(!(this.spawnflags & TRAIN_NOROTATE))
		{
			vector destang = vectoangles(targ.origin - this.origin);
			if(this.spawnflags & TRAIN_ROTATEY)
			{
				destang_x = this.angles_x;
				destang_z = this.angles_z;
			}
			if(this.multiplier > 0)
				SUB_CalcAngleMoveController(this, destang, this.speed2*this.multiplier, func_null, this.rotatecontroller);
			else
				this.angles = destang;
		}
	}

	if(!this.state)
	{
		this.state = 1;
		if(this.classname == "misc_modeltrain" && this.style != TRAIN_STYLE_SINGLEANIM && getthink(this.animcontroller))
			getthink(this.animcontroller)(this.animcontroller);
	}

	vector displ = '0 0 0';
	if(this.classname != "misc_modeltrain")
		displ = this.mins;

	float smdist = (targ.smoothdist) ? targ.smoothdist : this.smoothdist;
	if(smdist)
	{
		float nextspeed;
		if(this.wait)
			nextspeed = 0;
		else
			nextspeed = (targ.speed) ? targ.speed : this.speed2;
 		
 		float curspeed = this.speed2;
		//void(vector tdest, float smdist, float tspeed, float stspeed, float fnspeed, void() func) SUB_CalcMoveSmooth
		SUB_CalcMoveSmooth(this, targ.origin - displ, smdist, curspeed, prevspeed, nextspeed, alk_train_wait);
	}
	else
	{
		//void(vector tdest, float tspeed, void() func) SUB_CalcMove
		SUB_CalcMove(this, targ.origin - displ, TSPEED_LINEAR, this.speed2, alk_train_wait);
	}
}

// searches for the first path_corner after the train entity is initialized
void alk_func_train_find(entity this)
{
	entity targ = find(NULL, targetname, this.target);
	this.target = targ.target;

	vector displ = '0 0 0';
	if(this.classname != "misc_modeltrain")
		displ = this.mins;
	this.enemy = targ;
	setorigin(this, targ.origin - displ);
	if(targ.speed)
		this.speed2 = targ.speed; // uses speed from the 1st path corner if set

	if(!this.targetname || this.targetname == "")
	{	// not triggered, so start immediately
		this.nextthink = this.ltime + 0.1;
		setthink(this, alk_train_next);
	}
}

// identical so we can reuse it
void train_blocked(entity this, entity blocker);

/*QUAKED func_train (0 .5 .8) ? RETRIGGER
Trains are moving platforms that players can ride.
The targets origin specifies the min point of the train at each corner.
The train spawns at the first target it is pointing at.
If the train is the target of a button or trigger, it will not begin moving until activated.

RETRIGGER: stop at each path_corner and don't resume until triggered again (ignores wait time)

speed	default 100
dmg		default	2
sounds
1) ratchet metal
2) base

*/
void func_train_alk(entity this)
{
	if(!this.speed)
		this.speed = 100;
	if(!this.target || this.target == "")
	{
		objerror(this, "func_train without a target");
		return;
	}
	if(!this.dmg)
		this.dmg = 2;

	if((this.spawnflags & TRAIN_STOPONTRIGGER) && (this.spawnflags & TRAIN_MOVEONTRIGGER))
	{
		objerror(this, "func_train: Stop and move on trigger set at the same time");
		return;
	}

	if(this.sounds == 1)
	{
		if(this.noise == "")
			this.noise = ("plats/train2.wav");
		if(this.noise1 == "")
			this.noise1 = ("plats/train1.wav");
	}
	else if(this.sounds == 2)
	{ // base door sound
		if(this.noise == "")
			this.noise = "doors/hydro2.wav";
		if(this.noise1 == "")
			this.noise1 = "doors/hydro1.wav";
	}
	else
	{
		if(this.noise == "")
			this.noise = ("misc/null.wav");
		if(this.noise1 == "")
			this.noise1 = ("misc/null.wav");
	}

	precache_sound(this.noise);
	precache_sound(this.noise1);
	if(this.noise2 && this.noise2 != "")
		precache_sound(this.noise2);

	this.cnt = TRAIN_NEXT_WAIT;
	
	if(this.spawnflags & TRAIN_NONSOLID)
	{
		this.solid = SOLID_NOT;
		set_movetype(this, MOVETYPE_NOCLIP);
	}
	else
	{
		this.solid = SOLID_BSP;
		set_movetype(this, MOVETYPE_PUSH);
	}

	setblocked(this, train_blocked);
	this.use = alk_train_use;
	//this.classname = "train";

	_setmodel(this, this.model);
	setsize(this, this.mins, this.maxs);
	setorigin(this, this.origin);

	// start trains on the second frame, to make sure their targets have had
	// a chance to spawn

	if(this.move_movetype == MOVETYPE_PUSH)
		this.nextthink = this.ltime + 0.1;
	else
		this.nextthink = time + 0.1;

	setthink(this, alk_func_train_find);

	this.speed2 = this.speed;
}


//===================================================

// already defined
float wrap(float value, float minValue, float maxValue);

void animcontroller_think(entity this)
{
	entity tr = this.owner;
	
	float first = 0, last = 0, atype = 0;

	// train just went from stopped to moving or vice-versa,
	// and have both animations set
	if(this.state != tr.state && tr.style != TRAIN_STYLE_SINGLEANIM)
	{
		if(tr.state)
		{ // just started moving
			tr.frame = zeroconvert(tr.first_frame2);
		}
		else
		{ // just stopped
			tr.frame = zeroconvert(tr.first_frame);
		}
		tr.distance = 1; // reset back/forth status
		this.state = tr.state;
	}
	else
	{
		if(this.state && tr.style != TRAIN_STYLE_SINGLEANIM)
		{ // moving train animation, if set
			first = zeroconvert(tr.first_frame2);
			last = zeroconvert(tr.last_frame2);
			atype = tr.animtype2;
		}
		else
		{ // stopped/default train animation
			first = zeroconvert(tr.first_frame);
			last = zeroconvert(tr.last_frame);
			atype = tr.animtype;
		}

		float step;
		float dir;
		if(first > last)
			step = dir = -1; // reverse direction
		else
			step = dir = 1;

		// back-and-forth is going the other way, so invert the step's signal
		if(tr.distance < 0)
			step = step * (-1);
		
		int nextframe = tr.frame + step;

		if(atype == TRAIN_ANIMTYPE_BACKFORTH)
		{
			if((dir > 0 && (nextframe > last || nextframe < first)) || (dir < 0 && (nextframe > first || nextframe < last)))
			{
				nextframe = tr.frame - step;
				tr.distance = tr.distance * (-1);
			}
		}

		if(dir > 0)
			nextframe = wrap(nextframe, first, last);
		else
			nextframe = wrap(nextframe, last, first);
		
		tr.frame = nextframe;

	}

	setthink(this, animcontroller_think);
	if(this.state || tr.style == TRAIN_STYLE_SINGLEANIM)
		this.nextthink = time + tr.frtime;
	else
		this.nextthink = time + tr.frtime2;
}

spawnfunc(misc_modeltrain)
{
	precache_model(this.mdl);

	func_train_alk(this);

	if(this.spawnflags & TRAIN_NONSOLID)
		this.solid = SOLID_NOT;
	else
	{ 
		this.solid = SOLID_BBOX;
		if(this.cmins == '0 0 0')
			this.cmins = '-8 -8 -8';
		if(this.cmaxs == '0 0 0')
			this.cmaxs = '8 8 8';
	}

	set_movetype(this, MOVETYPE_NOCLIP);
	_setmodel(this, this.mdl);
	setsize(this, this.cmins , this.cmaxs);
	setorigin(this, this.origin);

	entity rot = spawn();
	this.rotatecontroller = rot;
	rot.classname = "rotatecontroller";
	rot.owner = this;

	entity anim = spawn();
	this.animcontroller = anim;
	anim.classname = "animcontroller";
	anim.owner = this;

	setthink(anim, animcontroller_think);
	anim.nextthink = time + 0.2;

	this.distance = 1;

	if(!this.frtime)
		this.frtime = 0.1;
	if(!this.frtime2)
		this.frtime2 = this.frtime;
	if(!this.multiplier)
		this.multiplier = 1;


	// make sure all first and last frame fields are filled
	if(this.first_frame && !this.last_frame)
		this.last_frame = this.first_frame;
	else if(!this.first_frame && this.last_frame)
		this.first_frame = this.last_frame;
	
	if(this.first_frame2 && !this.last_frame2)
		this.last_frame2 = this.first_frame2;
	else if(!this.first_frame2 && this.last_frame2)
		this.first_frame2 = this.last_frame2;

	if(!this.first_frame2)
		this.style = TRAIN_STYLE_SINGLEANIM;

	if(!this.animtype)
		this.animtype = TRAIN_ANIMTYPE_FORWARD;
	if(!this.animtype2)
		this.animtype2 = this.animtype;

	this.frame = this.first_frame;
}

#endif
