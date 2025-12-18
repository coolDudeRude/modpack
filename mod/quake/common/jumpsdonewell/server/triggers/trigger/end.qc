#ifdef SVQC

.float end1_touch_time;
.float end2_touch_time;

void end2_touch(entity this, entity toucher)
{
	if(time < toucher.end1_touch_time)
		return;
	toucher.end1_touch_time = time + 20;
	msg_entity = toucher;
	WriteHeader(MSG_ONE, TE_CSQC_END2);
	changelevel_touch(this, toucher);
}

spawnfunc(trigger_end2)
{
	if(!IsJumpsDoneWell())
	{
		delete(this);
		return;
	}

	this.solid = SOLID_TRIGGER;
	_setmodel(this, this.model);
	this.modelindex = 0;
	settouch(this, end2_touch);

	this.count = 0.7;
	this.map = "quake";

	setthink(this, changelevel_think);
	this.nextthink = time + 0.1;
	this.active = ACTIVE_ACTIVE;

	WaypointSprite_SpawnFixed(WP_Exit, (this.absmin + this.absmax) * 0.5, this, sprite, NULL);
	this.sprite.waypointsprite_visible_for_player = changelevel_waypointsprite_visible_for_player;
}

void end1_touch(entity this, entity toucher)
{
	if(time < toucher.end2_touch_time)
		return;
	toucher.end2_touch_time = time + 20;

	if (toucher.max_health < 8)
	{
		msg_entity = toucher;
		WriteHeader(MSG_ONE, TE_CSQC_END1);
		changelevel_touch(this, toucher);
	}
	else
	{
		entity door = find(NULL, classname, "func_door");
		if (!door) return;
		pointparticles(EFFECT_ENEMY_DIE, (door.absmin + door.absmax) * 0.5, '0 0 1', 1);
		sound(door, CHAN_AUTO, SND_SWORD2, 1, ATTEN_NORM);
		delete(door);
	}
}

spawnfunc(trigger_end1)
{
	if(!IsJumpsDoneWell())
	{
		delete(this);
		return;
	}

	this.solid = SOLID_TRIGGER;
	_setmodel(this, this.model);
	this.modelindex = 0;
	settouch(this, end1_touch);

	this.count = 0.7;
	this.map = "quake";

	setthink(this, changelevel_think);
	this.nextthink = time + 0.1;
	this.active = ACTIVE_ACTIVE;

	WaypointSprite_SpawnFixed(WP_Exit, (this.absmin + this.absmax) * 0.5, this, sprite, NULL);
	this.sprite.waypointsprite_visible_for_player = changelevel_waypointsprite_visible_for_player;
}

#endif
