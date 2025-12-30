#include "shop.qh"

#ifdef SVQC
string Shop_Passive_Message(int itemid)
{
	switch(itemid)
	{
		case PASSIVE_PULSERIFLE: return "Pulse Rifle Sidearm activated";
		case PASSIVE_FIREBALL: return "Fireball Launcher activated";
		case PASSIVE_AMMOPOUCH: return "Ammo capacity increased";
		case PASSIVE_ADRENALIN: return "Fire rate increased";
		case PASSIVE_BOOMER: return "Slain foes will explode";
		case PASSIVE_LOOTER: return "Bonus loot drops more often";
		case PASSIVE_AURA: return "Your aura damages nearby enemies";
		case PASSIVE_ELECTRIFYING: return "Slain foes will let out a shockwave";
		case PASSIVE_BUNNYBOOTS: return "Bunny Boots let you auto jump";
		case PASSIVE_ARCANA: return "Spell efficiency increased";
		case PASSIVE_SPONGE: return "Damaged taken capped at 50";
		case PASSIVE_HERMESBOOTS: return "Movement speed increased";
	}
	return "";
}

int Shop_Passive_Item(string item)
{
	switch(item)
	{
		case "rifle": return PASSIVE_PULSERIFLE;
		case "fireball": return PASSIVE_FIREBALL;
		case "ammopouch": return PASSIVE_AMMOPOUCH;
		case "adrenalin": return PASSIVE_ADRENALIN;
		case "boomer": return PASSIVE_BOOMER;
		case "looter": return PASSIVE_LOOTER;
		case "aura": return PASSIVE_AURA;
		case "electrifying": return PASSIVE_ELECTRIFYING;
		case "bunnyboots": return PASSIVE_BUNNYBOOTS;
		case "arcana": return PASSIVE_ARCANA;
		case "sponge": return PASSIVE_SPONGE;
		case "hermesboots": return PASSIVE_HERMESBOOTS;
	}
	return 0;
}
#endif

#ifdef CSQC
string Shop_Passive_PrettyName(int itemid)
{
	switch(itemid)
	{
		case PASSIVE_PULSERIFLE: return "Pulse Rifle Sidearm";
		case PASSIVE_FIREBALL: return "Fireball Launcher";
		case PASSIVE_AMMOPOUCH: return "Ammo Pouch";
		case PASSIVE_ADRENALIN: return "Adrenalin";
		case PASSIVE_BOOMER: return "Boomer";
		case PASSIVE_LOOTER: return "Looter";
		case PASSIVE_AURA: return "Aura of Pain";
		case PASSIVE_ELECTRIFYING: return "Electrifying";
		case PASSIVE_BUNNYBOOTS: return "Bunny Boots";
		case PASSIVE_ARCANA: return "Arcane efficiency";
		case PASSIVE_SPONGE: return "Damage Sponge";
		case PASSIVE_HERMESBOOTS: return "Hermes Boots";
	}
	return "";
}

string Shop_Passive_Description(int itemid)
{
	switch(itemid)
	{
		case PASSIVE_PULSERIFLE: return "Fire automatic lasers at enemies";
		case PASSIVE_FIREBALL: return "Shoot automatic fireballs at enemies";
		case PASSIVE_AMMOPOUCH: return "Double ammo capacity";
		case PASSIVE_ADRENALIN: return "20% quicker shooting speed";
		case PASSIVE_BOOMER: return "Enemies explode when killed";
		case PASSIVE_LOOTER: return "Enemies drop 20% more loot";
		case PASSIVE_AURA: return "Deal constant damage around you";
		case PASSIVE_ELECTRIFYING: return "Enemies zap others when killed";
		case PASSIVE_BUNNYBOOTS: return "Automatic jumps";
		case PASSIVE_ARCANA: return "Double mana capacity";
		case PASSIVE_SPONGE: return "Incoming damage capped at 50";
		case PASSIVE_HERMESBOOTS: return "50% quicker movement speed";
	}
	return "";
}

string Shop_Passive_Name(int itemid)
{
	switch(itemid)
	{
		case PASSIVE_PULSERIFLE: return "rifle";
		case PASSIVE_FIREBALL: return "fireball";
		case PASSIVE_AMMOPOUCH: return "ammopouch";
		case PASSIVE_ADRENALIN: return "adrenalin";
		case PASSIVE_BOOMER: return "boomer";
		case PASSIVE_LOOTER: return "looter";
		case PASSIVE_AURA: return "aura";
		case PASSIVE_ELECTRIFYING: return "electrifying";
		case PASSIVE_BUNNYBOOTS: return "bunnyboots";
		case PASSIVE_ARCANA: return "arcana";
		case PASSIVE_SPONGE: return "sponge";
		case PASSIVE_HERMESBOOTS: return "hermesboots";
	}
	return "";
}
#endif
