#include "squeaker.qh"

#ifdef SVQC
PRECACHE(Squeaker)
{
	precache_model("progs/v_squeaker.mdl");
	precache_model("progs/g_squeaker.mdl");
}

void wep_squeaker_squeak7(entity this) { wep_set_anim(this, 151, w_ready); }
void wep_squeaker_squeak6(entity this) { wep_set_anim(this, 150, wep_squeaker_squeak7); }
void wep_squeaker_squeak5(entity this) { wep_set_anim(this, 149, wep_squeaker_squeak6); }
void wep_squeaker_squeak4(entity this) { wep_set_anim(this, 148, wep_squeaker_squeak5); }
void wep_squeaker_squeak3(entity this) { wep_set_anim(this, 147, wep_squeaker_squeak4); }
void wep_squeaker_squeak2(entity this) { wep_set_anim(this, 146, wep_squeaker_squeak3); }
void wep_squeaker_squeak1(entity this) { wep_set_anim(this, 145, wep_squeaker_squeak2); }

entity W_FireSqueaker(entity this, .entity weaponentity)
{
	W_TakeMana(this, 20);

	sound(this, CH_WEAPON_SINGLE, SND_SQUEAKER_FIRE_RANDOM(), 1, ATTN_NORM);

	this.punchangle_x = -2 * autocvar_sv_quake_recoil;

	entity missile = Create_Egg(this, MON_SQUEAK);
	missile.projectiledeathtype = WEP_SQUEAKER.m_id;

	// set missile speed	

	makevectors(this.v_angle);

	if(this.v_angle_x)
		missile.velocity = v_forward*400 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		missile.velocity = qc_aim(this, 10000);
		missile.velocity = missile.velocity * 400;
		missile.velocity_z = 200;
	}

	missile.angles = vectoangles(missile.velocity);
	missile.mangle = vec2(missile.angles);

	setorigin(missile, W_Shotorg(this, weaponentity));

	return missile;
}

METHOD(Squeaker, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	if(thiswep.wr_checkammo1(thiswep, actor, weaponentity) && STAT(MANA, actor) >= 20)
	{
		if(IS_PLAYER(actor))
			player_rocket1(actor);
		wep_squeaker_squeak1(actor.(weaponentity));
		W_FireSqueaker(actor, weaponentity);
		weapon_prepareattack(thiswep, actor, weaponentity, 1);
	}
}
METHOD(Squeaker, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	return true; // doesn't use ammo in the traditional sense
}
METHOD(Squeaker, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(Squeaker, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_FRAG;
}
#endif
