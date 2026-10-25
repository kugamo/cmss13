/**
 * Active state of "I am currently on top of a climbable structure".
 * Handles pixel offsets, movement interception, falling off, stacking movement, throw animation, etc.
 */
/datum/component/climbing
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS

	/// The structure we are currently on top of
	var/obj/structure/climbed_structure

	/// The config that was used when we climbed
	var/datum/climbable_config/config

	/// Our original pixel_y before we climbed
	var/original_pixel_y

	/// Our original layer before we climbed
	var/original_layer

	/// Whether we are currently in the middle of the climb-up animation
	var/climbing_up = FALSE

/datum/component/climbing/Initialize(obj/structure/structure, datum/climbable_config/given_config)
	climbed_structure = structure
	config = given_config || structure.climbable
	if(!config || !istype(parent, /atom/movable))
		return COMPONENT_INCOMPATIBLE

	var/mob/living/climber = parent
	original_pixel_y = climber.pixel_y
	original_layer = climber.layer

	// Apply the visual offset immediately (or start the climb-up animation)
	apply_offset(animate = TRUE)

	RegisterSignal(climbed_structure, COMSIG_MOVABLE_MOVED, PROC_REF(on_structure_moved))
	RegisterSignal(climbed_structure, COMSIG_PARENT_QDELETING, PROC_REF(on_structure_deleted))
	// Also useful: COMSIG_ATOM_ATTACKBY / mouse drop signals if we want to handle stacking from here

/datum/component/climbing/Destroy(force, silent)
	var/mob/living/climber = parent
	if(climber)
		// Reset visuals
		animate(climber, pixel_y = original_pixel_y, time = 0.2 SECONDS)
		if(config?.climber_layer)
			climber.layer = original_layer

	climbed_structure = null
	config = null
	return ..()

/// Called when the climb action starts – moves the mob onto the structure's tile and animates upward
/datum/component/climbing/proc/start_climb_animation(mob/living/climber)
	climbing_up = TRUE
	// ForceMove to the structure's turf first, then animate pixel_y up over the climb_delay
	climber.forceMove(get_turf(climbed_structure))
	animate(climber, pixel_y = original_pixel_y + config.pixel_y_offset, time = config.climb_delay)
	// After the timer, climbing_up = FALSE and we are fully "on" it

/// Applies / refreshes the pixel offset (and layer if configured)
/datum/component/climbing/proc/apply_offset(animate = FALSE)
	var/mob/living/climber = parent
	var/target_y = original_pixel_y + config.pixel_y_offset
	if(animate)
		animate(climber, pixel_y = target_y, time = 0.2 SECONDS)
	else
		climber.pixel_y = target_y

	if(config.climber_layer)
		climber.layer = config.climber_layer

/// Intercept the climber trying to move
/datum/component/climbing/proc/on_climber_pre_move(mob/living/climber, atom/new_loc, direction)
	SIGNAL_HANDLER

	if(climbing_up)
		return COMPONENT_MOVABLE_BLOCK_PRE_MOVE   // locked during the climb animation

	var/turf/target = get_step(climber, direction)

	// 1. Moving onto an adjacent climbable of compatible height → transfer the component
	var/obj/structure/adjacent = locate(/obj/structure) in target
	if(adjacent?.climbable && can_transfer_to(adjacent))
		// Transfer logic (or just let the normal climb proc handle it)
		return

	// 2. Moving off / wrong intent → climb down or fall
	if(climber.a_intent == INTENT_HARM || !config.can_stand_on)
		do_climb_down(climber)
		return

	// 3. Otherwise allow the move but keep the component if we stay on the same structure tile
	// (or remove it if we leave)

/// Structure itself was moved (dragged, pushed, etc.)
/datum/component/climbing/proc/on_structure_moved(obj/structure/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER

	if(!config.moves_climbers)
		// Fall off
		qdel(src)
		return

	var/mob/living/climber = parent
	// Move with it (or animate)
	climber.forceMove(get_turf(source))
	// Re-apply offset in case the structure's own pixel offset changed
	apply_offset()

/// Structure is being deleted / destroyed
/datum/component/climbing/proc/on_structure_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)   // fall off

/// Resting change – decide whether we stay attached or fall
/datum/component/climbing/proc/on_resting_change(mob/living/climber, new_resting)
	SIGNAL_HANDLER
	if(new_resting && !config.allows_resting)
		do_climb_down(climber)

/// Helper: properly climb down / fall off
/datum/component/climbing/proc/do_climb_down(mob/living/climber)
	// Animate down, then qdel the component
	animate(climber, pixel_y = original_pixel_y, time = 0.3 SECONDS)
	qdel(src)

/// Used by throw / toss code so they know how to animate a mob that is currently climbed
/datum/component/climbing/proc/get_toss_animation_data()
	return list(
		"pixel_y_start" = parent.pixel_y,
		"pixel_y_end" = original_pixel_y,
		// any other data the toss proc needs
	)
