
//Burrower Abilities
/mob/living/carbon/Xenomorph/proc/burrow()
	if(!check_state())
		return

	if(used_burrow || tunnel || is_ventcrawling || action_busy)
		return

	var/turf/T = get_turf(src)
	if(!T)
		return

	if(istype(T, /turf/open/floor/almayer/research/containment) || istype(T, /turf/closed/wall/almayer/research/containment))
		to_chat(src, SPAN_XENOWARNING("You can't escape this cell!"))
		return

	if(clone) //Prevents burrowing on stairs
		to_chat(src, SPAN_XENOWARNING("You can't burrow here!"))
		return

	if(caste_type && GLOB.xeno_datum_list[caste_type])
		caste = GLOB.xeno_datum_list[caste_type]

	used_burrow = TRUE

	if(mutation_type == BURROWER_SPIKEY) //Spikey Burrower specific
		if(burrow)
			burrow_off()
			return
		var/obj/effect/alien/weeds/weeds = locate() in T
		if(!weeds)
			to_chat(src, SPAN_XENOWARNING("You need to burrow on weeds!"))
			addtimer(CALLBACK(src, .proc/do_burrow_cooldown), (caste ? caste.burrow_cooldown : 5 SECONDS))
			return
		if(!do_after(src, 1.5 SECONDS, INTERRUPT_ALL, BUSY_ICON_HOSTILE))
			addtimer(CALLBACK(src, .proc/do_burrow_cooldown), (caste ? caste.burrow_cooldown : 5 SECONDS))
			return
		to_chat(src, SPAN_XENOWARNING("You begin burrowing yourself into the weeds."))
		burrow = TRUE
		invisibility = 101
		density = FALSE
		add_temp_pass_flags(PASS_MOB_THRU|PASS_BUILDING|PASS_UNDER|PASS_BURROWED)
		RegisterSignal(src, COMSIG_LIVING_PREIGNITION, .proc/fire_immune)
		RegisterSignal(src, list(
			COMSIG_LIVING_FLAMER_CROSSED,
			COMSIG_LIVING_FLAMER_FLAMED,
		), .proc/flamer_crossed_immune)
		mouse_opacity = FALSE
		update_icons()
		addtimer(CALLBACK(src, .proc/do_burrow_cooldown), (caste ? caste.burrow_cooldown : 5 SECONDS))
		process_burrow_spiker()
		return

	to_chat(src, SPAN_XENOWARNING("You begin burrowing yourself into the ground."))
	if(!do_after(src, 1.5 SECONDS, INTERRUPT_ALL, BUSY_ICON_HOSTILE))
		addtimer(CALLBACK(src, .proc/do_burrow_cooldown), (caste ? caste.burrow_cooldown : 5 SECONDS))
		return
	// TODO Make immune to all damage here.
	to_chat(src, SPAN_XENOWARNING("You burrow yourself into the ground."))
	burrow = TRUE
	frozen = TRUE
	invisibility = 101
	anchored = TRUE
	density = FALSE
	if(caste.fire_immunity == FIRE_IMMUNITY_NONE)
		RegisterSignal(src, COMSIG_LIVING_PREIGNITION, .proc/fire_immune)
		RegisterSignal(src, list(
			COMSIG_LIVING_FLAMER_CROSSED,
			COMSIG_LIVING_FLAMER_FLAMED,
		), .proc/flamer_crossed_immune)
	update_canmove()
	update_icons()
	addtimer(CALLBACK(src, .proc/do_burrow_cooldown), (caste ? caste.burrow_cooldown : 5 SECONDS))
	burrow_timer = world.time + 90		// How long we can be burrowed
	process_burrow()

/mob/living/carbon/Xenomorph/proc/process_burrow()
	if(!burrow)
		return
	if(world.time > burrow_timer && !tunnel)
		burrow_off()
	if(observed_xeno)
		overwatch(observed_xeno, TRUE)
	if(burrow)
		addtimer(CALLBACK(src, .proc/process_burrow), 1 SECONDS)

