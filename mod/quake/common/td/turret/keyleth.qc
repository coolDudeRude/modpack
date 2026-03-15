#include "poop.qh"

// =========
//  SWARMER
// =======--

#ifdef SVQC
void SwarmHome(entity this)
{
	if(!this.enemy || this.enemy.health < 1)
	{
		if(this.enemy && this.owner.lastvictim == this.enemy)
			this.owner.lastvictim = NULL;

		RandomSelection_Init();
		float myrange = (this.cnt) ? this.cnt : 256;
		FOREACH_ENTITY_RADIUS(this.origin, myrange, it.takedamage && IS_MONSTER(it) && it.health > 0,
		{
			RandomSelection_AddEnt(it, 1, 1);
		});
		this.enemy = RandomSelection_chosen_ent;
	}

	vector vtemp = (this.enemy) ? CENTER_OR_VIEWOFS(this.enemy) : this.origin;
	if(time > this.count)
	{
		if(this.enemy && this.owner.lastvictim == this.enemy)
			this.owner.lastvictim = NULL;
		stopsound(this, CH_SHOTS_SINGLE);
		delete(this);
		return;
	}
	if(time >= this.idle_finished)
	{
		this.idle_finished = time + 1;
		_sound(this, CH_SHOTS_SINGLE, "turrets/swarmer_swarm.wav", 1, ATTN_NORM);
	}
	if(time >= this.attack_finished)
	{
		float damage = (this.dmg) ? this.dmg : 15;
		FOREACH_ENTITY_RADIUS(this.origin, 16, it.takedamage && IS_MONSTER(it) && it.health > 0,
		{
			if(it.monsterdef.spawnflags & MONSTER_TYPE_BOSS)
				continue;
			T_Damage(it, this, this.owner, damage, DEATH_TRAP.m_id);
		});

		this.attack_finished = time + 0.5;
	}

	vector dir = normalize(vtemp - this.origin);
	this.velocity = dir * 250;
	this.nextthink = time;
	UpdateCSQCProjectile(this);
}

void Swarm_Launch(entity this, vector org, entity targ)
{
	vector dir = normalize(CENTER_OR_VIEWOFS(targ) - org);

	entity missile = spawn();
	missile.flags = FL_PROJECTILE;
	missile.classname = "swarm";
	missile.owner = this;
	missile.projectiledeathtype = DEATH_TRAP.m_id;
	missile.clipgroup = this.clipgroup;

	missile.solid = SOLID_TRIGGER;
	set_movetype(missile, MOVETYPE_FLYMISSILE);

	setsize(missile, '0 0 0', '0 0 0');		

	setorigin(missile, org);
	missile.velocity = dir * 400;
	missile.nextthink = time;
	missile.count = time + 5;
	setthink(missile, SwarmHome);
	missile.enemy = targ;
	missile.dmg = 15 * turret_getpower(this.tur_level, 0.2);
	missile.cnt = 256 * turret_getpower(this.tur_level, 0.2);

	IL_PUSH(g_projectiles, missile);

	CSQCProjectile(missile, false, PROJECTILE_SWARM, true);
}

METHOD(KeylethSwarmer, tr_precache, void(KeylethSwarmer thistur))
{
	precache_sound("turrets/swarmer_swarm.wav");
}
METHOD(KeylethSwarmer, tr_think, void(KeylethSwarmer thistur, entity actor))
{
	if(time <= actor.attack_finished)
		return;
	actor.attack_finished = time + max(0.03, (1.2 / turret_getpower(actor.tur_level, 0.25)));

	// pick a random nearby target each time we attack
	// make sure it matches drawn values!
	float myrange = 320 * turret_getpower(actor.tur_level, 0.2);
	entity targ = turret_findtarget_ignore(actor, 0.15, myrange, actor.lastvictim);
	if(targ)
	{
		//actor.attack_finished = time + max(0.03, (1.2 / turret_getpower(actor.tur_level, 0.25)));
		actor.clientframe = TANIM_SHOOT;

		vector org = CENTER_OR_VIEWOFS(actor) + '0 0 8';
		Swarm_Launch(actor, org, targ);
		actor.lastvictim = targ;
	}
}
METHOD(KeylethSwarmer, tr_setup, void(KeylethSwarmer this, entity actor))
{
	actor.health = 400;
	actor.max_health = actor.health;
}
#endif // SVQC
#ifdef CSQC
METHOD(KeylethSwarmer, tr_drawselected, void(KeylethSwarmer this, entity actor))
{
	float myrange = 320 * turret_getpower(actor.tur_level, 0.2);
	vector org = actor.origin + ((actor.mins + actor.maxs) * 0.5) + '0 0 8';
	makevectors(actor.angles);

	Draw_Cone(org, v_forward, myrange, 0.15);

	// TODO: circle
	//Draw_CylindricLine(org, org + v_forward * myrange, 6, "particles/laserbeam", 0.25, -time * 3, '1 0.25 0', 1, DRAWFLAG_NORMAL, view_origin);
}
METHOD(KeylethSwarmer, tr_setup, void(KeylethSwarmer this, entity actor))
{
	actor.anim_idle = '0 20 0';
	actor.anim_shoot = '40 57 0';
}
#endif // CSQC

