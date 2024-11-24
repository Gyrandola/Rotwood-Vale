/obj/structure/window
	name = "window"
	desc = ""
	icon_state = "window"
	density = TRUE
	layer = ABOVE_OBJ_LAYER //Just above doors
	pressure_resistance = 4*ONE_ATMOSPHERE
	anchored = TRUE //initially is 0 for tile smoothing
	flags_1 = ON_BORDER_1
	max_integrity = 25
	can_be_unanchored = TRUE
	resistance_flags = ACID_PROOF
	armor = list("blunt" = 0, "slash" = 0, "stab" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 80, "acid" = 100)
	CanAtmosPass = ATMOS_PASS_PROC
	rad_insulation = RAD_VERY_LIGHT_INSULATION
	rad_flags = RAD_PROTECT_CONTENTS
	var/ini_dir = null
	var/state = WINDOW_OUT_OF_FRAME
	var/reinf = FALSE
	var/heat_resistance = 800
	var/decon_speed = 30
	var/wtype = "glass"
	var/fulltile = FALSE
	var/glass_type = /obj/item/stack/sheet/glass
	var/glass_amount = 1
	var/mutable_appearance/crack_overlay
	var/real_explosion_block	//ignore this, just use explosion_block
	var/breaksound = "shatter"
	var/hitsound = 'sound/blank.ogg'


/obj/structure/window/examine(mob/user)
	. = ..()
	if(reinf)
		if(anchored && state == WINDOW_SCREWED_TO_FRAME)
			. += span_notice("The window is <b>screwed</b> to the frame.")
		else if(anchored && state == WINDOW_IN_FRAME)
			. += span_notice("The window is <i>unscrewed</i> but <b>pried</b> into the frame.")
		else if(anchored && state == WINDOW_OUT_OF_FRAME)
			. += span_notice("The window is out of the frame, but could be <i>pried</i> in. It is <b>screwed</b> to the floor.")
		else if(!anchored)
			. += span_notice("The window is <i>unscrewed</i> from the floor, and could be deconstructed by <b>wrenching</b>.")
	else
		if(anchored)
			. += span_notice("The window is <b>screwed</b> to the floor.")
		else
			. += span_notice("The window is <i>unscrewed</i> from the floor, and could be deconstructed by <b>wrenching</b>.")

/obj/structure/window/Initialize(mapload, direct)
	. = ..()
	if(direct)
		setDir(direct)
	if(reinf && anchored)
		state = RWINDOW_SECURE

	ini_dir = dir
	air_update_turf(1)

	if(fulltile)
		setDir()

	//windows only block while reinforced and fulltile, so we'll use the proc
	real_explosion_block = explosion_block
	explosion_block = EXPLOSION_BLOCK_PROC

/obj/structure/window/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/simple_rotation,ROTATION_ALTCLICK | ROTATION_CLOCKWISE | ROTATION_COUNTERCLOCKWISE | ROTATION_VERBS ,null,CALLBACK(src, PROC_REF(can_be_rotated)),CALLBACK(src,PROC_REF(after_rotation)))

/obj/structure/window/narsie_act()
	add_atom_colour(NARSIE_WINDOW_COLOUR, FIXED_COLOUR_PRIORITY)

/obj/structure/window/singularity_pull()

/obj/structure/window/setDir(direct)
	if(!fulltile)
		..()
	else
		..(FULLTILE_WINDOW_DIR)

/obj/structure/window/CanPass(atom/movable/mover, turf/target)
	if(istype(mover) && (mover.pass_flags & PASSGLASS))
		return 1
	if(dir == FULLTILE_WINDOW_DIR)
		return 0	//full tile window, you can't move into it!
	if(get_dir(loc, target) == dir)
		return !density
	if(istype(mover, /obj/structure/window))
		var/obj/structure/window/W = mover
		if(!valid_window_location(loc, W.ini_dir))
			return FALSE
	return 1

/obj/structure/window/CheckExit(atom/movable/O, turf/target)
	if(istype(O) && (O.pass_flags & PASSGLASS))
		return 1
	if(get_dir(O.loc, target) == dir)
		return 0
	return 1

