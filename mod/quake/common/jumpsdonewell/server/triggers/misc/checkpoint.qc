#ifdef SVQC

void checkpoint_touch(entity this, entity toucher)
{
	if (toucher.cp != this)
	{
		msg_entity = toucher;
		WriteHeader(MSG_ONE, TE_CSQC_ITEMPICKUP_JDW);
		WriteByte(MSG_ONE, 4);
	}
	toucher.cp = this;
}

bool checkpoint_customize(entity this, entity client)
{
    this.frame = ((client.cp == this) ? 1 : 0);
    return true;
}

spawnfunc(misc_checkpoint)
{
	precache_model("models/checkpoint.iqm");

	this.solid = SOLID_TRIGGER;
	settouch(this, checkpoint_touch);
	_setmodel(this, "models/checkpoint.iqm");
	setsize(this, '-32 -32 0', '32 32 48');
	setcefc(this, checkpoint_customize);
}

#endif
