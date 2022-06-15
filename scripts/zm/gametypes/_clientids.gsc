#using scripts\codescripts\struct;

#using scripts\shared\callbacks_shared;
#using scripts\shared\array_shared;
#using scripts\shared\system_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\hud_util_shared;
#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_bgb;
#using scripts\zm\_zm_bgb_machine;
#using scripts\zm\_zm_magicbox;
#using scripts\zm\_zm_perks;
#using scripts\zm\_zm_powerups;
#using scripts\zm\_zm_powerup_fire_sale;
#using scripts\zm\_zm_powerup_nuke;
#using scripts\zm\_zm_laststand;
#using scripts\zm\_zm_score;
#using scripts\zm\_zm_spawner;
#using scripts\zm\_zm_lightning_chain;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weapons;

#insert scripts\shared\shared.gsh;

#namespace clientids;

#define N_NUKE_SPAWN_DELAY 3

#precache( "material", "modifier_ammo_recall" );
#precache( "material", "modifier_bad_news_bear" );
#precache( "material", "modifier_bargainer" );
#precache( "material", "modifier_blackened" );
#precache( "material", "modifier_box_suppression" );
#precache( "material", "modifier_connoisseur" );
#precache( "material", "modifier_dropzone" );
#precache( "material", "modifier_dud" );
#precache( "material", "modifier_fined" );
#precache( "material", "modifier_gum_shortage" );
#precache( "material", "modifier_halfway_there" );
#precache( "material", "modifier_heavy" );
#precache( "material", "modifier_hunter" );
#precache( "material", "modifier_immortal" );
#precache( "material", "modifier_joker" );
#precache( "material", "modifier_juggernaughts" );
#precache( "material", "modifier_lightfoot" );
#precache( "material", "modifier_low_charge" );
#precache( "material", "modifier_lucky" );
#precache( "material", "modifier_out_of_order" );
#precache( "material", "modifier_perkalicious_gift" );
#precache( "material", "modifier_probation" );
#precache( "material", "modifier_raining_bullets" );
#precache( "material", "modifier_rebate" );
#precache( "material", "modifier_sky_high" );
#precache( "material", "modifier_slaughterhouse" );
#precache( "material", "modifier_sober" );
#precache( "material", "modifier_supercharged_grenades" );
#precache( "material", "modifier_thirsty" );
#precache( "material", "modifier_threes_a_party" );
#precache( "material", "modifier_unworthy" );
#precache( "material", "modifier_weapon_locked" );

REGISTER_SYSTEM("clientids", &__init__, undefined)
	
function __init__()
{
	callback::on_start_gametype(&init);
	callback::on_connect(&on_player_connect);
	callback::on_spawned(&on_player_spawned);
}	

function init()
{
	level.clientid = 0;

	level.modifiers_init = false;

	// Enabled by default
	level.modifier_pap_enable = true;
	level.modifiers_perks_purchasable = true;

	// Disabled by default
	level.modifiers_aat_grenades = false;
	level.modifiers_dropzone_round = false;
	level.modifiers_force_bear = false;
	level.modifiers_good_box_luck = false;
	level.modifiers_no_ww_in_box = false;
	level.modifiers_joker_active = false;
	level.modifiers_high_drop = false;
	level.modifiers_drop_noinstakill = false;
	level.disable_firesale_drop = false;

	// Callbacks and overrides
	level._zombiemode_chest_joker_chance_override_func = &modifier_joker_chance_override;
	level.modifiercustomrandomweaponweights = &modifier_random_weapon_weights;

	zm_spawner::register_zombie_damage_callback(&modifier_damage_response);

	level thread init_challenge_modifiers();
}

function on_player_connect()
{
	self.clientid = matchRecordNewPlayer(self);

	if (!IsDefined(self.clientid) || self.clientid == -1)
	{
		self.clientid = level.clientid;
		level.clientid++;
	}
}

