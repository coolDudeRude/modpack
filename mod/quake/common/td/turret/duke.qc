#include "duke.qh"

// =============
//  FLAK CANNON
// =============

#ifdef SVQC
void flakcannon_touch(entity this, entity toucher)
{
	if(toucher == this.owner || toucher.solid == SOLID_TRIGGER)
		return;		// don't explode on owner

	if(pointcontents(this.origin) == CONTENT_SKY)
	{
		delete(this);
		return;
	}

	float mydmg = (this.dmg) ? this.dmg : 15;
	float damg = mydmg + random() * (mydmg * 0.2);
	
	if(toucher.health)
	{
		if(toucher.monsterdef && (toucher.monsterdef.spawnflags & MON_FLAG_EXPLOSIONRESISTANT))
			damg = damg * 0.5;	// mostly immune
		if(toucher.resist_rockets != 0)
		{
			damg = Resist_Damage(toucher, IT_ROCKETS, damg);
			Resist_Rockets(toucher, this.origin);
		}
		T_Damage(toucher, this, this.owner, damg, this.projectiledeathtype);
	}

	// don't do radius damage to the toucher, because all the damage
	// was done in the impact
	T_RadiusDamage(this, this.owner, mydmg * 1.2, this.projectiledeathtype, toucher);

	if(this.noise && this.noise != "")
		_sound(this, CH_WEAPON_SINGLE, this.noise, 1, ATTN_NORM);

	this.origin = this.origin - 8 * normalize(this.velocity);

	entity exp = spawn();
	exp.nextthink = time;
	setthink(exp, s_explode1);
	_setmodel(exp, "progs/s_explod.spr");
	setsize(exp, '0 0 0', '0 0 0');
	setorigin(exp, this.origin);

	delete(this);
}

METHOD(DukeFlakCannon, tr_precache, void(DukeFlakCannon thistur))
{
	precache_sound("turrets/flakcannon_fire.wav");
	precache_sound("turrets/flakcannon_explode.wav");
}
METHOD(DukeFlakCannon, tr_think, void(DukeFlakCannon thistur, entity actor))
{
	// make sure it matches drawn values!
	float myrange = 700 * turret_getpower(actor.tur_level, 0.2);
	float viscone = 0.5;
	if(actor.enemy)
	{
		vector myorg = actor.origin + actor.view_ofs;
		vector targ_org = (actor.enemy.absmin + actor.enemy.absmax) * 0.5;
		makevectors(actor.angles);
		vector vec = normalize(targ_org - myorg);
		float dot = vec * v_forward;

		bool isvisible = visible(actor, actor.enemy);
		if(isvisible || dot < viscone)
			actor.search_time = time + 1;
		if(actor.enemy.health < 1 || actor.enemy.exptime != 0 || time > actor.search_time || vdist(myorg - targ_org, >, myrange * 1.5))
		{
			actor.enemy = NULL;
			return; // won't find a new target this frame
		}

		if(time >= actor.attack_finished && dot > viscone && isvisible)
		{
			actor.attack_finished = time + max(0.03, (2 / turret_getpower(actor.tur_level, 0.5)));

			_sound(actor, CH_WEAPON_SINGLE, "turrets/flakcannon_fire.wav", 1, ATTN_NORM);

			vector org = myorg;
			vector dir = normalize(CENTER_OR_VIEWOFS(actor.enemy) - org);
			entity newmis = launch_spike(actor, org, dir);
			newmis.projectiledeathtype = DEATH_TRAP.m_id;
			newmis.velocity = dir * 1200;
			newmis.noise = "turrets/flakcannon_explode.wav";
			settouch(newmis, flakcannon_touch);
			newmis.dmg = thistur.tur_dmg * turret_getpower(actor.tur_level, thistur.tur_dmgscale);
			CSQCProjectile(newmis, true, PROJECTILE_FLAK_CANNON, true);
		}
	}
	
	if(!actor.enemy && time >= actor.idle_finished)
	{
		actor.idle_finished = time + 0.5;
		actor.enemy = turret_findtarget(actor, viscone, myrange);
	}
}
METHOD(DukeFlakCannon, tr_setup, void(DukeFlakCannon this, entity actor))
{
	actor.view_ofs = '0 0 35';
}
#endif // SVQC
#ifdef CSQC
METHOD(DukeFlakCannon, tr_drawselected, void(DukeFlakCannon this, entity actor))
{
	float myrange = 800 * turret_getpower(actor.tur_level, 0.2);
	makevectors(actor.angles);
	vector org = actor.origin + '0 0 35';

	Draw_Cone(org, v_forward, myrange, 0.5);

	// TODO: cone?
	//Draw_CylindricLine(org, org + v_forward * myrange, 6, "particles/laserbeam", 0.25, -time * 3, '1 0.25 0', 1, DRAWFLAG_NORMAL, view_origin);
}
#endif // CSQC

// ========
//  NAILER
// ========

