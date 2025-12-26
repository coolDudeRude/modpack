#include "floyd.qh"

#ifdef SVQC

void FLaunchLaser(entity this, vector org, vector vec);
void floydchamp_fire(entity this, float muzzle)
{
	this.effects |= EF_MUZZLEFLASH;
	makevectors(this.v_angle);
	
	vector org = this.origin + v_forward * 30 + '0 0 28' + v_right * muzzle;
	vector dir = v_forward;

	_sound(this, CH_WEAPON_SINGLE, "floyd/fire.wav", 1, ATTN_NORM);
	FLaunchLaser(this, org, dir);
}

void floydchamp_attack9(entity this) { set_animofs(this, anim_floyd_attack1, 9, player_run); }
void floydchamp_attack8(entity this) { set_animofs(this, anim_floyd_attack1, 8, floydchamp_attack9); }
void floydchamp_attack7(entity this) { set_animofs(this, anim_floyd_attack1, 7, floydchamp_attack8); floydchamp_fire(this, -6); }
void floydchamp_attack6(entity this) { set_animofs(this, anim_floyd_attack1, 6, floydchamp_attack7); }
void floydchamp_attack5(entity this) { set_animofs(this, anim_floyd_attack1, 5, floydchamp_attack6); }
void floydchamp_attack4(entity this) { set_animofs(this, anim_floyd_attack1, 4, floydchamp_attack5); floydchamp_fire(this, 0); }
void floydchamp_attack3(entity this) { set_animofs(this, anim_floyd_attack1, 3, floydchamp_attack4); }
void floydchamp_attack2(entity this) { set_animofs(this, anim_floyd_attack1, 2, floydchamp_attack3); }
void floydchamp_attack1(entity this) { set_animofs(this, anim_floyd_attack1, 1, floydchamp_attack2); floydchamp_fire(this, 6); }

METHOD(FloydChamp, m_activate, void(Champions this, entity actor))
{
	_sound(actor, CH_VOICE, "floyd/sight.wav", 1, ATTN_NORM);
}

METHOD(FloydChamp, m_weaponframe, bool(Champions this, entity actor, .entity weaponentity))
{
	// no regular weapon use!
	return true;
}

METHOD(FloydChamp, m_playerthink, void(Champions this, entity actor))
{
	if(PHYS_INPUT_BUTTON_ATCK(actor) && IS_ONGROUND(actor) && time > actor.floyd_shoot_time && !actor.tank && !STAT(CANNON, actor))
	{
		actor.floyd_shoot_time = time + 1.5;
		floydchamp_attack1(actor);
	}
}

METHOD(FloydChamp, m_cannon_launch, void(Champions this, entity actor, entity cannon))
{
	_sound(actor, CH_TRIGGER_SINGLE, "hammer/hammer_clang2_floyd.wav", 1, ATTN_NORM);
	actor.floyd_cannon = true;
}

METHOD(FloydChamp, m_cannon_land, bool(Champions this, entity actor))
{
	if(!actor.floyd_cannon)
		return false;
	_sound(actor, CH_TRIGGER_SINGLE, "hammer/charge_full_floyd.wav", 1, ATTN_NORM);
	actor.floyd_cannon = false;
	return false;
}
#endif

METHOD(FloydChamp, m_playerjump, float(Champions this, entity actor))
{
	return 0.5;
}