function on_player_spawned()
{
	level flag::wait_till("initial_blackscreen_passed");

	//if (!level.modifiers_init && self.clientid == 0)
	//{
	//	level thread init_challenge_modifiers();
	//}
	
	self thread run_modifier_ui();
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Setup
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function init_challenge_modifiers()
{
	level endon("end_game");

	level.good_modifiers = [];
	level.bad_modifiers = [];
	level.modifier_title = "Normal";
	level.modifier_desc = "No modifier active.";

	add_modifier_good("Dropzone", "Powerup spawn rate and max\namount increased!", &persistent_dropzone, "modifier_dropzone");
	add_modifier_good("Perkalicious Gift", "Free perk given to all players!", &free_perk, "modifier_perkalicious_gift");
	add_modifier_good("Halfway There", "Amount of zombies this round is\nhalved!", &halve_zombie_round_total, "modifier_halfway_there");
	add_modifier_good("Bargainer", "Fire sale all round!", &persistent_firesale, "modifier_bargainer");
	add_modifier_good("Slaughterhouse", "Instakill all round!", &persistent_instakill, "modifier_slaughterhouse");
	add_modifier_good("Three's a Party", "Triple points all round!", &persistent_triplepoints, "modifier_threes_a_party");
	add_modifier_good("Supercharged Grenades", "Grenades apply deadwire!", &set_aat_grenades, "modifier_supercharged_grenades");
	add_modifier_good("Lightfoot", "Increased movement and jump\nheight this round!", &persistent_superspeed, "modifier_lightfoot");
	add_modifier_good("Connoisseur", "All players have all perks this\nround!", &one_round_perkaholic, "modifier_connoisseur");
	add_modifier_good("Immortal", "All players are invincible this\nround!", &persistent_godmode, "modifier_immortal");
	add_modifier_good("Thirsty", "Perk limit disabled this round!", &disable_perk_limit, "modifier_thirsty");
	add_modifier_good("Raining Bullets", "Infinite ammo all round!", &persistent_infammo, "modifier_raining_bullets");
	add_modifier_good("Blackened", "Nukes detonates and endsthe\nround!", &persistent_nukes, "modifier_blackened");
	add_modifier_good("Rebate", "Everyone gets points back for their\nnext 3 purchases!", &persistent_rebate, "modifier_rebate");
	add_modifier_good("Lucky", "Box luck is vastly improved this\nround!", &persistent_box_luck, "modifier_lucky");
	add_modifier_good("Hunter", "Traps are free all round!", &free_traps, "modifier_hunter");

	add_modifier_bad("Juggernaughts", "Zombie health doubled this round.", &juggernaught_zombies, "modifier_juggernaughts");
	add_modifier_bad("Sky High", "Powerups will spawn out of reach\nthis round.", &persistent_highdrops, "modifier_sky_high");
	add_modifier_bad("Sober", "All perks except juggernog and\nmule kick disabled this round.", &disable_most_perks, "modifier_sober");
	add_modifier_bad("Dud", "No grenades this round.", &disable_nades, "modifier_dud");
	add_modifier_bad("Low Charge", "No double Pack-a-Punch effects\nwork this round.", &disable_aats, "modifier_low_charge");
	add_modifier_bad("Weapon Locked", "Players are locked to the weapon\nthey're holding.", &lock_to_current_weapon, "modifier_weapon_locked");
	add_modifier_bad("Bad News Bear", "Box hits give teddy bears this\nround.", &persistent_bear, "modifier_bad_news_bear");
	add_modifier_bad("Gum Shortage", "Gobblegum machines will give\nno gums this round.", &disable_bgb, "modifier_gum_shortage");
	add_modifier_bad("Probation", "Perks cannot be purchased this\nround.", &disable_perk_purchase, "modifier_probation");
	add_modifier_bad("Heavy", "Run speed is slowed and jumping\nis disabled this round.", &make_players_heavy, "modifier_heavy");
	add_modifier_bad("Fined", "Half your points have been\ndeducted.", &deduct_half_points, "modifier_fined");
	add_modifier_bad("Out of Order", "Pack-a-Punch machine disabled this\nround.", &disable_pap, "modifier_out_of_order");
	add_modifier_bad("Unworthy", "No points will be awarded this\nround.", &persistent_nopoints, "modifier_unworthy");
	add_modifier_bad("Ammo Recall", "Players lose ammo from one random\nweapon this round.", &persistent_random_noammo, "modifier_ammo_recall");
	add_modifier_bad("Joker", "50% chance powerups are inverted.\nNukes could hit players, max ammo\ncould take ammo, etc.", &invert_powerups, "modifier_joker");
	add_modifier_bad("Box Suppression", "Wonder weapons removed from the\nbox this round.", &persistent_no_ww, "modifier_box_suppression");

	for (i = 0; ; i++)
	{
		level waittill("start_of_round");

		players = GetPlayers();
		good_or_bad = RandomInt(100);

		// First three rounds are "gifted" with a good modifier, guarenteed
		if (i < 3)
			good_or_bad = 10;

		if (good_or_bad < 50)
		{
			keys = GetArrayKeys(level.good_modifiers);
			random_key_index = RandomInt(keys.size);
			random_key = keys[random_key_index];

			round_modifier = level.good_modifiers[random_key];

			level.modifier_title = random_key;
			level.modifier_desc = round_modifier.description;
			level thread [[round_modifier.handler]]();

			for (p = 0; p < players.size; p++)
			{
				players[p] flash_modifier_notice(random_key, round_modifier.material);
			}
		}
		else
		{
			keys = GetArrayKeys(level.bad_modifiers);
			random_key_index = RandomInt(keys.size);
			random_key = keys[random_key_index];

			round_modifier = level.bad_modifiers[random_key];

			level.modifier_title = random_key;
			level.modifier_desc = round_modifier.description;
			level thread [[round_modifier.handler]]();

			for (p = 0; p < players.size; p++)
			{
				players[p] flash_modifier_notice(random_key, round_modifier.material);
			}
		}
	}
}

function run_modifier_ui()
{
	self.modifiers_ui_info_title_bg = self createRectangle("RIGHT", "RIGHT", 0, -240, 130, 60, (0, 0, 0), "white", 1, .7);
	self.modifiers_ui_info_desc_bg = self createRectangle("RIGHT", "RIGHT", 0, -200, 130, 75, (0.05, 0.05, 0.05), "white", 1, .7);
	self.modifiers_ui_info_title_txt = self createText("default", 1.5, 2, level.modifier_txt, "LEFT", "RIGHT", -120, -225, (1, 1, 1), 1);
	self.modifiers_ui_info_desc_txt = self createText("default", 1, 2, level.modifier_desc_txt, "LEFT", "RIGHT", -120, -200, (1, 1, 1), 1);
	self.modifiers_ui_notice_img = self createRectangle("CENTER", "CENTER", 0, -150, 100, 100, (1, 1, 1), "modifier_supercharged_grenades", 1, 0);
	self.modifiers_ui_notice_txt = self createText("default", 1.5, 2, level.modifier_title, "CENTER", "CENTER", 0, -90, (1, 1, 1), 0);

	for (;;)
	{
		self.modifiers_ui_info_title_txt setText(level.modifier_title);
		self.modifiers_ui_info_desc_txt setText(level.modifier_desc);
		wait .5;
	}
}

function flash_modifier_notice(title, material)
{
	self.modifiers_ui_notice_img setShader(material, 100, 100);
	self.modifiers_ui_notice_txt setText(title);
	self.modifiers_ui_notice_img.alpha = 1;
	self.modifiers_ui_notice_txt.alpha = 1;

	wait 3;

	self.modifiers_ui_notice_img.alpha = 0;
	self.modifiers_ui_notice_txt.alpha = 0;
}

function add_modifier_good(name, description, handler, material)
{
	level.good_modifiers[name] = spawnStruct();
	level.good_modifiers[name].description = description;
	level.good_modifiers[name].handler = handler;
	level.good_modifiers[name].material = material;
}

function add_modifier_bad(name, description, handler, material)
{
	level.bad_modifiers[name] = spawnStruct();
	level.bad_modifiers[name].description = description;
	level.bad_modifiers[name].handler = handler;
	level.bad_modifiers[name].material = material;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Callbacks
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function modifier_random_weapon_weights(keys)
{
	// If no relavent modifiers are active, just return the default keyset
	if (!level.modifiers_good_box_luck && !level.modifiers_no_ww_in_box)
	{
		return keys;
	}

	filtered_keys = [];

	keyset_chooser = RandomInt(100);
	ww_only = false;

	// 20% chance of giving the player a wonderweapon or tactical grenade
	if (keyset_chooser < 20)
	{
		ww_only = true;
	}

	// If the "no ww" modifier is active, create a new list without wonderweapons and return it
	if (level.modifiers_no_ww_in_box)
	{
		for (i = 0; i < keys.size; i++)
		{
			if (!IsDefined(keys[i]) || zm_weapons::is_wonder_weapon(keys[i]))
				continue;

			filtered_keys[filtered_keys.size] = keys[i];
		}

		return filtered_keys;
	}

	// At this point, we either give a wonderweapon or a "good" gun by filtering out bad keys
	for (i = 0; i < keys.size; i++)
	{
		if (!IsDefined(keys[i]))
			continue;

		key = keys[i];

		if (ww_only == true && (zm_weapons::is_wonder_weapon(key) || zm_utility::is_tactical_grenade(key))) {
			// Give wonderweapon
			filtered_keys[filtered_keys.size] = key;
		} else if (ww_only == false) {
			// Give "good" gun
			if (!IsDefined(key.name))
				continue;

			if (key.name == "smg_fastfire" ||
				key.name == "lmg_heavy" ||
				key.name == "ar_standard" ||
				key.name == "ar_m14" ||
				key.name == "launcher_multi" ||
				key.name == "smg_ak74u" ||
				key.name == "lmg_slowfire" ||
				key.name == "ar_famas" ||
				key.name == "lmg_light" ||
				key.name == "sniper_fastbolt" ||
				key.name == "smg_capacity" ||
				key.name == "shotgun_precision" ||
				key.name == "sniper_powerbolt" ||
				key.name == "smg_burst" ||
				key.name == "ar_m16" ||
				key.name == "launcher_standard" ||
				key.name == "pistol_fullauto" ||
				key.name == "smg_versatile" ||
				key.name == "shotgun_pump" ||
				key.name == "smg_standard" ||
				key.name == "ar_longburst" ||
				key.name == "ar_marksman" ||
				key.name == "shotgun_semiauto" ||
				key.name == "ar_marksman" ||
				key.name == "ar_peacekeeper" ||
				key.name == "special_crossbow" ||
				key.name == "ar_garand" ||
				key.name == "smg_sten" ||
				key.name == "ar_stg44" ||
				key.name == "smg_mp40_1940"
				)
			{
				continue;
			}

			filtered_keys[filtered_keys.size] = key;
		}
	}

	return filtered_keys;
}

function modifier_joker_chance_override(chance_of_joker)
{
	// If the "bad news bear" modifier is active, return a 100% chance of joker, else don't modify it
	if (level.modifiers_force_bear == true)
	{
		return (100);
	}

	return (chance_of_joker);
}

// self is a zombie
function modifier_damage_response( str_mod, str_hit_location, v_hit_origin, e_player, n_amount, w_weapon, direction_vec, tagName, modelName, partName, dFlags, inflictor, chargeLevel )
{
	// If the damage is from a grenade and the "supercharged grenades" modifier is active, apply deadwire / arc damage
	if (level.modifiers_aat_grenades == true && IsDefined(self.damageweapon) && zm_utility::is_lethal_grenade(self.damageweapon))
	{
		self lightning_chain::arc_damage(self, e_player, 1);

		if (!IS_TRUE( self.no_damage_points ) && IsDefined(e_player))
		{
			damage_type = "damage";
			e_player zm_score::player_add_points( damage_type, str_mod, str_hit_location, false, undefined, w_weapon );
		}

		return true;
	}

	return false;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Good modifiers
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Dropzone
function persistent_dropzone()
{
	level endon("end_game");

	level.modifiers_dropzone_round = true;
	level waittill("end_of_round");
	level.modifiers_dropzone_round = false;
}

// Perkalicious Gift
function free_perk()
{
	level endon("end_game");

	players = GetPlayers();

	for (i = 0; i < players.size; i++)
	{
		if (!players[i] laststand::player_is_in_laststand() && !(players[i].sessionstate == "spectator"))
		{
			player = players[i];
			free_perk = player give_random_perk();

			if (isDefined(free_perk) && isDefined(level.perk_bought_func))
			{
				player[[level.perk_bought_func]](free_perk);
			}
		}
	}
}

function give_random_perk()
{
	random_perk = undefined;
	a_str_perks = GetArrayKeys(level._custom_perks);

	perks = [];

	for (i = 0; i < a_str_perks.size; i++)
	{
		perk = a_str_perks[i];

		if (IsDefined( self.perk_purchased ) && self.perk_purchased == perk)
		{
			continue;
		}

		if (!self HasPerk(perk) && !(IsDefined(self.disabled_perks) && IsDefined(self.disabled_perks[perk]) && self.disabled_perks[perk]))
		{
			perks[perks.size] = perk;
		}
	}

	if (perks.size > 0)
	{
		perks = array::randomize(perks);
		random_perk = perks[0];
		self zm_perks::vending_trigger_post_think(self, random_perk);
	}
	else
	{
		// No Perks Left To Get
		self PlaySoundToPlayer(level.zmb_laugh_alias, self);
	}

	return (random_perk);
}

// Halfway There
function halve_zombie_round_total()
{
	level.zombie_total = int(level.zombie_total / 2);
}

// Bargainer
function persistent_firesale()
{
	level endon("end_game");

	level thread zm_audio::sndAnnouncerPlayVox("fire_sale");

	level.zombie_vars["zombie_powerup_fire_sale_on"] = true;
	level.disable_firesale_drop = true;

	bgb_machine::turn_on_fire_sale();

	for (i = 0; i < level.chests.size; i++)
	{
		show_firesale_box = level.chests[i] [[level._zombiemode_check_firesale_loc_valid_func]]();

		if (show_firesale_box)
		{
			level.chests[i].zombie_cost = 10;

			if (level.chest_index != i)
			{
				level.chests[i].was_temp = true;
				if (IS_TRUE(level.chests[i].hidden))
				{
					level.chests[i] thread zm_powerup_fire_sale::apply_fire_sale_to_chest();
				}
			}
		}
	}

	level waittill("end_of_round");

	level.zombie_vars["zombie_powerup_fire_sale_on"] = false;
	level.disable_firesale_drop = false;

	bgb_machine::turn_off_fire_sale();

	for (i = 0; i < level.chests.size; i++)
	{
		show_firesale_box = level.chests[i] [[level._zombiemode_check_firesale_loc_valid_func]]();

		if (show_firesale_box)
		{
			if (level.chest_index != i && IsDefined(level.chests[i].was_temp))
			{
				level.chests[i].was_temp = undefined;
				level thread zm_powerup_fire_sale::remove_temp_chest(i);
			}

			level.chests[i].zombie_cost = level.chests[i].old_cost;
		}
	}
}

// Slaughterhouse
function persistent_instakill()
{
	level endon("end_game");

	players = GetPlayers();
	player = players[0];
	team = player.team;

	level.zombie_vars[team]["zombie_insta_kill"] = 1;
	level.modifiers_drop_noinstakill = true;

	level waittill("end_of_round");

	level.zombie_vars[team]["zombie_insta_kill"] = 0;
	level.modifiers_drop_noinstakill = false;

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			players[i] notify("insta_kill_over");
		}
	}
}

// Three's a Party
function persistent_triplepoints()
{
	level endon("end_game");

	players = GetPlayers();
	player = players[0];

	team = player.team;

	level.zombie_vars[team]["zombie_point_scalar"] = 3;
	level waittill("end_of_round");
	level.zombie_vars[team]["zombie_point_scalar"] = 1;
}

// Supercharged Grenades
function set_aat_grenades()
{
	level endon("end_game");

	level.modifiers_aat_grenades = true;
	level waittill("end_of_round");
	level.modifiers_aat_grenades = false;
}

// Lightfoot
function persistent_superspeed()
{
	level endon("end_game");

	players = GetPlayers();

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			players[i] setMoveSpeedScale(1.25);
			setDvar("player_sprintCameraBob", 0);
			setDvar("bg_viewBobMax", 0);
		}
	}

	setJumpHeight(78);

	level waittill("end_of_round");

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			players[i] setMoveSpeedScale(1.0);
			setDvar("player_sprintCameraBob", .5);
			setDvar("bg_viewBobMax", 8);
		}
	}

	setJumpHeight(39);
}

