#include "northpole.qh"

#include "../../monsters/_mod.qh"

#ifdef SVQC
void W_FireNorthPole(entity this, .entity weaponentity);

void player_northpoleb4(entity this) { set_animofs(this, anim_player_axattc1, 4, player_run); }
void player_northpoleb3(entity this) { set_animofs(this, anim_player_axattc1, 3, player_northpoleb4); }
void player_northpoleb2(entity this) { set_animofs(this, anim_player_axattc1, 2, player_northpoleb3); }
void player_northpoleb1(entity this) { set_animofs(this, anim_player_axattc1, 1, player_northpoleb2); }

void wep_northpole_sworda4(entity this) { wep_set_anim(this, 4, w_ready); }
void wep_northpole_sworda3(entity this) { wep_set_anim(this, 3, wep_northpole_sworda4); W_FireNorthPole(this.owner, this.weaponentity_fld); }
void wep_northpole_sworda2(entity this) { wep_set_anim(this, 2, wep_northpole_sworda3); }
void wep_northpole_sworda1(entity this) { wep_set_anim(this, 1, wep_northpole_sworda2); W_Parry_Trigger(this.owner, 0); }

void icicle_touch(entity this, entity toucher)
{
	if(toucher == this.owner || toucher.owner == this.owner)
		return;

	if(toucher.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if(pointcontents(this.origin) == CONTENT_SKY)
	{
		delete(this);
		return;
	}
	
// hit something that bleeds
	if(toucher.takedamage) // yoder mod, jan 05 2021
	{
		float damg = ((this.dmg) ? this.dmg : 30);
		spawn_touchblood(this, damg, toucher);
		T_Damage(toucher, this, this.owner, damg, this.projectiledeathtype);
	}

	_sound(this, CH_WEAPON_SINGLE, "ice_queen/frostshard_impact.wav", 1, ATTN_NORM);
	//te_explosion2(this.origin, 244, 3);
	particle(this.origin, '0 0 0', 40, 10);

	delete(this);
}

void icicle_launch(entity this, vector org)
{
	// assumes v_ angles are setup

	entity newmis = launch_spike(this, org, '0 0 1');
	newmis.velocity = '0 0 1'; // gravity handles it mostly
	newmis.avelocity = '0 0 0';
	newmis.dmg = 40;
	settouch(newmis, icicle_touch);
	set_movetype(newmis, MOVETYPE_TOSS);
	newmis.angles = vectoangles(newmis.velocity);
	newmis.projectiledeathtype = WEP_NORTHPOLE.m_id;
	setsize(newmis, '0 0 0', '0 0 0');
	setthink(newmis, SUB_Remove);
	newmis.count = time + 7;
	newmis.noise = "ice_queen/frostshard_impact.wav";

	CSQCProjectile(newmis, true, PROJECTILE_ICICLE, true);
}

void W_IceSpear_Explode(entity this)
{
	_sound(this, CH_WEAPON_SINGLE, "ice_queen/frostshard_impact.wav", 1, ATTN_NORM);
	te_explosion2(this.origin, 40, 7);

	delete(this);
}

void W_IceSpear_Touch(entity this, entity toucher)
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
		setthink(this, W_IceSpear_Explode);
		this.nextthink = time;
		settouch(this, func_null);
	}

	//delete(this);
}

