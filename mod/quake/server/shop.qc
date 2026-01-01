#include "shop.qh"

#include "../common/shop.qh"

PRECACHE(Shopkeep)
{
	precache_model("progs/grem.mdl");
	precache_model("progs/gift08.mdl");
	precache_sound("damion/purchase.wav");
}

bool shop_buypassive(entity this, string item)
{
	int passive = Shop_Passive_Item(item);
	if(!passive)
		return false;

	if(!(shop_passives & passive))
	{
		sprint(this, "Invalid item\n");
		return true;
	}

	if(this.frags < SHOP_COST_PASSIVE)
	{
		sprint(this, "You do not have enough points to buy this item, keep fragging!\n");
		return true;
	}

	if(STAT(PASSIVES, this) & passive)
	{
		sprint(this, "You already have this item\n");
		return true;
	}

	this.frags -= SHOP_COST_PASSIVE;
	STAT(PASSIVES, this) |= passive;
	string themsg = Shop_Passive_Message(passive);
	if(themsg != "")
		centerprint(this, strcat(themsg, "\n"));
	_sound(this, CH_TRIGGER_SINGLE, "weapons/pulse/install.wav", 1, ATTN_NORM);

	return true;
}

bool shop_hasweapon(Weapon wep)
{
	return (shop_weapons.x == wep.m_id || shop_weapons.y == wep.m_id || shop_weapons.z == wep.m_id);
}

void shop_addweapon(Weapon wep)
{
	// TODO: doesn't support adding extra weapons!
	if(shop_weapons.x == 0)
		shop_weapons.x = wep.m_id;
	else if(shop_weapons.y == 0)
		shop_weapons.y = wep.m_id;
	else if(shop_weapons.z == 0)
		shop_weapons.z = wep.m_id;
}

void shop_buyitem(entity this, string item)
{
	if(!IS_PLAYER(this) || this.health <= 0)
		return;
	if(shop_opentime < time)
	{
		sprint(this, "You can only buy items after a boss wave\n");
		return;
	}

	if(item == "heal")
	{
		if(this.tank)
		{
			sprint(this, "You can't buy health while in a tank!\n");
			return;
		}
		if(this.frags < SHOP_COST_HEAL)
		{
			sprint(this, "You do not have enough points to buy this item, keep fragging!\n");
			return;
		}
		if(T_Heal(this, 100, true))
		{
			this.frags -= SHOP_COST_HEAL;
			_sound(this, CH_TRIGGER_SINGLE, "items/r_item2.wav", 1, ATTN_NORM);
			sprint(this, "Health restored\n");
		}
		else
			sprint(this, "Already at maximum health\n");
		return;
	}

	if(item == "armor")
	{
		if(this.tank)
		{
			sprint(this, "You can't buy armor while in a tank!\n");
			return;
		}
		if(this.frags < SHOP_COST_ARMOR)
		{
			sprint(this, "You do not have enough points to buy this item, keep fragging!\n");
			return;
		}
		int type = ARMOR_GREEN;
		float value = 100;

		if(this.armortype == ARMOR_GREEN)
		{
			type = ARMOR_YELLOW;
			value = 150;
		}
		else if(this.armortype == ARMOR_YELLOW || this.armortype == ARMOR_RED)
		{
			type = ARMOR_RED;
			value = 200;
		}
		else if(this.armortype == ARMOR_MAGE)
		{
			type = ARMOR_MAGE;
			value = 200;
		}
		else if(this.armortype == ARMOR_TECH)
		{
			sprint(this, "Tech armor does not need upgrading\n");
			return;
		}
		if(armor_getstrength(this.armortype) * this.armorvalue >= armor_getstrength(type) * value)
		{
			sprint(this, "Already at maximum armor\n");
			return;
		}
		this.frags -= SHOP_COST_ARMOR;
		this.armortype = type;
		this.armorvalue = value;
		_sound(this, CH_TRIGGER_SINGLE, "items/armor1.wav", 1, ATTN_NORM);
		sprint(this, "Armor upgraded\n");
		return;
	}

	if(item == "ammo")
	{
		if(this.frags < SHOP_COST_AMMO)
		{
			sprint(this, "You do not have enough points to buy this item, keep fragging!\n");
			return;
		}
		// TODO: does not verify that the player actually gained any ammo!
		this.frags -= SHOP_COST_AMMO;
		this.ammo_shells += 30; SendItemPickup(this, IT_SHELLS, 30);
		this.ammo_nails += 60; SendItemPickup(this, IT_NAILS, 60);
		this.ammo_rockets += 20; SendItemPickup(this, IT_ROCKETS, 20);
		this.ammo_cells += 30; SendItemPickup(this, IT_CELLS, 30);
		this.ammo_lava_nails += 60; SendItemPickup(this, IT_LAVA_NAILS, 60);
		this.ammo_multi_rockets += 20; SendItemPickup(this, IT_MULTI_ROCKETS, 20);
		this.ammo_plasma += 40; SendItemPickup(this, IT_PLASMA_AMMO, 40);
		this.ammo_drills += 20; SendItemPickup(this, IT_DRILLS, 20);
		bound_other_ammo(this);
		sprint(this, "Ammunition restocked\n");
		_sound(this, CH_TRIGGER_SINGLE, "weapons/lock4.wav", 1, ATTN_NORM);
		return;
	}

	if(shop_buypassive(this, item))
		return;

	Weapon wep = Weapon_from_name(item);
	if(wep == WEP_Null || (wep.spawnflags & WEP_FLAG_NOSTEAL) || !shop_hasweapon(wep) || (wep.spawnflags & WEP_FLAG_CHAMPION))
	{
		sprint(this, "Invalid weapon\n");
		return;
	}

	if(Inventory_have(wep, this, ITEM_OWNED) && (autocvar_g_weaponswitch_debug != 2 || Inventory_have(wep, this, ITEM_DUALWIELD) || (wep.spawnflags & WEP_FLAG_NODUAL) || (wep.spawnflags & WEP_FLAG_DUALWIELD)))
	{
		sprint(this, "You already have that weapon\n");
		return;
	}

	if(this.frags < SHOP_COST_WEAPON)
	{
		sprint(this, "You do not have enough points to buy this item, keep fragging!\n");
		return;
	}

	switch(wep.ammo_type)
	{
		case IT_SHELLS: this.ammo_shells += wep.aflag; break;
		case IT_NAILS: this.ammo_nails += wep.aflag; break;
		case IT_ROCKETS: this.ammo_rockets += wep.aflag; break;
		case IT_CELLS: this.ammo_cells += wep.aflag; break;
		case IT_LAVA_NAILS: this.ammo_lava_nails += wep.aflag; break;
		case IT_MULTI_ROCKETS: this.ammo_multi_rockets += wep.aflag; break;
		case IT_PLASMA_AMMO: this.ammo_plasma += wep.aflag; break;
		case IT_DRILLS: this.ammo_drills += wep.aflag; break;
	}

	Send_Notification(NOTIF_ONE, this, MSG_MULTI, ITEM_WEAPON_GOT, wep.m_name);
	_sound(this, CH_TRIGGER_SINGLE, "weapons/pkup.wav", 1, ATTN_NORM);

	bound_other_ammo(this);

	this.frags -= SHOP_COST_WEAPON;
	if(Inventory_have(wep, this, ITEM_OWNED))
		Inventory_add(wep, this, ITEM_DUALWIELD);
	else
		Inventory_add(wep, this, ITEM_OWNED);

	if(!this.cvar_cl_autoswitch)
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(wep == w_getbestweapon(this, weaponentity))
				W_SwitchWeapon(this, wep, weaponentity);
			if(autocvar_g_weaponswitch_debug != 1)
				break;
		}
	}
}