// ======
//  FROG
// ======

#ifdef SVQC
void frog_spit_touch(entity this, entity toucher)
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

	// slow all enemies near the impact site
	FOREACH_ENTITY_RADIUS(this.origin, 16, it.takedamage && IS_MONSTER(it) && it.health > 0,
	{
		float efftime = 3;
		float curtime = StatusEffects_gettime(STATUSEFFECT_Slowness, it);
		if((time + efftime) > curtime)
			StatusEffects_apply(STATUSEFFECT_Slowness, it, time + efftime, 0);
	});

	//te_wizspike(this.origin);
	//te_explosion2(this.origin, 55, 5);
	Send_Effect(EFFECT_TE_POISONBIG, this.origin, '0 0 0', 1);
	_sound(this, CH_SHOTS, "weapons/grape_impact.wav", 1, ATTN_NORM);

	delete(this);
}

METHOD(KeylethFrog, tr_precache, void(KeylethFrog thistur))
{
	precache_sound("turrets/frog_attack1.wav");
	precache_sound("turrets/frog_attack2.wav");
	precache_sound("weapons/grape_impact.wav");
}
METHOD(KeylethFrog, tr_think, void(KeylethFrog thistur, entity actor))
{
	// make sure it matches drawn values!
	float myrange = 600 * turret_getpower(actor.tur_level, 0.15);
	float viscone = 0.3;
	if(actor.enemy)
	{
		makevectors(actor.angles);
		vector vec = normalize(actor.enemy.origin - actor.origin);
		float dot = vec * v_forward;

		bool isvisible = visible(actor, actor.enemy);
		if(isvisible || dot < viscone)
			actor.search_time = time + 1;
		if(actor.enemy.health < 1 || actor.enemy.exptime != 0 || time > actor.search_time || vdist(actor.origin - actor.enemy.origin, >, myrange * 1.5))
		{
			actor.enemy = NULL;
			return; // won't find a new target this frame
		}

		if(time >= actor.attack_finished && dot > viscone && isvisible)
		{
			actor.clientframe = TANIM_SHOOT;
			actor.attack_finished = time + max(0.03, (5 / turret_getpower(actor.tur_level, 0.15)));
			if(random() > 0.5)
				_sound(actor, CH_WEAPON_SINGLE, "turrets/frog_attack1.wav", 1, ATTN_NORM);
			else
				_sound(actor, CH_WEAPON_SINGLE, "turrets/frog_attack2.wav", 1, ATTN_NORM);

			vector org = actor.origin;
			vector dir = normalize(CENTER_OR_VIEWOFS(actor.enemy) - org);
			entity newmis = launch_spike(actor, org, dir);
			newmis.projectiledeathtype = DEATH_TRAP.m_id;
			newmis.velocity = dir * 600;
			//newmis.dmg = 16 * turret_getpower(actor.tur_level, 0.15);
			settouch(newmis, frog_spit_touch);
			CSQCProjectile(newmis, true, PROJECTILE_FROG_SPIT, true);
		}
	}
	
	if(!actor.enemy && time >= actor.idle_finished)
	{
		actor.idle_finished = time + 0.5;
		actor.enemy = turret_findtarget(actor, viscone, myrange);
	}
}
METHOD(KeylethFrog, tr_setup, void(KeylethFrog this, entity actor))
{
	actor.health = 250;
	actor.max_health = actor.health;
}
#endif // SVQC
#ifdef CSQC
METHOD(KeylethFrog, tr_drawselected, void(KeylethFrog this, entity actor))
{
	float myrange = 600 * turret_getpower(actor.tur_level, 0.2);
	makevectors(actor.angles);
	vector org = actor.origin;

	Draw_Cone(org, v_forward, myrange, 0.3);

	// TODO: cone?
	//Draw_CylindricLine(org, org + v_forward * myrange, 6, "particles/laserbeam", 0.25, -time * 3, '1 0.25 0', 1, DRAWFLAG_NORMAL, view_origin);
}
METHOD(KeylethFrog, tr_setup, void(KeylethFrog this, entity actor))
{
	actor.anim_idle = '0 11 0';
	actor.anim_shoot = '12 20 0';
}
#endif // CSQC

