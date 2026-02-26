#include "starfury.qh"

#include "../../monsters/_mod.qh"

#ifdef SVQC
void W_FireStarfury(entity this, .entity weaponentity);
void W_Starfury_Star(entity this, .entity weaponentity);

void player_starfurya4(entity this) { set_animofs(this, anim_player_axattd1, 4, player_run); }
void player_starfurya3(entity this) { set_animofs(this, anim_player_axattd1, 3, player_starfurya4); }
void player_starfurya2(entity this) { set_animofs(this, anim_player_axattd1, 2, player_starfurya3); }
void player_starfurya1(entity this) { set_animofs(this, anim_player_axattd1, 1, player_starfurya2); }

void wep_starfury_sworda4(entity this) { wep_set_anim(this, 3, w_ready); }
void wep_starfury_sworda3(entity this) { wep_set_anim(this, 3, wep_starfury_sworda4); W_FireStarfury(this.owner, this.weaponentity_fld); }
void wep_starfury_sworda2(entity this) { wep_set_anim(this, 2, wep_starfury_sworda3); }
void wep_starfury_sworda1(entity this) { wep_set_anim(this, 1, wep_starfury_sworda2); W_Parry_Trigger(this.owner, 0); W_Starfury_Star(this.owner, this.weaponentity_fld); }

void player_starfuryb4(entity this) { set_animofs(this, anim_player_axattc1, 4, player_run); }
void player_starfuryb3(entity this) { set_animofs(this, anim_player_axattc1, 3, player_starfuryb4); }
void player_starfuryb2(entity this) { set_animofs(this, anim_player_axattc1, 2, player_starfuryb3); }
void player_starfuryb1(entity this) { set_animofs(this, anim_player_axattc1, 1, player_starfuryb2); }

void wep_starfury_swordb4(entity this) { wep_set_anim(this, 8, w_ready); }
void wep_starfury_swordb3(entity this) { wep_set_anim(this, 7, wep_starfury_swordb4); W_FireStarfury(this.owner, this.weaponentity_fld); }
void wep_starfury_swordb2(entity this) { wep_set_anim(this, 6, wep_starfury_swordb3); }
void wep_starfury_swordb1(entity this) { wep_set_anim(this, 5, wep_starfury_swordb2); W_Parry_Trigger(this.owner, 0); W_Starfury_Star(this.owner, this.weaponentity_fld); }

.int star_hitcount;
.float star_dmgtime;
void W_Starfury_Think(entity this)
{
	if(time > this.count)
	{
		_sound(this, CH_WEAPON_SINGLE, "weapons/starfury_star_impact.wav", 1, 0.5);
		Send_Effect(EFFECT_MEOWMERE_GLIMMER, this.origin, '0 0 20', 1);
		delete(this);
		return;
	}

	// hack to ensure the projectile keeps going even if it hits a target
	this.nextthink = time;

	bool hitenemy = false;
	FOREACH_ENTITY_RADIUS(this.origin, this.cnt, it.takedamage && it != this.owner,
	{
		if(it.star_dmgtime > time)
			continue;
		if(it.clipgroup && it.clipgroup == this.clipgroup)
			continue;
		float damg = ((this.dmg) ? this.dmg : 60);
		if(it.monsterdef.spawnflags & MONSTER_TYPE_UNDEAD)
			damg = 120;
		spawn_touchblood(this, damg, it);
		T_Damage(it, this, this.owner, damg, this.projectiledeathtype);

		it.star_dmgtime = time + 0.2; // prevent instant death

		hitenemy = true;
	});

	if(hitenemy)
	{
		this.star_hitcount += 1;

		if(this.star_hitcount >= 3)
		{
			setthink(this, SUB_Remove);
			this.nextthink = time;
			settouch(this, func_null);
		}
	}
}

void W_Starfury_Fire(entity this, vector org, vector dir, .entity weaponentity)
{
	// assumes v_ angles are setup

	org += v_right * 8;

	entity missile = spawn();
	missile.classname = "starfury_star";
	missile.flags = FL_PROJECTILE;
	missile.owner = this;
	missile.realowner = this;
	missile.clipgroup = this.clipgroup;
	set_movetype(missile, MOVETYPE_NOCLIP);
	missile.solid = SOLID_NOT;
	//missile.gravity = 1;
	missile.projectiledeathtype = WEP_STARFURY.m_id;
	missile.cnt = 24; // rough area of effect during travel
	missile.dmg = 100;

	float myspeed = 1800;

	missile.velocity = dir * myspeed;
	//missile.velocity_z = 200;

	missile.angles = vectoangles(missile.velocity);

	missile.count = time + (1000 / myspeed);
	missile.nextthink = time;
	setthink(missile, W_Starfury_Think);

	setsize(missile, '0 0 0', '0 0 0');
	setorigin(missile, org);

	_sound(missile, CH_WEAPON_SINGLE, "weapons/starfury_star_fall.wav", 1, 0.5);

	IL_PUSH(g_projectiles, missile);

	CSQCProjectile(missile, true, PROJECTILE_STARFURY, true);
}

