#include "vampirism.qh"

#ifdef SVQC
bool vampglobe_customize(entity this, entity client)
{
	return (client == this.owner);
}

void VampGlobeTouch(entity this, entity toucher)
{
	if(toucher != this.owner)
		return;
	// TODO: regular heal prevention checks?

	float r = random();
	if(r < 0.33)
		_sound(toucher, CHAN_ITEM, "items/vamppickup1.wav", 1, ATTN_NORM);
	else if(r < 0.66)
		_sound(toucher, CHAN_ITEM, "items/vamppickup2.wav", 1, ATTN_NORM);
	else
		_sound(toucher, CHAN_ITEM, "items/vamppickup3.wav", 1, ATTN_NORM);

	T_Heal(toucher, 5, true);
	delete(this);
}

// from Xonotic's ctf_CalculatePassVelocity
void vampglobe_CalculateVelocity(entity this, vector to, vector from, float turnrate, float fly_velocity, float fly_turnrate)
{
	float arc_max = 50;
	float arc = 10;
	float current_distance = vlen((('1 0 0' * to.x) + ('0 1 0' * to.y)) - (('1 0 0' * from.x) + ('0 1 0' * from.y))); // for the sake of this check, exclude Z axis
	float initial_height = min(arc_max, (this.distance * tanh(arc)));
	float current_height = (initial_height * min(1, (current_distance / this.distance)));
	//print("current_height = ", ftos(current_height), ", initial_height = ", ftos(initial_height), ".\n");

	vector targpos;
	if(current_height) // make sure we can actually do this arcing path
	{
		targpos = (to + ('0 0 1' * current_height));
		traceline(this.origin, targpos, MOVE_NOMONSTERS, this);
		if(trace_fraction < 1)
		{
			//print("normal arc line failed, trying to find new pos...");
			traceline(to, targpos, MOVE_NOMONSTERS, this);
			float arc_offset = -10;
			targpos = (trace_endpos + eZ * arc_offset);
			traceline(this.origin, targpos, MOVE_NOMONSTERS, this);
			if(trace_fraction < 1) { targpos = to; /* print(" ^1FAILURE^7, reverting to original direction.\n"); */ }
			/*else { print(" ^3SUCCESS^7, using new arc line.\n"); } */
		}
	}
	else { targpos = to; }

	//this.angles = normalize(('0 1 0' * to_y) - ('0 1 0' * from_y));

	vector desired_direction = normalize(targpos - from);
	if(turnrate) { this.velocity = (normalize(normalize(this.velocity) + (desired_direction * fly_turnrate)) * fly_velocity); }
	else { this.velocity = (desired_direction * fly_velocity); }
}

void VampGlobeHome(entity this, entity targ)
{
	float home_radius = 250;
	vector targ_origin = (0.5 * (targ.absmin + targ.absmax));
	if(vdist(this.origin - targ_origin, >, home_radius))
	{
		if(this.distance)
			set_movetype(this, MOVETYPE_TOSS);
		this.distance = 0;
		return;
	}

	if(!this.distance)
	{
		set_movetype(this, MOVETYPE_NOCLIP);
		this.distance = vlen((('1 0 0' * targ_origin.x) + ('0 1 0' * targ_origin.y)) - (('1 0 0' *  this.origin.x) + ('0 1 0' *  this.origin.y))); // for the sake of this check, exclude Z axis
	}
	vampglobe_CalculateVelocity(this, targ_origin, this.origin, false, 600, 50);
}

void VampGlobeThink(entity this)
{
	this.nextthink = time;

	entity actor = this.owner;
	if(time > this.wait || intermission_running
		|| !actor || actor.health < 1 || actor.exptime != 0)
	{
		delete(this);
		return;
	}

	if(this.wait < time + 4 && this.cnt > time)
	{
		this.alpha = (this.alpha == 1) ? 0.25 : 1;
		this.cnt = time + 0.25;
	}

	VampGlobeHome(this, this.owner);
}

void DropVampGlobe(entity from, entity player)
{
	entity item = new(VampGlobe);
	setorigin(item, from.origin + '0 0 24');

	item.velocity_x = -150 + (random() * 300);
	item.velocity_y = -150 + (random() * 300);
	item.velocity_z = 300 + (random() * 100);

	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.effects = EF_FULLBRIGHT;
	set_movetype(item, MOVETYPE_TOSS);
	_setmodel(item, "progs/item_vampglobe.mdl");
	setsize(item, '-16 -16 -24', '16 16 24');
	settouch(item, VampGlobeTouch);
	item.owner = player;
	item.wait = time + max(time, StatusEffects_gettime(STATUSEFFECT_Vampirism, player) - 4);
	item.alpha = 1;
	item.state = 0;
	item.distance = 0;

	setcefc(item, vampglobe_customize);
	setthink(item, VampGlobeThink);
	item.nextthink = time;
}

void vampglobe_Killed(entity targ, entity attacker)
{
	if(!IS_PLAYER(attacker))
		return;
	if(!(IS_MONSTER(targ) || (IS_PLAYER(targ) && deathmatch)))
		return;
	if(!StatusEffects_active(STATUSEFFECT_Vampirism, attacker))
		return;

	int globes = floor(random() * 4) + 1;

	for(int j = 0; j < globes; ++j)
	{
		DropVampGlobe(targ, attacker);
	}
}

METHOD(Vampirism, m_remove, void(StatusEffects this, entity actor, int removal_type))
{
	bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
	if(wasactive)
		stopsound(actor, CH_TRIGGER_SINGLE); // get rid of the pickup sound
	actor.vampirism_warning = false;
	SUPER(Vampirism).m_remove(this, actor, removal_type);
}
METHOD(Vampirism, m_apply, void(StatusEffects this, entity actor, float eff_time, float eff_flags))
{
	SUPER(Vampirism).m_apply(this, actor, eff_time, eff_flags);
}
METHOD(Vampirism, m_tick, void(StatusEffects this, entity actor))
{
	float curtime = StatusEffects_gettime(this, actor);
	if(curtime < time + 3 && !actor.vampirism_warning && IS_REAL_CLIENT(actor))
	{
		if(gametype != GAMETYPE_HORDE)
			Send_Notification(NOTIF_ONE, actor, MSG_MULTI, POWERDOWN_VAMPIRISM);
		_sound(actor, CH_TRIGGER_SINGLE, "items/vampfade.wav", 1, ATTN_NORM);
		actor.vampirism_warning = true;
	}
	SUPER(Vampirism).m_tick(this, actor);
}
#endif