/obj/structure/window/attack_tk(mob/user)
	user.changeNext_move(CLICK_CD_MELEE)
	user.visible_message(span_notice("Something knocks on [src]."))
	add_fingerprint(user)
	playsound(src, 'sound/blank.ogg', 50, TRUE)

/obj/structure/window/attack_hulk(mob/living/carbon/human/user, does_attack_animation = 0)
	if(!can_be_reached(user))
		return
	. = ..()

/obj/structure/window/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	if(!can_be_reached(user))
		return
	user.changeNext_move(CLICK_CD_MELEE)
	user.visible_message(span_notice("[user] knocks on [src]."), \
		span_notice("I knock on [src]."))
	add_fingerprint(user)
	playsound(src, 'sound/blank.ogg', 50, TRUE)

/obj/structure/window/attack_paw(mob/user)
	return attack_hand(user)

/obj/structure/window/attack_generic(mob/user, damage_amount = 0, damage_type = BRUTE, damage_flag = 0, sound_effect = 1)	//used by attack_alien, attack_animal, and attack_slime
	if(!can_be_reached(user))
		return
	..()

/obj/structure/window/attackby(obj/item/I, mob/living/user, params)
	if(!can_be_reached(user))
		return 1 //skip the afterattack

	add_fingerprint(user)

	if(I.tool_behaviour == TOOL_WELDER && user.used_intent.type == INTENT_HELP)
		if(obj_integrity < max_integrity)
			if(!I.tool_start_check(user, amount=0))
				return

			to_chat(user, span_notice("I begin repairing [src]..."))
			if(I.use_tool(src, user, 40, volume=50))
				obj_integrity = max_integrity
				update_nearby_icons()
				to_chat(user, span_notice("I repair [src]."))
		else
			to_chat(user, span_warning("[src] is already in good condition!"))
		return

	if(!(flags_1&NODECONSTRUCT_1) && !(reinf && state >= RWINDOW_FRAME_BOLTED))
		if(I.tool_behaviour == TOOL_SCREWDRIVER)
			to_chat(user, span_notice("I begin to [anchored ? "unscrew the window from":"screw the window to"] the floor..."))
			if(I.use_tool(src, user, decon_speed, volume = 75, extra_checks = CALLBACK(src, PROC_REF(check_anchored), anchored)))
				setAnchored(!anchored)
				to_chat(user, span_notice("I [anchored ? "fasten the window to":"unfasten the window from"] the floor."))
			return
		else if(I.tool_behaviour == TOOL_WRENCH && !anchored)
			to_chat(user, span_notice("I begin to disassemble [src]..."))
			if(I.use_tool(src, user, decon_speed, volume = 75, extra_checks = CALLBACK(src, PROC_REF(check_state_and_anchored), state, anchored)))
				var/obj/item/stack/sheet/G = new glass_type(user.loc, glass_amount)
				G.add_fingerprint(user)
				playsound(src, 'sound/blank.ogg', 50, TRUE)
				to_chat(user, span_notice("I successfully disassemble [src]."))
				qdel(src)
			return
		else if(I.tool_behaviour == TOOL_CROWBAR && reinf && (state == WINDOW_OUT_OF_FRAME) && anchored)
			to_chat(user, span_notice("I begin to lever the window into the frame..."))
			if(I.use_tool(src, user, 100, volume = 75, extra_checks = CALLBACK(src, PROC_REF(check_state_and_anchored), state, anchored)))
				state = RWINDOW_SECURE
				to_chat(user, span_notice("I pry the window into the frame."))
			return

	return ..()

/obj/structure/window/setAnchored(anchorvalue)
	..()
	air_update_turf(TRUE)
	update_nearby_icons()

/obj/structure/window/proc/check_state(checked_state)
	if(state == checked_state)
		return TRUE

/obj/structure/window/proc/check_anchored(checked_anchored)
	if(anchored == checked_anchored)
		return TRUE

/obj/structure/window/proc/check_state_and_anchored(checked_state, checked_anchored)
	return check_state(checked_state) && check_anchored(checked_anchored)

/obj/structure/window/proc/can_be_reached(mob/user)
	if(!fulltile)
		if(get_dir(user,src) & dir)
			for(var/obj/O in loc)
				if(!O.CanPass(user, user.loc, 1))
					return 0
	return 1

