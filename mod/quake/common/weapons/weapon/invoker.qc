#include "invoker.qh"

#ifdef GAMEQC
REGISTER_NET_TEMP(TE_CSQC_INVOKERTRAIL)
#endif

#if defined(SVQC)
void SendCSQCInvokerTrail(vector start, vector dir)
{
	WriteHeader(MSG_BROADCAST, TE_CSQC_INVOKERTRAIL);
	WriteVector(MSG_BROADCAST, start);
	WriteAngleVector(MSG_BROADCAST, dir);
}
#elif defined(CSQC)
PRECACHE(Invoker)
{
	precache_model("progs/proj_chain.mdl");
}

// even more smooth:
// defined elsewhere
float lerpCosine(float a, float b, float mix);

void InvokerTrail_Draw(entity this)
{
	this.alpha = bound(0.0001, lerpCosine(1, 0, 1 - (this.count - time) / 0.5), 1);

	if(time > this.count)
		delete(this);
}

void InvokerTrail_Spawn(vector org, vector direction, bool isNew)
{
	// no need for all the excessive tracing the server side, we're just guessing here!
	traceline(org, org + direction * 8192, false, NULL);
	vector dest = trace_endpos;

	if(!trace_ent || trace_ent.solid == SOLID_BSP)
	{
		if(!(trace_dphitcontents & DPCONTENTS_SKY) && pointcontents(dest) != CONTENT_SKY)
			te_gunshot(dest);
	}

	float len = vlen(dest - org);
	vector dir = normalize(dest - org);
	vector ang = vectoangles(dest - org);

	entity sg = NULL;
	float ct = (len) ? floor(len / 30) : 0;
	for(int i = 0; i < ct; i++)
	{
		sg = spawn();

		sg.solid = SOLID_NOT;
		_setmodel(sg, "progs/proj_chain.mdl");
		setsize(sg, '0 0 0', '0 0 0');
		setorigin(sg, org + dir * 30 * i);

		sg.draw = InvokerTrail_Draw;
		if (isNew) IL_PUSH(g_drawables, sg);
		sg.drawmask = MASK_NORMAL;

		sg.classname = "lgsegment";
		sg.effects = EF_FULLBRIGHT;
		sg.angles = ang;
		sg.angles_z = random()*360;
		sg.count = time + 0.02 + 0.001 * i;
		sg.alpha = 0.9;
	}
	// add an effect to the impact site
	if(sg)
	{
		pointparticles(EFFECT_INVOKER_MUZZLEFLASH, sg.origin, dir * -1, 1);
		//sg.effects |= EF_MUZZLEFLASH;
	}
}

NET_HANDLE(TE_CSQC_INVOKERTRAIL, bool isNew)
{
	vector org = ReadVector();
	vector dir = ReadAngleVector();

	makevectors(dir);
	
	vector up = v_up;
	vector right = v_right;

	InvokerTrail_Spawn(org + (up * 32) + (right * -32), dir, isNew); // top left
	InvokerTrail_Spawn(org + (up * 32) + (right * 0), dir, isNew); // top center
	InvokerTrail_Spawn(org + (up * 32) + (right * 32), dir, isNew); // top right
	InvokerTrail_Spawn(org + (up * 0) + (right * -32), dir, isNew); // center left
	InvokerTrail_Spawn(org + (up * 0) + (right * 0), dir, isNew); // center
	InvokerTrail_Spawn(org + (up * 0) + (right * 32), dir, isNew); // center right
	InvokerTrail_Spawn(org + (up * -32) + (right * -32), dir, isNew); // bottom left
	InvokerTrail_Spawn(org + (up * -32) + (right * 0), dir, isNew); // bottom center
	InvokerTrail_Spawn(org + (up * -32) + (right * 32), dir, isNew); // bottom right

	// extra invisible traces to the sides of the crosshair to catch up rogue swarmers
	//InvokerTrail_Spawn(org + (up * 0) + (right * -12), dir, isNew); // left
	//InvokerTrail_Spawn(org + (up * 0) + (right * -24), dir, isNew); // left
	//InvokerTrail_Spawn(org + (up * 0) + (right * 12), dir, isNew); // right
	//InvokerTrail_Spawn(org + (up * 0) + (right * 24), dir, isNew); // right

	return true;
}
#endif

