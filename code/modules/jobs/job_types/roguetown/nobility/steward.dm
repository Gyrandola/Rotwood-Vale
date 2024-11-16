/datum/job/roguetown/steward
	title = "Steward"
	flag = STEWARD
	department_flag = NOBLEMEN
	faction = "Station"
	total_positions = 1
	spawn_positions = 1

	allowed_races = RACES_TOLERATED_UP
	allowed_sexes = list(MALE, FEMALE)
	display_order = JDO_STEWARD
	tutorial = "Coin, Coin, Coin! Oh beautiful coin: You're addicted to it, and you hold the position as the Duke's personal treasurer of both coin and information. You know the power silver and gold has on a man's mortal soul, and you know just what lengths they'll go to in order to get even more. Keep your festering economy and your rats alive, the'yre the only two things you can weigh any trust into anymore."
	outfit = /datum/outfit/job/roguetown/steward
	give_bank_account = 17
	min_pq = 2
	max_pq = null

/datum/outfit/job/roguetown/steward/pre_equip(mob/living/carbon/human/H)
	..()
	H.virginity = TRUE
	armor = /obj/item/clothing/suit/roguetown/armor/leather/steward
	shirt = /obj/item/clothing/suit/roguetown/shirt/undershirt/red
	pants = /obj/item/clothing/under/roguetown/tights/black
	shoes = /obj/item/clothing/shoes/roguetown/shortboots
	belt = /obj/item/storage/belt/rogue/leather
	beltr = /obj/item/keyring/steward

	ADD_TRAIT(H, TRAIT_SEEPRICES, type)
	

	if(H.mind)
		H.mind.adjust_skillrank(/datum/skill/misc/reading, 6, TRUE)
		H.mind.adjust_skillrank(/datum/skill/misc/riding, 2, TRUE)
		H.mind.adjust_skillrank(/datum/skill/combat/crossbows, 2, TRUE)
		H.mind.adjust_skillrank(/datum/skill/combat/wrestling, 2, TRUE)
		H.mind.adjust_skillrank(/datum/skill/combat/unarmed, 2, TRUE)
		H.mind.adjust_skillrank(/datum/skill/misc/swimming, 1, TRUE)
		H.mind.adjust_skillrank(/datum/skill/misc/climbing, 1, TRUE)
		H.mind.adjust_skillrank(/datum/skill/misc/athletics, 1, TRUE)
		H.mind.adjust_skillrank(/datum/skill/combat/swords, 1, TRUE)
		H.mind.adjust_skillrank(/datum/skill/combat/knives, 3, TRUE)
		H.mind.adjust_skillrank(/datum/skill/misc/treatment, 2, TRUE)
		H.mind.adjust_skillrank(/datum/skill/craft/cooking, 1, TRUE)
		H.mind.adjust_skillrank(/datum/skill/misc/riding, 2, TRUE)
		H.change_stat("intelligence", 2)
		H.change_stat("perception", 2)
		H.change_stat("speed", -1)
	ADD_TRAIT(H, TRAIT_NOBLE, TRAIT_GENERIC)
	ADD_TRAIT(H, TRAIT_SEEPRICES, TRAIT_GENERIC)

	if(H.charflaw)
		if(H.charflaw.type != /datum/charflaw/badsight)
			var/obj/item/bodypart/O = H.get_bodypart(BODY_ZONE_R_ARM)
			if(O)
				O.drop_limb()
				qdel(O)
			O = H.get_bodypart(BODY_ZONE_L_ARM)
			if(O)
				O.drop_limb()
				qdel(O)
			H.regenerate_limb(BODY_ZONE_R_ARM)
			H.regenerate_limb(BODY_ZONE_L_ARM)
			H.charflaw = new /datum/charflaw/badsight()
			if(!istype(H.wear_mask, /obj/item/clothing/mask/rogue/spectacles))
				qdel(H.wear_mask)
				mask = /obj/item/clothing/mask/rogue/spectacles