/obj/structure/window/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1)
	. = ..()
	if(.) //received damage
		update_nearby_icons()

/obj/structure/window/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			if(damage_amount)
				playsound(src, hitsound, 75, TRUE)
			else
				playsound(src, 'sound/blank.ogg', 50, TRUE)
		if(BURN)
			playsound(src, 'sound/blank.ogg', 100, TRUE)


/obj/structure/window/deconstruct(disassembled = TRUE)
	if(QDELETED(src))
		return
	if(!disassembled)
		playsound(src, breaksound, 70, TRUE)
		if(!(flags_1 & NODECONSTRUCT_1))
			for(var/obj/item/shard/debris in spawnDebris(drop_location()))
				transfer_fingerprints_to(debris) // transfer fingerprints to shards only
	qdel(src)
	update_nearby_icons()

/obj/structure/window/proc/spawnDebris(location)
	. = list()
	. += new /obj/item/shard(location)
	. += new /obj/effect/decal/cleanable/glass(location)
	if (reinf)
		. += new /obj/item/stack/rods(location, (fulltile ? 2 : 1))
	if (fulltile)
		. += new /obj/item/shard(location)

/obj/structure/window/proc/can_be_rotated(mob/user,rotation_type)
	if(anchored)
		to_chat(user, span_warning("[src] cannot be rotated while it is fastened to the floor!"))
		return FALSE

	var/target_dir = turn(dir, rotation_type == ROTATION_CLOCKWISE ? -90 : 90)

	if(!valid_window_location(loc, target_dir))
		to_chat(user, span_warning("[src] cannot be rotated in that direction!"))
		return FALSE
	return TRUE

/obj/structure/window/proc/after_rotation(mob/user,rotation_type)
	air_update_turf(1)
	ini_dir = dir
	add_fingerprint(user)

/obj/structure/window/Destroy()
	density = FALSE
	air_update_turf(1)
	update_nearby_icons()
	return ..()


/obj/structure/window/Move()
	var/turf/T = loc
	. = ..()
	setDir(ini_dir)
	move_update_air(T)

/obj/structure/window/CanAtmosPass(turf/T)
	if(!anchored || !density)
		return TRUE
	return !(FULLTILE_WINDOW_DIR == dir || dir == get_dir(loc, T))

//This proc is used to update the icons of nearby windows.
/obj/structure/window/proc/update_nearby_icons()
	update_icon()
	if(smooth)
		queue_smooth_neighbors(src)

//merges adjacent full-tile windows into one
/obj/structure/window/update_icon()
	if(!QDELETED(src))
		if(!fulltile)
			return

		var/ratio = obj_integrity / max_integrity
		ratio = CEILING(ratio*4, 1) * 25

		if(smooth)
			queue_smooth(src)

		cut_overlay(crack_overlay)
		if(ratio > 75)
			return
		crack_overlay = mutable_appearance('icons/obj/structures.dmi', "damage[ratio]", -(layer+0.1))
		add_overlay(crack_overlay)

/obj/structure/window/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)

	if(exposed_temperature > (T0C + heat_resistance))
		take_damage(round(exposed_volume / 100), BURN, 0, 0)
	..()

/obj/structure/window/get_dumping_location(obj/item/storage/source,mob/user)
	return null

/obj/structure/window/CanAStarPass(ID, to_dir)
	if(!density)
		return 1
	if((dir == FULLTILE_WINDOW_DIR) || (dir == to_dir))
		return 0

	return 1

/obj/structure/window/GetExplosionBlock()
	return reinf && fulltile ? real_explosion_block : 0

/obj/structure/window/spawner/east
	dir = EAST

/obj/structure/window/spawner/west
	dir = WEST

/obj/structure/window/spawner/north
	dir = NORTH

/obj/structure/window/unanchored
	anchored = FALSE

/obj/structure/window/reinforced
	name = "reinforced window"
	desc = ""
	icon_state = "rwindow"
	reinf = TRUE
	heat_resistance = 1600
	armor = list("blunt" = 80, "slash" = 80, "stab" = 80, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 25, "bio" = 100, "rad" = 100, "fire" = 80, "acid" = 100)
	max_integrity = 75
	explosion_block = 1
	damage_deflection = 11
	state = RWINDOW_SECURE
	glass_type = /obj/item/stack/sheet/rglass
	rad_insulation = RAD_HEAVY_INSULATION

