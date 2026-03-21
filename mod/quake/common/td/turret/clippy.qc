#include "clippy.qh"

// =============
//  RECYCLE BIN
// =============

#ifdef SVQC
vector tuba_calc_arc(vector org, vector tgt, float ht); // saves some copy-pasta
vector recyclebin_calc_velocity(entity actor, vector org, entity targ)
{
	//vector oldvel = normalize(actor.enemy.origin - org) * 500 + v_up * 500;

	vector tpos1 = (targ.absmin + targ.absmax) * 0.5;
	vector v = org;

	traceline(v, v + '0 0 1' * 65535, MOVE_WORLDONLY, actor);
	float h1 = 0.75 * vlen(v - trace_endpos);

	traceline(v, tpos1 + '0 0 1' * 65535, MOVE_WORLDONLY, actor);
	float h2 = 0.75 * vlen(tpos1 - v);

	return tuba_calc_arc(v, tpos1, ((h1 < h2) ? h1 : h2));
}

METHOD(ClippyRecycleBin, tr_precache, void(ClippyRecycleBin thistur))
{
	precache_sound("turrets/recyclebin_fire.wav");
}
METHOD(ClippyRecycleBin, tr_think, void(ClippyRecycleBin thistur, entity actor))
{
	// make sure it matches drawn values!
	float myrange = 460 * turret_getpower(actor.tur_level, 0.2);
	float viscone = 0.4;
	if(actor.enemy)
	{
		makevectors(actor.angles);
		vector vec = normalize(actor.enemy.origin - actor.origin);
		float dot = vec * v_forward;

		bool isvisible = visible(actor, actor.enemy);
		if(isvisible || dot < viscone)
			actor.search_time = time + 1;
		if(actor.enemy.health < 1 || actor.enemy.exptime != 0 || time > actor.search_time || vdist(actor.origin - actor.enemy.origin, >, myrange * 1.5))
		{
			actor.enemy = NULL;
			return; // won't find a new target this frame
		}

		if(time >= actor.attack_finished && dot > viscone && isvisible)
		{
			actor.attack_finished = time + max(0.03, (1 / turret_getpower(actor.tur_level, 0.33)));

			_sound(actor, CH_WEAPON_SINGLE, "turrets/recyclebin_fire.wav", 1, ATTN_NORM);

			vector org = actor.origin + actor.view_ofs;
			entity newmis = launch_spike(actor, org, '0 0 1');
			newmis.projectiledeathtype = DEATH_TRAP.m_id;
			newmis.velocity = recyclebin_calc_velocity(newmis, org, actor.enemy);
			newmis.gravity = 1;
			newmis.dmg = thistur.tur_dmg * turret_getpower(actor.tur_level, thistur.tur_dmgscale);
			set_movetype(newmis, MOVETYPE_TOSS);
			CSQCProjectile(newmis, true, PROJECTILE_RECYCLEBIN, true);
		}
	}
	
	if(!actor.enemy && time >= actor.idle_finished)
	{
		actor.idle_finished = time + 0.5;
		actor.enemy = turret_findtarget(actor, viscone, myrange);
	}
}
METHOD(ClippyRecycleBin, tr_setup, void(ClippyRecycleBin this, entity actor))
{
	actor.view_ofs = '0 0 12'; // for line of sight checks
}
#endif // SVQC
#ifdef CSQC
METHOD(ClippyRecycleBin, tr_drawselected, void(ClippyRecycleBin this, entity actor))
{
	float myrange = 420 * turret_getpower(actor.tur_level, 0.2);
	makevectors(actor.angles);
	vector org = actor.origin + '0 0 12';

	Draw_Cone(org, v_forward, myrange, 0.4);

	// TODO: cone?
	//Draw_CylindricLine(org, org + v_forward * myrange, 6, "particles/laserbeam", 0.25, -time * 3, '1 0.25 0', 1, DRAWFLAG_NORMAL, view_origin);
}
#endif // CSQC
