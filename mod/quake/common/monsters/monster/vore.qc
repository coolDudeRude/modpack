#include "vore.qh"

#include "legond.qh"
#include "zombie.qh"

#ifdef SVQC
const int anim_shal_attack = 0; //'0 10 0'
const int anim_shal_pain = 11; //'11 15 0'
const int anim_shal_death = 16; //'16 22 0'
const int anim_shal_walk = 23; //'23 34 0'

void ShalMissile(entity this);

void shal_stand(entity this) { set_animofs(this, anim_shal_walk, 1, shal_stand); ai_stand(this); }

void shal_walk1(entity this);
void shal_walk12(entity this) { set_animofs(this, anim_shal_walk, 1, shal_walk1); ai_walk(this, 5); }
void shal_walk11(entity this) { set_animofs(this, anim_shal_walk, 12, shal_walk12); ai_walk(this, 4); }
void shal_walk10(entity this) { set_animofs(this, anim_shal_walk, 11, shal_walk11); ai_walk(this, 0); monster_footstep(this, false); }
void shal_walk9(entity this) { set_animofs(this, anim_shal_walk, 10, shal_walk10); ai_walk(this, 5); }
void shal_walk8(entity this) { set_animofs(this, anim_shal_walk, 9, shal_walk9); ai_walk(this, 6); }
void shal_walk7(entity this) { set_animofs(this, anim_shal_walk, 8, shal_walk8); ai_walk(this, 5); }
void shal_walk6(entity this) { set_animofs(this, anim_shal_walk, 7, shal_walk7); ai_walk(this, 0); monster_footstep(this, false); }
void shal_walk5(entity this) { set_animofs(this, anim_shal_walk, 6, shal_walk6); ai_walk(this, 0); }
void shal_walk4(entity this) { set_animofs(this, anim_shal_walk, 5, shal_walk5); ai_walk(this, 0); }
void shal_walk3(entity this) { set_animofs(this, anim_shal_walk, 4, shal_walk4); ai_walk(this, 0); monster_footstep(this, false); }
void shal_walk2(entity this) { set_animofs(this, anim_shal_walk, 3, shal_walk3); ai_walk(this, 4); }
void shal_walk1(entity this)
{
	set_animofs(this, anim_shal_walk, 2, shal_walk2);
	if(random() < 0.2)
	{
		if(IsQBJMap())
			_sound(this, CH_VOICE, "shalrath/shalrath_idle.wav", 1, ATTN_IDLE);
		else
			_sound(this, CH_VOICE, "shalrath/idle.wav", 1, ATTN_IDLE);
	}
	ai_walk(this, 6);
}

void shal_run1(entity this);
void shal_run12(entity this) { set_animofs(this, anim_shal_walk, 1, shal_run1); ai_run(this, 5); }
void shal_run11(entity this) { set_animofs(this, anim_shal_walk, 12, shal_run12); ai_run(this, 4); }
void shal_run10(entity this) { set_animofs(this, anim_shal_walk, 11, shal_run11); ai_run(this, 0); }
void shal_run9(entity this) { set_animofs(this, anim_shal_walk, 10, shal_run10); ai_run(this, 5); monster_footstep(this, false); }
void shal_run8(entity this) { set_animofs(this, anim_shal_walk, 9, shal_run9); ai_run(this, 6); }
void shal_run7(entity this) { set_animofs(this, anim_shal_walk, 8, shal_run8); ai_run(this, 5); }
void shal_run6(entity this) { set_animofs(this, anim_shal_walk, 7, shal_run7); ai_run(this, 0); monster_footstep(this, false); }
void shal_run5(entity this) { set_animofs(this, anim_shal_walk, 6, shal_run6); ai_run(this, 0); }
void shal_run4(entity this) { set_animofs(this, anim_shal_walk, 5, shal_run5); ai_run(this, 0); }
void shal_run3(entity this) { set_animofs(this, anim_shal_walk, 4, shal_run4); ai_run(this, 0); monster_footstep(this, false); }
void shal_run2(entity this) { set_animofs(this, anim_shal_walk, 3, shal_run3); ai_run(this, 4); }
void shal_run1(entity this)
{
	set_animofs(this, anim_shal_walk, 2, shal_run2);
	if(random() < 0.2)
	{
		if(IsQBJMap())
			_sound(this, CH_VOICE, "shalrath/shalrath_idle.wav", 1, ATTN_IDLE);
		else
			_sound(this, CH_VOICE, "shalrath/idle.wav", 1, ATTN_IDLE);
	}
	ai_run(this, 6);
}