// Connoisseur
function one_round_perkaholic()
{
	level endon("end_game");

	players = GetPlayers();
	a_str_perks = GetArrayKeys( level._custom_perks );

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]) && !players[i] laststand::player_is_in_laststand() && !(players[i].sessionstate == "spectator"))
		{
			players[i].old_perks = [];

			foreach (str_perk in a_str_perks)
			{
				players[i].old_perks[str_perk] = players[i] HasPerk(str_perk);

				if (!players[i].old_perks[str_perk])
				{
					players[i] zm_perks::give_perk(str_perk);
				}
			}
		}
	}

	level waittill("end_of_round");

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			foreach (str_perk in a_str_perks)
			{
				if (players[i].old_perks[str_perk] != true)
				{
					str_stop_perk = str_perk + "_stop";
					players[i] notify(str_stop_perk);
				}
			}
		}
	}
}

// Immortal
function persistent_godmode()
{
	level endon("end_game");

	players = GetPlayers();

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			players[i] EnableInvulnerability();
		}
	}

	level waittill("end_of_round");

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			players[i] DisableInvulnerability();
		}
	}
}

// Thirsty
function disable_perk_limit()
{
	level endon("end_game");

	level.perk_purchase_limit = 20;
	level waittill("end_of_round");
	level.perk_purchase_limit = 4;
}

