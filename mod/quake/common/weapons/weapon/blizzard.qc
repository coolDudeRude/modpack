#include "blizzard.qh"

#ifdef SVQC
PRECACHE(Blizzard)
{
	precache_model("progs/v_blizzard.mdl");
	precache_model("progs/g_blizzard.mdl");

	precache_sound("ice_queen/frostshard_impact.wav");
}

void W_Blizzard_Attack(entity this)
{
	entity actor = this.owner;
	.entity weaponentity = this.weaponentity_fld;
	if(!actor.button0 || STAT(MANA, actor) < 2)
	{
		w_ready(this);
		return;
	}

	if(IS_PLAYER(actor))
		player_nail1(actor);

	//actor.effects |= EF_MUZZLEFLASH;

	wep_set_anim(this, 1, W_Blizzard_Attack);
	SuperDamageSound(actor);
	W_FireBlizzard(actor, weaponentity);
	ATTACK_FINISHED(actor, weaponentity) = time + 0.2;
}

void blizzard_shard_explode(entity this)
{
	_sound(this, CH_WEAPON_SINGLE, "ice_queen/frostshard_impact.wav", 1, 0.5);
	particle(this.origin, '0 0 0', 40, 10);

	this.velocity = '0 0 0';
	setthink(this, SUB_Remove);
	this.nextthink = time;
}

void blizzard_shard_think(entity this)
{
	if(time > this.count)
	{
		blizzard_shard_explode(this);
		return;
	}

	// hack to ensure the projectile keeps going even if it hits a target
	this.nextthink = time;

	bool hitenemy = false;
	FOREACH_ENTITY_RADIUS(this.origin, this.cnt, it.takedamage && it != this.owner,
	{
		if(it.clipgroup && it.clipgroup == this.clipgroup)
			continue;
		float damg = ((this.dmg) ? this.dmg : 9);
		spawn_touchblood(this, damg, it);
		T_Damage(it, this, this.owner, damg, this.projectiledeathtype);

		hitenemy = true;
	});

	if(hitenemy)
		blizzard_shard_explode(this);
}

void blizzard_shard_launch(entity this, vector org, vector dir, .entity weaponentity)
{
	// assumes v_ angles are setup

	org += v_right * 8;

	entity missile = spawn();
	missile.classname = "blizzard_shard";
	missile.flags = FL_PROJECTILE;
	missile.owner = this;
	missile.realowner = this;
	missile.clipgroup = this.clipgroup;
	set_movetype(missile, MOVETYPE_NOCLIP);
	missile.solid = SOLID_NOT;
	//missile.gravity = 1;
	missile.projectiledeathtype = WEP_BLIZZARD.m_id | HITTYPE_MAGIC;
	missile.cnt = 16; // rough area of effect during travel
	missile.dmg = 16;

	float myspeed = 1200;

	missile.velocity = dir * myspeed;
	//missile.velocity_z = 200;

	missile.angles = vectoangles(missile.velocity);

	missile.count = time + (1000 / myspeed);
	missile.nextthink = time;
	setthink(missile, blizzard_shard_think);

	setsize(missile, '0 0 0', '0 0 0');
	setorigin(missile, org);

	IL_PUSH(g_projectiles, missile);

	CSQCProjectile(missile, true, PROJECTILE_BLIZZARD_SHARD, true);
}

void W_FireBlizzard(entity this, .entity weaponentity)
{
	makevectors(this.v_angle);

	W_TakeMana(this, 2);

	vector source = W_Shotorg(this, weaponentity);
	int oldsolid = this.dphitcontentsmask;
	this.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	float arange = 800;
	traceline(source, source + v_forward * arange, false, this);
	this.dphitcontentsmask = oldsolid;

	vector to = trace_endpos;
	vector from = to + '0 0 1000';

	int shards = 2; // this many per frame
	for(int j = 0; j < shards; ++j)
	{
		vector start = from;
		vector end = to;

		// offset it so it isn't faling directly down
		start.x += crandom() * 350;
		start.y += crandom() * 350;

		// also offset the impact location a little
		end.x += crandom() * 32;
		end.y += crandom() * 32;

		vector dir = normalize(end - start);

		blizzard_shard_launch(this, start, dir, weaponentity);
	}
}

METHOD(Blizzard, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	//if(thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	if(STAT(MANA, actor) >= 2)
		W_Blizzard_Attack(actor.(weaponentity));
}
METHOD(Blizzard, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	return true; // uses mana
}
METHOD(Blizzard, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(Blizzard, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_FRAG;
}
#endif
