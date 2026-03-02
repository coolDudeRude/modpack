#include "scattercrumb.qh"

#ifdef SVQC
PRECACHE(Scattercrumb)
{
	precache_model("progs/v_scattercrumb.mdl");
	precache_model("progs/g_scattercrumb.mdl");

	precache_sound("weapons/breadgun_fire.wav");
}

void crumb_touch(entity this, entity toucher)
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
	if(toucher.takedamage) // yoder mod, jan 05 2021
	{
		float damg = ((this.dmg) ? this.dmg : 4);
		if(toucher.resist_shells != 0)
			damg = Resist_Damage(toucher, IT_SHELLS, damg);
		Resist_Shells(toucher, this.origin, this.velocity, damg);

		spawn_touchblood(this, damg, toucher);
		T_Damage(toucher, this, this.owner, damg, this.projectiledeathtype);

		delete(this);
		return;
	}

	//spamsound(this, CH_SHOTS, SND_SCATTERCRUMB_BOUNCE, 1, ATTN_NORM);
}

// copied from FireBullets
void FireCrumbs(entity this, int shotcount, vector org, vector dir, vector spread, int deathtype)
{
	float bullet_speed;
	if(IS_PLAYER(this))
	{
		makevectors(this.v_angle);
		bullet_speed = 2000;
	}
	else
	{
		makevectors(this.angles);
		bullet_speed = 800 + (autocvar_skill * 150);
	}
	vector src_origin = org;
	if(!IS_PLAYER(this))
		src_origin.z = this.absmin_z + this.size_z * 0.7;

	traceline(src_origin, src_origin + v_forward, MOVE_NORMAL, this);
	src_origin = trace_endpos;

	for(int j = 0; j < shotcount; ++j)
	{
		float var_speed = crandom() * 10 + bullet_speed;
		vector spread_dir = dir + (crandom() * spread.x) * v_right + (crandom() * spread.y) * v_up;
		entity missile = launch_spike(this, src_origin, spread_dir);
		missile.classname = "crumb";
		missile.velocity = spread_dir * var_speed;
		missile.projectiledeathtype = deathtype;
		missile.gravity = 1;
		missile.bouncefactor = 0.5;
		missile.bouncestop = 0.125;
		missile.nextthink = time + 4;
		_setmodel(missile, "");
		setsize(missile, '0 0 0', '0 0 0');
		set_movetype(missile, MOVETYPE_BOUNCE);
		settouch(missile, crumb_touch);

		CSQCProjectile(missile, true, PROJECTILE_CRUMB, true);
	}
}

void W_FireScattercrumb(entity this, .entity weaponentity)
{
	_sound(this, CH_WEAPON_SINGLE, "weapons/breadgun_fire.wav", 1, ATTN_NORM);	

	this.punchangle_x = -4 * autocvar_sv_quake_recoil;

	W_TakeAmmo(this, IT_SHELLS, 1);
	vector dir = qc_aim(this, 100000);
	FireCrumbs(this, 14, W_Shotorg(this, weaponentity), dir, '0.14 0.08 0', WEP_SCATTERCRUMB.m_id);
}

METHOD(Scattercrumb, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	if(thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	{
		if(IS_PLAYER(actor))
			player_shot1(actor);
		wep_generic_shot1(actor.(weaponentity));
		W_FireScattercrumb(actor, weaponentity);
		weapon_prepareattack(thiswep, actor, weaponentity, 0.7);
	}
}
METHOD(Scattercrumb, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = actor.ammo_shells >= 1;
	return ammo_amount;
}
METHOD(Scattercrumb, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(Scattercrumb, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_FRAG;
}
#endif