/mob/living/carbon/Xenomorph/proc/process_burrow_spiker(var/turf/T = get_turf(src))
	var/obj/effect/alien/weeds/weeds = locate() in T
	if(!burrow)
		return
	if(!weeds)
		burrow_off()
	if(observed_xeno)
		overwatch(observed_xeno, TRUE)
	if(burrow)
		addtimer(CALLBACK(src, .proc/process_burrow_spiker), 1 SECONDS)

/mob/living/carbon/Xenomorph/proc/burrow_off()
	if(caste_type && GLOB.xeno_datum_list[caste_type])
		caste = GLOB.xeno_datum_list[caste_type]
	to_chat(src, SPAN_NOTICE("You resurface."))
	burrow = FALSE
	if(mutation_type == BURROWER_SPIKEY)
		remove_temp_pass_flags(PASS_MOB_THRU|PASS_BUILDING|PASS_UNDER|PASS_BURROWED)
		mouse_opacity = TRUE
	if(caste.fire_immunity == FIRE_IMMUNITY_NONE)
		UnregisterSignal(src, list(
			COMSIG_LIVING_PREIGNITION,
			COMSIG_LIVING_FLAMER_CROSSED,
			COMSIG_LIVING_FLAMER_FLAMED,
		))
	frozen = FALSE
	invisibility = FALSE
	anchored = FALSE
	density = TRUE
	for(var/mob/living/carbon/human/H in loc)
		H.KnockDown(2)
	addtimer(CALLBACK(src, .proc/do_burrow_cooldown), (caste ? caste.burrow_cooldown : 5 SECONDS))
	update_canmove()
	update_icons()

/mob/living/carbon/Xenomorph/proc/do_burrow_cooldown()
	used_burrow = FALSE
	if(burrow)
		to_chat(src, SPAN_NOTICE("You can now surface."))
	for(var/X in actions)
		var/datum/action/act = X
		act.update_button_icon()


/mob/living/carbon/Xenomorph/proc/tunnel(var/turf/T)
	if(!burrow)
		to_chat(src, SPAN_NOTICE("You must be burrowed to do this."))
		return

	if(used_tunnel)
		to_chat(src, SPAN_NOTICE("You must wait some time to do this."))
		return

	if(!T)
		to_chat(src, SPAN_NOTICE("You can't tunnel there!"))
		return

	if(T.density)
		to_chat(src, SPAN_XENOWARNING("You can't tunnel into a solid wall!"))
		return

	if(istype(T, /turf/open/space))
		to_chat(src, SPAN_XENOWARNING("You make tunnels, not wormholes!"))
		return

	if(clone) //Prevents tunnels in Z transition areas
		to_chat(src, SPAN_XENOWARNING("You make tunnels, not wormholes!"))
		return

	var/area/A = get_area(T)
	if(A.flags_area & AREA_NOTUNNEL)
		to_chat(src, SPAN_XENOWARNING("There's no way to tunnel over there."))
		return

	for(var/obj/O in T.contents)
		if(O.density)
			if(O.flags_atom & ON_BORDER)
				continue
			to_chat(src, SPAN_WARNING("There's something solid there to stop you emerging."))
			return

	if(tunnel)
		tunnel = FALSE
		to_chat(src, SPAN_NOTICE("You stop tunneling."))
		used_tunnel = TRUE
		addtimer(CALLBACK(src, .proc/do_tunnel_cooldown), (caste ? caste.tunnel_cooldown : 5 SECONDS))
		return

	if(!T || T.density)
		to_chat(src, SPAN_NOTICE("You cannot tunnel to there!"))
	tunnel = TRUE
	to_chat(src, SPAN_NOTICE("You start tunneling!"))
	tunnel_timer = (get_dist(src, T)*10) + world.time
	process_tunnel(T)


