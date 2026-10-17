/obj/effect/landmark/supply_elevator
	icon_state = "elevator"
	var/faction = FACTION_MARINE

/obj/effect/landmark/supply_elevator/upp
	icon_state = "elevator_upp"
	faction = FACTION_UPP

/obj/effect/landmark/supply_elevator/Initialize(mapload, ...)
	. = ..()
	switch(faction)
		if(FACTION_MARINE)
			GLOB.supply_controller.supply_elevator = get_turf(src)
		if(FACTION_UPP)
			GLOB.supply_controller_upp.supply_elevator = get_turf(src)
		else
			GLOB.supply_controller.supply_elevator = get_turf(src)
	return INITIALIZE_HINT_QDEL

/obj/effect/landmark/supply_elevator/LateInitialize()
	. = ..()
	GLOB.supply_controller_upp.supply_elevator = get_turf(src)
	var/datum/shuttle/ferry/supply/shuttle = SSoldshuttle.shuttle_controller.shuttles["Supply upp"]
	if(shuttle.pick_loc())
		shuttle.Elevator_x = shuttle.pick_loc().x
		shuttle.Elevator_y = shuttle.pick_loc().y
		shuttle.Elevator_z = shuttle.pick_loc().z
		shuttle.the_pit = new /obj/effect/elevator(locate(shuttle.Elevator_x, shuttle.Elevator_y, shuttle.Elevator_z))
		shuttle.the_pit.vis_contents += shuttle.elevator_animation
	return INITIALIZE_HINT_QDEL



/datum/shuttle/ferry/supply
	iselevator = 1
	location = 1
	warmup_time = 1
	move_time = ELEVATOR_TRANSIT_DURATION
	var/away_location = 1 //the location to hide at while pretending to be in-transit
	var/late_chance = 0
	var/max_late_time = 300
	var/railing_id = "supply_elevator_railing"
	var/gear_id = "supply_elevator_gear"
	var/obj/effect/elevator/the_pit
	var/Elevator_x
	var/Elevator_y
	var/Elevator_z
	var/elevator_loc
	///Used to mirrors the turfs (and their contents) on the elevator when raising/lowering, so they don't instantly teleport or vanish.
	var/obj/effect/elevator/animation_overlay/elevator_animation
	var/datum/controller/supply/linked_supply_controller
	var/faction = FACTION_MARINE

/datum/shuttle/ferry/supply/upp
	faction= FACTION_UPP
	railing_id = "supply_elevator_railing_upp"
	gear_id = "supply_elevator_gear_upp"

/datum/shuttle/ferry/supply/proc/pick_loc()
	RETURN_TYPE(/turf)
	return linked_supply_controller.supply_elevator

/datum/shuttle/ferry/supply/New()
	..()
	switch(faction)
		if(FACTION_MARINE)
			linked_supply_controller = GLOB.supply_controller
		if(FACTION_UPP)
			linked_supply_controller = GLOB.supply_controller_upp
		else
			linked_supply_controller = GLOB.supply_controller
	linked_supply_controller.shuttle = src
	elevator_animation = new()
	elevator_animation.pixel_x = 160 //Matches the slope on the sprite.
	elevator_animation.pixel_y = -80
	if(pick_loc())
		Elevator_x = pick_loc().x
		Elevator_y = pick_loc().y
		Elevator_z = pick_loc().z
		the_pit = new /obj/effect/elevator(locate(Elevator_x,Elevator_y,Elevator_z))
		the_pit.vis_contents += elevator_animation