//this is shitcode but all of construction is shitcode and needs a refactor, it works for now
//If you find this like 4 years later and construction still hasn't been refactored, I'm so sorry for this
/obj/structure/window/reinforced/attackby(obj/item/I, mob/living/user, params)
	switch(state)
		if(RWINDOW_SECURE)
			if(I.tool_behaviour == TOOL_WELDER && user.used_intent.type == INTENT_HARM)
				user.visible_message(span_notice("[user] holds \the [I] to the security screws on \the [src]..."),
										span_notice("I begin heating the security screws on \the [src]..."))
				if(I.use_tool(src, user, 150, volume = 100))
					to_chat(user, span_notice("The security bolts are glowing white hot and look ready to be removed."))
					state = RWINDOW_BOLTS_HEATED
					addtimer(CALLBACK(src, PROC_REF(cool_bolts)), 300)
				return
		if(RWINDOW_BOLTS_HEATED)
			if(I.tool_behaviour == TOOL_SCREWDRIVER)
				user.visible_message(span_notice("[user] digs into the heated security screws and starts removing them..."),
										span_notice("I dig into the heated screws hard and they start turning..."))
				if(I.use_tool(src, user, 50, volume = 50))
					state = RWINDOW_BOLTS_OUT
					to_chat(user, span_notice("The screws come out, and a gap forms around the edge of the pane."))
				return
		if(RWINDOW_BOLTS_OUT)
			if(I.tool_behaviour == TOOL_CROWBAR)
				user.visible_message(span_notice("[user] wedges \the [I] into the gap in the frame and starts prying..."),
										span_notice("I wedge \the [I] into the gap in the frame and start prying..."))
				if(I.use_tool(src, user, 40, volume = 50))
					state = RWINDOW_POPPED
					to_chat(user, span_notice("The panel pops out of the frame, exposing some thin metal bars that looks like they can be cut."))
				return
		if(RWINDOW_POPPED)
			if(I.tool_behaviour == TOOL_WIRECUTTER)
				user.visible_message(span_notice("[user] starts cutting the exposed bars on \the [src]..."),
										span_notice("I start cutting the exposed bars on \the [src]"))
				if(I.use_tool(src, user, 20, volume = 50))
					state = RWINDOW_BARS_CUT
					to_chat(user, span_notice("The panels falls out of the way exposing the frame bolts."))
				return
		if(RWINDOW_BARS_CUT)
			if(I.tool_behaviour == TOOL_WRENCH)
				user.visible_message(span_notice("[user] starts unfastening \the [src] from the frame..."),
					span_notice("I start unfastening the bolts from the frame..."))
				if(I.use_tool(src, user, 40, volume = 50))
					to_chat(user, span_notice("I unscrew the bolts from the frame and the window pops loose."))
					state = WINDOW_OUT_OF_FRAME
					setAnchored(FALSE)
				return
	return ..()

/obj/structure/window/proc/cool_bolts()
	if(state == RWINDOW_BOLTS_HEATED)
		state = RWINDOW_SECURE
		visible_message(span_notice("The bolts on \the [src] look like they've cooled off..."))

/obj/structure/window/reinforced/examine(mob/user)
	. = ..()
	switch(state)
		if(RWINDOW_SECURE)
			. += span_notice("It's been screwed in with one way screws, you'd need to <b>heat them</b> to have any chance of backing them out.")
		if(RWINDOW_BOLTS_HEATED)
			. += span_notice("The screws are glowing white hot, and you'll likely be able to <b>unscrew them</b> now.")
		if(RWINDOW_BOLTS_OUT)
			. += span_notice("The screws have been removed, revealing a small gap you could fit a <b>prying tool</b> in.")
		if(RWINDOW_POPPED)
			. += span_notice("The main plate of the window has popped out of the frame, exposing some bars that look like they can be <b>cut</b>.")
		if(RWINDOW_BARS_CUT)
			. += span_notice("The main pane can be easily moved out of the way to reveal some <b>bolts</b> holding the frame in.")

/obj/structure/window/reinforced/spawner/east
	dir = EAST

/obj/structure/window/reinforced/spawner/west
	dir = WEST

