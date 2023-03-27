extends Node

func localize_date(date_raw: String) -> String:
	if date_raw == "null" or date_raw.empty():
		return date_raw
	var year := date_raw.substr(0, 4)
	var month := date_raw.substr(4, 2)
	var day := date_raw.substr(6, 2)
	var hour := date_raw.substr(9, 2)
	var minute := date_raw.substr(11, 2)
	var second := date_raw.substr(13, 2)
	var format_arr : Array
	match RetroHubConfig.config.date_format:
		"dd/mm/yyyy":
			format_arr = [day, month, year, hour, minute, second]
		"yyyy/mm/dd":
			format_arr = [year, month, day, hour, minute, second]
		"mm/dd/yyyy", _:
			format_arr = [month, day, year, hour, minute, second]
	return "%s/%s/%s %s:%s:%s" % format_arr

func globalize_date_str(date_raw: String, source_format: String = ""):
	if date_raw == "null" or date_raw.empty():
		return date_raw
	var date_split := date_raw.split(" ")
	var year := 1970
	var month := 1
	var day := 1
	var hour := 0
	var minute := 0
	var second := 0

	var format : String = RetroHubConfig.config.date_format if source_format.empty() else source_format
	match format:
		"dd/mm/yyyy":
			day = int(date_split[0].get_slice("/", 0))
			month = int(date_split[0].get_slice("/", 1))
			year = int(date_split[0].get_slice("/", 2))
		"yyyy/mm/dd":
			day = int(date_split[0].get_slice("/", 2))
			month = int(date_split[0].get_slice("/", 1))
			year = int(date_split[0].get_slice("/", 0))
		"mm/dd/yyyy", _:
			day = int(date_split[0].get_slice("/", 1))
			month = int(date_split[0].get_slice("/", 0))
			year = int(date_split[0].get_slice("/", 2))
	# TODO: Hour format
	hour = int(date_split[1].get_slice(":", 0))
	minute = int(date_split[1].get_slice(":", 1))
	second = int(date_split[1].get_slice(":", 2))

	return "%04d%02d%02dT%02d%02d%02d" % [year, month, day, hour, minute, second]

func globalize_date_dict(date_dict: Dictionary):
	var year : int = date_dict["year"]
	var month : int = date_dict["month"]
	var day : int = date_dict["day"]
	var hour : int = date_dict["hour"]
	var minute : int = date_dict["minute"]
	var second : int = date_dict["second"]

	return "%04d%02d%02dT%02d%02d%02d" % [year, month, day, hour, minute, second]

func localize_age_rating(age_rating_raw: String) -> Control:
	var rating_idx := localize_age_rating_idx()
	var rating_node : Control = preload("res://scenes/ui_nodes/AgeRatingTextureRect.tscn").instance()
	rating_node.from_idx(age_rating_raw.get_slice("/", rating_idx), rating_idx)
	return rating_node

func localize_age_rating_idx() -> int:
	match RetroHubConfig.config.rating_system:
		"pegi":
			return 1
		"cero":
			return 2
		"esrb", _:
			return 0

func localize_system_name(system_name: String) -> String:
	if RetroHubConfig.config.system_names.has(system_name):
		return RetroHubConfig.config.system_names[system_name]
	return system_name