/mob/living/carbon/Xenomorph/proc/process_tunnel(var/turf/T)
	if(world.time > tunnel_timer)
		tunnel = FALSE
		do_tunnel(T)
	if(tunnel && T)
		addtimer(CALLBACK(src, .proc/process_tunnel, T), 1 SECONDS)

/mob/living/carbon/Xenomorph/proc/do_tunnel(var/turf/T)
	to_chat(src, SPAN_NOTICE("You tunnel to your destination."))
	anchored = FALSE
	unfreeze()
	forceMove(T)
	UnregisterSignal(src, COMSIG_LIVING_FLAMER_FLAMED)
	burrow_off()

/mob/living/carbon/Xenomorph/proc/do_tunnel_cooldown()
	used_tunnel = FALSE
	to_chat(src, SPAN_NOTICE("You can now tunnel while burrowed."))
	for(var/X in actions)
		var/datum/action/act = X
		act.update_button_icon()

/mob/living/carbon/Xenomorph/proc/rename_tunnel(var/obj/structure/tunnel/T in oview(1))
	set name = "Rename Tunnel"
	set desc = "Rename the tunnel."
	set category = null

	if(!istype(T))
		return

	var/new_name = strip_html(input("Change the description of the tunnel:", "Tunnel Description") as text|null)
	if(new_name)
		new_name = "[new_name] ([get_area_name(T)])"
		log_admin("[key_name(src)] has renamed the tunnel \"[T.tunnel_desc]\" as \"[new_name]\".")
		msg_admin_niche("[src]/([key_name(src)]) has renamed the tunnel \"[T.tunnel_desc]\" as \"[new_name]\".")
		T.tunnel_desc = "[new_name]"
	return

/datum/action/xeno_action/onclick/tremor/action_cooldown_check()
	var/mob/living/carbon/Xenomorph/xeno = owner
	return !xeno.used_tremor

/mob/living/carbon/Xenomorph/proc/tremor() //More support focused version of crusher earthquakes.
	if(burrow || is_ventcrawling)
		to_chat(src, SPAN_XENOWARNING("You must be above ground to do this."))
		return

	if(!check_state())
		return

	if(used_tremor)
		to_chat(src, SPAN_XENOWARNING("Your aren't ready to cause more tremors yet!"))
		return

	if(!check_plasma(100)) return

	use_plasma(100)
	playsound(loc, 'sound/effects/alien_footstep_charge3.ogg', 75, 0)
	visible_message(SPAN_XENODANGER("[src] digs itself into the ground and shakes the earth itself, causing violent tremors!"), \
	SPAN_XENODANGER("You dig into the ground and shake it around, causing violent tremors!"))
	create_stomp() //Adds the visual effect. Wom wom wom
	used_tremor = 1

	for(var/mob/living/carbon/M in range(7, loc))
		to_chat(M, SPAN_WARNING("You struggle to remain on your feet as the ground shakes beneath your feet!"))
		shake_camera(M, 2, 3)

	for(var/mob/living/carbon/human/H in range(3, loc))
		to_chat(H, SPAN_WARNING("The violent tremors make you lose your footing!"))
		H.KnockDown(1)

	spawn(caste.tremor_cooldown)
		used_tremor = 0
		to_chat(src, SPAN_NOTICE("You gather enough strength to cause tremors again."))
		for(var/X in actions)
			var/datum/action/act = X
			act.update_button_icon()

