#include "cl_td.qh"

#include "td.qh"
void td_UpdateView(entity this)
{
	// always reset at the first draw call, so we don't get lingering data
	buildtool_targ = NULL;

	if(!td_ent || !STAT(TD_BUILDMODE) || STAT(TD_PHASE) == TD_PHASE_WIN || intermission || STAT(HEALTH) < 1)
		return;
	
	buildtool_frame(this);
}

void HUD_TD(entity this)
{
	if(!td_ent || !STAT(TD_BUILDMODE) || STAT(TD_PHASE) == TD_PHASE_WIN || intermission || STAT(HEALTH) < 1)
		return;

	buildtool_draw2d(this);
}

.int worldtype; // TODO?
.float td_chest_frametick;
void td_chest_draw(entity this)
{
	if(time > this.td_chest_frametick)
	{
		if((this.state && this.frame < 2) || (!this.state && this.frame > 0))
		{
			CSQCModel_InterpolateAnimation_1To2_PreNote(this, BIT(23));
			int dir = (this.state) ? 1 : -1;
			if(this.state && this.frame == 0 && this.noise && this.noise != "")
				_sound(this, CH_TRIGGER_SINGLE, this.noise, VOL_BASE, ATTEN_NORM);
			this.frame += dir;
			CSQCModel_InterpolateAnimation_1To2_Note(this, BIT(23), true);
		}

		this.td_chest_frametick = time + 0.1; // roughly match quake animations
	}

	CSQCModel_InterpolateAnimation_Do(this);
}

void td_chest_remove(entity this)
{
	strfree(this.mdl);
	strfree(this.noise);
}

NET_HANDLE(ENT_CLIENT_TD_CHEST, bool isnew)
{
	this.origin = ReadVector();
	setorigin(this, this.origin);
	float ang = ReadAngle();
	this.angles = '0 1 0' * ang;
	int sf = ReadByte();
	this.worldtype = ReadByte();

	if(sf & SF_TD_CHEST_MDL)
		strcpy(this.mdl, ReadString());

	if(sf & SF_TD_CHEST_NOISE)
		strcpy(this.noise, ReadString());

	this.classname = "td_chest"; // for identification

	this.state = (sf & SF_TD_CHEST_OPEN);

	this.effects = EF_FULLBRIGHT;
	this.solid = SOLID_BBOX;
	string fallbackmdl = string_null;
	string fallbacknoise = string_null;
	switch(this.worldtype)
	{
		default:
		case WORLDTYPE_MEDIEVAL: fallbackmdl = "progs/td_chest_medieval.mdl"; fallbacknoise = "td/chest_medieval_open.wav"; break;
		case WORLDTYPE_METAL: fallbackmdl = "progs/td_chest_metal.mdl"; fallbacknoise = "td/chest_metal_open.wav"; break;
		case WORLDTYPE_BASE: fallbackmdl = "progs/td_chest_base.mdl"; fallbacknoise = "misc/menu2.wav"; break;
	}
	if(!this.mdl && fallbackmdl)
		strcpy(this.mdl, fallbackmdl);
	if(!this.noise && fallbacknoise)
		strcpy(this.noise, fallbacknoise);

	precache_sound(this.noise);
	precache_model(this.mdl);
	_setmodel(this, this.mdl);
	setsize(this, '-24 -24 0', '24 24 32');

	set_movetype(this, MOVETYPE_NONE);
	//this.td_chest_frametick = 0;
	if(isnew)
	{
		this.frame = 0;
		CSQCModel_InterpolateAnimation_1To2_PreNote(this, BIT(23));
		CSQCModel_InterpolateAnimation_1To2_Note(this, BIT(23), true);
		this.lerpfrac = 0; // reset frames
	}

	this.entremove = td_chest_remove;
	this.draw = td_chest_draw;
	if(isnew && !IL_CONTAINS(g_drawables, this))
		IL_PUSH(g_drawables, this);
	this.drawmask = MASK_NORMAL;

	return = true;
}

void td_tower_remove(entity this)
{
	strfree(this.mdl);
}

NET_HANDLE(ENT_CLIENT_TD_TOWER, bool isnew)
{
	this.origin = ReadVector();
	setorigin(this, this.origin);
	float ang = ReadAngle();
	this.angles = '0 1 0' * ang;
	int sf = ReadByte();
	this.worldtype = ReadByte();

	if(sf & SF_TD_TOWER_MDL)
		strcpy(this.mdl, ReadString());

	this.classname = "td_tower"; // for identification

	this.solid = SOLID_BBOX;
	string fallbackmdl = string_null;
	switch(this.worldtype)
	{
		case WORLDTYPE_MEDIEVAL: fallbackmdl = "progs/chaosorb.mdl"; break;
		default:
		case WORLDTYPE_METAL: fallbackmdl = "progs/floyd.mdl"; break;
		case WORLDTYPE_BASE: fallbackmdl = "progs/reactor.mdl"; break;
	}
	if(!this.mdl && fallbackmdl)
		strcpy(this.mdl, fallbackmdl);

	precache_model(this.mdl);
	_setmodel(this, this.mdl);
	setsize(this, '-32 -32 -24', '32 32 64');

	set_movetype(this, MOVETYPE_NONE);

	this.entremove = td_tower_remove;
	this.drawmask = MASK_NORMAL;

	return = true;
}

NET_HANDLE(ENT_CLIENT_TD_SPAWNPOINT, bool isnew)
{
	this.origin = ReadVector();
	setorigin(this, this.origin);

	this.classname = "td_spawnpoint"; // for identification
	this.solid = SOLID_TRIGGER;
	setsize(this, '-150 -150 -150', '150 150 150');
	set_movetype(this, MOVETYPE_NONE);

	return = true;
}

void td_ent_remove(entity this)
{
	if(td_ent == this)
		td_ent = NULL;
}

NET_HANDLE(ENT_CLIENT_TD_ENT, bool isnew)
{
	int sf = ReadByte();

	if(sf & SF_TD_ENT_COUNTS)
	{
		this.wave = ReadByte();
		this.tur_units = ReadShort();
	}

	if(sf & SF_TD_ENT_LIMITS)
	{
		this.count = ReadByte();
		this.currentammo = ReadShort();
	}

	td_ent = this;

	return = true;
}
