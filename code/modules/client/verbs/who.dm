
/client/verb/who()
	set name = "Whom"
	set category = "Options"

	var/msg = ""

	var/list/Lines = list()

	var/wled = 0
	if(holder)
		to_chat(src, span_info("Loading Whom, please wait..."))
		for(var/client/C in GLOB.clients)
			var/entry = "<span class='info'>\t[C.key]"
			if(C.holder && C.holder.fakekey)
				entry += " <i>(as [C.holder.fakekey])</i>"
			if (isnewplayer(C.mob))
				entry += " - <font color='darkgray'><b>In Lobby</b></font>"
				if(C.ckey in GLOB.anonymize)
					entry += " (as [get_fake_key(C.ckey)])"
			else
				if(ishuman(C.mob))
					var/mob/living/carbon/human/H = C.mob
					entry += " - Playing as [C.mob.real_name][H.job ? " ([H.job])" : ""]"
				else
					entry += " - Playing as [C.mob.real_name]"
				switch(C.mob.stat)
					if(UNCONSCIOUS)
						entry += " - <font color='darkgray'><b>UNCON</b></font>"
					if(DEAD)
						if(isobserver(C.mob))
							var/mob/dead/observer/O = C.mob
							if(O.started_as_observer)
								entry += " - <font color='gray'>Observing</font>"
							else
								entry += " - <b>GHOST</b>"
						else
							entry += " - <b>DEAD</b>"
				if(C.mob.mind)
					if(C.mob.mind.special_role)
						entry += " - <b><font color='red'>[C.mob.mind.special_role]</font></b>"
			entry += " ([CheckIPCountry(C.address)])"
			if(C.whitelisted())
				wled++
				entry += "(WL)"
			entry += "</span>"
			Lines += entry
	else
		for(var/client/C in GLOB.clients)
			if(C.whitelisted())
				wled++
			var/usedkey = C.ckey
			if(C.ckey in GLOB.anonymize)
				usedkey = get_fake_key(C.ckey)
			Lines += span_info("[usedkey]")
	for(var/line in sortList(Lines))
		msg += "[line]\n"
	msg += "<b>Players at the table:</b> [length(Lines)]"
	if(holder)
		msg += "<br><b>Whitelisted players:</b> [wled]"
	to_chat(src, msg)

/client/proc/adminwho()
	set category = "Admin"
	set name = "Adminwho"
	set desc = "Lists all admins currently online."
	
	var/datum/admins/A = GLOB.deadmins[ckey]
	if(!A)
		if(!check_rights(R_ADMIN))
			return

	var/msg = "<b>Current Admins:</b>\n"
	if(holder)
		for(var/client/C in GLOB.admins)
			msg += "\t[C] is a [C.holder.rank]"

			if(C.holder.fakekey)
				msg += " <i>(as [C.holder.fakekey])</i>"

			if(isobserver(C.mob))
				msg += " - Observing"
			else if(isnewplayer(C.mob))
				msg += " - Lobby"
			else
				msg += " - Playing"

			if(C.is_afk())
				msg += " (AFK)"
			msg += "\n"
	else
		for(var/client/C in GLOB.admins)
			if(C.is_afk())
				continue //Don't show afk admins to adminwho
			if(!C.holder.fakekey)
				msg += "\t[C] is a [C.holder.rank]\n"
		msg += span_info("Adminhelps are also sent to IRC. If no admins are available in game adminhelp anyways and an admin on IRC will see it and respond.")
	to_chat(src, msg)

