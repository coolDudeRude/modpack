#include "axe.qh"

#include "../../monsters/_mod.qh"

#ifdef SVQC
PRECACHE(CorruptedClaws)
{
	//precache_model("progs/g_corrupted.mdl");
	precache_model("progs/v_corrupted.mdl");

	precache_sound("weapons/terra_swing.wav");

	precache_sound("impact/hit_player1.wav");
	precache_sound("impact/hit_player2.wav");
	precache_sound("impact/hit_player3.wav");
	precache_sound("impact/hit_player4.wav");
}

void wep_corrupted_lunge5(entity this) { wep_set_anim(this, 18, w_ready); }
void wep_corrupted_lunge4(entity this) { wep_set_anim(this, 17, wep_corrupted_lunge5); }
void wep_corrupted_lunge3(entity this) { wep_set_anim(this, 16, wep_corrupted_lunge4); }
void wep_corrupted_lunge2(entity this) { wep_set_anim(this, 15, wep_corrupted_lunge3); }
void wep_corrupted_lunge1(entity this) { wep_set_anim(this, 14, wep_corrupted_lunge2); }

void corrupted_lunge5(entity this) { set_animofs(this, anim_player_axatt1, 4, player_run); }
void corrupted_lunge4(entity this) { set_animofs(this, anim_player_axatt1, 4, corrupted_lunge5); }
void corrupted_lunge3(entity this) { set_animofs(this, anim_player_axatt1, 3, corrupted_lunge4); }
void corrupted_lunge2(entity this) { set_animofs(this, anim_player_axatt1, 2, corrupted_lunge3); }
void corrupted_lunge1(entity this) { set_animofs(this, anim_player_axatt1, 1, corrupted_lunge2); }

void wep_corrupted_anim_fire(entity this)
{
	entity actor = this.owner;
	.entity weaponentity = this.weaponentity_fld;

	if(this.m_frame == 9 || this.m_frame == 12)
		W_FireCorruptedClaws(actor, weaponentity);

	this.m_frame += 1;

	if(this.m_frame == 11 || this.m_frame >= 14)
	{
		w_ready(this);
		return;
	}

	wep_set_anim(this, this.m_frame, wep_corrupted_anim_fire);
}

void wep_corrupted_anim(entity this)
{
	entity actor = this.owner;
	//.entity weaponentity = this.weaponentity_fld;

	_sound(actor, CH_WEAPON_B, "weapons/terra_swing.wav", 1, ATTN_NORM);

	bool doalt = this.count;
	this.count = (this.count) ? 0 : 1;

	if(IS_PLAYER(actor))
	{
		if(doalt)
			player_axe1(actor);
		else
			player_axeb1(actor);
	}

	this.m_frame = (doalt) ? 11 : 8;

	wep_set_anim(this, this.m_frame, wep_corrupted_anim_fire);
}

//=============================================================================================

void sound_corrupted_hit_enemy(entity this, float fisthit_volume)
{
	float r = floor(random()*4);
	if(r == 0)
		_sound(this, CH_SHOTS, "impact/hit_player1.wav", fisthit_volume, ATTN_NORM);
	else if(r == 1)
		_sound(this, CH_SHOTS, "impact/hit_player2.wav", fisthit_volume, ATTN_NORM);
	else if(r == 2)
		_sound(this, CH_SHOTS, "impact/hit_player3.wav", fisthit_volume, ATTN_NORM);
	else
		_sound(this, CH_SHOTS, "impact/hit_player4.wav", fisthit_volume, ATTN_NORM);
}

void hitcorrupted(entity this, entity hitent, vector org, vector dir)
{
	if(hitent.takedamage) 
	{		
		hitent.axhitme = 1;

		float damage = 60;

		SpawnBlood(org, dir, damage, hitent);

		T_Damage(hitent, this, this, damage, WEP_CORRUPTED_CLAWS.m_id);
		
		//johnfitz -- make clank sound when hitting brushmodels
		if(hitent.solid == SOLID_BSP || hitent.movetype == MOVETYPE_PUSH || hitent.movetype == MOVETYPE_NONE)
			sound_corrupted_hit_enemy(this, 0.8);
		else
			sound_corrupted_hit_enemy(hitent, 1);	
	}
	else
	{	// hit wall
		sound_corrupted_hit_enemy(this, 0.8);
		
		FX_Wrench(org, dir, true);
	}
}