/obj/structure/window/reinforced/spawner/north
	dir = NORTH

/obj/structure/window/reinforced/unanchored
	anchored = FALSE
	state = WINDOW_OUT_OF_FRAME

/obj/structure/window/plasma
	name = "plasma window"
	desc = ""
	icon_state = "plasmawindow"
	reinf = FALSE
	heat_resistance = 25000
	armor = list("blunt" = 80, "slash" = 60, "stab" = 40, "bullet" = 5, "laser" = 0, "energy" = 0, "bomb" = 45, "bio" = 100, "rad" = 100, "fire" = 99, "acid" = 100)
	max_integrity = 200
	explosion_block = 1
	glass_type = /obj/item/stack/sheet/plasmaglass
	rad_insulation = RAD_NO_INSULATION

/obj/structure/window/plasma/spawnDebris(location)
	. = list()
	. += new /obj/item/shard/plasma(location)
	. += new /obj/effect/decal/cleanable/glass/plasma(location)
	if (reinf)
		. += new /obj/item/stack/rods(location, (fulltile ? 2 : 1))
	if (fulltile)
		. += new /obj/item/shard/plasma(location)

/obj/structure/window/plasma/spawner/east
	dir = EAST

/obj/structure/window/plasma/spawner/west
	dir = WEST

/obj/structure/window/plasma/spawner/north
	dir = NORTH

/obj/structure/window/plasma/unanchored
	anchored = FALSE

/obj/structure/window/plasma/reinforced
	name = "reinforced plasma window"
	desc = ""
	icon_state = "plasmarwindow"
	reinf = TRUE
	heat_resistance = 50000
	armor = list("blunt" = 80, "slash" = 50, "stab" = 25, "bullet" = 20, "laser" = 0, "energy" = 0, "bomb" = 60, "bio" = 100, "rad" = 100, "fire" = 99, "acid" = 100)
	max_integrity = 500
	damage_deflection = 21
	explosion_block = 2
	glass_type = /obj/item/stack/sheet/plasmarglass

//entirely copypasted code
//take this out when construction is made a component or otherwise modularized in some way
/obj/structure/window/plasma/reinforced/attackby(obj/item/I, mob/living/user, params)
	switch(state)
		if(RWINDOW_SECURE)
			if(I.tool_behaviour == TOOL_WELDER && user.used_intent.type == INTENT_HARM)
				user.visible_message(span_notice("[user] holds \the [I] to the security screws on \the [src]..."),
										span_notice("I begin heating the security screws on \the [src]..."))
				if(I.use_tool(src, user, 180, volume = 100))
					to_chat(user, span_notice("The security screws are glowing white hot and look ready to be removed."))
					state = RWINDOW_BOLTS_HEATED
					addtimer(CALLBACK(src, PROC_REF(cool_bolts)), 300)
				return
		if(RWINDOW_BOLTS_HEATED)
			if(I.tool_behaviour == TOOL_SCREWDRIVER)
				user.visible_message(span_notice("[user] digs into the heated security screws and starts removing them..."),
										span_notice("I dig into the heated screws hard and they start turning..."))
				if(I.use_tool(src, user, 80, volume = 50))
					state = RWINDOW_BOLTS_OUT
					to_chat(user, span_notice("The screws come out, and a gap forms around the edge of the pane."))
				return
		if(RWINDOW_BOLTS_OUT)
			if(I.tool_behaviour == TOOL_CROWBAR)
				user.visible_message(span_notice("[user] wedges \the [I] into the gap in the frame and starts prying..."),
										span_notice("I wedge \the [I] into the gap in the frame and start prying..."))
				if(I.use_tool(src, user, 50, volume = 50))
					state = RWINDOW_POPPED
					to_chat(user, span_notice("The panel pops out of the frame, exposing some thin metal bars that looks like they can be cut."))
				return
		if(RWINDOW_POPPED)
			if(I.tool_behaviour == TOOL_WIRECUTTER)
				user.visible_message(span_notice("[user] starts cutting the exposed bars on \the [src]..."),
										span_notice("I start cutting the exposed bars on \the [src]"))
				if(I.use_tool(src, user, 30, volume = 50))
					state = RWINDOW_BARS_CUT
					to_chat(user, span_notice("The panels falls out of the way exposing the frame bolts."))
				return
		if(RWINDOW_BARS_CUT)
			if(I.tool_behaviour == TOOL_WRENCH)
				user.visible_message(span_notice("[user] starts unfastening \the [src] from the frame..."),
					span_notice("I start unfastening the bolts from the frame..."))
				if(I.use_tool(src, user, 50, volume = 50))
					to_chat(user, span_notice("I unfasten the bolts from the frame and the window pops loose."))
					state = WINDOW_OUT_OF_FRAME
					setAnchored(FALSE)
				return
	return ..()