// Raining Bullets
function persistent_infammo()
{
	level endon("end_game");
	level endon("end_of_round");

	players = GetPlayers();

	for (;;)
	{
		for (i = 0; i < players.size; i++)
		{
			if (IsDefined(players[i]))
			{
				players[i] SetWeaponAmmoStock(players[i] getcurrentweapon(), 1337);
				players[i] SetWeaponAmmoClip(players[i] getcurrentweapon(), 1337);
			}
		}

		wait .2;
	}
}

// Blackened
function persistent_nukes()
{
	level endon("end_game");
	level endon("end_of_round");

	players = GetPlayers();
	player = players[0];

	level.zombie_total = int(1);

	for (;;)
	{
		zm_powerup_nuke::nuke_powerup(player, player.team);
		wait 20;
	}
}

// Rebate
function persistent_rebate()
{
	level endon("end_game");
	level endon("end_of_round");

	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			players[i].modifiers_rebates = 3;
			players[i].modifiers_prev_score = players[i].score;
		}
	}
	
	for (;;)
	{
		for (i = 0; i < players.size; i++)
		{
			if (IsDefined(players[i]) && players[i].modifiers_rebates > 0)
			{
				if (players[i].score < players[i].modifiers_prev_score)
				{
					players[i].score = players[i].modifiers_prev_score;
					players[i].pers["score"] = players[i].score;

					players[i].modifiers_rebates--;
				}
			}

			players[i].modifiers_prev_score = players[i].score;
		}

		wait .2;
	}
}

