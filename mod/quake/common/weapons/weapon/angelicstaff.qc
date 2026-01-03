#include "angelicstaff.qh"

#ifdef SVQC
void wep_angelicstaff_shot7(entity this) { wep_set_anim(this, 11, w_ready); }
void wep_angelicstaff_shot6(entity this) { wep_set_anim(this, 10, wep_angelicstaff_shot7); W_FireAngelicStaff(this.owner, this.weaponentity_fld); }
void wep_angelicstaff_shot5(entity this) { wep_set_anim(this, 9, wep_angelicstaff_shot6); }
void wep_angelicstaff_shot4(entity this) { wep_set_anim(this, 8, wep_angelicstaff_shot5); }
void wep_angelicstaff_shot3(entity this) { wep_set_anim(this, 7, wep_angelicstaff_shot4); }
void wep_angelicstaff_shot2(entity this) { wep_set_anim(this, 6, wep_angelicstaff_shot3); }
void wep_angelicstaff_shot1(entity this) { wep_set_anim(this, 5, wep_angelicstaff_shot2); }

PRECACHE(AngelicStaff)
{
	precache_model("progs/v_angelicstaff.mdl");
	precache_model("progs/g_angelicstaff.mdl");

	precache_sound("weapons/angelicstaff_charge.wav");
	precache_sound("weapons/angelicstaff_fire.wav");
}

bool W_AngelicStaff_Cleanse(entity this)
{
	int cleancount = 1;
	bool washealed = false;

	FOREACH(StatusEffect, it.instanceOfDebuffs,
	{
		if(StatusEffects_active(it, this))
		{
			StatusEffects_remove(it, this, STATUSEFFECT_REMOVE_CLEAR);
			washealed = true;
			cleancount -= 1;
		}
		if(cleancount <= 0)
			break;
	});

	return washealed;
}

bool W_AngelicStaff_Heal(entity this, int healamount)
{
	bool washealed = T_Heal(this, healamount, true);

	if(washealed)
		this.healthrot_nextcheck = time + 5;

	// special: cleanse some negative effects
	washealed |= W_AngelicStaff_Cleanse(this);

	if(!washealed)
		return false;

	Send_Effect(EFFECT_ANGELICSTAFF_HEAL, this.origin, '0 0 0', 1);
	return true;
}

void W_FireAngelicStaff(entity this, .entity weaponentity)
{
	this.effects |= EF_MUZZLEFLASH;

	W_TakeMana(this, 30);
	_sound(this, CH_WEAPON_SINGLE, "weapons/angelicstaff_fire.wav", 1, ATTN_NORM);

	makevectors(this.v_angle);

	int healamount = 20;

	W_AngelicStaff_Heal(this, healamount);

	// heal people!

	int healedcount = 3;
	FOREACH_ENTITY_RADIUS(this.origin, 1000, it.takedamage && it.health > 0 && it.exptime == 0 && it != this && ((IS_PLAYER(it) && !deathmatch) || (IS_MONSTER(it) && it.charmer == this)),
	{
		if(it.monsterdef && (it.monsterdef.spawnflags & MONSTER_TYPE_UNDEAD))
			continue; // no healing the dead
		if(!IS_PLAYER(it) && (it.health + healamount) >= it.max_health)
			continue;
		//if(!checkpvs(this.origin, it))
			//continue; // cheaper than tracing
		vector targ_pos = (it.absmin + it.absmax) * 0.5;
		vector vec = normalize(targ_pos - this.origin);
		float dot = vec * v_forward;
		if(dot > 0.66 && W_AngelicStaff_Heal(it, healamount))
			healedcount -= 1;

		if(healedcount <= 0)
			break;
	});
}

METHOD(AngelicStaff, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	//if(thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	if(STAT(MANA, actor) >= 30)
	{
		if(IS_PLAYER(actor))
			player_shot1(actor);
		_sound(actor, CH_WEAPON_SINGLE, "weapons/angelicstaff_charge.wav", 1, ATTN_NORM);
		wep_angelicstaff_shot1(actor.(weaponentity));
		weapon_prepareattack(thiswep, actor, weaponentity, 1);
	}
}
METHOD(AngelicStaff, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	return true; // uses mana
}
METHOD(AngelicStaff, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(AngelicStaff, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_FRAG;
}
#endif