void shal_attack11(entity this) { set_animofs(this, anim_shal_attack, 11, shal_run1); ai_face(this); }
void shal_attack10(entity this) { set_animofs(this, anim_shal_attack, 10, shal_attack11); ai_face(this); }
void shal_attack9(entity this) { set_animofs(this, anim_shal_attack, 9, shal_attack10); ShalMissile(this); }
void shal_attack8(entity this) { set_animofs(this, anim_shal_attack, 8, shal_attack9); ai_face(this); }
void shal_attack7(entity this) { set_animofs(this, anim_shal_attack, 7, shal_attack8); ai_face(this); }
void shal_attack6(entity this) { set_animofs(this, anim_shal_attack, 6, shal_attack7); ai_face(this); }
void shal_attack5(entity this) { set_animofs(this, anim_shal_attack, 5, shal_attack6); ai_face(this); }
void shal_attack4(entity this) { set_animofs(this, anim_shal_attack, 4, shal_attack5); ai_face(this); }
void shal_attack3(entity this) { set_animofs(this, anim_shal_attack, 3, shal_attack4); ai_face(this); }
void shal_attack2(entity this) { set_animofs(this, anim_shal_attack, 2, shal_attack3); ai_face(this); }
void shal_attack1(entity this)
{
	set_animofs(this, anim_shal_attack, 1, shal_attack2);
	if(IsQBJMap())
		_sound(this, CH_VOICE, "shalrath/shalrath_attack.wav", 1, ATTN_NORM);
	else
		_sound(this, CH_VOICE, "shalrath/attack.wav", 1, ATTN_NORM);
	ai_face(this);
}

void shal_pain5(entity this) { set_animofs(this, anim_shal_pain, 5, shal_run1); }
void shal_pain4(entity this) { set_animofs(this, anim_shal_pain, 4, shal_pain5); }
void shal_pain3(entity this) { set_animofs(this, anim_shal_pain, 3, shal_pain4); }
void shal_pain2(entity this) { set_animofs(this, anim_shal_pain, 2, shal_pain3); }
void shal_pain1(entity this) { set_animofs(this, anim_shal_pain, 1, shal_pain2); }

void shal_death7(entity this)
{
	set_animofs(this, anim_shal_death, 7, shal_death7);
	CorpseThink(this);
}
void shal_death6(entity this) { set_animofs(this, anim_shal_death, 6, shal_death7); }
void shal_death5(entity this) { set_animofs(this, anim_shal_death, 5, shal_death6); }
void shal_death4(entity this) { set_animofs(this, anim_shal_death, 4, shal_death5); }
void shal_death3(entity this) { set_animofs(this, anim_shal_death, 3, shal_death4); }
void shal_death2(entity this) { set_animofs(this, anim_shal_death, 2, shal_death3); }
void shal_death1(entity this) { set_animofs(this, anim_shal_death, 1, shal_death2); }

void shalrath_pain(entity this, entity attacker, float damage, int deathtype)
{
	if(this.pain_finished > time)
		return;

	if(IsQBJMap())
		_sound(this, CH_VOICE, "shalrath/shalrath_pain.wav", 1, ATTN_NORM);
	else
		_sound(this, CH_VOICE, "shalrath/pain.wav", 1, ATTN_NORM);
	this.pain_finished = time + 3;
	shal_pain1(this);
}

void shalrath_die(entity this, entity inflictor, entity attacker, int deathtype)
{
	int killed_type = Death_SpecialType(this, inflictor, attacker, deathtype);
	switch(killed_type)
	{
		case KILLED_NORMAL: break; // normal death
		case KILLED_GIBBED:
		{
			_sound(this, CH_VOICE, "player/udeath.wav", 1, ATTN_NORM);
			if(IsQBJMap())
				ThrowGib(this, inflictor, "progs/gibs/gibhead_vore.mdl", this.health);
			else
				ThrowGib(this, inflictor, "progs/h_shal.mdl", this.health);
			ThrowGib(this, inflictor, "progs/gib1.mdl", this.health);
			ThrowGib(this, inflictor, "progs/gib2.mdl", this.health);
			ThrowGib(this, inflictor, "progs/gib3.mdl", this.health);
			// fall through to special handling
		}
		default: Death_SpecialHandle(this, killed_type); return;
	}

	if(IsQBJMap())
		_sound(this, CH_VOICE, "shalrath/shalrath_death.wav", 1, ATTN_NORM);
	else
		_sound(this, CH_VOICE, "shalrath/death.wav", 1, ATTN_NORM);
	shal_death1(this);
	this.solid = SOLID_NOT;
	// insert death sounds here
}