// Lucky
function persistent_box_luck()
{
	level endon("end_game");

	level.modifiers_good_box_luck = true;
	level waittill("end_of_round");
	level.modifiers_good_box_luck = false;
}

// Hunter
function free_traps()
{
	level endon("end_game");

	oldtrapcost = [];

	traps = getentarray("zombie_trap", "targetname");

	for (i = 0; i < traps.size; i++)
	{
		oldtrapcost[i] = traps[i].zombie_cost;
		traps[i].zombie_cost = 0;
	}

	level waittill("end_of_round");

	for (i = 0; i < traps.size; i++)
	{
		traps[i].zombie_cost = oldtrapcost[i];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Bad modifiers
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Juggernaughts
function juggernaught_zombies()
{
	level endon("end_game");

	old_zombie_health = level.zombie_health;
	level.zombie_health = old_zombie_health * 2;

	level waittill("end_of_round");

	level.zombie_health = old_zombie_health;
}

// Sky High
function persistent_highdrops()
{
	level endon("end_game");
	
	level.modifiers_high_drop = true;
	level waittill("end_of_round");
	level.modifiers_high_drop = false;
}

// Sober
function disable_most_perks()
{
	level endon("end_game");

	players = GetPlayers();
	a_str_perks = GetArrayKeys(level._custom_perks);

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			players[i].old_perks = [];

			foreach (str_perk in a_str_perks)
			{
				players[i].old_perks[str_perk] = players[i] HasPerk(str_perk);

				if (players[i].old_perks[str_perk] == true && str_perk != "specialty_armorvest" && str_perk != "specialty_additionalprimaryweapon")
				{
					str_stop_perk = str_perk + "_stop";
					players[i] notify(str_stop_perk);
				}
			}
		}
	}

	level waittill("end_of_round");

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			foreach (str_perk in a_str_perks)
			{
				if (players[i].old_perks[str_perk] == true && str_perk != "specialty_armorvest" && str_perk != "specialty_additionalprimaryweapon")
				{
					players[i] zm_perks::give_perk(str_perk);
				}
			}
		}
	}
}

