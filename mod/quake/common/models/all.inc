// Global list of models

MODEL(ITEM_NAILS,                      	 	"maps/b_nail0.bsp");
MODEL(ITEM_NAILS_BIG,                      	"maps/b_nail1.bsp");
MODEL(ITEM_SHELLS,                      	"maps/b_shell0.bsp");
MODEL(ITEM_SHELLS_BIG,                      "maps/b_shell1.bsp");
MODEL(ITEM_ROCKETS,                      	"maps/b_rock0.bsp");
MODEL(ITEM_ROCKETS_BIG,                     "maps/b_rock1.bsp");
MODEL(ITEM_CELLS,                      		"maps/b_batt0.bsp");
MODEL(ITEM_CELLS_BIG,                     	"maps/b_batt1.bsp");

MODEL(ITEM_SILVERKEY,                     	"progs/w_s_key.mdl");
MODEL(ITEM_SILVERRUNEKEY,                   "progs/m_s_key.mdl");
MODEL(ITEM_SILVERKEYCARD,                   "progs/b_s_key.mdl");
MODEL(ITEM_GOLDKEY,                     	"progs/w_g_key.mdl");
MODEL(ITEM_GOLDRUNEKEY,                   	"progs/m_g_key.mdl");
MODEL(ITEM_GOLDKEYCARD,                   	"progs/b_g_key.mdl");

MODEL(LAVABALL,                             "progs/lavaball.mdl");

MODEL(EXPLOSION,                            "progs/s_explod.spr");

MODEL(RUNE_VORELING,                        "progs/voreling_rune.spr");
MODEL(RUNE_BONE,                            "progs/bone_rune.spr");
MODEL(RUNE_FIRE,                            "progs/fire_rune.spr");
MODEL(RUNE_ICE,                             "progs/ice_rune.spr");
MODEL(RUNE_HEALING,                         "progs/healing_rune.spr");

MODEL(CHAT,                                 "models/misc/chatbubble.spr");

