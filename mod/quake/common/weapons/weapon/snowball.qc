#include "snowball.qh"

#include "../../monsters/_mod.qh"

#ifdef SVQC

PRECACHE(Snowball)
{
	precache_model("progs/g_snowball.mdl");
	precache_model("progs/v_snowball.mdl");

	precache_model("progs/xmas/proj_snowball.mdl");
	precache_sound("weapons/snowball_impact.wav");
}

void snowball_touch(entity this, entity toucher)
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

	_sound(this, CH_WEAPON_SINGLE, "weapons/snowball_impact.wav", 1, ATTN_NORM);

	if(toucher.takedamage)
	{
		//spawn_touchblood(this, 15, toucher);
		T_Damage(toucher, this, this.owner, 15, this.projectiledeathtype);
	}

	Send_Effect(EFFECT_SNOWBALL_IMPACT, this.origin, '0 0 0', 1);

	delete(this);
}

void W_Snowball_Fire(entity this, .entity weaponentity)
{
	makevectors(this.v_angle);

	sound(this, CH_WEAPON_SINGLE, SND_SNOWBALL_THROW, 1, ATTN_NORM);

	vector dir = qc_aim(this, 1000);
	entity newmis = launch_spike(this, W_Shotorg(this, weaponentity) + v_right * 3, dir);
	if(this.v_angle_x)
		newmis.velocity = v_forward * 1000 + v_up * 100 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		newmis.velocity = qc_aim(this, 1000);
		newmis.velocity = newmis.velocity * 1000;
		newmis.velocity_z = 100;
	}

	set_movetype(newmis, MOVETYPE_TOSS);
	newmis.projectiledeathtype = WEP_SNOWBALL.m_id;
	newmis.classname = "snowball";
	//newmis.scale = 2;
	newmis.gravity = 0.5;
	settouch(newmis, snowball_touch);
	setsize(newmis, '0 0 0', '0 0 0');
	CSQCProjectile(newmis, true, PROJECTILE_SNOWBALL, true);
}

METHOD(Snowball, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	//if(thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	{
		if(IS_PLAYER(actor))
			player_shot1(actor);
		wep_generic_shot1(actor.(weaponentity));
		W_Snowball_Fire(actor, weaponentity);
		weapon_prepareattack(thiswep, actor, weaponentity, 0.25);
	}
}
METHOD(Snowball, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	// does not use ammo
	return true;
}
METHOD(Snowball, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(Snowball, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_FRAG;
}
#endif
