extends Node

signal config_ready(config_data)
signal config_updated(key, old_value, new_value)

signal theme_config_ready()
signal theme_config_updated(key, old_value, new_value)

signal system_data_updated(system_data)
signal game_data_updated(game_data)
signal game_media_data_updated(game_media_data)

enum OS_ID {
	WINDOWS,
	MACOS,
	LINUX,
	UNSUPPORTED
}

var config := ConfigData.new()
var theme : Node
var theme_path : String
var theme_data : RetroHubTheme
var _theme_config_changed := false
var _theme_config_old : Dictionary
var _theme_config : Dictionary

var games : Array
var systems : Dictionary
var _systems_raw : Dictionary
var emulators : Array
var emulators_map : Dictionary

var _dir := Directory.new()
var _file := File.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	if FileUtils.get_os_id() == FileUtils.OS_ID.UNSUPPORTED:
		OS.alert("Current OS is unsupported! You're on your own!")
	
	# Load configuration file
	bootstrap_config_dir()
	load_config_file()
	_systems_raw = JSONUtils.map_array_by_key(JSONUtils.load_json_file(get_systems_file())["systems_list"], "name")
	expand_systems()
	emulators = JSONUtils.load_json_file(get_emulators_file())["emulators_list"]
	emulators_map = JSONUtils.map_array_by_key(emulators, "name")
	if not config.is_first_time:
		load_game_data_files()
	
	# Wait until all other nodes have processed _ready
	yield(get_tree(), "idle_frame")
	emit_signal("config_ready", config)
	config.connect("config_updated", self, "_on_config_updated")

func expand_systems():
	for key in _systems_raw:
		if _systems_raw[key].has("extends"):
			_systems_raw[key].merge(_systems_raw[_systems_raw[key]["extends"]])

func load_config_file():
	var err = config.load_config_from_path(get_config_file())
	if err == ERR_FILE_NOT_FOUND:
		config.save_config_to_path(get_config_file(), true)
	elif err == ERR_FILE_CORRUPT:
		print("File is corrupt!")
		config.save_config_to_path(get_config_file(), true)
		# TODO: behavior for when file is corrupt

func _on_config_updated(key, old_value, new_value):
	if key == ConfigData.KEY_GAMES_DIR:
		load_game_data_files()
	if key == ConfigData.KEY_DATE_FORMAT:
		refresh_game_data_dates(old_value)

	emit_signal("config_updated", key, old_value, new_value)

func load_game_data_files():
	games.clear()
	systems.clear()
	if _dir.open(config.games_dir) or _dir.list_dir_begin(true):
		print("Error when opening game directory " + config.games_dir)
		return
	var file_name = _dir.get_next()
	while file_name != "":
		if _dir.current_is_dir() and _systems_raw.has(file_name):
			load_system_gamelists_files(config.games_dir + "/" + file_name, file_name)
		# We are not interested in files, only folders
		file_name = _dir.get_next()
	_dir.list_dir_end()

func refresh_game_data_dates(old_format):
	var date_raw : String
	for game in games:
		date_raw = RegionUtils.globalize_date_str(game.release_date, old_format)
		game.release_date = RegionUtils.localize_date(date_raw)
		date_raw = RegionUtils.globalize_date_str(game.last_played, old_format)
		game.last_played = RegionUtils.localize_date(date_raw)
		emit_signal("game_data_updated", game)

func load_system_gamelists_files(folder_path: String, system_name: String):
	print("Loading games from directory " + folder_path)
	var dir = Directory.new()
	if dir.open(folder_path) or dir.list_dir_begin(true):
		print("Error when opening game directory " + folder_path)
		return
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = folder_path + "/" + file_name
		if dir.current_is_dir():
			# Recurse
			# TODO: prevent infinite recursion with shortcuts/symlinks
			load_system_gamelists_files(full_path, system_name)
		else:
			if is_file_from_system(file_name, system_name):
				if not systems.has(system_name):
					var system := RetroHubSystemData.new()
					system.name = system_name
					system.fullname = _systems_raw[system_name]["fullname"]
					system.platform = _systems_raw[system_name]["platform"]
					system.category = convert_system_category(_systems_raw[system_name]["category"])
					system.num_games = 1
					systems[system_name] = system
				else:
					systems[system_name].num_games += 1

				var game := RetroHubGameData.new()
				game.path = full_path
				game.system = systems[system_name]
				# Check if metadata exists, in the form of a .json file
				var metadata_path = get_game_data_path_from_file(system_name, full_path)
				if dir.file_exists(metadata_path):
					if not fetch_game_data(metadata_path, game):
						print("Metadata file corrupt!")
						game.name = file_name
						game.has_metadata = false
					game.has_metadata = true
				else:
					game.name = file_name
					game.age_rating = "0/0/0"
					game.has_metadata = false
				games.push_back(game)
		file_name = dir.get_next()
	dir.list_dir_end()

