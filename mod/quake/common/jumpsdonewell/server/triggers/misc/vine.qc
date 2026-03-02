#ifdef SVQC

void vine_destroy(entity this)
{
	this.solid = SOLID_NOT;
	_setmodel(this, "models/vine_broken.iqm");
	pointparticles(EFFECT_ENEMY_DIE, this.origin + '0 0 32', '0 0 1', 1);
	_sound(this, CHAN_AUTO, "sword2.wav", 0.7, ATTEN_NORM);
	setthink(this, spawnfunc_misc_vine);
	this.nextthink = time + 20;
	CSQCMODEL_AUTOUPDATE(this);
}

spawnfunc(misc_vine)
{
	if(gametype != GAMETYPE_JUMPSDONEWELL)
	{
		delete(this);
		return;
	}

	precache_model("models/vine.iqm");
	precache_model("models/vine_broken.iqm");

	this.solid = SOLID_BBOX;
	_setmodel(this, "models/vine.iqm");
	this.angles_y = random() * 360;
	setsize(this, '-32 -32 0', '32 32 128');
	CSQCMODEL_AUTOINIT(this);
}

#endif