#ifdef SVQC
void wep_invoker_shot2(entity this) { wep_set_anim(this, 2, w_ready); }
void wep_invoker_shot1(entity this) { wep_set_anim(this, 1, wep_invoker_shot2); this.owner.effects |= EF_MUZZLEFLASH; }

// for railgun damage (hitting multiple enemies)
.bool railgunhit;
.float railgunhitsolidbackup;
.vector railgunhitloc;

.float invokerhit;

// defined elsewhere
//IntrusiveList g_railgunhit;
//STATIC_INIT(g_railgunhit) { g_railgunhit = IL_NEW(); }

PRECACHE(Invoker)
{
	precache_model("progs/v_invoker.mdl");
	precache_model("progs/g_invoker.mdl");

	precache_model("progs/proj_chain.mdl");
	precache_model("progs/fx/invoked_chain.mdl");

	precache_sound("invoker/magic07.wav");
	precache_sound("invoker/magic08.wav");
	precache_sound("invoker/magic21.wav");
	precache_sound("invoker/magic26.wav");

	precache_sound("invoker/invoker_firerail.wav");

	precache_sound("invoker/energy_charge.wav");
	precache_sound("invoker/energy_hit1.wav");
	precache_sound("invoker/energy_hit2.wav");
	precache_sound("invoker/energy_hit3.wav");
	precache_sound("invoker/energy_hit4.wav");
}

void anim_invoked(entity this)
{
	vector playerpos = this.pos1;
	
	// further away = slower fade
	float dist = vlen(this.origin - playerpos);
	
	if(dist > 600)
		dist = 600;
	else if(dist == 0)
		dist = 1; // div0 fix
	
	float fade_rate = 0.05 - (dist / 600) * 0.03;
	
	this.alpha -= fade_rate;

	if(this.alpha <= 0.5 && this.alpha > 0.2)
	{
		vector amax = this.absmax;
		amax.z = min(amax.z * (this.alpha + 0.8), amax.z);
		te_particlecube(this.absmin, amax, '0 0 0', bound(20, vlen(this.mins + this.maxs), 150), 75, true, 0);
	}

	if(this.alpha <= 0)
	{
		delete(this);
		return;
	}
	
	setthink(this, anim_invoked);
	this.nextthink = time + 0.05;
}

// NOTE: needs to be given a pre-death model!
void FX_Invoked(string invoked_model, int targframe, vector targorg, vector targangles, vector targmin, vector targmax, vector playerpos)
{
	entity fx = spawn();
	set_movetype(fx, MOVETYPE_NONE);
	fx.solid = SOLID_NOT;
	fx.classname = "impact";
	
	//fx.angles = vectoangles(dir);
	
	//fx.frame = 0;
	fx.frame = targframe;
	fx.angles = targangles;
	fx.effects = EF_ADDITIVE;
	fx.colormod = '1 0 0';
	fx.alpha = 1;
	
	fx.pos1 = playerpos;
	
	setthink(fx, anim_invoked);
	fx.nextthink = time + 0.1;

	if(invoked_model && invoked_model != "")
		_setmodel(fx, invoked_model);
	else
		_setmodel(fx, "progs/null.mdl");
	setsize(fx, targmin, targmax);

	setorigin(fx, targorg);
}
//==============================================

void anim_chains(entity this)
{
	this.alpha -= 0.10;
	this.frame ++;

	if(this.frame >= 6)
	{
		delete(this);
		return;
	}
	setthink(this, anim_chains);
	this.nextthink = time + 0.05;
}

void FX_Chains(vector org, vector dir)
{
	entity fx = new(impact);
	fx.solid = SOLID_NOT;
	set_movetype(fx, MOVETYPE_NONE);

	fx.angles = vectoangles(dir);
	fx.nextthink = time;
	setthink(fx, anim_chains);

	fx.frame = 0;
	fx.alpha = 1;

	setorigin(fx, org);
	_setmodel(fx, "progs/fx/invoked_chain.mdl");
	setsize(fx, '0 0 0', '0 0 0');
}

void sound_invoker_impact(entity this, float invokerhit_volume)
{
	int r = floor(random() * 4);
	switch(r)
	{
		case 0: _sound(this, CHAN_BODY, "invoker/energy_hit1.wav", invokerhit_volume, ATTN_NORM); break;
		case 1: _sound(this, CHAN_BODY, "invoker/energy_hit2.wav", invokerhit_volume, ATTN_NORM); break;
		case 2: _sound(this, CHAN_BODY, "invoker/energy_hit3.wav", invokerhit_volume, ATTN_NORM); break;
		default: _sound(this, CHAN_BODY, "invoker/energy_hit4.wav", invokerhit_volume, ATTN_NORM); break;
	}
}

