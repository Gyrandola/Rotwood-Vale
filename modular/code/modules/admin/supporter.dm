GLOBAL_LIST_INIT(supporters, load_supporters_from_file())

/proc/load_supporters_from_file()
	var/json_file = file("data/supporters.json")
	if(fexists(json_file))
		var/list/json = json_decode(file2text(json_file))
		return json["data"]
	else
		return list()

/proc/save_supporters_to_file()
	var/json_file = file("data/supporters.json")
	var/list/file_data = list()
	file_data["data"] = GLOB.supporters
	fdel(json_file)
	WRITE_FILE(json_file,json_encode(file_data))

/client/proc/admin_add_supporter()
	set category = "GameMaster"
	set name = "Add Supporter"

	var/selection = input("Add a new supporter", "CKEY", "") as text|null
	if(selection)
		add_supporter(selection, ckey)

/proc/add_supporter(target_ckey, admin_ckey = "SYSTEM")
	if(!target_ckey)
		return

	target_ckey = ckey(target_ckey)
	GLOB.supporters |= target_ckey

	message_admins("SUPPORTER: Added [target_ckey] to the supporter list[admin_ckey? " by [admin_ckey]":""]")
	log_admin("SUPPORTER: Added [target_ckey] to the supporter list[admin_ckey? " by [admin_ckey]":""]")

	save_supporters_to_file()

/proc/remove_supporter(target_ckey, admin_ckey = "SYSTEM")
	if(!target_ckey)
		return

	target_ckey = ckey(target_ckey)
	GLOB.supporters -= target_ckey

	message_admins("SUPPORTER: Removed [target_ckey] from the supporter list[admin_ckey? " by [admin_ckey]":""]")
	log_admin("SUPPORTER: Removed [target_ckey] from the supporter list[admin_ckey? " by [admin_ckey]":""]")

	save_supporters_to_file()

/proc/is_supporter(target_ckey)
	if(target_ckey in GLOB.supporters)
		return TRUE
	else
		return FALSE