// projectiles TODO
#ifdef CSQC
MODEL(PROJECTILE_ROCKET,                    "progs/missile.mdl");
MODEL(PROJECTILE_MERMAID_BUBBLE,            "progs/s_bubble.spr");
MODEL(PROJECTILE_MAGIC_FIREBALL,            "progs/lavaball.mdl");
MODEL(PROJECTILE_CROSSBOW_BOLT,             "progs/proj_impalespike.mdl");
MODEL(PROJECTILE_VORE_SPIKE,                "progs/v_spike.mdl");
MODEL(PROJECTILE_SCRAG_SPIKE,               "progs/w_spike.mdl");
MODEL(PROJECTILE_KNIGHT_SPIKE,              "progs/k_spike.mdl");
MODEL(PROJECTILE_SPELLBOOK_METEOR,          "progs/lavaball.mdl");
MODEL(PROJECTILE_CAT,                       "progs/proj_cat.mdl");
MODEL(PROJECTILE_BANJO_MUSIC,               "progs/piano_musicnote_white.mdl");
MODEL(PROJECTILE_BULLET,                    "progs/spike.mdl");
MODEL(PROJECTILE_SAWBLADE,                  "progs/blade.mdl");
MODEL(PROJECTILE_SUPER_SPIKE,               "progs/s_spike.mdl");
MODEL(PROJECTILE_LAVA_NAIL,                 "progs/lspike.mdl");
MODEL(PROJECTILE_BIOGUN_BONESHARD,          "progs/bone_shard.mdl");
MODEL(PROJECTILE_GRENADE,                   "progs/grenade.mdl");
MODEL(PROJECTILE_MAYO,                      "progs/grenade_mayo.mdl");
MODEL(PROJECTILE_OCARINA,                   "progs/piano_musicnote_white.mdl");
MODEL(PROJECTILE_SHOCKGUN_PLASMA,           "progs/pbullet.mdl");
MODEL(PROJECTILE_HIP_LASER,                 "progs/lasrspik.mdl");
MODEL(PROJECTILE_PIANO_MUSIC,               "progs/piano_musicnote_white.mdl");
MODEL(PROJECTILE_LASER,                     "progs/laser.mdl");
MODEL(PROJECTILE_JIM_LASER,                 "progs/proj_laz.mdl");
MODEL(PROJECTILE_JIM_ROCKET,                "progs/proj_rocket.mdl");
MODEL(PROJECTILE_SNOWBALL,                  "progs/snowball.mdl");
MODEL(PROJECTILE_GOLDY,                     "progs/goldy_bag.mdl");
MODEL(PROJECTILE_CRUMB,                     "progs/crumb.mdl");
MODEL(PROJECTILE_SKAARJ_BULLET,             "progs/big_bullet.mdl");
MODEL(PROJECTILE_GUG_BILEBOMB,              "progs/bilebomb.mdl");
MODEL(PROJECTILE_GUG_BILEFRAG,              "progs/bilefrag.mdl");
MODEL(PROJECTILE_DROLE,                     "progs/proj_drole.mdl");
MODEL(PROJECTILE_DROLE_POISON,              "progs/proj_drolegrn.mdl");
MODEL(PROJECTILE_MULTI_ROCKET,              "progs/rockup_d.mdl");
MODEL(PROJECTILE_LAVABALL,                  "progs/lavaball.mdl");
MODEL(PROJECTILE_EE_P_SPHERE,               ((fexists("progs/ee_p_sphere.mdl") ? "progs/ee_p_sphere.mdl" : "progs/lavaball.mdl")));
MODEL(PROJECTILE_BLAZE_FIREBALL,            "progs/lavaball.mdl");
MODEL(PROJECTILE_LAVAMAN_FIREBALL,          "progs/lavaball.mdl");
MODEL(PROJECTILE_PASSIVE_FIREBALL,          "progs/lavaball.mdl");
MODEL(PROJECTILE_PASSIVE_PULSERIFLE,        "progs/pulse.mdl");
MODEL(PROJECTILE_TANK_BIGROCKET,            "progs/brocket.mdl");
MODEL(PROJECTILE_GHOST_SICKLE,              "progs/ghost_sickle.mdl");
MODEL(PROJECTILE_CACODEMON_FIREBALL,        "progs/cacodemon_fireball.mdl");
MODEL(PROJECTILE_MISSILE,                   "progs/proj_missile.mdl");
MODEL(PROJECTILE_MANCUBUS_BOLT,             "progs/proj_mancubus.mdl");
MODEL(PROJECTILE_BULLETKIN_SHOT,            "progs/proj_bulletkin.mdl");
MODEL(PROJECTILE_HELLKNIGHT_BIGSHOT,        "progs/k_spike2.mdl");
MODEL(PROJECTILE_HELLKNIGHT_SPINNER,        "progs/k_spike_cold.mdl");
MODEL(PROJECTILE_STAR_SMALL,                "progs/kirby_star.mdl");
MODEL(PROJECTILE_STAR_MEDIUM,               "progs/kirby_star.mdl");
MODEL(PROJECTILE_STAR_LARGE,                "progs/kirby_star.mdl");
MODEL(PROJECTILE_STAR_MEGA,                 "progs/kirby_star.mdl");
MODEL(PROJECTILE_SPARK_UPZAP,               "progs/pbullet.mdl");
MODEL(PROJECTILE_SEED,                      "progs/plantera_seed.mdl");
MODEL(PROJECTILE_SEED_POISON,               "progs/plantera_seed.mdl");
MODEL(PROJECTILE_THORNBALL,                 "progs/plantera_thornball.mdl");

PRECACHE(PROJECTILE_LETTERS)
{
	precache_model("progs/s_sns_a.spr");
	precache_model("progs/s_sns_b.spr");
	precache_model("progs/s_sns_c.spr");
	precache_model("progs/s_sns_d.spr");
	precache_model("progs/s_sns_e.spr");
	precache_model("progs/s_sns_f.spr");
	precache_model("progs/s_sns_g.spr");
	precache_model("progs/s_sns_h.spr");
	precache_model("progs/s_sns_i.spr");
	precache_model("progs/s_sns_j.spr");
	precache_model("progs/s_sns_k.spr");
	precache_model("progs/s_sns_l.spr");
	precache_model("progs/s_sns_m.spr");
	precache_model("progs/s_sns_n.spr");
	precache_model("progs/s_sns_o.spr");
	precache_model("progs/s_sns_p.spr");
	precache_model("progs/s_sns_q.spr");
	precache_model("progs/s_sns_r.spr");
	precache_model("progs/s_sns_s.spr");
	precache_model("progs/s_sns_t.spr");
	precache_model("progs/s_sns_u.spr");
	precache_model("progs/s_sns_v.spr");
	precache_model("progs/s_sns_w.spr");
	precache_model("progs/s_sns_x.spr");
	precache_model("progs/s_sns_y.spr");
	precache_model("progs/s_sns_z.spr");
}
#endif