.float icespear_dmgtime;
.float icespear_lastdrop;
.int icespear_hitcnt;
void W_IceSpear_Think(entity this)
{
	if(time > this.count)
	{
		W_IceSpear_Explode(this);
		return;
	}

	// hack to ensure the projectile keeps going even if it hits a target
	this.nextthink = time;

	if(time >= this.icespear_lastdrop)
	{
		this.icespear_lastdrop = time + 0.15;
		icicle_launch(this.owner, this.origin);
	}

	bool hitenemy = false;
	FOREACH_ENTITY_RADIUS(this.origin, this.cnt, it.takedamage && it != this.owner,
	{
		if(time < it.icespear_dmgtime)
			continue;
		if(it.clipgroup && it.clipgroup == this.clipgroup)
			continue;
		float damg = ((this.dmg) ? this.dmg : 30);
		if(it.monsterdef.spawnflags & MONSTER_TYPE_UNDEAD)
			damg = 120;
		spawn_touchblood(this, damg, it);
		T_Damage(it, this, this.owner, damg, this.projectiledeathtype);

		it.icespear_dmgtime = time + 0.2; // prevent instant death

		particle(this.origin, '0 0 20', 40, 10);

		hitenemy = true;
	});

	if(hitenemy)
	{
		this.icespear_hitcnt += 1;

		if(this.icespear_hitcnt >= 3)
		{
			setthink(this, W_IceSpear_Explode);
			this.nextthink = time;
			settouch(this, func_null);
		}
	}
}

void W_IceSpear_Fire(entity this, vector org, vector dir, .entity weaponentity)
{
	// assumes v_ angles are setup

	entity missile = spawn();
	missile.classname = "icespear";
	missile.flags = FL_PROJECTILE;
	missile.owner = this;
	missile.realowner = this;
	missile.clipgroup = this.clipgroup;
	set_movetype(missile, MOVETYPE_TOSS);
	missile.solid = SOLID_TRIGGER;
	missile.dphitcontentsmask = DPCONTENTS_SOLID;
	missile.gravity = 0.45;
	missile.projectiledeathtype = WEP_NORTHPOLE.m_id;
	missile.cnt = 32; // rough area of effect during travel
	missile.icespear_hitcnt = 0;
	missile.dmg = 50;
	missile.icespear_lastdrop = time + 0.3;

	missile.velocity = dir * 1000;
	missile.velocity_z += 100;

	missile.angles = vectoangles(missile.velocity);

	settouch(missile, W_IceSpear_Touch);

	missile.count = time + 10;
	missile.nextthink = time;
	setthink(missile, W_IceSpear_Think);

	setsize(missile, '0 0 0', '0 0 0');
	setorigin(missile, org);

	IL_PUSH(g_projectiles, missile);

	CSQCProjectile(missile, true, PROJECTILE_ICE_SPEAR, true);
}

void W_FireNorthPole(entity this, .entity weaponentity)
{
	makevectors(this.v_angle);
	vector dir = v_forward;
	vector source = W_Shotorg(this, weaponentity);
	int oldsolid = this.dphitcontentsmask;
	this.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	float arange = 180;
	traceline(source, source + v_forward * arange, false, this);
	this.dphitcontentsmask = oldsolid;
	if(trace_fraction == 1.0)
	{
		W_IceSpear_Fire(this, source, dir, weaponentity);
		return;
	}
	
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
		float damage = 90;
		T_Damage(trace_ent, this, this, damage, WEP_NORTHPOLE.m_id);

		W_IceSpear_Fire(this, source, dir, weaponentity);
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

PRECACHE(NorthPole)
{
	precache_model("progs/v_northpole.mdl");
	precache_model("progs/g_northpole.mdl");

	precache_sound("enviro/physics/trcut.wav");
	precache_sound("enviro/physics/axemet1.wav");
	precache_sound("enviro/physics/axemet2.wav");
	precache_sound("enviro/physics/axemet3.wav");
	precache_sound("monsters/juggers/jbent.wav");
}

METHOD(NorthPole, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	if(thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	{
		if(IS_PLAYER(actor))
			player_northpoleb1(actor);
		sound(actor, CH_WEAPON_SINGLE, SND_NORTHPOLE_SWING, 1, ATTN_NORM);
		wep_northpole_sworda1(actor.(weaponentity));
		weapon_prepareattack(thiswep, actor, weaponentity, 0.7);
	}
}
METHOD(NorthPole, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	// does not use ammo
	return true;
}
METHOD(NorthPole, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(NorthPole, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_FRAG;
}
#endif
