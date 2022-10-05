// Burrower Abilities

// Burrow
/datum/action/xeno_action/activable/burrow
	name = "Burrow"
	action_icon_state = "agility_on"
	ability_name = "burrow"
	macro_path = /datum/action/xeno_action/verb/verb_burrow
	action_type = XENO_ACTION_CLICK
	ability_primacy = XENO_PRIMARY_ACTION_3

/datum/action/xeno_action/activable/burrow/use_ability(atom/A)
	var/mob/living/carbon/Xenomorph/X = owner
/*	if (X.mutation_type != WARRIOR_BOXER)
		do_base_warrior_punch(H, L)
	else
		do_boxer_punch(H,L)*/
	if(X.burrow)
		X.tunnel(get_turf(A))
	else
		X.burrow()

/datum/action/xeno_action/onclick/tremor
	name = "Tremor (100)"
	action_icon_state = "stomp"
	ability_name = "tremor"
	macro_path = /datum/action/xeno_action/verb/verb_tremor
	action_type = XENO_ACTION_CLICK
	ability_primacy = XENO_PRIMARY_ACTION_4

/datum/action/xeno_action/onclick/tremor/use_ability()
	var/mob/living/carbon/Xenomorph/X = owner
	X.tremor()
	..()

//Spiker abilities
/datum/action/xeno_action/activable/burrowed_spikes
	name = "Burrowed Spikes"
	ability_name = "burrowed spikes"
	action_icon_state = "rav_scissor_cut"
	macro_path = /datum/action/xeno_action/verb/verb_burrowed_spikes
	action_type = XENO_ACTION_CLICK
	ability_primacy = XENO_PRIMARY_ACTION_3
	xeno_cooldown = 10 SECONDS
	plasma_cost = 25

	// Config
	var/damage = 45
