#ifdef SVQC

void bamboo_die_proper(entity this)
{
	setthink(this, spawnfunc_misc_bamboo);
	this.nextthink = time + 20;
	this.modelindex = 0;
	this.takedamage = DAMAGE_NO;
	this.solid = SOLID_NOT;
	setorigin(this, this.origin); // relink
	_sound(this, CHAN_AUTO, "sword2.wav", 0.7, ATTEN_NORM);
	pointparticles(EFFECT_ENEMY_DIE, this.origin + '0 0 32', '0 0 1', 1);
	CSQCMODEL_AUTOUPDATE(this);
}

void bamboo_die(entity this, entity inflictor, entity attacker, int deathtype)
{
	this.solid = SOLID_NOT;
	setorigin(this, this.origin); // relink
	this.frame = 2;
	setthink(this, bamboo_die_proper);
	this.nextthink = time + 0.4;
	CSQCMODEL_AUTOUPDATE(this);
}

void bamboo_hurt2(entity this)
{
	this.frame = 1;
	CSQCMODEL_AUTOUPDATE(this);
}

void bamboo_hurt(entity this, entity attacker, float damage, int deathtype)
{
	this.frame = 0;
	setthink(this, bamboo_hurt2);
	this.nextthink = time + 0.01;
	CSQCMODEL_AUTOUPDATE(this);
}

spawnfunc(misc_bamboo)
{
	if(!IsJumpsDoneWell())
	{
		delete(this);
		return;
	}

	precache_model("models/bamboo2.iqm");
	
	this.solid = SOLID_BBOX;
	_setmodel(this, "models/bamboo2.iqm");
	setsize(this, '-32 -32 -100', '32 32 225');
	this.takedamage = DAMAGE_YES;
	this.th_die = bamboo_die;
	this.th_pain = bamboo_hurt;
	this.health = 30;
	this.frame = 0;
	CSQCMODEL_AUTOINIT(this);
}

#endif
