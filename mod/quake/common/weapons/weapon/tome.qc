#include "tome.qh"

#ifdef SVQC
void wep_tome_shot5(entity this) { wep_set_anim(this, 5, w_ready); }
void wep_tome_shot4(entity this) { wep_set_anim(this, 4, wep_tome_shot5); }
void wep_tome_shot3(entity this) { wep_set_anim(this, 3, wep_tome_shot4); }
void wep_tome_shot2(entity this) { wep_set_anim(this, 2, wep_tome_shot3); }
void wep_tome_shot1(entity this) { wep_set_anim(this, 1, wep_tome_shot2); }

PRECACHE(Tome)
{
	precache_model("progs/v_tome.mdl");
	precache_model("progs/g_tome.mdl");

	precache_sound("brain/teleport.wav");
	precache_sound("weapons/starfury_star_impact.wav");
}

void demon_sickle_explode(entity this)
{
	_sound(this, CH_SHOTS, "weapons/starfury_star_impact.wav", 1, ATTN_NORM);
	particle(findbetterlocation(this.origin, 8), '0 0 0', 149, 128);

	delete(this);
}

void demon_sickle_touch(entity this, entity toucher)
{
	if(toucher == this.owner)
		return;

	if(toucher.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if(pointcontents(this.origin) == CONTENT_SKY)
	{
		delete(this);
		return;
	}
	
// hit something that bleeds
	if(toucher && toucher.solid != SOLID_BSP) // yoder mod, jan 05 2021
	{
		// handled by hack
	}
	else
	{
		demon_sickle_explode(this);
		return;
	}
}

.float demon_scythe_dmgtime;
.int scythe_bouncecnt;
void demon_sickle_think(entity this)
{
	if(time > this.count)
	{
		demon_sickle_explode(this);
		return;
	}

	// hack to ensure the projectile keeps going even if it hits a target
	this.nextthink = time;

	//this.avelocity_x = -720 * bound(1, (time - this.spawn_time), 3);

	float velmax = 2000;
	float vel = vlen(this.velocity);
	if(vel == 0)
		vel = 1; // hack to make sure avelocity never divs by 0

	if(vel < velmax)
	{
		// copied from PM_Accelerate
		float wishspeed = velmax;
		vector wishdir = this.movedir;
		float currentspeed = (this.velocity * wishdir);
		float addspeed = wishspeed - currentspeed;
		if(addspeed > 0)
		{
			float accelspeed = 0.1 * PHYS_INPUT_TIMELENGTH * wishspeed;
			if(accelspeed > addspeed)
				accelspeed = addspeed;

			this.velocity += accelspeed * wishdir;
		}
	}

	UpdateCSQCProjectile(this);

	bool hitenemy = false;

	FOREACH_ENTITY_RADIUS(this.origin, this.cnt, it.takedamage && it != this.owner,
	{
		if(time < it.demon_scythe_dmgtime)
			continue;
		if(it.clipgroup && it.clipgroup == this.clipgroup)
			continue;
		float damg = ((this.dmg) ? this.dmg : 20);
		if(it.monsterdef.spawnflags & MONSTER_TYPE_UNDEAD)
			damg = 120;
		spawn_touchblood(this, damg, it);
		T_Damage(it, this, this.owner, damg, this.projectiledeathtype);

		hitenemy = true;
		it.demon_scythe_dmgtime = time + 0.5; // prevent instant death
	});

	if(hitenemy)
	{
		this.scythe_bouncecnt += 1;

		if(this.scythe_bouncecnt >= 5)
		{
			setthink(this, demon_sickle_explode);
			this.nextthink = time;
			settouch(this, func_null);
		}
	}
}

void TomeFire(entity this, vector org, vector dir, .entity weaponentity)
{
	// assumes v_ angles are setup

	_sound(this, CH_WEAPON_A, "brain/teleport.wav", 1, ATTN_NORM);

	entity missile = new(demon_scythe);
	missile.flags = FL_PROJECTILE;
	missile.owner = this;
	missile.realowner = this;
	missile.clipgroup = this.clipgroup;
	set_movetype(missile, MOVETYPE_FLYMISSILE);
	missile.solid = SOLID_TRIGGER;
	missile.effects = EF_ADDITIVE;
	missile.dphitcontentsmask = DPCONTENTS_SOLID;
	missile.projectiledeathtype = WEP_TOME.m_id;
	missile.cnt = 32; // rough area of effect during travel
	missile.dmg = 60;

	missile.movedir = dir;
	missile.velocity = dir * 50;
	//missile.velocity_z = 200;

	missile.angles = vectoangles(missile.velocity);

	missile.count = time + 8;
	missile.nextthink = time;
	setthink(missile, demon_sickle_think);

	settouch(missile, demon_sickle_touch);

	setsize(missile, '0 0 0', '0 0 0');
	setorigin(missile, org);

	IL_PUSH(g_projectiles, missile);

	CSQCProjectile(missile, false, PROJECTILE_DEMON_SICKLE, true);
}

void W_FireTome(entity this, .entity weaponentity)
{
	W_TakeMana(this, 8);
	makevectors(this.v_angle);

	vector org = W_Shotorg(this, weaponentity);
	vector dir = qc_aim_fromorg(this, org, 2000);
	TomeFire(this, org, dir, weaponentity);
}

METHOD(Tome, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	//if(thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	if(STAT(MANA, actor) >= 8)
	{
		if(IS_PLAYER(actor))
			player_shot1(actor);
		wep_tome_shot1(actor.(weaponentity));
		W_FireTome(actor, weaponentity);
		weapon_prepareattack(thiswep, actor, weaponentity, 0.5);
	}
}
METHOD(Tome, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	return true; // uses mana
}
METHOD(Tome, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(Tome, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_FRAG;
}
#endif
