/**
 * Static definition of how a structure can be climbed on, stacked on, and have things placed on it.
 * Structures hold a typepath to one of these (or a subtype) instead of a pile of individual vars.
 */
/datum/climbable_config
	/// How high (in pixels) a mob is offset while standing on this structure
	var/pixel_y_offset = 12
	/// Base time to climb onto this structure
	var/climb_delay = CLIMB_DELAY_MEDIUM
	/// Extra move delay applied to anyone dragging this structure while something is on top of it
	var/drag_delay_penalty = 1 SECONDS
	/// Can other climbable structures be stacked on top of this one?
	var/can_be_stacked_on = FALSE
	/// Can this structure itself be stacked on top of other climbables?
	var/can_stack = FALSE
	/// Maximum stack height (number of structures) before it becomes unstable / unclimbable
	var/max_stack_height = 1
	/// Chance (0-100) that a stack of this height or higher collapses when climbed / moved
	var/collapse_chance_per_level = 0
	/// Whether items can be placed / mouse-dropped onto this structure
	var/can_place_items = TRUE
	/// Whether living mobs can stand / walk on top of it once climbed
	var/can_stand_on = TRUE
	/// Whether being on top of this structure lets you shoot over dense mobs below (balance flag)
	var/allows_shooting_over = FALSE
	/// Layer the climber is forced to while on top (null = don't touch layer)
	var/climber_layer = null
	/// Whether the structure moves its climbers with it when the structure itself is moved
	var/moves_climbers = TRUE
	/// Whether resting on this structure keeps you attached (vs falling off)
	var/allows_resting = TRUE

/datum/climbable_config/table
	pixel_y_offset = 12
	climb_delay = CLIMB_DELAY_SHORT
	can_place_items = TRUE
	can_stand_on = TRUE
	can_stack = FALSE

/datum/climbable_config/crate
	pixel_y_offset = 10
	climb_delay = CLIMB_DELAY_MEDIUM
	can_be_stacked_on = TRUE
	can_stack = TRUE
	max_stack_height = 3
	collapse_chance_per_level = 15
	can_place_items = TRUE
	can_stand_on = TRUE

/datum/climbable_config/large_container   // shipping containers, etc.
	pixel_y_offset = 24
	climb_delay = CLIMB_DELAY_LONG
	can_be_stacked_on = TRUE
	can_stack = FALSE          // you don't stack containers on each other by hand
	max_stack_height = 2
	collapse_chance_per_level = 40
	can_stand_on = TRUE
	allows_shooting_over = TRUE   // the "shoot over marines" question
