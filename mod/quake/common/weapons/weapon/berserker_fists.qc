#include "axe.qh"

#include "../../monsters/_mod.qh"

#ifdef SVQC
PRECACHE(BerserkerFists)
{
	//precache_model("progs/g_berserk.mdl");
	precache_model("progs/v_berserk.mdl");

	precache_sound("items/berserk_fire.wav");

	precache_sound("impact/fist_hit.wav");
	precache_sound("impact/fist_impact1.wav");
	precache_sound("impact/fist_impact2.wav");
	precache_sound("impact/fist_impact3.wav");
	precache_sound("impact/fist_impact4.wav");
}

void player_wrench1(entity this);

void wep_berserk_anim_fire(entity this)
{
	entity actor = this.owner;
	.entity weaponentity = this.weaponentity_fld;

	if(this.m_frame == 14 || this.m_frame == 34 || this.m_frame == 54 || this.m_frame == 64)
		W_FireBerserkerFists(actor, weaponentity);
	else if(this.m_frame == 60)
		this.m_frame = 40;
	else if(this.m_frame == 70)
		this.m_frame = 20;
	else if(this.m_frame == 30 || this.m_frame == 50)
		this.m_frame = 70;

	if(this.m_frame >= 80)
	{
		w_ready(this);
		return;
	}
	this.m_frame += 1;

	wep_set_anim(this, this.m_frame, wep_berserk_anim_fire);
	this.weapon_nextthink = time + 0.05;
}

void wep_berserk_anim(entity this)
{
	entity actor = this.owner;
	.entity weaponentity = this.weaponentity_fld;

	// shouldn't be able to, but just incase someone sneaks it in
	if(!StatusEffects_active(STATUSEFFECT_Berserk, actor))
	{
		ATTACK_FINISHED(actor, weaponentity) = time + 0.5;
		W_SwitchWeapon(actor, w_getbestweapon(actor, weaponentity), weaponentity);
		return;
	}

	_sound(actor, CH_WEAPON_B, "impact/wrench_swing.wav", 1, ATTN_NORM);

	if(IS_PLAYER(actor))
		player_wrench1(actor);

	bool doalt = (random() > 0.5);

	if(this.m_frame >= 0 && this.m_frame <= 70)
		this.m_frame = (doalt) ? 51 : 61;
	else if(this.m_frame >= 71 && this.m_frame <= 100) // idle loop
		this.m_frame = (doalt) ? 31 : 11;

	if(actor.berserk_sound < time)
	{
		actor.berserk_sound = time + 1;
		_sound(actor, CH_PLAYER, "items/berserk_fire.wav", 1, ATTN_NORM);
	}

	wep_set_anim(this, this.m_frame, wep_berserk_anim_fire);
	this.weapon_nextthink = time + 0.05;
}

//=============================================================================================

void sound_berserk_fist_hit_enemy(entity this, float fisthit_volume)
{
	float r = floor(random()*4);
	if(r == 0)
		_sound(this, CH_SHOTS, "impact/fist_impact1.wav", fisthit_volume, ATTN_NORM);
	else if(r == 1)
		_sound(this, CH_SHOTS, "impact/fist_impact2.wav", fisthit_volume, ATTN_NORM);
	else if(r == 2)
		_sound(this, CH_SHOTS, "impact/fist_impact3.wav", fisthit_volume, ATTN_NORM);
	else
		_sound(this, CH_SHOTS, "impact/fist_impact4.wav", fisthit_volume, ATTN_NORM);
}

void W_FireBerserkerFists(entity this, .entity weaponentity)
{
	if(this.health <= 0 || this.exptime != 0)
		return;
	
	makevectors(this.v_angle);
			
	vector source = this.origin + this.view_ofs;
	
	traceline(source, source + v_forward * (100), false, this);
		
	if(trace_fraction == 1.0) 
		return;
	
	this.show_hostile = time + 1;	// wake monsters up
		
	vector org = trace_endpos - v_forward * 4;

	if(trace_ent.takedamage)
	{
		trace_ent.axhitme = true;
		
		if(IS_MONSTER(trace_ent))
			sound_berserk_fist_hit_enemy(trace_ent, 1);
		SuperDamageSound(this);

		if ((trace_ent.movetype == MOVETYPE_STEP || trace_ent.movetype == MOVETYPE_WALK) && (
				!(trace_ent.monsterdef.spawnflags & MONSTER_TYPE_BOSS) && !(trace_ent.monsterdef.spawnflags & MON_FLAG_STATIONARY) || // don't swat bosses or other non-standard-sized enemies around
				(IS_PLAYER(trace_ent) && trace_ent.health < 1)) // push dying players?
			)
		{
			vector toss = v_forward;
			toss.z = 0;

			if(trace_ent.monsterdef.spawnflags & MONSTER_TYPE_UNDEAD)
			{
				toss = normalize(toss) * 200; // don't send zombies flying away
				toss.z = 150;			
			}
			else
			{
				toss = normalize(toss) * 800; // beserk doubled the knockback with the axe but removed the quad knockback
				toss.z = 100;
			}		
			
			trace_ent.origin_z = trace_ent.origin_z + 1;
			trace_ent.velocity = toss;
			UNSET_ONGROUND(trace_ent);
		}

		T_Damage(trace_ent, this, this, 480, WEP_BERSERKER_FISTS.m_id);
		SpawnBlood(org, '0 0 0', 20, trace_ent);
	}
	else
	{	// hit wall
		_sound(this, CH_WEAPON_SINGLE, "impact/fist_hit.wav", 1, ATTN_NORM);
		
		SuperDamageSound(this);
		te_gunshot(org);
	}
}

METHOD(BerserkerFists, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	//if(thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	{
		wep_berserk_anim(actor.(weaponentity));
		weapon_prepareattack(thiswep, actor, weaponentity, 0.5);
	}
}
METHOD(BerserkerFists, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	// does not use ammo
	return true;
}
METHOD(BerserkerFists, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(BerserkerFists, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_FRAG;
}
#endif