bool shopkeep_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_SHOPKEEP);

	WriteVector(MSG_ENTITY, this.origin);
	WriteByte(MSG_ENTITY, this.spawnflags);
	return true;
}

void shopkeep_spawn(entity this)
{
	if(season == SEASON_HALLOWEEN)
		this.spawnflags |= 1; // damion
	precache_sound("items/r_item2.wav");
	precache_sound("items/armor1.wav");
	precache_sound("weapons/pkup.wav");
	if(this.spawnflags & 1)
		setsize(this, '-16 -16 -1', '16 16 24');
	else
		setsize(this, VEC_HULL_MIN, VEC_HULL_MAX);
	this.solid = SOLID_NOT;
	DropToFloor_QC_DelayedInit(this);
	set_movetype(this, MOVETYPE_NONE);
	Net_LinkEntity(this, false, 0, shopkeep_send);
}

void shop_setup_weapons()
{
	// pick a random selection of weapons for the shop
	shop_weapons = '0 0 0'; // reset initially
	// NOTE: only supports 3 weapons!
	for(int j = 0; j < SHOP_WEAPON_COUNT; ++j)
	{
		RandomSelection_Init();
		FOREACH(Weapons, it != WEP_Null,
		{
			if(shop_hasweapon(it))
				continue;
			if((it.spawnflags & WEP_FLAG_NOSTEAL) || (it.spawnflags & WEP_FLAG_CHAMPION))
				continue; // exclude some weapons!
			RandomSelection_AddEnt(it, 1, 1);
		});
		shop_addweapon(RandomSelection_chosen_ent);
	}
}

void shop_setup_passive()
{
	shop_passives = 0; // reset initially

	for(int j = 0; j < SHOP_PASSIVE_COUNT; ++j)
	{
		RandomSelection_Init();
		for(int k = 0; k <= PASSIVE_LAST; ++k)
		{
			int passive = BIT(k);
			if(shop_passives & passive)
				continue;
			RandomSelection_AddFloat(passive, 1, 1);
		}
		shop_passives |= RandomSelection_chosen_float;
	}
}

// This must be called in SV_ParseClientCommand
// input entity this
// input string cmd: same as in SV_ParseClientCommand
// output bool: true if command was handled, false if not
bool sv_shop_command(entity this, string cmd, float argc)
{
	switch(cmd)
	{
		case "shop":
		{
			if(argc == 2)
				shop_buyitem(this, strtolower(argv(1)));
			else
				sprint(this, "Usage: shop itemname\nitemname may be heal to buy health, armor or ammo to buy ammunition or a weapon name (for example, nailgun)\n");
			return true;
		}
	}
	return false;
}
