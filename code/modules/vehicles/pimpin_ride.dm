//PIMP-CART
/obj/vehicle/ridden/janicart
	name = "janicart (pimpin' ride)"
	desc = ""
	icon_state = "pussywagon"
	var/obj/item/storage/bag/trash/mybag = null
	var/floorbuffer = FALSE

/obj/vehicle/ridden/janicart/Initialize(mapload)
	. = ..()
	update_icon()
	var/datum/component/riding/D = LoadComponent(/datum/component/riding)
	D.set_riding_offsets(RIDING_OFFSET_ALL, list(TEXT_NORTH = list(0, 4), TEXT_SOUTH = list(0, 7), TEXT_EAST = list(-12, 7), TEXT_WEST = list( 12, 7)))

	if(floorbuffer)
		AddElement(/datum/element/cleaning)

/obj/vehicle/ridden/janicart/Destroy()
	if(mybag)
		qdel(mybag)
		mybag = null
	. = ..()

/obj/item/janiupgrade
	name = "floor buffer upgrade"
	desc = ""
	icon = 'icons/obj/vehicles.dmi'
	icon_state = "upgrade"

/obj/vehicle/ridden/janicart/examine(mob/user)
	. += ..()
	if(floorbuffer)
		. += "It has been upgraded with a floor buffer."

/obj/vehicle/ridden/janicart/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/storage/bag/trash))
		if(mybag)
			to_chat(user, span_warning("[src] already has a trashbag hooked!"))
			return
		if(!user.transferItemToLoc(I, src))
			return
		to_chat(user, span_notice("I hook the trashbag onto [src]."))
		mybag = I
		update_icon()
	else if(istype(I, /obj/item/janiupgrade))
		if(floorbuffer)
			to_chat(user, span_warning("[src] already has a floor buffer!"))
			return
		floorbuffer = TRUE
		qdel(I)
		to_chat(user, span_notice("I upgrade [src] with the floor buffer."))
		AddElement(/datum/element/cleaning)
		update_icon()
	else
		return ..()

/obj/vehicle/ridden/janicart/update_icon()
	cut_overlays()
	if(mybag)
		add_overlay("cart_garbage")
	if(floorbuffer)
		add_overlay("cart_buffer")

/obj/vehicle/ridden/janicart/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	else if(mybag)
		mybag.forceMove(get_turf(user))
		user.put_in_hands(mybag)
		mybag = null
		update_icon()

/obj/vehicle/ridden/janicart/upgraded
	floorbuffer = TRUE