void W_FireCorruptedClaws(entity this, .entity weaponentity)
{
	entity hitent1 = NULL, hitent2 = NULL;
	vector hitpos1 = '0 0 0', hitpos2 = '0 0 0';
	float shortest_hit1 = 1000;
	float shortest_hit2 = 1000;
	int oldsolid = this.dphitcontentsmask;
	this.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;

	float rscale = 1;
	if(this.m_champion && this.m_champion.qcc_meleerange)
		rscale *= this.m_champion.qcc_meleerange;

	makevectors(this.v_angle);
	vector source = this.origin + this.view_ofs - v_up*0;

	traceline(source, source + v_forward * (60 * rscale) - v_right * (40 * rscale), false, this);
	if(trace_fraction < 1)
	{
		shortest_hit1 = vlen(trace_endpos - source);
		hitent1 = trace_ent;
		hitpos1 = trace_endpos;
 	}

	traceline(source, source + v_forward * (72 * rscale) - v_right * (20 * rscale), false, this);
	if(trace_fraction < 1)
	{
		if(trace_ent == hitent1 && vdist(trace_endpos - source, <, shortest_hit1))
		{
			shortest_hit1 = vlen(trace_endpos - source);
			hitent1 = trace_ent;
			hitpos1 = trace_endpos;
		}
		if(trace_ent != hitent1 && vdist(trace_endpos - source, <, shortest_hit2))
		{
			shortest_hit2 = vlen(trace_endpos - source);
			hitent2 = trace_ent;
			hitpos2 = trace_endpos;
		}
	}

	traceline(source, source + v_forward * (86 * rscale), false, this);
	if(trace_fraction < 1)
	{
		if(trace_ent == hitent1 && vdist(trace_endpos - source, <, shortest_hit1))
		{
			shortest_hit1 = vlen(trace_endpos - source);
			hitent1 = trace_ent;
			hitpos1 = trace_endpos;
		}
		if(trace_ent != hitent1 && vdist(trace_endpos - source, <, shortest_hit2))
		{
			shortest_hit2 = vlen(trace_endpos - source);
			hitent2 = trace_ent;
			hitpos2 = trace_endpos;
		}
	}

	traceline(source, source + v_forward * (72 * rscale) + v_right * (20 * rscale), false, this);
	if(trace_fraction < 1)
	{
		if(trace_ent == hitent1 && vdist(trace_endpos - source, <, shortest_hit1))
		{
			shortest_hit1 = vlen(trace_endpos - source);
			hitent1 = trace_ent;
			hitpos1 = trace_endpos;
		}
		if(trace_ent != hitent1 && vdist(trace_endpos - source, <, shortest_hit2))
		{
			shortest_hit2 = vlen(trace_endpos - source);
			hitent2 = trace_ent;
			hitpos2 = trace_endpos;
		}
	}

	traceline(source, source + v_forward * (60 * rscale) + v_right * (40 * rscale), false, this);
	if(trace_fraction < 1)
	{
		if(trace_ent == hitent1 && vdist(trace_endpos - source, <, shortest_hit1))
		{
			shortest_hit1 = vlen(trace_endpos - source);
			hitent1 = trace_ent;
			hitpos1 = trace_endpos;
		}
		if(trace_ent != hitent1 && vdist(trace_endpos - source, <, shortest_hit2))
		{
			shortest_hit2 = vlen(trace_endpos - source);
			hitent2 = trace_ent;
			hitpos2 = trace_endpos;
		}
	}

	this.dphitcontentsmask = oldsolid;

	if(shortest_hit1 == 1000 && shortest_hit2 == 1000)
		return;

	this.show_hostile = time + 1; // hit something, so alert monsters
	
	vector dir = v_right * 20 - v_up*5; // direction for blood particles

	if(shortest_hit1 < 1000)
		hitcorrupted(this, hitent1, hitpos1 - v_forward*4, dir);
	if(shortest_hit2 < 1000 && hitent1 != hitent2)
		hitcorrupted(this, hitent2, hitpos2 - v_forward*4, dir);
}

METHOD(CorruptedClaws, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	//if(thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	{
		wep_corrupted_anim(actor.(weaponentity));
		weapon_prepareattack(thiswep, actor, weaponentity, 0.33);
	}
}
METHOD(CorruptedClaws, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	// does not use ammo
	return true;
}
METHOD(CorruptedClaws, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(CorruptedClaws, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_FRAG;
}
#endif