/obj/structure/window/plasma/reinforced/examine(mob/user)
	. = ..()
	switch(state)
		if(RWINDOW_SECURE)
			. += span_notice("It's been screwed in with one way screws, you'd need to <b>heat them</b> to have any chance of backing them out.")
		if(RWINDOW_BOLTS_HEATED)
			. += span_notice("The screws are glowing white hot, and you'll likely be able to <b>unscrew them</b> now.")
		if(RWINDOW_BOLTS_OUT)
			. += span_notice("The screws have been removed, revealing a small gap you could fit a <b>prying tool</b> in.")
		if(RWINDOW_POPPED)
			. += span_notice("The main plate of the window has popped out of the frame, exposing some bars that look like they can be <b>cut</b>.")
		if(RWINDOW_BARS_CUT)
			. += span_notice("The main pane can be easily moved out of the way to reveal some <b>bolts</b> holding the frame in.")

/obj/structure/window/plasma/reinforced/spawner/east
	dir = EAST

/obj/structure/window/plasma/reinforced/spawner/west
	dir = WEST

/obj/structure/window/plasma/reinforced/spawner/north
	dir = NORTH

/obj/structure/window/plasma/reinforced/unanchored
	anchored = FALSE
	state = WINDOW_OUT_OF_FRAME

/obj/structure/window/reinforced/tinted
	name = "tinted window"
	icon_state = "twindow"
	opacity = 1
/obj/structure/window/reinforced/tinted/frosted
	name = "frosted window"
	icon_state = "fwindow"

/* Full Tile Windows (more obj_integrity) */

/obj/structure/window/fulltile
	icon = 'icons/obj/smooth_structures/window.dmi'
	icon_state = "window"
	dir = FULLTILE_WINDOW_DIR
	max_integrity = 50
	fulltile = TRUE
	flags_1 = PREVENT_CLICK_UNDER_1
	smooth = SMOOTH_TRUE
	canSmoothWith = list(/obj/structure/window/fulltile, /obj/structure/window/reinforced/fulltile, /obj/structure/window/reinforced/tinted/fulltile, /obj/structure/window/plasma/fulltile, /obj/structure/window/plasma/reinforced/fulltile)
	glass_amount = 2

/obj/structure/window/fulltile/unanchored
	anchored = FALSE

/obj/structure/window/plasma/fulltile
	icon = 'icons/obj/smooth_structures/plasma_window.dmi'
	icon_state = "plasmawindow"
	dir = FULLTILE_WINDOW_DIR
	max_integrity = 300
	fulltile = TRUE
	flags_1 = PREVENT_CLICK_UNDER_1
	smooth = SMOOTH_TRUE
	canSmoothWith = list(/obj/structure/window/fulltile, /obj/structure/window/reinforced/fulltile, /obj/structure/window/reinforced/tinted/fulltile, /obj/structure/window/plasma/fulltile, /obj/structure/window/plasma/reinforced/fulltile)
	glass_amount = 2

/obj/structure/window/plasma/fulltile/unanchored
	anchored = FALSE

/obj/structure/window/plasma/reinforced/fulltile
	icon = 'icons/obj/smooth_structures/rplasma_window.dmi'
	icon_state = "rplasmawindow"
	dir = FULLTILE_WINDOW_DIR
	state = RWINDOW_SECURE
	max_integrity = 1000
	fulltile = TRUE
	flags_1 = PREVENT_CLICK_UNDER_1
	smooth = SMOOTH_TRUE
	glass_amount = 2

/obj/structure/window/plasma/reinforced/fulltile/unanchored
	anchored = FALSE
	state = WINDOW_OUT_OF_FRAME