void W_Starfury_Star(entity this, .entity weaponentity)
{
	if(time < this.attack2_finished)
		return;
	this.attack2_finished = time + 1;

	// already have angles from upper function

	vector source = W_Shotorg(this, weaponentity);
	int oldsolid = this.dphitcontentsmask;
	this.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	float arange = 800;
	traceline(source, source + v_forward * arange, false, this);
	this.dphitcontentsmask = oldsolid;

	vector end = trace_endpos;
	vector start = end + '0 0 1000';
	// offset it so it isn't faling directly down
	start.x += crandom() * 256;
	start.y += crandom() * 256;

	vector dir = normalize(end - start);

	W_Starfury_Fire(this, start, dir, weaponentity);
}

void W_FireStarfury(entity this, .entity weaponentity)
{
	makevectors(this.v_angle);
	vector source = W_Shotorg(this, weaponentity);
	int oldsolid = this.dphitcontentsmask;
	this.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	float arange = 120;
	traceline(source, source + v_forward * arange, false, this);
	this.dphitcontentsmask = oldsolid;
	if(trace_fraction == 1.0)
		return;
	
	vector org = trace_endpos - v_forward * 4;

	if(trace_ent && W_Parry(this, trace_ent))
		return;

	float r = random();
	if(trace_ent.takedamage) // yoder mod, Jan 05 2021
	{
		{
			if(trace_ent.monsterdef == MON_JUGGERNAUT) // special case: axe attacks produce unique sound against juggernauts TODO: handle melee attacks in monster pain code
				_sound(this, CH_WEAPON_SINGLE, "monsters/juggers/jbent.wav", 1, ATTN_NORM);
			else if(trace_ent.monsterdef && (trace_ent.monsterdef.spawnflags & MON_FLAG_METAL))
			{
				if(r < 0.3)
					_sound(trace_ent, CH_SHOTS, "enviro/physics/axemet1.wav", 1, ATTN_NORM);
				else if(r < 0.6)
					_sound(trace_ent, CH_SHOTS, "enviro/physics/axemet2.wav", 1, ATTN_NORM);
				else
					_sound(trace_ent, CH_SHOTS, "enviro/physics/axemet3.wav", 1, ATTN_NORM);
			}
			else if(IS_PLAYER(trace_ent) && trace_ent.armorvalue > 0)
			{
				if(r < 0.3)
					_sound(trace_ent, CH_SHOTS, "enviro/physics/axemet1.wav", 1, ATTN_NORM);
				else if(r < 0.6)
					_sound(trace_ent, CH_SHOTS, "enviro/physics/axemet2.wav", 1, ATTN_NORM);
				else
					_sound(trace_ent, CH_SHOTS, "enviro/physics/axemet3.wav", 1, ATTN_NORM);
			}
			else
			{
				_sound(trace_ent, CH_SHOTS, "enviro/physics/trcut.wav", 1, ATTN_NORM);
				SpawnBlood(org, '0 0 0', 20, trace_ent);
				SpawnBlood(org, '0 0 0', 20, trace_ent);
				SpawnBlood(org, '0 0 0', 20, trace_ent);
			}
		}
		trace_ent.axhitme = true;
		float damage = 60;
		T_Damage(trace_ent, this, this, damage, WEP_STARFURY.m_id);
	}
	else
	{	// hit wall
		if(r < 0.3)
			_sound(this, CH_SHOTS, "enviro/physics/axemet1.wav", 1, ATTN_NORM);
		else if(r < 0.6)
			_sound(this, CH_SHOTS, "enviro/physics/axemet2.wav", 1, ATTN_NORM);
		else
			_sound(this, CH_SHOTS, "enviro/physics/axemet3.wav", 1, ATTN_NORM);
		te_gunshot(org);
	}
}

PRECACHE(Starfury)
{
	precache_model("progs/v_starfury.mdl");
	precache_model("progs/g_starfury.mdl");

	precache_sound("enviro/physics/trcut.wav");
	precache_sound("enviro/physics/axemet1.wav");
	precache_sound("enviro/physics/axemet2.wav");
	precache_sound("enviro/physics/axemet3.wav");
	precache_sound("monsters/juggers/jbent.wav");

	precache_sound("weapons/starfury_star_fall.wav");
	precache_sound("weapons/starfury_star_impact.wav");
	precache_sound("weapons/terra_swing.wav");
}

METHOD(Starfury, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	if(thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	{
		if(IS_PLAYER(actor))
			player_starfuryb1(actor);
		_sound(actor, CH_WEAPON_SINGLE, "weapons/terra_swing.wav", 1, ATTN_NORM);
		wep_starfury_sworda1(actor.(weaponentity));
		weapon_prepareattack(thiswep, actor, weaponentity, 0.33);
	}
}
METHOD(Starfury, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	// does not use ammo
	return true;
}
METHOD(Starfury, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(Starfury, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_FRAG;
}
#endif