func convert_system_category(category_raw: String):
	match category_raw:
		"computer":
			return RetroHubSystemData.Category.Computer
		"engine":
			return RetroHubSystemData.Category.GameEngine
		"arcade":
			return RetroHubSystemData.Category.Arcade
		"modern_console":
			return RetroHubSystemData.Category.ModernConsole
		"console", _:
			return RetroHubSystemData.Category.Console

func make_system_folder(system_raw: Dictionary):
	var path = config.games_dir + "/" + system_raw["name"]
	if not _dir.dir_exists(path):
		_dir.make_dir_recursive(path)

func fetch_game_data(path: String, game: RetroHubGameData) -> bool:
	var data : Dictionary = JSONUtils.load_json_file(path)
	if data.empty():
		return false
	
	game.name = data["name"]
	game.description = data["description"]
	game.rating = data["rating"]
	game.release_date = RegionUtils.localize_date(data["release_date"] as String)
	game.developer = data["developer"]
	game.publisher = data["publisher"]
	game.genres = data["genres"]
	game.num_players = data["num_players"]
	game.age_rating = data["age_rating"]
	game.favorite = data["favorite"]
	game.play_count = data["play_count"]
	game.last_played = RegionUtils.localize_date(data["last_played"] as String)
	game.has_media = data["has_media"]

	return true

func get_game_data_path_from_file(system_name: String, file_name: String):
	return get_gamelists_dir() + "/" + system_name + "/" + file_name.get_file().trim_suffix(file_name.get_extension()) + "json"

func save_game_data(game_data: RetroHubGameData) -> bool:
	var metadata_path = get_game_data_path_from_file(game_data.system.name, game_data.path)
	FileUtils.ensure_path(metadata_path)
	var game_data_raw = {}
	game_data_raw["name"] = game_data.name
	game_data_raw["description"] = game_data.description
	game_data_raw["rating"] = game_data.rating
	game_data_raw["release_date"] = RegionUtils.globalize_date_str(game_data.release_date)
	game_data_raw["developer"] = game_data.developer
	game_data_raw["publisher"] = game_data.publisher
	game_data_raw["genres"] = game_data.genres
	game_data_raw["num_players"] = game_data.num_players
	game_data_raw["age_rating"] = game_data.age_rating
	game_data_raw["favorite"] = game_data.favorite
	game_data_raw["play_count"] = game_data.play_count
	game_data_raw["last_played"] = RegionUtils.globalize_date_str(game_data.last_played)
	game_data_raw["has_media"] = game_data.has_media
	
	if _file.open(metadata_path, File.WRITE):
		print("Error when opening file %s!" % metadata_path)
		_file.close()
		return false
	
	_file.store_string(JSON.print(game_data_raw, "\t"))
	_file.close()

	emit_signal("game_data_updated", game_data)
	return true


func is_file_from_system(file_name: String, system_name: String) -> bool:
	var extensions : Array = _systems_raw[system_name]["extension"]
	var file_extension = ("." + file_name.get_extension()).to_lower()
	for extension in extensions:
		if extension.to_lower() == file_extension:
			return true
	
	return false


func load_theme() -> bool:
	var current_theme := config.current_theme
	if current_theme.ends_with(".pck"):
		theme_path = get_themes_dir() + "/" + current_theme
	else:
		theme_path = get_default_themes_dir() + "/" + current_theme + ".pck"
	if !ProjectSettings.load_resource_pack(theme_path, false):
		print("Error when loading theme " + theme_path)
		return false

	if theme_data and is_instance_valid(theme_data.entry_scene):
		theme_data.entry_scene.free()
	load_theme_data()
	if theme_data.entry_scene:
		return true
	else:
		return false

func load_theme_data():
	var theme_raw := JSONUtils.load_json_file("res://theme.json")
	if theme_raw.empty() or not theme_raw.has("id"):
		print("Error when loading theme data!")
		return

	theme_data = RetroHubTheme.new()
	theme_data.id = theme_raw["id"]
	if theme_raw.has("name"):
		theme_data.name = theme_raw["name"]
	if theme_raw.has("description"):
		theme_data.description = theme_raw["description"]
	if theme_raw.has("version"):
		theme_data.version = theme_raw["version"]
	if theme_raw.has("url"):
		theme_data.url = theme_raw["url"]
	if theme_raw.has("icon"):
		theme_data.icon = load(theme_raw["icon"])
	if theme_raw.has("screenshots"):
		for screenshot in theme_raw["screenshots"]:
			theme_data.screenshots.push_back(load(screenshot))
	if theme_raw.has("entry_scene"):
		theme_data.entry_scene = load(theme_raw["entry_scene"]).instance()
	if theme_raw.has("config_scene"):
		theme_data.config_scene = load(theme_raw["config_scene"]).instance()
	if theme_raw.has("app_theme"):
		theme_data.app_theme = load(theme_raw["app_theme"])

