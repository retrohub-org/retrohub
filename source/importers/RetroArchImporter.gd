extends RetroHubImporter

class_name RetroArchImporter

var config_path : String
var thumbnails_path : String
var playlists_path : String
var folder_size : int = -1

var game_datas := {}

const RA_MEDIA_NAMES := [
	"Named_Snaps", "Named_Titles"
]

const RH_MEDIA_NAMES := [
	"screenshot", "title-screen"
]

# Returns this importer name
func get_importer_name() -> String:
	return "RetroArch"

# Return this importer icon
func get_icon() -> Texture2D:
	return preload("res://assets/frontends/retroarch.png")

# Returns the compatibility level regarding existing game metadata.
# This one in particular must offer SUPPORTED or PARTIAL support.
# This is run after `is_available()`, so this method doesn't need to be
# static, and can change level depending on the existing configuration/version.
func get_metadata_compatibility_level() -> int:
	return CompatibilityLevel.PARTIAL

# Returns the compatibility level regarding existing game media
func get_media_compatibility_level() -> int:
	return CompatibilityLevel.SUPPORTED

# Returns the compatibility level regarding existing themes
func get_theme_compatibility_level() -> int:
	return CompatibilityLevel.UNSUPPORTED

# Returns a description/note to give more information about the
# game metadata compatibility level
func get_metadata_compatibility_level_description() -> String:
	return "Only game names. Remaining information will have to be scraped from RetroHub.\n\nWarning: RetroArch does not centralize game file locations, so no games will be copied. You will have to set the game folder location in the next step for RetroHub to find your games."

# Returns a description/note to give more information about the
# game media compatibility level
func get_media_compatibility_level_description() -> String:
	return "Only title screens and screenshots. Remaining media will have to be scraped from RetroHub."

# Returns a description/note to give more information about the
# theme compatibility level
func get_theme_compatibility_level_description() -> String:
	return "There's currently no wrapper for RetroArch themes."

# Returns the estimated size needed to copy the platform's data to RetroHub, in bytes.
# This will run in a thread, so avoid any unsafe-thread API
func get_estimated_size() -> int:
	if folder_size == -1:
		folder_size = 0
		var dir := DirAccess.open(thumbnails_path)
		if dir and not dir.list_dir_begin() :# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
			var next := dir.get_next()
			while not next.is_empty():
				if dir.current_is_dir() and next != "cheevos":
					folder_size += FileUtils.get_folder_size(thumbnails_path.path_join(next), RA_MEDIA_NAMES)
				next = dir.get_next()
	return folder_size

# Determines if this gaming library platform is available in the system
# As this may take some time to determine, this function will run in a
# thread. Therefore, you shouldn't use any unsafe-thread API, and limit
# to finding local files, reading content, and determining compatibility levels
func is_available() -> bool:
	var path := RetroHubRetroArchEmulator.get_config_path()
	if not path.is_empty():
		set_paths(path)
		return true
	return false

func set_paths(root: String):
	config_path = root
	thumbnails_path = config_path + "/thumbnails"
	playlists_path = config_path + "/playlists"

# Begins the import process. `copy` determines if the user wants
# to copy previous data and, therefore, not affect the other game library
# platform. This will be run in a thread, so avoid any unsafe-thread API
func begin_import(copy: bool):
	reset_major(3)
	progress_major("Importing game metadata")
	import_metadata()
	progress_major("Importing game media")
	import_media(copy)
	progress_major("Saving game data")
	save_game_data()
	progress_major("Finished")
	cleanup()

func import_metadata():
	reset_minor(0)
	var gamelists := {}
	var total_games := 0
	var dir := DirAccess.open(playlists_path)
	if dir and not dir.list_dir_begin() :# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := dir.get_next()
		while not next.is_empty():
			if not dir.current_is_dir() and next.to_lower().ends_with(".lpl"):
				var lpl_file := playlists_path.path_join(next)
				progress_minor("Reading gamedata from \"%s\"..." % next)
				var system_name := guess_system_name(lpl_file)
				if not system_name.is_empty():
					gamelists[system_name] = process_lpl_file(lpl_file)
			next = dir.get_next()
	reset_minor(total_games)
	for system in gamelists.keys():
		var base_path := RetroHubConfig.get_gamelists_dir().path_join(system as String)
		FileUtils.ensure_path(base_path)
		for child in gamelists[system]:
			process_metadata(system, child)