/obj/structure/window/reinforced/fulltile
	icon = 'icons/obj/smooth_structures/reinforced_window.dmi'
	icon_state = "r_window"
	dir = FULLTILE_WINDOW_DIR
	max_integrity = 150
	fulltile = TRUE
	flags_1 = PREVENT_CLICK_UNDER_1
	smooth = SMOOTH_TRUE
	state = RWINDOW_SECURE
	canSmoothWith = list(/obj/structure/window/fulltile, /obj/structure/window/reinforced/fulltile, /obj/structure/window/reinforced/tinted/fulltile, /obj/structure/window/plasma/fulltile, /obj/structure/window/plasma/reinforced/fulltile)
	level = 3
	glass_amount = 2

/obj/structure/window/reinforced/fulltile/unanchored
	anchored = FALSE
	state = WINDOW_OUT_OF_FRAME

/obj/structure/window/reinforced/tinted/fulltile
	icon = 'icons/obj/smooth_structures/tinted_window.dmi'
	icon_state = "tinted_window"
	dir = FULLTILE_WINDOW_DIR
	fulltile = TRUE
	flags_1 = PREVENT_CLICK_UNDER_1
	smooth = SMOOTH_TRUE
	canSmoothWith = list(/obj/structure/window/fulltile, /obj/structure/window/reinforced/fulltile, /obj/structure/window/reinforced/tinted/fulltile, /obj/structure/window/plasma/fulltile, /obj/structure/window/plasma/reinforced/fulltile)
	level = 3
	glass_amount = 2

/obj/structure/window/reinforced/fulltile/ice
	icon = 'icons/obj/smooth_structures/rice_window.dmi'
	icon_state = "ice_window"
	max_integrity = 150
	canSmoothWith = list(/obj/structure/window/fulltile, /obj/structure/window/reinforced/fulltile, /obj/structure/window/reinforced/tinted/fulltile, /obj/structure/window/plasma/fulltile, /obj/structure/window/plasma/reinforced/fulltile)
	level = 3
	glass_amount = 2

/obj/structure/window/shuttle
	name = "shuttle window"
	desc = ""
	icon = 'icons/obj/smooth_structures/shuttle_window.dmi'
	icon_state = "shuttle_window"
	dir = FULLTILE_WINDOW_DIR
	max_integrity = 150
	wtype = "shuttle"
	fulltile = TRUE
	flags_1 = PREVENT_CLICK_UNDER_1
	reinf = TRUE
	heat_resistance = 1600
	armor = list("blunt" = 90, "slash" = 60, "stab" = 40, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 50, "bio" = 100, "rad" = 100, "fire" = 80, "acid" = 100)
	smooth = SMOOTH_TRUE
	canSmoothWith = null
	explosion_block = 3
	level = 3
	glass_type = /obj/item/stack/sheet/titaniumglass
	glass_amount = 2

/obj/structure/window/shuttle/narsie_act()
	add_atom_colour("#3C3434", FIXED_COLOUR_PRIORITY)

/obj/structure/window/shuttle/tinted
	opacity = TRUE

/obj/structure/window/shuttle/unanchored
	anchored = FALSE

/obj/structure/window/plasma/reinforced/plastitanium
	name = "plastitanium window"
	desc = ""
	icon = 'icons/obj/smooth_structures/plastitanium_window.dmi'
	icon_state = "plastitanium_window"
	dir = FULLTILE_WINDOW_DIR
	max_integrity = 200
	wtype = "shuttle"
	fulltile = TRUE
	flags_1 = PREVENT_CLICK_UNDER_1
	heat_resistance = 1600
	armor = list("blunt" = 95, "slash" = 80, "stab" = 65, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 50, "bio" = 100, "rad" = 100, "fire" = 80, "acid" = 100)
	smooth = SMOOTH_TRUE
	canSmoothWith = null
	explosion_block = 3
	damage_deflection = 11 //The same as normal reinforced windows.
	level = 3
	glass_type = /obj/item/stack/sheet/plastitaniumglass
	glass_amount = 2
	rad_insulation = RAD_HEAVY_INSULATION

/obj/structure/window/plasma/reinforced/plastitanium/unanchored
	anchored = FALSE
	state = WINDOW_OUT_OF_FRAME

