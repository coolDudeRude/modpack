#include "berserk.qh"

#ifdef SVQC
METHOD(Berserk, m_remove, void(StatusEffects this, entity actor, int removal_type))
{
    bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
    if(wasactive)
        stopsound(actor, CH_TRIGGER_SINGLE); // get rid of the pickup sound
    // NOTE: we must call m_remove FIRST to ensure the player doesn't have the powerup anymore!
    SUPER(Berserk).m_remove(this, actor, removal_type);

    actor.berserk_warning = false;
    if(IS_PLAYER(actor))
    {
        Inventory_remove(WEP_BERSERKER_FISTS, actor, ITEM_OWNED);
        .entity weaponentity = weaponentities[0]; // WEAPONTODO
        if(wasactive && actor.(weaponentity).m_weapon == WEP_BERSERKER_FISTS)
        {
            W_LastWeapon(actor, weaponentity);
        }
    }
}
METHOD(Berserk, m_apply, void(StatusEffects this, entity actor, float eff_time, float eff_flags))
{
    if(IS_PLAYER(actor))
    {
        Inventory_add(WEP_BERSERKER_FISTS, actor, ITEM_OWNED); // TODO: "temporary" ownership flag?
        .entity weaponentity = weaponentities[0]; // WEAPONTODO
        W_SwitchWeapon(actor, WEP_BERSERKER_FISTS, weaponentity);
    }
    SUPER(Berserk).m_apply(this, actor, eff_time, eff_flags);
}
METHOD(Berserk, m_tick, void(StatusEffects this, entity actor))
{
    float curtime = StatusEffects_gettime(this, actor);
    if(curtime < time + 3 && !actor.berserk_warning && IS_REAL_CLIENT(actor))
    {
        if(gametype != GAMETYPE_HORDE)
            Send_Notification(NOTIF_ONE, actor, MSG_MULTI, POWERDOWN_BERSERK);
        _sound(actor, CH_TRIGGER_SINGLE, "items/berserk_fade.wav", 1, ATTN_NORM);
        actor.berserk_warning = true;
    }
    SUPER(Berserk).m_tick(this, actor);
}
#endif

#ifdef CSQC
METHOD(Berserk, m_tick, void(StatusEffects this, entity actor))
{
    drawfill('0 0 0', vec2(vid_conwidth, vid_conheight), '1 0 0', 0.025, DRAWFLAG_NORMAL);
    SUPER(Berserk).m_tick(this, actor);
}
#endif
