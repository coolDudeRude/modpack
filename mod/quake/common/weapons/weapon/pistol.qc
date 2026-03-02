#include "pistol.qh"

#ifdef SVQC
PRECACHE(Pistol)
{
	precache_model("progs/g_pistol.mdl");
	precache_model("progs/v_pistol.mdl");

	precache_sound("pistol/pistol_fire.wav");
	precache_sound("pistol/pistol_fire1.wav");
	precache_sound("pistol/pistol_fire2.wav");
	precache_sound("pistol/pistol_fire3.wav");
	precache_sound("pistol/pistol_fire4.wav");
	precache_sound("pistol/ammo_rattle.wav");
	precache_sound("pistol/deadlock_reload.wav");
	precache_sound("pistol/gun_click.wav");
	precache_sound("weapons/ax1.wav");
}

void W_FirePistol(entity this, .entity weaponentity);

void wep_pistol_anim_twirl(entity this)
{
	entity actor = this.owner;
	//.entity weaponentity = this.weaponentity_fld;

	if(this.m_frame == 82)
		_sound(actor, CH_WEAPON_A, "pistol/gun_click.wav", 0.5, ATTN_NORM);

	if(this.m_frame >= 91)
	{
		this.m_frame = 0;
		w_ready(this);
		return;
	}

	this.m_frame += 1;

	wep_set_anim(this, this.m_frame, wep_pistol_anim_twirl);
	this.weapon_nextthink = time + 0.05;
}

void wep_pistol_twirl(entity this)
{
	entity actor = this.owner;
	.entity weaponentity = this.weaponentity_fld;

	if(ATTACK_FINISHED(actor, weaponentity) > time)
		return;

	_sound(actor, CH_WEAPON_B, "weapons/ax1.wav", 1, ATTN_NORM);

	if(this.m_frame >= 66 && this.m_frame <= 80)
		this.m_frame = 68;
	else
		this.m_frame = 66;

	ATTACK_FINISHED(actor, weaponentity) = time + 0.1;

	wep_set_anim(this, this.m_frame, wep_pistol_anim_twirl);
	this.weapon_nextthink = time + 0.05;
}

void wep_pistol_anim_reload(entity this)
{
	entity actor = this.owner;
	//.entity weaponentity = this.weaponentity_fld;

	if(this.m_frame == 47)
		_sound(actor, CH_WEAPON_A, "pistol/deadlock_reload.wav", 1, ATTN_NORM);

	if(this.m_frame >= 59)
		this.pistol_shots = 0; // reset ammo

	if(this.m_frame >= 64)
	{
		this.m_frame = 0;
		w_ready(this);
		return;
	}

	this.m_frame += 1;

	wep_set_anim(this, this.m_frame, wep_pistol_anim_reload);
	this.weapon_nextthink = time + 0.05;
}

void wep_pistol_reload(entity this)
{
	entity actor = this.owner;
	.entity weaponentity = this.weaponentity_fld;

	if(this.weapon_think == wep_pistol_anim_reload)
		return;

	if(IS_PLAYER(actor))
		player_shot1(actor);

	ATTACK_FINISHED(actor, weaponentity) = time + 0.5;

	_sound(actor, CH_WEAPON_A, "pistol/gun_click.wav", 1, ATTN_NORM);

	wep_set_anim(this, 35, wep_pistol_anim_reload);
	this.weapon_nextthink = time + 0.05;
}

void wep_pistol_anim_fire(entity this)
{
	entity actor = this.owner;
	.entity weaponentity = this.weaponentity_fld;

	if(this.pistol_shots >= PISTOL_MAXSHOTS && time > (ATTACK_FINISHED(actor, weaponentity) - 0.1))
	{
		wep_pistol_reload(this);
		return;
	}

	if(this.m_frame >= 31)
	{
		this.m_frame = 10;
		w_ready(this);
		return;
	}
	this.m_frame += 1;

	wep_set_anim(this, this.m_frame, wep_pistol_anim_fire);
	this.weapon_nextthink = time + 0.025;
}

void wep_pistol_anim(entity this)
{
	entity actor = this.owner;
	.entity weaponentity = this.weaponentity_fld;

	if(this.pistol_shots >= PISTOL_MAXSHOTS)
	{
		wep_pistol_reload(this);
		return;
	}

	if(!StatusEffects_active(STATUSEFFECT_SharpShooter, actor))
		this.pistol_shots += 1;

	SuperDamageSound(actor);
	W_FirePistol(actor, weaponentity);

	// low ammo alert
	int ammo = PISTOL_MAXSHOTS - this.pistol_shots;
	switch(ammo)
	{
		case 0: _sound(actor, CH_WEAPON_B, "pistol/ammo_rattle.wav", 1, ATTN_NORM); break;
		case 1: _sound(actor, CH_WEAPON_B, "pistol/ammo_rattle.wav", 0.85, ATTN_NORM); break;
		case 2: _sound(actor, CH_WEAPON_B, "pistol/ammo_rattle.wav", 0.7, ATTN_NORM); break;
		case 3: _sound(actor, CH_WEAPON_B, "pistol/ammo_rattle.wav", 0.55, ATTN_NORM); break;
	}

	this.m_frame = 11;
	wep_set_anim(this, this.m_frame, wep_pistol_anim_fire);
	this.weapon_nextthink = time + 0.025;
}

void W_FirePistol(entity this, .entity weaponentity)
{
	_sound(this, CH_WEAPON_A, "pistol/pistol_fire.wav", 0.6, ATTN_NORM);

	float r = floor(random() * 4);
	switch(r)
	{
		case 0: _sound(this, CH_WEAPON_B, "pistol/pistol_fire1.wav", 0.3, ATTN_NORM); break;
		case 1: _sound(this, CH_WEAPON_B, "pistol/pistol_fire2.wav", 0.3, ATTN_NORM); break;
		case 2: _sound(this, CH_WEAPON_B, "pistol/pistol_fire3.wav", 0.3, ATTN_NORM); break;
		default: _sound(this, CH_WEAPON_B, "pistol/pistol_fire4.wav", 0.3, ATTN_NORM); break;
	}

	this.punchangle_x = -2 * autocvar_sv_quake_recoil;

	vector dir = qc_aim(this, 10000);
	FireBullets(this, 1, 20, W_Shotorg(this, weaponentity) + v_right * 8, dir, '0.015 0.015 0', WEP_PISTOL.m_id);
}

METHOD(Pistol, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	Weapon oldwep = actor.(weaponentity).pistol_prevwep;
	actor.(weaponentity).pistol_prevwep = actor.(weaponentity).m_weapon;

	if(oldwep != WEP_PISTOL) // only plays once!!
	{
		if(actor.(weaponentity).pistol_shots >= PISTOL_MAXSHOTS)
			wep_pistol_reload(actor.(weaponentity));
		else if(actor.(weaponentity).pistol_shots == 0)
			wep_pistol_twirl(actor.(weaponentity));
		return;
	}

	if(fire & 1)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	if(thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	{
		if(IS_PLAYER(actor))
			player_shot1(actor);
		wep_pistol_anim(actor.(weaponentity));
		weapon_prepareattack(thiswep, actor, weaponentity, 0.3);
	}

	if(fire & 2)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	if(actor.(weaponentity).pistol_shots > 0)
	{
		wep_pistol_reload(actor.(weaponentity));
	}
}
METHOD(Pistol, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	return true; // doesn't use ammo!
}
METHOD(Pistol, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(Pistol, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_FRAG;
}
#endif