/obj/structure/window/paperframe
	name = "paper frame"
	desc = ""
	icon = 'icons/obj/smooth_structures/paperframes.dmi'
	icon_state = "frame"
	dir = FULLTILE_WINDOW_DIR
	opacity = TRUE
	max_integrity = 15
	fulltile = TRUE
	flags_1 = PREVENT_CLICK_UNDER_1
	smooth = SMOOTH_TRUE
	canSmoothWith = list(/obj/structure/window/paperframe, /obj/structure/mineral_door/paperframe)
	glass_amount = 2
	glass_type = /obj/item/stack/sheet/paperframes
	heat_resistance = 233
	decon_speed = 10
	CanAtmosPass = ATMOS_PASS_YES
	resistance_flags = FLAMMABLE
	armor = list("blunt" = 0, "slash" = 0, "stab" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 0, "acid" = 0)
	breaksound = 'sound/blank.ogg'
	hitsound = 'sound/blank.ogg'
	var/static/mutable_appearance/torn = mutable_appearance('icons/obj/smooth_structures/paperframes.dmi',icon_state = "torn", layer = ABOVE_OBJ_LAYER - 0.1)
	var/static/mutable_appearance/paper = mutable_appearance('icons/obj/smooth_structures/paperframes.dmi',icon_state = "paper", layer = ABOVE_OBJ_LAYER - 0.1)

/obj/structure/window/paperframe/Initialize()
	. = ..()
	update_icon()

/obj/structure/window/paperframe/examine(mob/user)
	. = ..()
	if(obj_integrity < max_integrity)
		. += span_info("It looks a bit damaged, you may be able to fix it with some <b>paper</b>.")

/obj/structure/window/paperframe/spawnDebris(location)
	. = list(new /obj/item/stack/sheet/mineral/wood(location))
	for (var/i in 1 to rand(1,4))
		. += new /obj/item/paper/natural(location)

/obj/structure/window/paperframe/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	add_fingerprint(user)
	if(user.used_intent.type != INTENT_HARM)
		user.changeNext_move(CLICK_CD_MELEE)
		user.visible_message(span_notice("[user] knocks on [src]."))
		playsound(src, "pageturn", 50, TRUE)
	else
		take_damage(4,BRUTE,"blunt", 0)
		playsound(src, hitsound, 50, TRUE)
		if(!QDELETED(src))
			user.visible_message(span_danger("[user] tears a hole in [src]."))
			update_icon()

/obj/structure/window/paperframe/update_icon()
	if(obj_integrity < max_integrity)
		cut_overlay(paper)
		add_overlay(torn)
		set_opacity(FALSE)
	else
		cut_overlay(torn)
		add_overlay(paper)
		set_opacity(TRUE)
	queue_smooth(src)


/obj/structure/window/paperframe/attackby(obj/item/W, mob/user)
	if(W.get_temperature())
		fire_act(W.get_temperature())
		return
	if(user.used_intent.type == INTENT_HARM)
		return ..()
	if(istype(W, /obj/item/paper) && obj_integrity < max_integrity)
		user.visible_message(span_notice("[user] starts to patch the holes in \the [src]."))
		if(do_after(user, 20, target = src))
			obj_integrity = min(obj_integrity+4,max_integrity)
			qdel(W)
			user.visible_message(span_notice("[user] patches some of the holes in \the [src]."))
			if(obj_integrity == max_integrity)
				update_icon()
			return
	..()
	update_icon()

/obj/structure/window/bronze
	name = "brass window"
	desc = ""
	icon = 'icons/obj/smooth_structures/clockwork_window.dmi'
	icon_state = "clockwork_window_single"
	glass_type = /obj/item/stack/tile/bronze

/obj/structure/window/bronze/unanchored
	anchored = FALSE

/obj/structure/window/bronze/fulltile
	icon_state = "clockwork_window"
	smooth = SMOOTH_TRUE
	canSmoothWith = null
	fulltile = TRUE
	flags_1 = PREVENT_CLICK_UNDER_1
	dir = FULLTILE_WINDOW_DIR
	max_integrity = 50
	glass_amount = 2

/obj/structure/window/bronze/fulltile/unanchored
	anchored = FALSE