//=============================================================================================

void InvokerTrace(entity this, float arange, vector org, vector dir)
{
	while(true)
	{
		traceline(org, org + dir * arange, false, this);

		if(!trace_ent || trace_fraction == 1 || trace_ent.railgunhit)
			break; // if the same target is traced, we've hit an engine bug, thank you bones

		IL_PUSH(g_railgunhit, trace_ent);
		trace_ent.railgunhit = true;
		trace_ent.railgunhitloc = trace_endpos;
		trace_ent.railgunhitsolidbackup = trace_ent.solid;

		if(trace_ent.solid == SOLID_BSP)
			break;

		trace_ent.solid = SOLID_NOT;
	}
}

void InvokerFire(entity this, vector org, vector dir, float damage, int deathtype, bool drawtrail)
{
	float blength = 8192; // max length of the beam, bounces included
	vector start_org = org;

	//SendCSQCInvoker(org, dir);

	// limit the max bounces regardless
	for(int j = 0; j < 64; ++j)
	{
		vector oldorg = org;
		InvokerTrace(this, blength, org, dir);
		org = trace_endpos;
		//if(drawtrail)
			//SendCSQCInvokerTrail(oldorg, org);

		if((trace_dphitcontents & DPCONTENTS_SKY) || pointcontents(org) == CONTENT_SKY)
			break;

		blength -= vlen(org - oldorg);
		if(blength <= 0)
			break;
		//if(!trace_ent || trace_ent.solid == SOLID_BSP)
			//te_gunshot(org);
	}

	// find all the entities the railgun hit and restore their solid state
	IL_EACH(g_railgunhit, it.railgunhit,
	{
		it.solid = it.railgunhitsolidbackup;
	});

	// find all the entities the railgun hit and hurt them
	IL_EACH(g_railgunhit, it.railgunhit,
	{
		// removal from the list is handled below
		/* no falloff applied */

		// apply the damage
		if (it.takedamage && it.invokerhit != time)
		{
			vector vel = dir + 2 * normalize(it.railgunhitloc - start_org);
			vel *= 200;
			it.effects |= EF_MUZZLEFLASH;
			it.invokerhit = time; // prevent enemy damage spam
			string oldmdl = it.model;
			int oldmovetype = it.move_movetype;
			vector prevorg = it.origin;
			vector prevangles = it.angles;
			vector prevmin = it.mins;
			vector prevmax = it.maxs;
			int oldframe = it.frame;
			// double damage against non-players!
			float damg = (IS_PLAYER(it)) ? damage : damage * 2;
			if(!(it.monsterdef.spawnflags & MON_FLAG_METAL))
				SpawnBlood(it.railgunhitloc, vel * 0.2, damg, it);
			FX_Chains(it.railgunhitloc, dir);
			sound_invoker_impact(this, 1);
			T_Damage(it, this, this, damg, deathtype);

			if(!wasfreed(it) && it.health <= 0 && (IS_MONSTER(it) || IS_PLAYER(it)))
			{
				if(oldmovetype != it.move_movetype && it.move_movetype == MOVETYPE_BOUNCE) // rough gib check
					FX_Invoked(oldmdl, oldframe, prevorg, prevangles, prevmin, prevmax, this.origin);
				else
				{
					it.velocity = '0 0 175';
					UNSET_ONGROUND(it);

					if(!(it.monsterdef.spawnflags & MONSTER_TYPE_BOSS) && !(it.monsterdef.spawnflags & MON_FLAG_STATIONARY))
						it.velocity = dir * 400;
				}
			}
		}

		it.railgunhitloc = '0 0 0';
		it.railgunhitsolidbackup = SOLID_NOT;
		it.railgunhit = false;
	});

	IL_CLEAR(g_railgunhit);
}

