#include "water.qh"

#ifdef GAMEQC
bool PointInWaterBrush(vector org)
{
	bool found = false;
	IL_EACH(g_waterbrushes, boxesoverlap(org - '0 0 1', org + '0 0 1', it.absmin, it.absmax),
	{
		found = true;
		break;
	});
	return found;
}

int WaterBrush_Level(entity this, entity brush)
{
	// same method as the engine's internal function:
	// - horizontal axes checked against entity's origin
	// - vertical axis checked against entity's bottom limit and view_ofs 
	if(this.origin_x > brush.absmax_x) 
		return 0;
	if(this.origin_x < brush.absmin_x)
		return 0;
	if(this.origin_y > brush.absmax_y)
		return 0;
	if(this.origin_y < brush.absmin_y)
		return 0;
	if(this.absmin_z > brush.absmax_z)
		return 0;
	if(this.absmax_z - this.view_ofs_z < brush.absmin_z)
		return 0;
	
	int lvl;
	float depth = brush.absmax_z - this.absmin_z;

	if(depth > (this.view_ofs_z - this.mins_z + 2))
		lvl = 3;
	else if(depth > (this.absmax_z - this.absmin_z)/2)
		lvl = 2;
	else
		lvl = 1;
	return lvl;
}

void CheckWaterBrushes(entity this)
{
	IL_EACH(g_waterbrushes, true,
	{
		int wlevel = WaterBrush_Level(this, it);
		if(wlevel > 0)
		{
			this.waterlevel = wlevel;
			this.watertype = it.liquidtype;
			break; // we got what we wanted
		}
	});
}
#endif

#ifdef SVQC
void WaterBrushes_Frame()
{
	IL_EACH(g_waterbrushes, true,
	{
		CSQCMODEL_AUTOUPDATE(it);
	});
}

void WaterBrushes_Init(entity this)
{
	FOREACH_ENTITY_FLOAT(liquidbrush, 1,
	{
		it.solid = SOLID_NOT;
		if(it.move_movetype == MOVETYPE_PUSH)
			set_movetype(it, MOVETYPE_FAKEPUSH);
		setblocked(it, func_null);
		settouch(it, func_null); // TODO?
		setorigin(it, it.origin); // relink
		IL_PUSH(g_waterbrushes, it);

		CSQCMODEL_AUTOINIT(it);
	});

	delete(this);
}

STATIC_INIT_LATE(WaterBrushes)
{
	entity waterstart = new_pure(waterstart);
	setthink(waterstart, WaterBrushes_Init);
	waterstart.nextthink = time + 0.25; // give quake a moment to load
}
#endif
