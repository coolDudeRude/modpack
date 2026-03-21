#include "pepsiman.qh"

// =================
//  VENDING MACHINE
// =================

#ifdef SVQC
entity can_launch(entity this, vector org, vector dir);

METHOD(PepsimanVendingMachine, tr_precache, void(PepsimanVendingMachine thistur))
{
	precache_sound("player_pepsiman/can_roll.wav");
}
METHOD(PepsimanVendingMachine, tr_think, void(PepsimanVendingMachine thistur, entity actor))
{
	// make sure it matches drawn values!
	float myrange = 400; // doesn't get extended by levels
	float viscone = 0.6;
	if(actor.enemy)
	{
		makevectors(actor.angles);
		vector org = actor.origin + '0 0 8';
		vector targ_org = actor.enemy.origin;
		vector vec = normalize(targ_org - org);
		float dot = vec * v_forward;

		bool isvisible = visible(actor, actor.enemy);
		if(isvisible || dot < viscone)
			actor.search_time = time + 1;
		if(actor.enemy.health < 1 || actor.enemy.exptime != 0 || time > actor.search_time || vdist(org - targ_org, >, myrange * 1.5))
		{
			actor.enemy = NULL;
			return; // won't find a new target this frame
		}

		if(time > actor.attack_finished && dot > viscone && isvisible)
		{
			actor.attack_finished = time + max(0.03, (1 / turret_getpower(actor.tur_level, 0.25)));
			actor.clientframe = TANIM_SHOOT;

			vector dir = normalize(vec2(targ_org - org));

			entity can = can_launch(actor, org, dir);
			can.cnt = 24; // rough bounding box for cheaper math, update if hitbox is changed!
			setsize(can, '-12 -12 0', '12 12 12');
			can.dmg = thistur.tur_dmg * turret_getpower(actor.tur_level, thistur.tur_dmgscale);

			CSQCProjectile(can, true, PROJECTILE_CAN_SMALL, true);

			sound7(can, CH_SHOTS_SINGLE, "player_pepsiman/can_roll.wav", 1, ATTN_NORM, 200, 0);
		}
	}
	
	if(!actor.enemy && time >= actor.idle_finished)
	{
		actor.idle_finished = time + 0.5;
		actor.enemy = turret_findtarget(actor, viscone, myrange);
	}
}
#endif // SVQC
#ifdef CSQC
METHOD(PepsimanVendingMachine, tr_drawselected, void(PepsimanVendingMachine this, entity actor))
{
	float myrange = 400;
	makevectors(actor.angles);
	vector org = actor.origin + '0 0 8';

	Draw_Cone(org, v_forward, myrange, 0.6);

	// TODO: cone?
	//Draw_CylindricLine(org, org + v_forward * myrange, 6, "particles/laserbeam", 0.25, -time * 3, '1 0.25 0', 1, DRAWFLAG_NORMAL, view_origin);
}
METHOD(PepsimanVendingMachine, tr_setup, void(PepsimanVendingMachine this, entity actor))
{
	actor.anim_idle = '0 0 0';
	actor.anim_shoot = '0 0 0';
}
#endif // CSQC