//Spikey Burrower Abilities
/datum/action/xeno_action/activable/burrowed_spikes/use_ability(atom/A)
	var/mob/living/carbon/Xenomorph/X = owner
	if(!istype(X))
		return

	if(!action_cooldown_check())
		return

	if(!A || A.layer >= FLY_LAYER || !X.check_state())
		return

	if(!check_and_use_plasma_owner())
		return

	// Get line of turfs
	var/list/turf/target_turfs = list()

	var/facing = Get_Compass_Dir(X, A)
	var/turf/T = X.loc
	var/turf/temp = X.loc
	var/list/telegraph_atom_list = list()

	for (var/x in 0 to 4)
		temp = get_step(T, facing)
		if(!temp || temp.density || temp.opacity)
			break

		var/blocked = FALSE
		for(var/obj/structure/S in temp)
			if(S.opacity)
				blocked = TRUE
				break
		if(blocked)
			break

		T = temp
		target_turfs += T
		telegraph_atom_list += new /obj/effect/xenomorph/xeno_telegraph/brown(T, 0.25 SECONDS)

	// Extract our 'optimal' turf, if it exists
	if (target_turfs.len >= 2)
		X.animation_attack_on(target_turfs[target_turfs.len], 15)

	X.visible_message(SPAN_XENODANGER("[X] shoots spikes though the ground in front of it!"), SPAN_XENODANGER("You shoot your spikes though the ground in front of you!"))

	// Loop through our turfs, finding any humans there and dealing damage to them
	INVOKE_ASYNC(src, .proc/handle_damage, X, target_turfs, telegraph_atom_list)

	apply_cooldown()
	..()
	return

/datum/action/xeno_action/activable/burrowed_spikes/proc/handle_damage(var/mob/living/carbon/Xenomorph/X, target_turfs, telegraph_atom_list)
	for (var/turf/target_turf in target_turfs)
		telegraph_atom_list += new /obj/effect/xenomorph/xeno_telegraph/red(target_turf, chain_separation_delay)
		for (var/mob/living/carbon/C in target_turf)
			if (C.stat == DEAD)
				continue

			if(X.can_not_harm(C))
				continue
			X.flick_attack_overlay(C, "slash")
			C.apply_armoured_damage(damage, ARMOR_MELEE, BRUTE)
			playsound(get_turf(C), "alien_claw_flesh", 30, TRUE)
		for(var/obj/structure/S in target_turf)
			if(istype(S, /obj/structure/window/framed))
				var/obj/structure/window/framed/W = S
				if(!W.unslashable)
					W.shatter_window(TRUE)
					playsound(target_turf, "windowshatter", 50, TRUE)
		sleep(chain_separation_delay)


/datum/action/xeno_action/activable/sunken_tail/use_ability(atom/A)
	var/mob/living/carbon/Xenomorph/X = owner
	if(!istype(X))
		return

	if(!action_cooldown_check())
		return

	if(!A || A.layer >= FLY_LAYER || !X.check_state())
		return

	if(!check_and_use_plasma_owner())
		return

	if(get_dist(A, X) > max_distance)
		to_chat(X, SPAN_XENOWARNING("[A] is too far away!"))
		return

	var/turf/target = locate(A.x, A.y, A.z)
	var/list/telegraph_atom_list = list()
	telegraph_atom_list += new /obj/effect/xenomorph/xeno_telegraph/red(target, windup_delay)

	if(!do_after(X, windup_delay, INTERRUPT_ALL | BEHAVIOR_IMMOBILE, BUSY_ICON_HOSTILE))
		for(var/obj/effect/tele in telegraph_atom_list)
			qdel(tele)
		apply_cooldown() //no spam
		return
	X.visible_message(SPAN_XENOWARNING("The [X] stabs its tail in the ground toward [A]!"), SPAN_XENOWARNING("You stab your tail into the ground toward [A]!"))
	for (var/mob/living/carbon/C in target)
		if (C.stat == DEAD)
			continue

		if(X.can_not_harm(C))
			continue
		X.flick_attack_overlay(C, "slash")
		C.apply_armoured_damage(damage, ARMOR_MELEE, BRUTE)
		playsound(get_turf(C), "alien_claw_flesh", 30, TRUE)
	for(var/obj/structure/S in target)
		if(istype(S, /obj/structure/window/framed))
			var/obj/structure/window/framed/W = S
			if(!W.unslashable)
				W.shatter_window(TRUE)
				playsound(target, "windowshatter", 50, TRUE)


	apply_cooldown()
	..()
	return
