/datum/caste_datum/sentinel
	caste_type = XENO_CASTE_SENTINEL
	tier = 1

	melee_damage_lower = XENO_DAMAGE_TIER_1
	melee_damage_upper = XENO_DAMAGE_TIER_2
	max_health = XENO_HEALTH_TIER_6
	plasma_gain = XENO_PLASMA_GAIN_TIER_5
	plasma_max = XENO_PLASMA_TIER_4
	xeno_explosion_resistance = XENO_EXPLOSIVE_ARMOR_TIER_1
	armor_deflection = XENO_NO_ARMOR
	evasion = XENO_EVASION_NONE
	speed = XENO_SPEED_TIER_7

	caste_desc = "A weak ranged combat alien."
	evolves_to = list(XENO_CASTE_SPITTER)
	deevolves_to = "Larva"
	acid_level = 1

	tackle_min = 4
	tackle_max = 4
	tackle_chance = 50
	tacklestrength_min = 4
	tacklestrength_max = 4

	behavior_delegate_type = /datum/behavior_delegate/sentinel_base

/mob/living/carbon/Xenomorph/Sentinel
	caste_type = XENO_CASTE_SENTINEL
	name = XENO_CASTE_SENTINEL
	desc = "A slithery, spitting kind of alien."
	icon_size = 48
	icon_state = "Sentinel Walking"
	plasma_types = list(PLASMA_NEUROTOXIN)
	pixel_x = -12
	old_x = -12
	tier = 1
	base_actions = list(
		/datum/action/xeno_action/onclick/xeno_resting,
		/datum/action/xeno_action/onclick/regurgitate,
		/datum/action/xeno_action/watch_xeno,
		/datum/action/xeno_action/activable/corrosive_acid/weak,
		/datum/action/xeno_action/activable/slowing_spit, //first macro
		/datum/action/xeno_action/activable/scattered_spit, //second macro
		/datum/action/xeno_action/onclick/paralyzing_slash //third macro
	)
	inherent_verbs = list(
		/mob/living/carbon/Xenomorph/proc/vent_crawl,
	)
	mutation_type = SENTINEL_NORMAL

	icon_xenonid = 'icons/mob/xenonids/sentinel.dmi'

/mob/living/carbon/Xenomorph/Sentinel/Initialize(mapload, mob/living/carbon/Xenomorph/oldXeno, h_number)
	icon_xeno = get_icon_from_source(CONFIG_GET(string/alien_sentinel))
	. = ..()

/datum/behavior_delegate/sentinel_base
	name = "Base Sentinel Behavior Delegate"

	// State
	var/next_slash_buffed = FALSE

#define NEURO_TOUCH_DELAY 4 SECONDS

/datum/behavior_delegate/sentinel_base/melee_attack_modify_damage(original_damage, mob/living/carbon/C)
	if (!next_slash_buffed)
		return original_damage

	if (!isXenoOrHuman(C))
		return original_damage

	if(skillcheck(C, SKILL_ENDURANCE, SKILL_ENDURANCE_MAX ))
		C.visible_message(SPAN_DANGER("[C] withstands the neurotoxin!"))
		next_slash_buffed = FALSE
		return original_damage //endurance 5 makes you immune to weak neurotoxin
	if(ishuman(C))
		var/mob/living/carbon/human/H = C
		if(H.chem_effect_flags & CHEM_EFFECT_RESIST_NEURO || H.species.flags & NO_NEURO)
			H.visible_message(SPAN_DANGER("[H] shrugs off the neurotoxin!"))
			next_slash_buffed = FALSE
			return //species like zombies or synths are immune to neurotoxin
	if (next_slash_buffed)
		to_chat(bound_xeno, SPAN_XENOHIGHDANGER("You add neurotoxin into your attack, [C] is about to fall over paralyzed!"))
		to_chat(C, SPAN_XENOHIGHDANGER("You feel like you're about to fall over, as [bound_xeno] slashes you with its neurotoxin coated claws!"))
		C.sway_jitter(times = 3, steps = round(NEURO_TOUCH_DELAY/3))
		C.Daze(4)
		addtimer(CALLBACK(src, .proc/paralyzing_slash, C), NEURO_TOUCH_DELAY)
		next_slash_buffed = FALSE
	return original_damage

#undef NEURO_TOUCH_DELAY

/datum/behavior_delegate/sentinel_base/proc/paralyzing_slash(mob/living/carbon/human/H)
	H.KnockDown(2)
	to_chat(H, SPAN_XENOHIGHDANGER("You fall over, paralyzed by the toxin!"))
