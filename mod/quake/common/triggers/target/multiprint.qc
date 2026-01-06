#include "multiprint.qh"

#ifdef SVQC
void target_multiprint_use(entity this, entity actor, entity trigger)
{
	//dprint("in multiprint_use\n");
	// print the message
	//if (actor.classname == "player")
	//{
		if(this.message && this.message != "")
		{
			// just make sure it goes to all if actor is a weirdo, players do
			// silly things on purpose with monsters shooting buttons
			//centerprint (actor, this.message);
			if(IS_PLAYER(actor) && IS_REAL_CLIENT(actor))
			{
				centerprint_proximity(actor, process_string(this.message), this);
				_sound(actor, CH_INFO, QUAKE_TALKSOUND, 1, ATTN_NORM);

				if(actor.m_champion && actor.m_champion.m_triggermessage)
					actor.m_champion.m_triggermessage(actor.m_champion, actor, this);
			}
			
			if(!(this.spawnflags & 1))
				_sound(actor, CHAN_VOICE, QUAKE_TALKSOUND, 1, ATTN_NORM);
			
			this.message = this.noise;
			this.noise = this.noise1;
			this.noise1 = this.noise2;
			this.noise2 = this.noise3;
			this.noise3 = this.noise4;
			this.noise4 = string_null;
		}
		else
		{
			SUB_UseTargets(this, actor, trigger);
		}
	//}
}

/*QUAKED target_multiprint (.5 .5 .5) (-8 -8 -8) (8 8 8) SILENT
This entity will print a different string every time it's triggered.  Prints "message", 
"noise", "noise1", "noise2", "noise3", then "noise4."  Once all strings are used up, it will 
fire its targets instead (so several of these can be chained if you really need that 
many prints in a row).

SILENT: Don't play the beep wav when triggered.
*/
/*FGD
@PointClass color(128 128 128) size(16 16 16) base(Appearflags, Targetname, Target) = target_multiprint : 
"Target : Multiprint
This entity will print a different string every time it's triggered.  Prints 'message', 'noise', 'noise1', 'noise2', 'noise3', then 'noise4.'  Once all strings are used up, it will fire its targets instead (so several of these can be chained if you really need that 
many prints in a row)."
[
	spawnflags(flags) = [
		1 : "Silent" : 0
	]
	message(string) : "First print"
	noise(string) : "Second print"
	noise1(string) : "Third print"
	noise2(string) : "Fourth print"
	noise3(string) : "Fifth print"
	noise4(string) : "Sixth print"
]
*/
spawnfunc(target_multiprint)
{
	this.use = target_multiprint_use;
}
#endif