// Dud
function disable_nades()
{
	level endon("end_game");
	continuous_nade_disable();

	players = GetPlayers();

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			players[i] enable_player_nades();
		}
	}
}

function continuous_nade_disable()
{
	level endon("end_game");
	level endon("end_of_round");

	// First get old grenade counts for later restoration
	players = GetPlayers();

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			old_lethal_ammo = players[i] GetWeaponAmmoClip(players[i].current_lethal_grenade);
			players[i].modifiers_grenade_old_lethal_ammo = old_lethal_ammo;
		}
	}

	// Ensure they can't get nades
	for (;;)
	{
		players = GetPlayers();

		for (i = 0; i < players.size; i++)
		{
			if (IsDefined(players[i]))
			{
				players[i] SetWeaponAmmoClip(players[i].current_lethal_grenade, 0);
			}
		}

		wait .5;
	}
}

function enable_player_nades()
{
	current_lethal_grenade = self.current_lethal_grenade;
	self SetWeaponAmmoClip(current_lethal_grenade, self.modifiers_grenade_old_lethal_ammo);
}

// Low charge
function disable_aats()
{
	level endon("end_game");
	level endon("end_of_round");

	players = GetPlayers();
	keys = GetArrayKeys(level.aat);

	for (;;)
	{
		now = GetTime() / 1000;

		for (i = 0; i < players.size; i++)
		{
			if (IsDefined(players[i]))
			{
				foreach(key in keys)
				{
					players[i].aat_cooldown_start[key] = now;
				}
			}
		}
		
		wait 1;
	}
}

