/obj/effect/fun_balloon
	name = "fun balloon"
	desc = ""
	icon = 'icons/obj/balloons.dmi'
	icon_state = "syndballoon"
	anchored = TRUE
	var/popped = FALSE

/obj/effect/fun_balloon/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/effect/fun_balloon/Destroy()
	SSobj.processing -= src
	. = ..()

/obj/effect/fun_balloon/process()
	if(!popped && check() && !QDELETED(src))
		popped = TRUE
		effect()
		pop()

/obj/effect/fun_balloon/proc/check()
	return FALSE

/obj/effect/fun_balloon/proc/effect()
	return

/obj/effect/fun_balloon/proc/pop()
	visible_message(span_notice("[src] pops!"))
	playsound(get_turf(src), 'sound/blank.ogg', 50, TRUE, -1)
	qdel(src)

//ATTACK GHOST IGNORING PARENT RETURN VALUE
/obj/effect/fun_balloon/attack_ghost(mob/user)
	if(!user.client || !user.client.holder || popped)
		return
	var/confirmation = alert("Pop [src]?","Fun Balloon","Yes","No")
	if(confirmation == "Yes" && !popped)
		popped = TRUE
		effect()
		pop()

/obj/effect/fun_balloon/sentience
	name = "sentience fun balloon"
	desc = ""
	var/effect_range = 3
	var/group_name = "a bunch of giant spiders"

/obj/effect/fun_balloon/sentience/effect()
	var/list/bodies = list()
	for(var/mob/living/M in range(effect_range, get_turf(src)))
		bodies += M

	var/question = "Would you like to be [group_name]?"
	var/list/candidates = pollCandidatesForMobs(question, ROLE_PAI, null, FALSE, 100, bodies)
	while(LAZYLEN(candidates) && LAZYLEN(bodies))
		var/mob/dead/observer/C = pick_n_take(candidates)
		var/mob/living/body = pick_n_take(bodies)

		to_chat(body, span_warning("My mob has been taken over by a ghost!"))
		message_admins("[key_name_admin(C)] has taken control of ([key_name_admin(body)])")
		body.ghostize(0)
		body.key = C.key
		new /obj/effect/temp_visual/gravpush(get_turf(body))

/obj/effect/fun_balloon/scatter
	name = "scatter fun balloon"
	desc = ""
	var/effect_range = 5

/obj/effect/fun_balloon/scatter/effect()
	for(var/mob/living/M in range(effect_range, get_turf(src)))
		var/turf/T = find_safe_turf()
		new /obj/effect/temp_visual/gravpush(get_turf(M))
		M.forceMove(T)
		to_chat(M, span_notice("Pop!"))

/obj/effect/station_crash
	name = "station crash"
	desc = ""
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "syndballoon"
	anchored = TRUE

/obj/effect/station_crash/Initialize()
	..()
	for(var/S in SSshuttle.stationary)
		var/obj/docking_port/stationary/SM = S
		if(SM.id == "emergency_home")
			var/new_dir = turn(SM.dir, 180)
			SM.forceMove(get_ranged_target_turf(SM, new_dir, rand(3,15)))
			break
	return INITIALIZE_HINT_QDEL


//Arena

/obj/effect/forcefield/arena_shuttle
	name = "portal"
	timeleft = 0
	var/list/warp_points

/obj/effect/forcefield/arena_shuttle/Initialize()
	. = ..()
	for(var/obj/effect/landmark/shuttle_arena_safe/exit in GLOB.landmarks_list)
		warp_points += exit

/obj/effect/forcefield/arena_shuttle/Bumped(atom/movable/AM)
	if(!isliving(AM))
		return

	var/mob/living/L = AM
	if(L.pulling && istype(L.pulling, /obj/item/bodypart/head))
		to_chat(L, span_notice("My offering is accepted. You may pass."))
		qdel(L.pulling)
		var/turf/LA = get_turf(pick(warp_points))
		L.forceMove(LA)
		L.hallucination = 0
		to_chat(L, span_reallybigredtext("The battle is won. Your bloodlust subsides."))
		for(var/obj/item/twohanded/required/chainsaw/doomslayer/chainsaw in L)
			qdel(chainsaw)
	else
		to_chat(L, span_warning("I are not yet worthy of passing. Drag a severed head to the barrier to be allowed entry to the hall of champions."))

/obj/effect/landmark/shuttle_arena_safe
	name = "hall of champions"
	desc = ""

/obj/effect/landmark/shuttle_arena_entrance
	name = "the arena"
	desc = ""


/obj/effect/forcefield/arena_shuttle_entrance
	name = "portal"
	timeleft = 0
	var/list/warp_points = list()

/obj/effect/forcefield/arena_shuttle_entrance/Bumped(atom/movable/AM)
	if(!isliving(AM))
		return

	if(!warp_points.len)
		for(var/obj/effect/landmark/shuttle_arena_entrance/S in GLOB.landmarks_list)
			warp_points |= S

	var/obj/effect/landmark/LA = pick(warp_points)
	var/mob/living/M = AM
	M.forceMove(get_turf(LA))
	to_chat(M, span_reallybigredtext("You're trapped in a deadly arena! To escape, you'll need to drag a severed head to the escape portals."))
	INVOKE_ASYNC(src, PROC_REF(do_bloodbath), M)

/obj/effect/forcefield/arena_shuttle_entrance/proc/do_bloodbath(mob/living/L)
	var/obj/effect/mine/pickup/bloodbath/B = new (L)
	B.mineEffect(L)
