extends RetroHubImporter

class_name EmulationStationImporter

var theme_support : int

# Config level 7 is already ES-DE.
const MAXIMUM_SUPPORTED_CONFIG_LEVEL = 7

var config_path := FileUtils.get_home_dir() + "/.emulationstation"
var media_path := config_path + "/downloaded_media"
var gamelists_path := config_path + "/gamelists"
var folder_size : int = -1

var game_datas := {}

const ES_MEDIA_NAMES := [
	"3dboxes", "marquees", "screenshots",
	"titlescreens", "videos"
]

const RH_MEDIA_NAMES := [
	"box-render", "logo", "screenshot",
	"title-screen", "video"
]

# Returns this importer name
func get_name() -> String:
	return "EmulationStation / EmulationStation-DE"

# Return this importer icon
func get_icon() -> Texture:
	return preload("res://assets/frontends/es.png")

# Returns the compatibility level regarding existing game metadata.
# This one in particular must offer SUPPORTED or PARTIAL support.
# This is run after `is_available()`, so this method doesn't need to be
# static, and can change level depending on the existing configuration/version.
func get_metadata_compatibility_level() -> int:
	return CompatibilityLevel.SUPPORTED

# Returns the compatibility level regarding existing game media
func get_media_compatibility_level() -> int:
	return CompatibilityLevel.SUPPORTED

# Returns the compatibility level regarding existing themes
func get_theme_compatibility_level() -> int:
	return theme_support

# Returns a description/note to give more information about the
# game metadata compatibility level
func get_metadata_compatibility_level_description() -> String:
	return "Age ratings will have to be scraped from RetroHub."

# Returns a description/note to give more information about the
# game media compatibility level
func get_media_compatibility_level_description() -> String:
	return "Game box and physical support textures, used in 3D models, will have to be scraped from RetroHub."

# Returns a description/note to give more information about the
# theme compatibility level
func get_theme_compatibility_level_description() -> String:
	match get_theme_compatibility_level():
		CompatibilityLevel.PARTIAL:
			return "Supported with the default \"es-theme-wrapper\" theme. One or more themes are more recent than what's been tested on RetroHub, so there might be issues with them."
		CompatibilityLevel.SUPPORTED:
			return "Supported with the default \"es-theme-wrapper\" theme."
		_:
			return ""

# Returns the estimated size needed to copy the platform's data to RetroHub, in bytes.
# This will run in a thread, so avoid any unsafe-thread API
func get_estimated_size() -> int:
	if folder_size == -1:
		var dir := Directory.new()
		folder_size = 0
		if not dir.open(media_path) and not dir.list_dir_begin(true):
			var next = dir.get_next()
			while not next.empty():
				if dir.current_is_dir():
					folder_size += FileUtils.get_folder_size(media_path + "/" + next, ES_MEDIA_NAMES)
				next = dir.get_next()
	return folder_size

# Determines if this gaming library platform is available in the system
# As this may take some time to determine, this function will run in a
# thread. Therefore, you shouldn't use any unsafe-thread API, and limit
# to finding local files, reading content, and determining compatibility levels
func is_available() -> bool:
	# Does ~/.emulationstation exist?
	var dir := Directory.new()
	if not dir.dir_exists(config_path):
		return false
	
	# Are the theme's config version too recent?
	var theme_path = config_path + "/themes"
	var config_level : int = -1
	if not dir.open(theme_path):
		if not dir.list_dir_begin(true):
			var next := dir.get_next()
			while not next.empty():
				if dir.current_is_dir():
					config_level = max(config_level, check_theme_config_level(theme_path + "/" + next))
					print(config_level)
				next = dir.get_next()
	
	if config_level <= MAXIMUM_SUPPORTED_CONFIG_LEVEL:
		theme_support = CompatibilityLevel.SUPPORTED
	else:
		theme_support = CompatibilityLevel.PARTIAL
	return true

func check_theme_config_level(base_path: String):
	var dir := Directory.new()
	
	# Query first at root, and only move to folders if it doesn't exist
	var root_file = base_path + "/theme.xml"
	if dir.file_exists(root_file):
		var config_level = inspect_theme_xml(root_file)
		if config_level != -1:
			return config_level
	
	# Query system folders
	dir.open(base_path)
	if not dir.list_dir_begin(true):
		var path = dir.get_next()
		while not path.empty():
			var file = base_path + "/" + path + "/theme.xml"
			if dir.file_exists(file):
				var config_level = inspect_theme_xml(file)
				if config_level != -1:
					return config_level
			path = dir.get_next()

	return -1

func inspect_theme_xml(path: String) -> int:
	var file := File.new()
	file.open(path, File.READ)
	
	# No need to parse the whole XML. We only want to find <formatVersion> tags.
	var line := file.get_line()
	var start_tk := "<formatVersion>"
	var end_tk := "</formatVersion>"
	while not file.eof_reached():
		var start_idx := line.find(start_tk)
		if start_idx > -1:
			start_idx += start_tk.length()
			var end_idx := line.find(end_tk)
			if end_idx == -1:
				continue
			var version_str = line.substr(start_idx, end_idx - start_idx)
			file.close()
			return version_str.strip_edges().to_int()
		
		line = file.get_line()
	
	return -1
	

# Begins the import process. `copy` determines if the user wants
# to copy previous data and, therefore, not affect the other game library
# platform. This will be run in a thread, so avoid any unsafe-thread API
func begin_import(copy: bool):
	reset_major(4)
	progress_major("Importing configuration")
	import_config()
	progress_major("Importing game metadata")
	import_metadata()
	progress_major("Importing game media")
	import_media(copy)
	progress_major("Saving game data")
	save_game_data()
	progress_major("Finished")
	cleanup()

