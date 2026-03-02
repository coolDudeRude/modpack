#include "challenges.qh"

int Challenge_fromstring(string chalstr)
{
	switch(chalstr)
	{
		case "onehp": return CHALLENGE_ONEHP;
		case "bonk": return CHALLENGE_BONK;
	}

	return CHALLENGE_NONE;
}

bool Challenge_Active(int ctype)
{
#ifdef SVQC
	return !!(challenge & ctype);
#else
	return !!(STAT(CHALLENGE) & ctype);
#endif
}

#ifdef SVQC
STATIC_INIT(Challenges)
{
	challenge = CHALLENGE_NONE;

	if(deathmatch || gametype != GAMETYPE_NONE)
		return;

	FOREACH_WORD(autocvar_sv_quake_challenge, true,
	{
		challenge |= Challenge_fromstring(it);
	});
}
#endif
