#include "kiwi.qh"

#ifdef SVQC

METHOD(KiwiChamp, m_activate, void(Champions this, entity actor))
{
	_sound(actor, CH_VOICE, "kiwi/kiwi.wav", 1, ATTN_NORM);
}

METHOD(KiwiChamp, m_weaponframe, bool(Champions this, entity actor, .entity weaponentity))
{
	// no regular weapon use!
	return true;
}

METHOD(KiwiChamp, m_playerthink, void(Champions this, entity actor))
{
	if(PHYS_INPUT_BUTTON_ATCK(actor) && time > actor.kiwi_shoot_time && !actor.tank && !STAT(CANNON, actor))
	{
		actor.kiwi_shoot_time = time + 1;
		_sound(actor, CH_PLAYER_SINGLE, "kiwi/kiwi.wav", 1, ATTN_NORM);
	}
}
#endif

METHOD(KiwiChamp, m_playerjump, float(Champions this, entity actor))
{
	return 1;
}