// Weapon Locked
function lock_to_current_weapon()
{
	level endon("end_game");
	level endon("end_of_round");

	players = GetPlayers();

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			players[i].modifiers_locked_weapon = players[i] GetCurrentWeapon();
			players[i] iPrintlnBold("^7Weapon locks in 10 seconds...");
		}
	}

	wait 10;

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			players[i].modifiers_locked_weapon = players[i] GetCurrentWeapon();
			players[i] iPrintlnBold("^7Weapon ^1locked ^7for the round!");
		}
	}

	for (;;)
	{
		for (i = 0; i < players.size; i++)
		{
			if (IsDefined(players[i]) && players[i] GetCurrentWeapon() != players[i].modifiers_locked_weapon)
			{
				if (players[i] HasWeapon(players[i].modifiers_locked_weapon))
					players[i] SwitchToWeaponImmediate(players[i].modifiers_locked_weapon);
			}
		}

		wait .2;
	}
}

// Bad News Bear
function persistent_bear()
{
	level endon("end_game");

	level.modifiers_force_bear = true;
	level waittill("end_of_round");
	level.modifiers_force_bear = false;
}

// Gum Shortage
function disable_bgb()
{
	level endon("end_game");

	oldbgb = level.bgb;
	level.bgb = [];

	level waittill("end_of_round");

	level.bgb = oldbgb;
}

// Probation
function disable_perk_purchase()
{
	level endon("end_game");

	level.modifiers_perks_purchasable = false;
	level waittill("end_of_round");
	level.modifiers_perks_purchasable = true;
}

// Heavy
function make_players_heavy()
{
	level endon("end_game");

	players = GetPlayers();

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			players[i] setMoveSpeedScale(0.9);
		}
	}

	setJumpHeight(1);

	level waittill("end_of_round");

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			players[i] setMoveSpeedScale(1.0);
		}
	}

	setJumpHeight(39);
}

// Fined
function deduct_half_points()
{
	level endon("end_game");

	players = GetPlayers();

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			players[i] zm_score::player_reduce_points("take_half");
		}
	}
}

// Out of Order
function disable_pap()
{
	level endon("end_game");

	level.modifier_pap_enable = false;
	level waittill("end_of_round");
	level.modifier_pap_enable = true;
}