// ==========
//  FLY TRAP
// ==========

#ifdef SVQC
METHOD(KeylethFlyTrap, tr_precache, void(KeylethFlyTrap thistur))
{
	precache_sound("turrets/flytrap_spit1.wav");
	precache_sound("turrets/flytrap_spit2.wav");
}
METHOD(KeylethFlyTrap, tr_think, void(KeylethFlyTrap thistur, entity actor))
{
	// make sure it matches drawn values!
	float myrange = 150;
	float viscone = 0.3;
	vector org = actor.origin + '0 0 24';

	// copy of the parry code
	makevectors(actor.angles);
	entity targ = NULL;
	float bestdist = 0;
	FOREACH_ENTITY_RADIUS(org, myrange, (it.flags & FL_PROJECTILE) && time > it.parry_time && time > it.parry_cooldown && IS_MONSTER(it.owner),
	{
		if(it.clipgroup == actor.clipgroup || it.velocity == '0 0 0')
			continue;
		float dot = normalize(it.origin - org) * v_forward;
		if(dot <= viscone) { continue; }

		float mydist = vlen2(it.origin - org);
		if(!targ || mydist <= bestdist)
		{
			targ = it;
			bestdist = mydist;
		}
	});

	if(targ)
	{
		actor.clientframe = TANIM_SHOOT;
		actor.attack_finished = time + 0.4; // animation duration

		entity oldown = targ.owner;
		targ.owner = actor;
		targ.realowner = actor;
		targ.clipgroup = actor.clipgroup;
		targ.enemy = oldown;
		targ.parry_time = time; // hack to make parry code trigger on target
		//if(autocvar_sv_quake_reflectshots)
			targ.velocity *= -1;
		//else
			//targ.velocity = v_forward * vlen(targ.velocity);
		targ.angles = vectoangles(targ.velocity);

		targ.projectiledeathtype = DEATH_TRAP.m_id;

		UpdateCSQCProjectile(targ);

		if(time > actor.spamtime)
		{
			actor.spamtime = time + 0.1;
			if(random() > 0.5)
				_sound(actor, CH_WEAPON_SINGLE, "turrets/flytrap_spit1.wav", 1, ATTN_NORM);
			else
				_sound(actor, CH_WEAPON_SINGLE, "turrets/flytrap_spit2.wav", 1, ATTN_NORM);
		}

		// we also take a small amount of damage from the projectile
		float damage = (targ.dmg) ? targ.dmg * 0.5 : 10;
		T_Damage(actor, targ, oldown, damage, DEATH_TRAP.m_id);
	}
}
METHOD(KeylethFlyTrap, tr_setup, void(KeylethFlyTrap this, entity actor))
{
	actor.health = 180;
	actor.max_health = actor.health;
	actor.monster_attack = false;

	actor.solid = SOLID_TRIGGER;
}
#endif // SVQC
#ifdef CSQC
METHOD(KeylethFlyTrap, tr_drawselected, void(KeylethFlyTrap this, entity actor))
{
	float myrange = 150;
	makevectors(actor.angles);
	vector org = actor.origin + '0 0 24';

	Draw_Cone(org, v_forward, myrange, 0.3);

	// TODO: cone?
	//Draw_CylindricLine(org, org + v_forward * myrange, 6, "particles/laserbeam", 0.25, -time * 3, '1 0.25 0', 1, DRAWFLAG_NORMAL, view_origin);
}
METHOD(KeylethFlyTrap, tr_setup, void(KeylethFlyTrap this, entity actor))
{
	actor.anim_idle = '64 79 0';
	actor.anim_shoot = '84 95 0';

	actor.solid = SOLID_TRIGGER;
}
#endif // CSQC
