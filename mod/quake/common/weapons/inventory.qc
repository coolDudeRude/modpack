#include "inventory.qh"

#ifdef SVQC
void Inventory_add(entity this, entity player, int op)
{
    //LOG_DEBUGF("entity %i picked up %s", player, this.m_name);
    entity store = player;
    store.inventory.inv_items[this.m_id] |= op;
    Inventory_update(store);
}

void Inventory_remove(entity this, entity player, int op)
{
    //LOG_DEBUGF("entity %i picked up %s", player, this.m_name);
    entity store = player;
    store.inventory.inv_items[this.m_id] &= ~op;
    Inventory_update(store);
}
#endif

#ifdef GAMEQC
bool Inventory_have(entity this, entity player, int op)
{
    entity store = NULL;
#ifdef CSQC
    // TODO: per-entity on the client?
    store = g_inventory;
#elif defined(SVQC)
    store = player.inventory;
#endif

    if(!store) return false;
    return (store.inv_items[this.m_id] & op);
}
#endif