/*
================
ShalMissile
================
*/
void ShalMissileTouch(entity this, entity toucher);
void ShalHome(entity this);
void ShalMissile(entity this)
{
	vector dir = normalize((this.enemy.origin + '0 0 10') - this.origin);

	this.effects |= EF_MUZZLEFLASH;
	_sound(this, CH_WEAPON_SINGLE, "shalrath/attack2.wav", 1, ATTN_NORM);

	entity missile = spawn();
	missile.flags = FL_PROJECTILE;
	missile.classname = "vore_ball";
	missile.owner = this;
	missile.projectiledeathtype = DEATH_MONSTER_VORE.m_id | HITTYPE_MAGIC;
	missile.clipgroup = this.clipgroup;

	missile.solid = SOLID_BBOX;
	set_movetype(missile, MOVETYPE_FLYMISSILE);

	setsize(missile, '0 0 0', '0 0 0');		

	missile.origin = this.origin + '0 0 10';
	missile.velocity = dir * 400;
	missile.avelocity = '300 300 300';
	missile.nextthink = time;
	missile.count = time + 10;
	setthink(missile, ShalHome);
	missile.enemy = this.enemy;
	settouch(missile, ShalMissileTouch);

	IL_PUSH(g_projectiles, missile);

	CSQCProjectile(missile, false, PROJECTILE_VORE_SPIKE, true);
}

void ShalHome(entity this)
{
	vector vtemp = this.enemy.origin + '0 0 10';
	if(this.enemy.health < 1 || (this.enemy.flags & FL_NOTARGET) || time > this.count)
	{
		delete(this);
		return;
	}
	vector dir = normalize(vtemp - this.origin);
	this.velocity = dir * 250;
	this.nextthink = time;
	setthink(this, ShalHome);
	UpdateCSQCProjectile(this);
}

void ShalMissileTouch(entity this, entity toucher)
{
	if(toucher == this.owner)
		return;		// don't explode on owner

	if(toucher.monsterdef && (toucher.monsterdef.spawnflags & MONSTER_TYPE_UNDEAD))
		T_Damage(toucher, this, this, 110, this.projectiledeathtype);	
	T_RadiusDamage(this, this.owner, 40, this.projectiledeathtype, NULL);
	sound(this, CH_WEAPON_SINGLE, SND_ROCKET_EXPLOSION, 1, ATTN_NORM);

	Send_Effect(EFFECT_EXPLOSION, this.origin, '0 0 0', 1);

	entity newmis = spawn();
	set_movetype(newmis, MOVETYPE_NONE);
	newmis.solid = SOLID_NOT;
	setmodel(newmis, MDL_EXPLOSION);
	setsize(newmis, '0 0 0', '0 0 0');
	setorigin(newmis, findbetterlocation(this.origin, 8));
	s_explode1(newmis);

	delete(this);
}

/*QUAKED monster_shalrath(1 0 0)(-32 -32 -24)(32 32 48) Ambush
*/
spawnfunc(monster_shalrath)
{
	if(substring(world.model, 0, 9) == "maps/mcj_")
	{
		monster_start(this, true, MON_ENDERMAN);
		return;
	}

	if(coop == 2 && orig_random(this) < 0.2)
	{
		monster_start(this, true, MON_LEGOND);
		return;
	}
	monster_start(this, true, MON_VORE);
}

// alkaline
spawnfunc(monster_rider) { monster_start(this, true, MON_VORE); }
#endif // SVQC

#ifdef SVQC
METHOD(Vore, mr_setup, bool(Vore this, entity actor))
{
    TC(Vore, this);

	precache_model("progs/h_shal.mdl");

	precache_sound("shalrath/attack2.wav");

	if(IsQBJMap())
	{
		precache_model("progs/shalrath_qbj.mdl");
		precache_model("progs/gibs/gibhead_vore.mdl");

		precache_sound("shalrath/shalrath_attack.wav");
		precache_sound("shalrath/shalrath_death.wav");
		precache_sound("shalrath/shalrath_idle.wav");
		precache_sound("shalrath/shalrath_pain.wav");
		precache_sound("shalrath/shalrath_sight.wav");

		_setmodel(actor, "progs/shalrath_qbj.mdl");
		setsize(actor, this.m_mins, this.m_maxs);
	}
	else
	{
		precache_sound("shalrath/attack.wav");
		precache_sound("shalrath/death.wav");
		precache_sound("shalrath/idle.wav");
		precache_sound("shalrath/pain.wav");
		precache_sound("shalrath/sight.wav");
	}

    actor.health = 400;
    actor.gibhealth = -90;
    actor.th_stand = shal_stand;
	actor.th_walk = shal_walk1;
	actor.th_run = shal_run1;
	actor.th_die = shalrath_die;
	actor.th_pain = shalrath_pain;
	actor.th_missile = shal_attack1;

	actor.steptype = FS_TYPELIGHT;

    return true;
}
METHOD(Vore, mr_sight, bool(Vore this, entity actor))
{
	TC(Vore, this);

	if(IsQBJMap())
		_sound(actor, CH_VOICE, "shalrath/shalrath_sight.wav", 1, ATTN_NORM);
	else
		_sound(actor, CH_VOICE, "shalrath/sight.wav", 1, ATTN_NORM);

	return true;
}
#endif