// Unworthy
function persistent_nopoints()
{
	level endon("end_game");
	level endon("end_of_round");

	players = GetPlayers();
	
	for (;;)
	{
		for (i = 0; i < players.size; i++)
		{
			if (!IsDefined(players[i].modifiers_prev_score))
				players[i].modifiers_prev_score = players[i].score;

			if (IsDefined(players[i]))
			{
				if (players[i].score > players[i].modifiers_prev_score)
				{
					players[i].score = players[i].modifiers_prev_score;
					players[i].pers["score"] = players[i].score;
				}

				players[i].modifiers_prev_score = players[i].score;
			}
		}

		wait .2;
	}
}

// Ammo Recall
function persistent_random_noammo()
{
	level endon("end_game");
	
	players = GetPlayers();

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			player_weapons = players[i] GetWeaponsListPrimaries();
			player_weapons_randomized = array::randomize(player_weapons);
			player_rand_weapon = player_weapons_randomized[0];

			players[i].modifiers_prev_weapon = player_rand_weapon;
			players[i].modifiers_prev_weapon_stock = players[i] GetWeaponAmmoStock(player_rand_weapon);
			players[i].modifiers_prev_weapon_clip = players[i] GetWeaponAmmoClip(player_rand_weapon);

			players[i] SetWeaponAmmoStock(player_rand_weapon, 0);
			players[i] SetWeaponAmmoClip(player_rand_weapon, 0);
		}
	}

	level waittill("end_of_round");

	for (i = 0; i < players.size; i++)
	{
		if (IsDefined(players[i]))
		{
			player_rand_weapon = players[i].modifiers_prev_weapon;

			if (!(players[i] HasWeapon(player_rand_weapon)))
			{
				continue;
			}

			player_current_stock_ammo = players[i] GetWeaponAmmoStock(player_rand_weapon);
			player_current_clip_ammo = players[i] GetWeaponAmmoClip(player_rand_weapon);

			// Don't restore ammo if they already got ammo somehow in the round
			if (player_current_stock_ammo == 0 && player_current_clip_ammo == 0)
			{
				players[i] SetWeaponAmmoStock(player_rand_weapon, players[i].modifiers_prev_weapon_stock);
				players[i] SetWeaponAmmoClip(player_rand_weapon, players[i].modifiers_prev_weapon_clip);
			}
		}
	}
}

// Joker
function invert_powerups()
{
	level endon("end_game");

	level.modifiers_joker_active = true;
	level thread instakill_unkillable_zombies();

	level waittill("end_of_round");
	level.modifiers_joker_active = false;
}

function instakill_unkillable_zombies()
{
	level endon("end_game");
	level endon("end_of_round");

	players = GetPlayers();
	player = players[0];

	team = player.team;

	for (;;)
	{
		if (level.zombie_vars[team]["zombie_insta_kill"] == 1)
		{
			zombies = GetAiTeamArray( level.zombie_team );

			for (i = 0; i < zombies.size; i++)
			{
				zombies[i].health = 999999;
			}
		}

		wait 1;
	}
}

// Box Suppression
function persistent_no_ww()
{
	level endon("end_game");

	level.modifiers_no_ww_in_box = true;
	level waittill("end_of_round");
	level.modifiers_no_ww_in_box = false;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Utilities
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function createRectangle(align, relative, x, y, width, height, color, shader, sort, alpha)
{
    uiElement = newClientHudElem(self);
    uiElement.elemType = "bar";
    uiElement.width = width;
    uiElement.height = height;
    uiElement.xOffset = 0;
    uiElement.yOffset = 0;
    uiElement.hidewheninmenu = true;
    uiElement.children = [];
    uiElement.sort = sort;
    uiElement.color = color;
    uiElement.alpha = alpha;
    uiElement hud::setParent(level.uiParent);
    uiElement setShader(shader, width, height);
    uiElement.hidden = false;
    uiElement hud::setPoint(align, relative, x, y);
    return uiElement;
}

function createText(font, fontSize, sorts, text, align, relative, x, y, color, alpha)
{
    uiElement = hud::createFontString(font, fontSize);
    uiElement hud::setPoint(align, relative, x, y);
    uiElement settext(text);
    uiElement.sort = sorts;
    uiElement.hidewheninmenu = true;
    if( isDefined(alpha) )
        uiElement.alpha = alpha;
    if( isDefined(color) )
        uiElement.color = color;
    return uiElement;
}
