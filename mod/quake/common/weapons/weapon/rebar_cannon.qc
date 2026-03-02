#include "rebar_cannon.qh"

#ifdef SVQC
PRECACHE(RebarCannon)
{
	precache_model("progs/v_rebar.mdl");
	precache_model("progs/g_rebar.mdl");

	precache_model("progs/proj_rebar.mdl");
	precache_model("progs/proj_rebar_nosmoke.mdl");
	precache_model("progs/zom_gib.mdl");

	precache_model("progs/fx/spark1.mdl");
	precache_model("progs/fx/spark2.mdl");
	precache_model("progs/fx/spark3.mdl");
	precache_model("progs/fx/spark4.mdl");
	precache_model("progs/fx/blood_big1.mdl");
	precache_model("progs/fx/blood_big2.mdl");
	precache_model("progs/fx/blood_big3.mdl");
	precache_model("progs/fx/blood_big4.mdl");

	precache_sound("rebar/bow_clank.wav");
	precache_sound("rebar/penfire.wav");
	precache_sound("rebar/bow_reload1.wav");
	precache_sound("rebar/bow_reload2.wav");
	precache_sound("rebar/bow_reload3.wav");
	precache_sound("rebar/bow_reload4.wav");

	precache_sound("rebar/stick1.wav");
	precache_sound("rebar/stick_metal1.wav");
	precache_sound("rebar/stick_metal2.wav");
	precache_sound("rebar/pierce1.wav");
	precache_sound("rebar/pierce2.wav");
	precache_sound("rebar/pierce3.wav");
	precache_sound("rebar/pierce_impact.wav");
}

void wep_rebar_anim(entity this)
{
	entity actor = this.owner;
	//.entity weaponentity = this.weaponentity_fld;

	switch(this.m_frame)
	{
		case 18: _sound(actor, CH_WEAPON_B, "rebar/bow_reload2.wav", 0.3, ATTN_NORM); break;
		case 20: _sound(actor, CH_WEAPON_B, "rebar/bow_clank.wav", 0.4, ATTN_NORM); break;
		case 23: _sound(actor, CH_WEAPON_B, "rebar/bow_reload3.wav", 0.3, ATTN_NORM); break;
		case 26: _sound(actor, CH_WEAPON_B, "rebar/bow_reload4.wav", 0.4, ATTN_NORM); break;
	}

	if(this.m_frame >= 30)
	{
		this.m_frame = 10;
		w_ready(this);
		return;
	}
	else
		this.m_frame += 1;

	wep_set_anim(this, this.m_frame, wep_rebar_anim);
	this.weapon_nextthink = time + 0.05;
}

void anim_rebarfx(entity this)
{
	this.alpha -= 0.1;
	this.frame += 1;

	if(this.frame >= 6)
	{
		delete(this);
		return;
	}

	setthink(this, anim_rebarfx);
	this.nextthink = time + 0.05;
}

void FX_Rebar(vector org, vector dir, bool is_spark)
{
	entity fx = spawn();
	set_movetype(fx, MOVETYPE_NONE);
	fx.solid = SOLID_NOT;
	fx.classname = "impact";

	fx.angles = vectoangles(dir);

	fx.frame = 0;
	fx.alpha = 1;

	setthink(fx, anim_rebarfx);
	fx.nextthink = time + 0.1;

	int r = floor(random() * 4);
	if(is_spark)
	{
		switch(r)
		{
			case 0: _setmodel(fx, "progs/fx/spark1.mdl"); break;
			case 1: _setmodel(fx, "progs/fx/spark2.mdl"); break;
			case 2: _setmodel(fx, "progs/fx/spark3.mdl"); break;
			default: _setmodel(fx, "progs/fx/spark4.mdl"); break;
		}
	}
	else
	{
		switch(r)
		{
			case 0: _setmodel(fx, "progs/fx/blood_big1.mdl"); break;
			case 1: _setmodel(fx, "progs/fx/blood_big2.mdl"); break;
			case 2: _setmodel(fx, "progs/fx/blood_big3.mdl"); break;
			default: _setmodel(fx, "progs/fx/blood_big4.mdl"); break;
		}
	}
	setsize(fx, '0 0 0', '0 0 0');

	setorigin(fx, org);
}

void RebarFade(entity this)
{
	this.alpha -= PHYS_INPUT_FRAMETIME;
	
	if(this.alpha <= 0)
	{
		delete(this);
		return;
	}

	if(!this.state)
	{
		this.angles = vectoangles(this.velocity);
		UNSET_ONGROUND(this);
		this.oldvelocity = this.velocity;
	}

	setthink(this, RebarFade);
	this.nextthink = time;
}

