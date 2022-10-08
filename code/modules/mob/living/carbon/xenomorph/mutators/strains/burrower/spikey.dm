/datum/xeno_mutator/burrower_spikey
	name = "STRAIN: Burrower - Spikey"
	description = "GUH"
	cost = MUTATOR_COST_EXPENSIVE
	individual_only = TRUE
	caste_whitelist = list(XENO_CASTE_BURROWER)
	keystone = TRUE
	behavior_delegate_type = /datum/behavior_delegate/burrower_spikey
	mutator_actions_to_remove = list(
		/datum/action/xeno_action/onclick/build_tunnel,
		/datum/action/xeno_action/onclick/tremor,
		/datum/action/xeno_action/activable/corrosive_acid,
		/datum/action/xeno_action/activable/place_construction,
		/datum/action/xeno_action/onclick/plant_weeds,
		/datum/action/xeno_action/onclick/place_trap
	)
	mutator_actions_to_add = list(
		/datum/action/xeno_action/activable/burrowed_spikes,
		/datum/action/xeno_action/activable/sunken_tail
	)

/datum/xeno_mutator/burrower_spikey/apply_mutator(datum/mutator_set/individual_mutators/MS)
	. = ..()
	if (. == 0)
		return

	var/mob/living/carbon/Xenomorph/Burrower/B = MS.xeno
	B.mutation_type = BURROWER_SPIKEY

	mutator_update_actions(B)
	MS.recalculate_actions(description, flavor_description)

	apply_behavior_holder(B)
	B.recalculate_everything()


/datum/behavior_delegate/burrower_spikey
	name = "Spikey Burrower Behavior Delegate"



/datum/behavior_delegate/burrower_spikey/on_update_icons()
	if(bound_xeno.stat == DEAD)
		return
/*
	if(bound_xeno.burrow)
		bound_xeno.icon_state = "[bound_xeno.mutation_type] Burrower Burrowed"
		return TRUE


	if(bound_xeno.fortify)
		bound_xeno.icon_state = "[bound_xeno.mutation_type] Defender Fortify"
		return TRUE
	if(bound_xeno.crest_defense)
		bound_xeno.icon_state = "[bound_xeno.mutation_type] Defender Crest"
		return TRUE
*/
