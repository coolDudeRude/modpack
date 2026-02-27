#include "bladeofgrass.qh"

#include "../../monsters/_mod.qh"

#ifdef SVQC
void W_FireBladeOfGrass(entity this, .entity weaponentity);

void player_grassa4(entity this) { set_animofs(this, anim_player_axattd1, 4, player_run); }
void player_grassa3(entity this) { set_animofs(this, anim_player_axattd1, 3, player_grassa4); }
void player_grassa2(entity this) { set_animofs(this, anim_player_axattd1, 2, player_grassa3); }
void player_grassa1(entity this) { set_animofs(this, anim_player_axattd1, 1, player_grassa2); }

void wep_grass_grassa4(entity this) { wep_set_anim(this, 12, w_ready); }
void wep_grass_grassa3(entity this) { wep_set_anim(this, 11, wep_grass_grassa4); W_FireBladeOfGrass(this.owner, this.weaponentity_fld); }
void wep_grass_grassa2(entity this) { wep_set_anim(this, 10, wep_grass_grassa3); }
void wep_grass_grassa1(entity this) { wep_set_anim(this, 9, wep_grass_grassa2); W_Parry_Trigger(this.owner, 0); }

void player_grassb4(entity this) { set_animofs(this, anim_player_axattc1, 4, player_run); }
void player_grassb3(entity this) { set_animofs(this, anim_player_axattc1, 3, player_grassb4); }
void player_grassb2(entity this) { set_animofs(this, anim_player_axattc1, 2, player_grassb3); }
void player_grassb1(entity this) { set_animofs(this, anim_player_axattc1, 1, player_grassb2); }

void wep_grass_grassb4(entity this) { wep_set_anim(this, 8, w_ready); }
void wep_grass_grassb3(entity this) { wep_set_anim(this, 7, wep_grass_grassb4); W_FireBladeOfGrass(this.owner, this.weaponentity_fld); }
void wep_grass_grassb2(entity this) { wep_set_anim(this, 6, wep_grass_grassb3); }
void wep_grass_grassb1(entity this) { wep_set_anim(this, 5, wep_grass_grassb2); W_Parry_Trigger(this.owner, 0); }

void sound_bladeofgrass_hit_enemy(entity this, float fisthit_volume)
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

void sound_bladeofgrass_hit_world(entity this, float vol)
{
	float r = floor(random()*4);
	if(r == 0)
		_sound(this, CH_SHOTS, "weapons/leafattack1.wav", vol, ATTN_NORM);
	else if(r == 1)
		_sound(this, CH_SHOTS, "weapons/leafattack2.wav", vol, ATTN_NORM);
	else if(r == 2)
		_sound(this, CH_SHOTS, "weapons/leafattack3.wav", vol, ATTN_NORM);
	else
		_sound(this, CH_SHOTS, "weapons/leafattack4.wav", vol, ATTN_NORM);
}

void hitbladeofgrass(entity this, entity hitent, vector org, vector dir)
{
	if(hitent.takedamage) 
	{		
		hitent.axhitme = 1;

		this.show_hostile = time + 1; // hit something, so alert monsters

		float damage = 50;

		//SpawnBlood(org, dir, damage, hitent);
		particle(org, dir, 57, 64);

		T_Damage(hitent, this, this, damage, WEP_CORRUPTED_CLAWS.m_id);
		
		//johnfitz -- make clank sound when hitting brushmodels
		if(hitent.solid == SOLID_BSP || hitent.movetype == MOVETYPE_PUSH || hitent.movetype == MOVETYPE_NONE)
			sound_bladeofgrass_hit_enemy(this, 0.8);
		else
			sound_bladeofgrass_hit_enemy(hitent, 1);

		if(this.m_champion == CHAMPION_Dryad && hitent.takedamage)
		{
			IL_EACH(g_leaves, it.owner == this && time > it.leaf_chargetime,
			{
				if(random() > 0.5)
				{
					it.enemy = hitent;
					it.leaf_chargetime = time + 1.5;
				}
			});
		}
	}
	else
	{	// hit wall
		sound_bladeofgrass_hit_world(this, 0.8);

		particle(org, dir * -1, 57, 64);
	}
}

void W_FireBladeOfGrass(entity this, .entity weaponentity)
{
	float lag = (IS_PLAYER(this)) ? antilag_getlag(this) : 0;
	if(lag)
		antilag_takeback_all(this, lag);

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

	traceline(source, source + v_forward * (100 * rscale) - v_right * (40 * rscale), false, this);
	if(trace_fraction < 1)
	{
		shortest_hit1 = vlen(trace_endpos - source);
		hitent1 = trace_ent;
		hitpos1 = trace_endpos;
 	}

	traceline(source, source + v_forward * (124 * rscale) - v_right * (20 * rscale), false, this);
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

	traceline(source, source + v_forward * (152 * rscale), false, this);
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

	traceline(source, source + v_forward * (124 * rscale) + v_right * (20 * rscale), false, this);
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

	traceline(source, source + v_forward * (100 * rscale) + v_right * (40 * rscale), false, this);
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
	{
		if(lag)
			antilag_restore_all(this);
		return;
	}

	if((hitent1 && W_Parry(this, hitent1)) || (hitent2 && W_Parry(this, hitent2)))
	{
		if(lag)
			antilag_restore_all(this);
		return;
	}
	
	vector dir = v_right * 20 - v_up*5; // direction for blood particles

	if(shortest_hit1 < 1000)
		hitbladeofgrass(this, hitent1, hitpos1 - v_forward*4, dir);
	if(shortest_hit2 < 1000 && hitent1 != hitent2)
		hitbladeofgrass(this, hitent2, hitpos2 - v_forward*4, dir);

	if(lag)
		antilag_restore_all(this);
}

PRECACHE(BladeOfGrass)
{
	precache_model("progs/v_bladeofgrass.mdl");
	precache_model("progs/g_bladeofgrass.mdl");

	precache_sound("enviro/physics/trcut.wav");
	precache_sound("enviro/physics/axemet1.wav");
	precache_sound("enviro/physics/axemet2.wav");
	precache_sound("enviro/physics/axemet3.wav");
	precache_sound("monsters/juggers/jbent.wav");

	precache_sound("weapons/leafattack1.wav");
	precache_sound("weapons/leafattack2.wav");
	precache_sound("weapons/leafattack3.wav");
	precache_sound("weapons/leafattack4.wav");
}

METHOD(BladeOfGrass, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	if(thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	{
		bool altframe = actor.(weaponentity).count;
		actor.(weaponentity).count = (actor.(weaponentity).count) ? 0 : 1;
		if(IS_PLAYER(actor))
		{
			if(altframe)
				player_grassb1(actor);
			else
				player_grassa1(actor);
		}
		sound(actor, CH_WEAPON_SINGLE, SND_SWORD_SWING, 1, ATTN_NORM);
		if(altframe)
			wep_grass_grassb1(actor.(weaponentity));
		else
			wep_grass_grassa1(actor.(weaponentity));
		weapon_prepareattack(thiswep, actor, weaponentity, 0.5);
	}
}
METHOD(BladeOfGrass, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	// does not use ammo
	return true;
}
METHOD(BladeOfGrass, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(BladeOfGrass, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_FRAG;
}
#endif