/datum/shuttle/ferry/supply/short_jump(area/origin, area/destination)
	if(moving_status != SHUTTLE_IDLE)
		return

	if(isnull(location))
		return

	recharging = 1

	if(!destination)
		destination = get_location_area(!location)
	if(!origin)
		origin = get_location_area(location)

	//it would be cool to play a sound here
	moving_status = SHUTTLE_WARMUP
	spawn(warmup_time)
		if (moving_status == SHUTTLE_IDLE)
			return //someone cancelled the launch

		if (at_station())
			raise_railings()
			sleep(12)
			if(forbidden_atoms_check())
				//cancel the launch because of forbidden atoms. announce over supply channel?
				moving_status = SHUTTLE_IDLE
				playsound(locate(Elevator_x,Elevator_y,Elevator_z), 'sound/machines/buzz-two.ogg', 50, 0)
				lower_railings()
				return
		else //at centcom
			linked_supply_controller.buy()

		//We pretend it's a long_jump by making the shuttle stay at centcom for the "in-transit" period.
		var/area/away_area = get_location_area(away_location)
		moving_status = SHUTTLE_INTRANSIT

		/*We attach the turfs in our starting area to the vis_contents overlay. The elevator effect procs will animate this. If we're going down, the stuff will instantly be
		teleported and then cosmetically animated as lowering; otherwise, it will be animated as raising, then teleported afterwards. Either way, it's all on the admin level.*/
		var/lowest_x
		var/highest_x
		var/lowest_y
		var/highest_y
		for(var/turf/T in away_area)
			var/obj/turf_holder_for_vis_contents/thing = new()
			T.vis_flags &= ~VIS_INHERIT_PLANE
			thing.vis_contents += T
			elevator_animation.vis_contents += thing
			if(lowest_x == null)
				lowest_x = T.x
			else if(T.x < lowest_x)
				lowest_x = T.x

			if(highest_x == null)
				highest_x = T.x
			else if(T.x > highest_x)
				highest_x = T.x

			if(lowest_y == null)
				lowest_y = T.y
			else if(T.y < lowest_y)
				lowest_y = T.y

			if(highest_y == null)
				highest_y = T.y
			else if(T.y > highest_y)
				highest_y = T.y

		for(var/obj/turf_holder_for_vis_contents/thing in elevator_animation.vis_contents)
			var/turf/T = locate(/turf) in thing.vis_contents
			if(!T)
				continue
			thing.pixel_x = (T.x - lowest_x) * world.icon_size
			thing.pixel_y = (T.y - lowest_y) * world.icon_size

		/*
		for(var/turf/vis_turf in elevator_animation.vis_contents)
			for(var/atom/movable/vis_content in vis_turf.contents)
				vis_content.blocks_emissive = EMISSIVE_BLOCK_NONE
				vis_content.update_emissive_block()*/

		if (origin != away_area)
			playsound(locate(Elevator_x,Elevator_y,Elevator_z), 'sound/machines/asrs_lowering.ogg', 50, 0)
			move(origin, away_area)
			the_pit.forceMove(locate(Elevator_x,Elevator_y, Elevator_z))
			animate(elevator_animation, pixel_x = 160, pixel_y = -80, time = 2 SECONDS)
			start_gears(SOUTH)
			sleep(21)
			sleep(70)
		else
			playsound(locate(Elevator_x,Elevator_y,Elevator_z), 'sound/machines/asrs_raising.ogg', 50, 0)
			start_gears(NORTH)
			sleep(70)
			animate(elevator_animation, pixel_x = 0, pixel_y = 0, time = 2 SECONDS)
			sleep(2 SECONDS)
			the_pit.moveToNullspace()
			move(away_area, destination)

		moving_status = SHUTTLE_IDLE
		stop_gears()

		for(var/turf/vis_turf in elevator_animation.vis_contents)
			for(var/atom/movable/vis_content in vis_turf.contents)
				vis_content.blocks_emissive = initial(vis_content.blocks_emissive)
				vis_content.update_emissive_block()

		elevator_animation.vis_contents.Cut()

		if (!at_station()) //at centcom
			handle_sell()
		else
			lower_railings()

		spawn(0)
			recharging = 0

/datum/shuttle/ferry/supply/proc/handle_sell()
	linked_supply_controller.sell() // fix this make it expandable

// returns 1 if the supply shuttle should be prevented from moving because it contains forbidden atoms
/datum/shuttle/ferry/supply/proc/forbidden_atoms_check()
	if (!at_station())
		return 0 //if badmins want to send mobs or a nuke on the supply shuttle from centcom we don't care

	return linked_supply_controller.forbidden_atoms_check(get_location_area())

/datum/shuttle/ferry/supply/proc/at_station()
	return (!location)

//returns 1 if the shuttle is idle and we can still mess with the cargo shopping list
/datum/shuttle/ferry/supply/proc/idle()
	return (moving_status == SHUTTLE_IDLE)

/datum/shuttle/ferry/supply/proc/raise_railings()
	var/effective = 0
	for(var/obj/structure/machinery/door/poddoor/M in GLOB.machines)
		if(M.id == railing_id && !M.density)
			effective = 1
			spawn()
				M.close()
	if(effective)
		playsound(locate(Elevator_x,Elevator_y,Elevator_z), 'sound/machines/elevator_openclose.ogg', 50, 0)

/datum/shuttle/ferry/supply/proc/lower_railings()
	var/effective = 0
	for(var/obj/structure/machinery/door/poddoor/M in GLOB.machines)
		if(M.id == railing_id && M.density)
			effective = 1
			INVOKE_ASYNC(M, TYPE_PROC_REF(/obj/structure/machinery/door, open))
	if(effective)
		playsound(locate(Elevator_x,Elevator_y,Elevator_z), 'sound/machines/elevator_openclose.ogg', 50, 0)

/datum/shuttle/ferry/supply/proc/start_gears(direction = 1)
	for(var/obj/structure/machinery/gear/M in GLOB.machines)
		if(M.id == gear_id)
			spawn()
				M.icon_state = "gear_moving"
				M.setDir(direction)

/datum/shuttle/ferry/supply/proc/stop_gears()
	for(var/obj/structure/machinery/gear/M in GLOB.machines)
		if(M.id == gear_id)
			spawn()
				M.icon_state = "gear"
