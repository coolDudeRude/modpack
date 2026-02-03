#include "gibs.qh"

#ifdef SVQC
// TODO: generic gib handling? a lot of monsters do their own thing!
#endif

#ifdef CSQC

.vector colormod;
.bool silent;

#include "rubble.qh"
#include "../../physics/movetypes/movetypes.qh"

.float scale;
.float alpha;
.float cnt;
.float gravity;

void Gib_Delete(entity this)
{
	delete(this);
}

void SUB_RemoveOnNoImpact(entity this, entity toucher)
{
	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
		Gib_Delete(this);
}

void Gib_Touch(entity this, entity toucher)
{
	// TODO maybe bounce of walls, make more gibs, etc.

	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		Gib_Delete(this);
		return;
	}

	//if(!this.silent)
		//sound(this, CH_PAIN, SND_GIB_SPLAT_RANDOM(), VOL_BASE, ATTEN_NORM);
	pointparticles(EFFECT_TE_BLOOD, this.origin + '0 0 1', '0 0 30', 10);

	Gib_Delete(this);
}

void Gib_Draw(entity this)
{
	Movetype_Physics_MatchTicrate(this, autocvar_cl_gibs_ticrate, autocvar_cl_gibs_sloppy);
	if(wasfreed(this))
		return;

	// TODO? origin check seems necessary to prevent effect spam
	if(this.trail_oldorigin != this.origin)
		Projectile_DrawTrail(this, this.origin);

	this.renderflags = 0;

	// make gibs die faster at low view quality
	// if view_quality is 0.5, we want to have them die twice as fast
	this.nextthink -= frametime * (1 / bound(0.01, view_quality, 1.00) - 1);

	this.alpha = bound(0, this.nextthink - time, 1);

	if(this.alpha < ALPHA_MIN_VISIBLE)
	{
		this.drawmask = 0;
		Gib_Delete(this);
	}
}

void TossGib (string mdlname, vector safeorg, vector org, vector vconst, vector vrand, int specnum, bool destroyontouch, bool issilent)
{
	entity gib = ListNewChildRubble(CasingsNGibs, new(gib));
	set_movetype(gib, MOVETYPE_BOUNCE);
	gib.gravity = 1;
	gib.solid = SOLID_CORPSE;
	gib.cnt = specnum;
	gib.silent = issilent;
	//gib.colormap = 4; // red
	//gib.colormap |= BIT(10); // RENDER_COLORMAPPED
	_setmodel(gib, mdlname);
	gib.skin = specnum;
	if(!issilent) // HACK: we don't have gib sounds, so just abuse it to hide the trail
		gib.traileffect = EFFECT_TR_BLOOD.m_id;

	setsize (gib, '-8 -8 -8', '8 8 8');

	gib.draw = Gib_Draw;
	IL_PUSH(g_drawables, gib);
	if(destroyontouch)
		settouch(gib, Gib_Touch);
	else
		settouch(gib, SUB_RemoveOnNoImpact);

	// don't spawn gibs inside solid - just don't
	if(org != safeorg)
	{
		tracebox(safeorg, gib.mins, gib.maxs, org, MOVE_NOMONSTERS, gib);
		org = trace_endpos;
	}

	setorigin(gib, org);
	gib.trail_oldorigin = org;
	gib.velocity = vconst;
	//gib.velocity = vconst * autocvar_cl_gibs_velocity_scale + vrand * autocvar_cl_gibs_velocity_random + '0 0 1' * autocvar_cl_gibs_velocity_up;
	//gib.avelocity = randomvec() * vlen(gib.velocity) * autocvar_cl_gibs_avelocity_scale;
	gib.avelocity_x = random() * 600;
	gib.avelocity_y = random() * 600;
	gib.avelocity_z = random() * 600;
	gib.move_time = time;
	//gib.damageforcescale = autocvar_cl_gibs_damageforcescale;

	gib.nextthink = time + 10 * (1 + prandom() * 0.15);
	gib.drawmask = MASK_NORMAL;

	LimitedChildrenRubble(CasingsNGibs, "gib", autocvar_cl_gibs_maxcount, Gib_Delete, NULL);
}

// NOTE: requires `normalize(this.origin - inflictor.origin)` operation to be performed on server
vector VelocityForDamage(vector org, vector targnorm, vector targvel, float dm)
{
	vector v;

	// check if the inflictor had velocity, e.g. like a rocket or explode box
	if(targvel != '0 0 0')
	{
		// impact some of inflictor's velocity on the gibs
		v = 0.2 * targvel;
		v = v + (25 * targnorm);
		v.z = 100 + 100 * random();
		v.x = v.x + (50 * crandom());
		v.y = v.y + (50 * crandom());
	}
	else
	{
		v.x = 100 * crandom();
		v.y = 100 * crandom();
		v.z = 200 + 100 * random();
	}

	// TODO: damageforcescale support
	if(dm > -50)
	{
//		dprint("level 1\n");
		v = v * 0.7;
	}
	else if(dm > -200)
	{
//		dprint("level 3\n");
		v = v * 2;
	}
	else
		v = v * 10;

	return v;
}
#endif