void RebarTouch(entity this, entity toucher)
{
	if(toucher.solid == SOLID_TRIGGER)
		return;

	if(pointcontents(this.origin) == CONTENT_SKY)
	{
		delete(this);
		return;
	}
	
	if(toucher.takedamage)
	{
		float damage = 100;
		if(toucher.monsterdef.spawnflags & MONSTER_TYPE_UNDEAD)
			damage = 59;
		T_Damage(toucher, this, this.realowner, damage, this.projectiledeathtype);

		if(toucher.solid != SOLID_BSP && !(toucher.monsterdef.spawnflags & MON_FLAG_METAL))
		{
			ThrowGib(toucher, this, "progs/zom_gib.mdl", 20);
			ThrowGib(toucher, this, "progs/zom_gib.mdl", 20);
		}

		FX_Rebar(this.origin, this.oldvelocity, false);

		particle(this.origin, this.velocity * 0.1, 73, 40);

		float chance = random();
		if(chance < 0.33)
			_sound(this, CH_SHOTS, "rebar/pierce1.wav", 1, ATTN_NORM);
		else if(chance < 0.66)
			_sound(this, CH_SHOTS, "rebar/pierce2.wav", 1, ATTN_NORM);
		else
			_sound(this, CH_SHOTS, "rebar/pierce3.wav", 1, ATTN_NORM);

		_sound(this, CH_SHOTS, "rebar/pierce_impact.wav", 1, ATTN_NORM);

		// doesn't go through doors
		if(toucher.solid != SOLID_BSP)
		{
			this.velocity = this.oldvelocity;
			setorigin(this, this.origin + normalize(this.velocity) * 0.1);
			return;
		}
	}

	_sound(this, CH_SHOTS, "rebar/stick1.wav", 0.5, ATTN_NORM);

	if(random() < 0.5)
		_sound(this, CH_SHOTS, "rebar/stick_metal1.wav", 0.7, ATTN_NORM);
	else
		_sound(this, CH_SHOTS, "rebar/stick_metal2.wav", 0.7, ATTN_NORM);

	FX_Rebar(this.origin, this.oldvelocity, true);

	te_gunshot(this.origin);

	if(toucher.solid == SOLID_BSP && toucher.classname != "func_movewall")
	{
		entity rebar = spawn();
		set_movetype(rebar, MOVETYPE_NONE);
		rebar.solid = SOLID_NOT;
		rebar.owner = toucher;
		rebar.angles = this.angles;
		settouch(rebar, func_null);
		// change model so that smoke doesn't appear when stuck to moving brushes
		_setmodel(rebar, "progs/proj_rebar_nosmoke.mdl");
		setsize(rebar, '0 0 0', '0 0 0');

		// move origin away from walls when stuck, helps prevent "void-lighting"
		setorigin(rebar, this.origin - 2 * normalize(this.velocity));
		if(toucher)
			attach_sameorigin(rebar, toucher, "");

		// set state 2 to rebars attached to non-world entities (for movement and validity checks)
		rebar.state = (toucher) ? 2 : 1;

		rebar.alpha = 1;
		setthink(rebar, RebarFade);
		rebar.nextthink = time + 10;
	}

	delete(this);
}

void RebarThink(entity this)
{
	this.nextthink = time;
	if(this.cnt < time)
	{
		RebarFade(this);
		return;
	}

	UNSET_ONGROUND(this);
	this.angles = vectoangles(this.velocity);
	this.oldvelocity = this.velocity;
}

void W_FireRebarCannon(entity this, .entity weaponentity)
{
	this.punchangle_x = -2 * autocvar_sv_quake_recoil;

	W_TakeAmmo(this, IT_NAILS, 10);

	_sound(this, CH_WEAPON_SINGLE, "rebar/penfire.wav", 1, ATTN_NORM);
	_sound(this, CH_WEAPON_B, "rebar/bow_reload1.wav", 0.5, ATTN_NORM);

	entity newmis = spawn();
	newmis.flags = FL_PROJECTILE;
	newmis.projectiledeathtype = WEP_REBAR_CANNON.m_id;
	newmis.clipgroup = this.clipgroup;
	newmis.owner = newmis.realowner = this;
	set_movetype(newmis, MOVETYPE_BOUNCEMISSILE);
	newmis.solid = SOLID_BBOX;
	newmis.classname = "rebar";
	newmis.gravity = 0.75;
	newmis.alpha = 1;

	makevectors(this.v_angle);
	vector dir = qc_aim(this, 1400);
	newmis.velocity = dir * 1400;
	newmis.angles = vectoangles(newmis.velocity);
	settouch(newmis, RebarTouch);
	newmis.cnt = time + 5;
	newmis.nextthink = time;
	setthink(newmis, RebarThink);

	_setmodel(newmis, "progs/proj_rebar.mdl");
	setsize(newmis, '0 0 0', '0 0 0');
	vector org = W_Shotorg(this, weaponentity) - v_up * 8; // v_forward * 15, not used because it goes through mobs!
	setorigin(newmis, org);

	IL_PUSH(g_projectiles, newmis);

	//CSQCProjectile(newmis, true, PROJECTILE_REBAR, true);
}

METHOD(RebarCannon, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	if(!(time < ATTACK_FINISHED(actor, weaponentity)))
	if(thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	{
		W_FireRebarCannon(actor, weaponentity);
		if(IS_PLAYER(actor))
			player_shot1(actor);
		actor.(weaponentity).m_frame = 10; // will be increased by 1 instantly
		wep_rebar_anim(actor.(weaponentity));
		weapon_prepareattack(thiswep, actor, weaponentity, 1);
	}
}
METHOD(RebarCannon, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = actor.ammo_nails >= 10;
	return ammo_amount;
}
METHOD(RebarCannon, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(RebarCannon, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_FRAG;
}
#endif
