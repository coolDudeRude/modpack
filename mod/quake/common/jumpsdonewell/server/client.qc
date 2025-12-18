#include "client.qh"

#include "combat.qh"

PRECACHE(JumpsDoneWell)
{
	if(!IsJumpsDoneWell())
		return;

	precache_model("models/player.iqm");
	precache_model("models/sword_equip.iqm");

	precache_sound("sword1.wav");
	precache_sound("sword2.wav");
	precache_sound("sword_pickup.wav");
	precache_sound("ding.wav");
	precache_sound("hurt.wav");
	precache_sound("jump.wav");
}

bool sword_customize(entity this, entity client)
{
	return (STAT(SWORDPOWER, this.owner) > 0);
}

vector get_spawn_point()
{
	RandomSelection_Init();
	IL_EACH(g_spawnpoints, true,
	{
		RandomSelection_AddEnt(it, 1, 1);
	});
	entity spawnpoint = RandomSelection_chosen_ent;

	return spawnpoint.origin + '0 0 1';
}

void revive(entity this)
{
	if(!this.cp)
		setorigin(this, get_spawn_point());
	else
		setorigin(this, this.cp.origin);
	this.health = this.max_health;
	this.solid = SOLID_SLIDEBOX;
	this.takedamage = DAMAGE_YES;
	this.invuln_time = time + 1;
	this.frame = 0;
	set_movetype(this, MOVETYPE_WALK);

	msg_entity = this;
	WriteHeader(MSG_ONE, TE_CSQC_REVIVE);
}

void JDW_PutObserverInServer(entity this)
{
	if(this.sword)
		delete(this.sword);
	this.sword = NULL;
}

void JDW_PutPlayerInServer(entity this)
{
	this.solid = SOLID_SLIDEBOX;
	_setmodel(this, "models/player.iqm");
	setsize(this, '-16 -16 0', '16 16 64');
	set_movetype(this, MOVETYPE_WALK);
	this.health = 3;
	this.max_health = this.health;
	setorigin(this, get_spawn_point());
	this.fixangle = true;
	this.view_ofs = '0 0 48';
	this.takedamage = DAMAGE_YES;
	this.th_pain = player_hurt;
	STAT(FEATHER, this) = 1;
	settouch(this, JDW_PlayerTouch);
	this.invuln_time = time + 2;

	if(!this.sword)
		this.sword = new(sword);
	this.sword.owner = this;
	_setmodel(this.sword, "models/sword_equip.iqm");
	setattachment(this.sword, this, "hand.R");
	setcefc(this.sword, sword_customize);
	this.sword.effects = EF_LOWPRECISION;

	this.dphitcontentsmask = DPCONTENTS_BODY | DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP;
	
	if(getworldbasename() == "map2")
		STAT(SWORDPOWER, this) = 0;
	else
	{
		STAT(SWORDPOWER, this) = 2;
		STAT(FEATHER, this) = 2;
	}
}



/*
================
PlayerPreThink

Called every frame before physics are run
================
*/

.string netname_previous;
void JDW_PlayerPreThink(entity this)
{
	if(this.health <= 0)
	{
		this.frame = 6;
		if(time > this.respawn_time)
			revive(this);
		return;
	}

	player_weapons(this);

	if(IS_ONGROUND(this) && time - STAT(JUMP_PRESSED_TIME, this) > 0.1 && this.health > 0)
	{
		if(this.pain_time + 0.3 > time)
			this.frame = 5;
		else if(time > STAT(ATTACK_FINISHED, this))
		{
			if(vdist(this.velocity, >, 1))
				this.frame = 1;
			else
				this.frame = 0;
		}
	}
}


/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void JDW_ClientDisconnect(entity this)
{
	IL_EACH(g_moveables, it.collected,
	{
		if(IL_CONTAINS(it.collected, this))
			IL_REMOVE(it.collected, this);
	});

	if(this.sword)
		delete(this.sword);
	this.sword = NULL;
}
