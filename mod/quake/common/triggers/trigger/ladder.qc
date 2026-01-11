bool CheckLadder(entity this)
{
	if(IL_EMPTY(g_ladders))
		return false;

	vector emin = this.absmin, emax = this.absmax;
	emin -= '1 1 1';
	emax += '1 1 1';
	bool foundladder = false;

	FOREACH_ENTITY_BOX_ORDERED(emin, emax, it != this && it.classname == "ladder",
	{
		foundladder = true;
		break;
	});

	return foundladder;
}

#ifdef SVQC

bool trigger_ladder_SendEntity(entity this, entity to, int sendflags)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TRIGGER_LADDER);
	WriteByte(MSG_ENTITY, sendflags);
	if(sendflags & SF_LADDER_ORIGIN)
	{
		WriteVector(MSG_ENTITY, this.origin);
	}
	if(sendflags & SF_TRIGGER_INIT)
	{
		if(this.model != "null")
		{
			WriteShort(MSG_ENTITY, this.modelindex);
			WriteVector(MSG_ENTITY, this.mins);
			WriteVector(MSG_ENTITY, this.maxs);
		}
		else
		{
			WriteShort(MSG_ENTITY, 0);
			WriteVector(MSG_ENTITY, this.maxs);
		}
	}
	return true;
}

spawnfunc(trigger_ladder)
{
	this.solid = SOLID_TRIGGER; // for radius checks
	if(this.model != "")
	{
		precache_model(this.model);
		_setmodel(this, this.model);
	}

	if(!this.modelindex)
	{
		setorigin(this, this.origin + this.mins);
		setsize(this, '0 0 0', this.maxs - this.mins);
	}

	this.classname = "ladder";

	Net_LinkEntity(this, false, 0, trigger_ladder_SendEntity);

	IL_PUSH(g_ladders, this);
}

// try for Xonotic compatibility
spawnfunc(func_ladder) { spawnfunc_trigger_ladder(this); }

#endif

#ifdef CSQC

NET_HANDLE(ENT_CLIENT_TRIGGER_LADDER, bool isnew)
{
	int sendflags = ReadByte();
	if(sendflags & SF_LADDER_ORIGIN)
	{
		this.origin = ReadVector();
	}
	if(sendflags & SF_TRIGGER_INIT)
	{
		this.modelindex = ReadShort();
		if(this.modelindex)
		{
			this.mins = ReadVector();
			this.maxs = ReadVector();
		}
		else
		{
			this.mins    = '0 0 0';
			this.maxs = ReadVector();
		}
	}

	this.solid = SOLID_TRIGGER;
	this.classname = "ladder";
	setorigin(this, this.origin);
	setsize(this, this.mins, this.maxs);
	if(isnew)
	{
		IL_PUSH(g_ladders, this);
	}
	return true;
}

#endif