func unload_theme():
	if theme_data:
		# Save config if exists
		if theme_data.config_scene:
			save_theme_config()

		if !ProjectSettings.unload_resource_pack(theme_path):
			print("Error when unloading theme " + theme_path)
			return

func get_theme_config(key, default_value):
	if not _theme_config.has(key):
		return default_value
	return _theme_config[key]

func set_theme_config(key, value):
	_theme_config_changed = true
	_theme_config[key] = value

func load_theme_config():
	_theme_config = {}
	_theme_config_changed = false
	var theme_config_path = get_theme_config_dir() + "/config.json"
	FileUtils.ensure_path(theme_config_path)
	if not _file.open(theme_config_path, File.READ):
		var result := JSON.parse(_file.get_as_text())
		_file.close()
		if not result.error:
			_theme_config = result.result
			_theme_config_old = _theme_config.duplicate()
		else:
			print("Error when parsing theme config at %s" % theme_config_path)
	else:
		print("Error when reading theme config at %s" % theme_config_path)
	emit_signal("theme_config_ready")

func save_theme_config():
	if _theme_config_changed:
		var theme_config_path = get_theme_config_dir() + "/config.json"
		if _file.open(theme_config_path, File.WRITE):
			print("Error when saving theme config at %s" % theme_config_path)
			return
		_file.store_string(JSON.print(_theme_config, "\t"))
		_file.close()

		for key in _theme_config:
			if not _theme_config_old.has(key):
				emit_signal("theme_config_updated", key, "", _theme_config[key])
			elif _theme_config_old[key] != _theme_config[key]:
				emit_signal("theme_config_updated", key, _theme_config_old[key], _theme_config[key])
		
		_theme_config_changed = false

func _exit_tree():
	save_config()

func bootstrap_config_dir():
	# Create directories
	if not _dir.dir_exists(get_config_dir()):
		print("First time!")
		# Create base directories
		var dir := Directory.new()
		dir.make_dir_recursive(get_config_dir())
		dir.make_dir_recursive(get_themes_dir())
		dir.make_dir_recursive(get_gamelists_dir())
		dir.make_dir_recursive(get_gamemedia_dir())
		
		# Bootstrap system specific configs
		for filename in ["emulators.json", "systems.json"]:
			var filepath = "res://base_config/" + filename
			if(_file.open(filepath, File.READ)):
				print("Error when opening file " + filepath + " for reading")
				return
			var json_result := JSON.parse(_file.get_as_text())
			if(json_result.error):
				print("Error when parsing JSON file " + filepath)
				return
			var json_parsed = JSONUtils.make_system_specific(json_result.result, FileUtils.get_os_string())
			var filepathOut = get_config_dir() + "/rh_" + filename;
			_file.close()
			if(_file.open(filepathOut, File.WRITE)):
				print("Error when opening file " + filepath + " for saving")
				return
			_file.store_string(JSON.print(json_parsed, "\t"))
			_file.close()

func save_config():
	config.save_config_to_path(get_config_file())

func get_config_dir() -> String:
	var path : String
	match FileUtils.get_os_id():
		OS_ID.WINDOWS:
			path = FileUtils.get_home_dir() + "/RetroHub"
			if RetroHub._is_dev_env():
				path += "-Dev"
			return path
		_:
			path = FileUtils.get_home_dir() + "/.retrohub"
			if RetroHub._is_dev_env():
				path += "-dev"
	return path

func get_config_file() -> String:
	return get_config_dir() + "/rh_config.json"

func get_systems_file() -> String:
	return get_config_dir() + "/rh_systems.json"

func get_emulators_file() -> String:
	return get_config_dir() + "/rh_emulators.json"

func get_default_themes_dir() -> String:
	return "res://default_themes"

func get_themes_dir() -> String:
	return get_config_dir() + "/themes"

func get_theme_config_dir() -> String:
	return get_themes_dir() + "/config/" + theme_data.id if theme_data else ""

func get_gamelists_dir() -> String:
	return get_config_dir() + "/gamelists"

func get_gamemedia_dir() -> String:
	return get_config_dir() + "/gamemedia"