func import_config():
	reset_minor(1)
	progress_minor("Reading game directory...")
	var config = XML2JSON.parse(config_path + "/es_settings.xml")
	if config.has("string"):
		for child in config["string"]:
			if child.has("#attributes") and child["#attributes"]["name"] == "ROMDirectory":
				RetroHubConfig.config.games_dir = child["#attributes"]["value"]
	progress_minor("Finished")

func import_metadata():
	reset_minor(0)
	var dir := Directory.new()
	var gamelists := {}
	var total_games := 0
	if not dir.open(gamelists_path) and not dir.list_dir_begin(true):
		var next_folder = dir.get_next()
		while not next_folder.empty():
			if dir.current_is_dir():
				var gamelist_path = gamelists_path + "/" + next_folder + "/gamelist.xml"
				progress_minor("Reading gamedata from \"%s\"..." % next_folder)
				var gamelist_dict = XML2JSON.parse(gamelist_path)
				if not gamelist_dict.empty() and gamelist_dict.has("gameList"):
					gamelist_dict = gamelist_dict["gameList"]
					if gamelist_dict.has("game"):
						var game = gamelist_dict["game"]
						gamelists[next_folder] = game
						if game is Dictionary:
							total_games += 1
						elif game is Array:
							total_games += game.size()
			next_folder = dir.get_next()
	reset_minor(total_games)
	for system in gamelists.keys():
		var base_path = RetroHubConfig.get_gamelists_dir() + "/" + system
		dir.make_dir_recursive(base_path)
		var data = gamelists[system]
		if data is Array:
			for child in data:
				process_metadata(system, child)
		elif data is Dictionary:
			process_metadata(system, data)
		
func process_metadata(system: String, dict: Dictionary):
	var game_data := RetroHubGameData.new()
	var root_path = RetroHubConfig.config.games_dir + "/" + system
	game_data.has_metadata = true
	game_data.path = root_path + "/" + dict["path"].substr(2)
	game_data.system_name = system
	progress_minor("Converting \"%s\" (\"%s\")" % [game_data.path.get_file(), system])
	if dict.has("name"):
		game_data.name = dict["name"]
	if dict.has("desc"):
		game_data.description = dict["desc"]
	if dict.has("rating"):
		game_data.rating = float(dict["rating"])
	if dict.has("releasedate"):
		game_data.release_date = RegionUtils.localize_date(dict["releasedate"])
	if dict.has("developer"):
		game_data.developer = dict["developer"]
	if dict.has("publisher"):
		game_data.publisher = dict["publisher"]
	if dict.has("genre"):
		game_data.genres = [dict["genre"]]
	if dict.has("players"):
		var players : String = dict["players"]
		if "-" in players:
			var split := players.split("-")
			game_data.num_players = "%s-%s" % [split[0], split[1]]
		else:
			game_data.num_players = "%s-%s" % [players, players]
	if dict.has("playcount"):
		game_data.play_count = dict["playcount"]
	if dict.has("lastplayed"):
		game_data.last_played = RegionUtils.localize_date(dict["lastplayed"])
	if dict.has("favorite"):
		game_data.favorite = bool(dict["favorite"])
	var short_path = system + "/" + game_data.path.get_file().get_basename()
	game_datas[short_path] = game_data


func import_media(copy: bool):
	var dir := Directory.new()
	var count := 0
	if not dir.open(media_path) and not dir.list_dir_begin(true):
		var next = dir.get_next()
		while not next.empty():
			if dir.current_is_dir():
				count += FileUtils.get_file_count(media_path + "/" + next, ES_MEDIA_NAMES)
			next = dir.get_next()
	reset_minor(count)
	if not dir.list_dir_begin(true):
		var next = dir.get_next()
		while not next.empty():
			if dir.current_is_dir():
				var base_path = RetroHubConfig.get_gamemedia_dir() + "/" + next
				dir.make_dir_recursive(base_path)
				process_media_subfolder(media_path + "/" + next, next, copy)
			next = dir.get_next()
	
func process_media_subfolder(path: String, system: String, copy: bool):
	var dir := Directory.new()
	if not dir.open(path) and not dir.list_dir_begin(true):
		var next = dir.get_next()
		while not next.empty():
			if dir.current_is_dir() and next in ES_MEDIA_NAMES:
				process_media(path + "/" + next, system, RH_MEDIA_NAMES[ES_MEDIA_NAMES.find(next)], copy)
			next = dir.get_next()

func process_media(path: String, system: String, media_name: String, copy: bool):
	var dir := Directory.new()
	if not dir.open(path) and not dir.list_dir_begin(true):
		var next = dir.get_next()
		while not next.empty():
			if not dir.current_is_dir():
				var from_path = path + "/" + next
				var to_path = RetroHubConfig.get_gamemedia_dir() + "/" + system + "/" + media_name + "/" + from_path.get_file()
				FileUtils.ensure_path(to_path)
				if copy:
					progress_minor("Copying \"%s\" (\"%s\")" % [from_path.get_file(), system])
					dir.copy(from_path, to_path)
				else:
					progress_minor("Moving \"%s\" (\"%s\")" % [from_path.get_file(), system])
					dir.rename(from_path, to_path)
				var short_path = system + "/" + from_path.get_file().get_basename()
				if game_datas.has(short_path):
					game_datas[short_path].has_media = true
			next = dir.get_next()

func save_game_data():
	reset_minor(game_datas.size())
	for game_data in game_datas.values():
		progress_minor("Saving \"%s\" metadata" % game_data.name)
		RetroHubConfig.save_game_data(game_data)


func cleanup():
	game_datas.clear()