#ifdef SVQC
METHOD(DukeTwinGun, tr_precache, void(DukeTwinGun thistur))
{
	precache_sound("weapons/spike2.wav");
}
METHOD(DukeTwinGun, tr_think, void(DukeTwinGun thistur, entity actor))
{
	// make sure it matches drawn values!
	float myrange = 600 * turret_getpower(actor.tur_level, 0.2);
	if(actor.enemy)
	{
		vector myorg = actor.origin + actor.view_ofs;
		vector targ_org = (actor.enemy.absmin + actor.enemy.absmax) * 0.5;
		makevectors(actor.angles);
		vector vec = normalize(targ_org - myorg);
		float dot = vec * v_forward;

		bool isvisible = visible(actor, actor.enemy);
		if(isvisible || dot < 0.3)
			actor.search_time = time + 1;
		if(actor.enemy.health < 1 || actor.enemy.exptime != 0 || time > actor.search_time || vdist(myorg - targ_org, >, myrange * 1.5))
		{
			actor.enemy = NULL;
			return; // won't find a new target this frame
		}

		if(time >= actor.attack_finished && dot > 0.3 && isvisible)
		{
			actor.attack_finished = time + max(0.03, (0.33 / turret_getpower(actor.tur_level, 0.3)));
			float offset = (actor.cnt) ? 6 : -6;
			actor.cnt = (actor.cnt) ? 0 : 1;

			_sound(actor, CH_WEAPON_SINGLE, "weapons/spike2.wav", 0.7, ATTN_NORM);

			vector org = myorg + v_right * offset;
			vector dir = normalize(CENTER_OR_VIEWOFS(actor.enemy) - org);
			entity newmis = launch_spike(actor, org, dir);
			newmis.projectiledeathtype = DEATH_TRAP.m_id;
			newmis.velocity = dir * 1000;
			newmis.dmg = thistur.tur_dmg * turret_getpower(actor.tur_level, thistur.tur_dmgscale);
			CSQCProjectile(newmis, true, PROJECTILE_BULLET, true);
		}
	}
	
	if(!actor.enemy && time >= actor.idle_finished)
	{
		actor.idle_finished = time + 0.5;
		actor.enemy = turret_findtarget(actor, 0.3, myrange);
	}
}
METHOD(DukeTwinGun, tr_setup, void(DukeTwinGun this, entity actor))
{
	actor.view_ofs = '0 0 29';
}
#endif // SVQC
#ifdef CSQC
METHOD(DukeTwinGun, tr_drawselected, void(DukeTwinGun this, entity actor))
{
	float myrange = 600 * turret_getpower(actor.tur_level, 0.2);
	makevectors(actor.angles);
	vector org = actor.origin + '0 0 29';

	Draw_Cone(org, v_forward, myrange, 0.3);

	// TODO: cone?
	//Draw_CylindricLine(org, org + v_forward * myrange, 6, "particles/laserbeam", 0.25, -time * 3, '1 0.25 0', 1, DRAWFLAG_NORMAL, view_origin);
}
#endif // CSQC

// ========
//  MORTAR
// ========

#ifdef SVQC
METHOD(DukeRocketLauncher, tr_precache, void(DukeRocketLauncher thistur))
{
	precache_sound("turrets/rocketlauncher_fire.wav");
}
METHOD(DukeRocketLauncher, tr_think, void(DukeRocketLauncher thistur, entity actor))
{
	// make sure it matches drawn values!
	float myrange = 420 * turret_getpower(actor.tur_level, 0.2);
	float viscone = 0.4;
	if(actor.enemy)
	{
		vector myorg = actor.origin + actor.view_ofs;
		vector targ_org = (actor.enemy.absmin + actor.enemy.absmax) * 0.5;
		makevectors(actor.angles);
		vector vec = normalize(targ_org - myorg);
		float dot = vec * v_forward;

		bool isvisible = visible(actor, actor.enemy);
		if(isvisible || dot < viscone)
			actor.search_time = time + 1;
		if(actor.enemy.health < 1 || actor.enemy.exptime != 0 || time > actor.search_time || vdist(myorg - targ_org, >, myrange * 1.5))
		{
			actor.enemy = NULL;
			return; // won't find a new target this frame
		}

		if(time >= actor.attack_finished && dot > viscone && isvisible)
		{
			actor.attack_finished = time + max(0.03, (1.7 / turret_getpower(actor.tur_level, 0.3)));
			float offset = (actor.cnt) ? 14 : -14;
			actor.cnt = (actor.cnt) ? 0 : 1;

			_sound(actor, CH_WEAPON_SINGLE, "turrets/rocketlauncher_fire.wav", 1, ATTN_NORM);

			vector org = myorg + v_right * offset;
			vector dir = normalize(CENTER_OR_VIEWOFS(actor.enemy) - org);
			entity newmis = launch_spike(actor, org, dir);
			newmis.projectiledeathtype = DEATH_TRAP.m_id;
			newmis.velocity = dir * 1000;
			settouch(newmis, T_MissileTouch);
			newmis.dmg = thistur.tur_dmg * turret_getpower(actor.tur_level, thistur.tur_dmgscale);
			CSQCProjectile(newmis, true, PROJECTILE_MULTI_ROCKET, true);
		}
	}
	
	if(!actor.enemy && time >= actor.idle_finished)
	{
		actor.idle_finished = time + 0.5;
		actor.enemy = turret_findtarget(actor, viscone, myrange);
	}
}
METHOD(DukeRocketLauncher, tr_setup, void(DukeRocketLauncher this, entity actor))
{
	actor.view_ofs = '0 0 29'; // for line of sight checks
}
#endif // SVQC
#ifdef CSQC
METHOD(DukeRocketLauncher, tr_drawselected, void(DukeRocketLauncher this, entity actor))
{
	float myrange = 420 * turret_getpower(actor.tur_level, 0.2);
	makevectors(actor.angles);
	vector org = actor.origin + '0 0 29';

	Draw_Cone(org, v_forward, myrange, 0.4);

	// TODO: cone?
	//Draw_CylindricLine(org, org + v_forward * myrange, 6, "particles/laserbeam", 0.25, -time * 3, '1 0.25 0', 1, DRAWFLAG_NORMAL, view_origin);
}
#endif // CSQC