void W_FireInvoker(entity this, .entity weaponentity)
{
	makevectors(this.v_angle);

	vector org = W_Shotorg(this, weaponentity);
	vector dir = qc_aim(this, 8192);
	
	vector up = v_up;
	vector right = v_right;

	float damage = 333; // TODO: double against monsters?
	int deathtype = WEP_INVOKER.m_id | HITTYPE_MAGIC;

	float lag = (IS_PLAYER(this)) ? antilag_getlag(this) : 0;
	if(lag)
		antilag_takeback_all(this, lag);

	InvokerFire(this, org + (up * 32) + (right * -32), dir, damage, deathtype, true); // top left
	InvokerFire(this, org + (up * 32) + (right * 0), dir, damage, deathtype, true); // top center
	InvokerFire(this, org + (up * 32) + (right * 32), dir, damage, deathtype, true); // top right
	InvokerFire(this, org + (up * 0) + (right * -32), dir, damage, deathtype, true); // center left
	InvokerFire(this, org + (up * 0) + (right * 0), dir, damage, deathtype, true); // center
	InvokerFire(this, org + (up * 0) + (right * 32), dir, damage, deathtype, true); // center right
	InvokerFire(this, org + (up * -32) + (right * -32), dir, damage, deathtype, true); // bottom left
	InvokerFire(this, org + (up * -32) + (right * 0), dir, damage, deathtype, true); // bottom center
	InvokerFire(this, org + (up * -32) + (right * 32), dir, damage, deathtype, true); // bottom right

	// extra invisible traces to the sides of the crosshair to catch up rogue swarmers
	InvokerFire(this, org + (up * 0) + (right * -12), dir, damage, deathtype, false); // left
	InvokerFire(this, org + (up * 0) + (right * -24), dir, damage, deathtype, false); // left
	InvokerFire(this, org + (up * 0) + (right * 12), dir, damage, deathtype, false); // right
	InvokerFire(this, org + (up * 0) + (right * 24), dir, damage, deathtype, false); // right

	if(lag)
		antilag_restore_all(this);

	SendCSQCInvokerTrail(org, dir);
}

void weaponanim_invoker_loop(entity this)
{
	entity actor = this.owner;
	.entity weaponentity = this.weaponentity_fld;
	if(intermission_running)
		return;

	if(this.m_frame == 41)
		_sound(actor, CH_WEAPON_A, "invoker/magic07.wav", 1, ATTN_NORM);
	else if(this.m_frame == 77)
		_sound(actor, CH_WEAPON_A, "invoker/energy_charge.wav", 1, ATTN_NORM);

	// keep playing attack animation so player doesn't cancel attacks
	// TODO: weapon attack animation locking
	if(IS_PLAYER(actor))
		player_shot1(actor);

	if(this.m_frame >= 64 && this.m_frame <= 94)
	{ /* TODO: weapon locking */ }
	else
	{ /* TODO */ }

	if(this.m_frame == 78)
	{
		actor.effects |= EF_MUZZLEFLASH;
		W_TakeMana(actor, 100);

		SuperDamageSound(actor);
		W_FireInvoker(actor, weaponentity);
	}

	if(this.m_frame >= 110) // added post-fire + ready to fire --> idle padding
	{
		ATTACK_FINISHED(actor, weaponentity) = time + 0.5;
		this.m_frame = 95;
		w_ready(this);
		return;
	}

	wep_set_anim(this, this.m_frame + 1, weaponanim_invoker_loop);
	this.weapon_nextthink = time + 0.025;
	ATTACK_FINISHED(actor, weaponentity) = time + 0.2;
}

void weaponanim_invoker(entity this)
{
	entity actor = this.owner;
	.entity weaponentity = this.weaponentity_fld;
	_sound(actor, CH_WEAPON_A, "invoker/magic21.wav", 1, ATTN_NORM);
	_sound(actor, CH_WEAPON_A, "invoker/magic26.wav", 1, ATTN_NORM);

	wep_set_anim(this, 11, weaponanim_invoker_loop);
	this.weapon_nextthink = time + 0.025;
	ATTACK_FINISHED(actor, weaponentity) = time + 0.2;
}

METHOD(Invoker, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	//if(thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	if(STAT(MANA, actor) >= 100)
	{
		if(IS_PLAYER(actor))
			player_shot1(actor);
		weaponanim_invoker(actor.(weaponentity));
		weapon_prepareattack(thiswep, actor, weaponentity, 5);
	}
}
METHOD(Invoker, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	return true; // uses mana
}
METHOD(Invoker, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(Invoker, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_FRAG;
}
#endif
