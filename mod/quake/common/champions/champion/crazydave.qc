#include "crazydave.qh"

#ifdef SVQC
void CrazyDave_Aggro(entity this)
{
	FOREACH_ENTITY_RADIUS(this.origin, autocvar_sv_quake_crazydave_range, true,
	{
		if(IS_MONSTER(it) && it.health > 0 && it.enemy && !it.charmed && !(it.effects & EF_NODRAW) && !it.is_frozen && !it.elec && it.enemy != this && !wasfreed(it.enemy))
		{
			//if(gametype == GAMETYPE_TD)
				//continue;
			//if(it.monsterdef.spawnflags & MONSTER_TYPE_BOSS)
				//continue;
			// low chance to aggro monsters each frame
			if(random() > 0.25)
				continue;
			if(!checkpvs(this.origin, it))
				continue;
			it.aggro_time = time;
			if(IS_PLAYER(it.enemy))
				it.oldenemy = it.enemy;
			it.enemy = this;
			FoundTarget(it);
		}
	});
}

METHOD(CrazyDave, m_playerthink, void(Champions this, entity actor))
{
	if(PHYS_INPUT_BUTTON_CROUCH(actor) && QCC_CanCastAbility(actor))
	{
		player_sound(actor, CH_PLAYER_SINGLE, "awooga.wav", ATTN_NORM);
		CrazyDave_Aggro(actor);
		STAT(QCC_ABILITYTIME, actor) = time + 5;
		actor.crazydave_crazy_time = time + 10 + (random() * 15);
	}

	if(time > actor.crazydave_crazy_time)
	{
		actor.crazydave_crazy_time = time + 10 + (random() * 15);
		float rsound = bound(1, rint(random() * 12), 13);
		string s = strcat("talk", ftos(rsound), ".wav");
		player_sound(actor, CH_VOICE, s, ATTN_NORM);
	}
}

METHOD(CrazyDave, m_takedamage, float(Champions this, entity targ, entity inflictor, entity attacker, float damage, int deathtype))
{
	if(targ.m_champion == this)
	{
		if(deathmatch)
			return 0.75;
		return 0.5;
	}
	return 1;
}

METHOD(CrazyDave, m_activate, void(Champions this, entity actor))
{
	int r = bound(1, rint(random() * 7), 7);
	player_sound(actor, CH_VOICE, strcat("start", itos(r), ".wav"), ATTN_NORM);
	actor.crazydave_crazy_time = time + 10 + (random() * 15);
}

METHOD(CrazyDave, m_cannon_launch, void(Champions this, entity actor, entity cannon))
{
	player_sound(actor, CH_TRIGGER_SINGLE, "cannon_launch.wav", ATTN_NORM);
	actor.crazydave_cannon = true;
	actor.crazydave_crazy_time = time + 10 + (random() * 15);
}

METHOD(CrazyDave, m_cannon_land, bool(Champions this, entity actor))
{
	if(!actor.crazydave_cannon)
		return false;
	player_sound(actor, CH_TRIGGER_SINGLE, "cannon_land.wav", ATTN_NORM);
	actor.crazydave_cannon = false;
	actor.crazydave_crazy_time = time + 10 + (random() * 15);
	return false;
}
#endif