func guess_system_name(name: String) -> String:
	# RetroArch saves system information in the file name as full name.
	# We have to try and match it to known entries
	if "Nintendo - Nintendo 64" in name:
		return "n64"
	elif "Nintendo - Nintendo Entertainment System" in name:
		return "nes"
	elif "Nintendo - Super Nintendo Entertainment System" in name:
		return "snes"
	elif "Nintendo - GameCube" in name:
		return "gc"
	# TODO: More names
	return ""

func process_lpl_file(path: String) -> Array:
	# RetroArch 1.7.5 onwards saves data in JSON format.
	var json : Dictionary = JSONUtils.load_json_file(path)
	var names := []
	if not json.is_empty():
		if json.has("items"):
			for child in json["items"]:
				names.append({"name": child["label"], "path": child["path"]})
	else:
		# Deprecated format. File consists of 6-line chunks of information
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			while not file.eof_reached():
				var file_path := file.get_line()
				var name := file.get_line()
				names.push_back({"name": name, "path": file_path})
				for _i in range(4):
					file.get_line()
			file.close()
	return names

func process_metadata(system: String, dict: Dictionary):
	var game_data := RetroHubGameData.new()
	var root_path := RetroHubConfig.config.games_dir.path_join(system)
	game_data.has_metadata = true
	game_data.path = root_path.path_join(dict["path"].substr(2))
	progress_minor("Converting \"%s\" (\"%s\")" % [game_data.path.get_file(), system])
	if dict.has("name"):
		game_data.name = dict["name"]
	var short_path := system.path_join(game_data.path.get_file().get_basename())
	if RetroHubConfig.systems.has(system):
		game_data.system = RetroHubConfig.systems[system]
	game_data.system_path = system
	game_datas[short_path] = game_data


func import_media(copy: bool):
	var count := 0
	var dir := DirAccess.open(thumbnails_path)
	if dir and not dir.list_dir_begin() :# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := dir.get_next()
		while not next.is_empty():
			if dir.current_is_dir() and next != "cheevos":
				count += FileUtils.get_file_count(thumbnails_path.path_join(next), RA_MEDIA_NAMES)
			next = dir.get_next()
	reset_minor(count)
	if not dir.list_dir_begin() :# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := dir.get_next()
		while not next.is_empty():
			if dir.current_is_dir() and next != "cheevos":
				var system_name := guess_system_name(next)
				if not system_name.is_empty():
					var base_path := RetroHubConfig.get_gamemedia_dir().path_join(system_name)
					FileUtils.ensure_path(base_path)
					process_media_subfolder(thumbnails_path.path_join(next), system_name, copy)
			next = dir.get_next()

func process_media_subfolder(path: String, system: String, copy: bool):
	var dir := DirAccess.open(path)
	if dir and not dir.list_dir_begin() :# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := dir.get_next()
		while not next.is_empty():
			if dir.current_is_dir() and next in RA_MEDIA_NAMES:
				process_media(path.path_join(next), system, RH_MEDIA_NAMES[RA_MEDIA_NAMES.find(next)], copy)
			next = dir.get_next()

func process_media(path: String, system: String, media_name: String, copy: bool):
	var dir := DirAccess.open(path)
	if dir and not dir.list_dir_begin() :# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := dir.get_next()
		var base_path := RetroHubConfig.get_gamemedia_dir().path_join(system).path_join(media_name)
		while not next.is_empty():
			if not dir.current_is_dir():
				var from_path := path.path_join(next)
				# RetroHub uses game name for media names.
				var game_data := find_game_data_with_label(next.get_basename())
				if game_data:
					var to_path := base_path.path_join(game_data.path.get_file().get_basename() + "." + next.get_extension())
					FileUtils.ensure_path(to_path)
					if copy:
						progress_minor("Copying \"%s\" (\"%s\")" % [from_path.get_file(), system])
						if dir.copy(from_path, to_path):
							push_error("Failed to copy \"%s\" to \"%s\"" % [from_path, to_path])
					else:
						progress_minor("Moving \"%s\" (\"%s\")" % [from_path.get_file(), system])
						if dir.rename(from_path, to_path):
							push_error("Failed to move \"%s\" to \"%s\"" % [from_path, to_path])
					game_data.has_media = true
				next = dir.get_next()

func find_game_data_with_label(label: String) -> RetroHubGameData:
	for game_data in game_datas.values():
		if game_data.name == label:
			return game_data
	return null

func save_game_data():
	reset_minor(game_datas.size())
	for game_data in game_datas.values():
		progress_minor("Saving \"%s\" metadata" % game_data.name)
		if not RetroHubConfig.save_game_data(game_data):
			push_error("Failed to save game data for \"%s\"" % game_data.name)


func cleanup():
	game_datas.clear()
