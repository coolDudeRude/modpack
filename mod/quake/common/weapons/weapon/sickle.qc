#include "sickle.qh"

#include "../../monsters/_mod.qh"

#ifdef SVQC
void W_FireSickle(entity this, .entity weaponentity);

void player_sicklea4(entity this) { set_animofs(this, anim_player_axattd1, 4, player_run); }
void player_sicklea3(entity this) { set_animofs(this, anim_player_axattd1, 3, player_sicklea4); }
void player_sicklea2(entity this) { set_animofs(this, anim_player_axattd1, 2, player_sicklea3); }
void player_sicklea1(entity this) { set_animofs(this, anim_player_axattd1, 1, player_sicklea2); }

void wep_sickle_sworda5(entity this) { wep_set_anim(this, 5, w_ready); }
void wep_sickle_sworda4(entity this) { wep_set_anim(this, 4, wep_sickle_sworda5); }
void wep_sickle_sworda3(entity this) { wep_set_anim(this, 3, wep_sickle_sworda4); W_FireSickle(this.owner, this.weaponentity_fld); }
void wep_sickle_sworda2(entity this) { wep_set_anim(this, 2, wep_sickle_sworda3); }
void wep_sickle_sworda1(entity this) { wep_set_anim(this, 1, wep_sickle_sworda2); W_Parry_Trigger(this.owner, 0); }

void player_sickleb4(entity this) { set_animofs(this, anim_player_axattc1, 4, player_run); }
void player_sickleb3(entity this) { set_animofs(this, anim_player_axattc1, 3, player_sickleb4); }
void player_sickleb2(entity this) { set_animofs(this, anim_player_axattc1, 2, player_sickleb3); }
void player_sickleb1(entity this) { set_animofs(this, anim_player_axattc1, 1, player_sickleb2); }

.float ghost_sickle_dmgtime;
void ghost_sickle_think(entity this)
{
	if(time > this.count)
	{
		delete(this);
		return;
	}

	// hack to ensure the projectile keeps going even if it hits a target
	this.nextthink = time;

	//this.avelocity_x = -720 * bound(1, (time - this.spawn_time), 3);

	this.velocity = this.velocity * (1 - frametime * 4);

	UpdateCSQCProjectile(this);

	if(time <= this.ghost_sickle_dmgtime)
		return; // cooldown to prevent damage spam

	FOREACH_ENTITY_RADIUS(this.origin, this.cnt, it.takedamage && it != this.owner,
	{
		if(it.clipgroup && it.clipgroup == this.clipgroup)
			continue;
		float damg = ((this.dmg) ? this.dmg : 20);
		if(it.monsterdef.spawnflags & MONSTER_TYPE_UNDEAD)
			damg = 120;
		spawn_touchblood(this, damg, it);
		T_Damage(it, this, this.owner, damg, this.projectiledeathtype);

		this.ghost_sickle_dmgtime = time + 0.2; // prevent instant death
	});
}

void W_GhostSickle_Fire(entity this, vector org, .entity weaponentity)
{
	// assumes v_ angles are setup

	org += v_right * 8;

	entity missile = new(ghost_sickle);
	missile.flags = FL_PROJECTILE;
	missile.owner = this;
	missile.realowner = this;
	missile.clipgroup = this.clipgroup;
	set_movetype(missile, MOVETYPE_FLYMISSILE);
	missile.solid = SOLID_NOT;
	missile.effects = EF_ADDITIVE;
	missile.dphitcontentsmask = DPCONTENTS_DONOTENTER;
	missile.projectiledeathtype = WEP_SICKLE.m_id;
	missile.cnt = 32; // rough area of effect during travel
	missile.dmg = 20;

	vector dir = qc_aim_fromorg(this, org, 800);
	missile.velocity = dir * 800;
	//missile.velocity_z = 200;

	missile.angles = vectoangles(missile.velocity);

	missile.spawn_time = time;
	missile.count = time + 2;
	missile.nextthink = time;
	setthink(missile, ghost_sickle_think);

	setsize(missile, '0 0 0', '0 0 0');
	setorigin(missile, org);

	IL_PUSH(g_projectiles, missile);

	CSQCProjectile(missile, false, PROJECTILE_GHOST_SICKLE, true);
}

void W_FireSickle(entity this, .entity weaponentity)
{
	makevectors(this.v_angle);
	vector source = W_Shotorg(this, weaponentity);
	int oldsolid = this.dphitcontentsmask;
	this.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	float arange = 120;
	traceline(source, source + v_forward * arange, false, this);
	this.dphitcontentsmask = oldsolid;
	if(trace_fraction == 1.0)
	{
		W_GhostSickle_Fire(this, source, weaponentity);
		return;
	}
	
	vector org = trace_endpos - v_forward * 4;

	if(trace_ent && W_Parry(this, trace_ent))
		return;

	W_GhostSickle_Fire(this, source, weaponentity);

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
		float damage = 80;
		T_Damage(trace_ent, this, this, damage, WEP_SICKLE.m_id);
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

PRECACHE(Sickle)
{
	precache_model("progs/v_sickle.mdl");
	precache_model("progs/g_sickle.mdl");

	precache_sound("enviro/physics/trcut.wav");
	precache_sound("enviro/physics/axemet1.wav");
	precache_sound("enviro/physics/axemet2.wav");
	precache_sound("enviro/physics/axemet3.wav");
	precache_sound("monsters/juggers/jbent.wav");
}

METHOD(Sickle, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	if(thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	{
		if(IS_PLAYER(actor))
			player_sickleb1(actor);
		sound(actor, CH_WEAPON_SINGLE, SND_SICKLE_SWING, 1, ATTN_NORM);
		wep_sickle_sworda1(actor.(weaponentity));
		weapon_prepareattack(thiswep, actor, weaponentity, 0.5);
	}
}
METHOD(Sickle, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	// does not use ammo
	return true;
}
METHOD(Sickle, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(Sickle, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_FRAG;
}
#endif
