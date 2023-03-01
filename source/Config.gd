extends Node

signal config_ready(config_data)
signal config_updated(key, old_value, new_value)

signal theme_config_ready()
signal theme_config_updated(key, old_value, new_value)

signal system_data_updated(system_data)
signal game_data_updated(game_data)
signal game_media_data_updated(game_media_data)

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
var _system_renames : Dictionary
var emulators_map : Dictionary

var _dir := Directory.new()
var _file := File.new()

var _implicit_mappings := {
	"rh_accept": "ui_accept",
	"rh_back": "ui_cancel",
	"rh_left": "ui_left",
	"rh_right": "ui_right",
	"rh_up": "ui_up",
	"rh_down": "ui_down"
}

# Called when the node enters the scene tree for the first time.
func _ready():
	OS.min_window_size = Vector2(1024, 576)
	if FileUtils.get_os_id() == FileUtils.OS_ID.UNSUPPORTED:
		OS.alert("Current OS is unsupported! You're on your own!")

	# Load configuration files
	bootstrap_config_dir()
	load_config_file()

	if not config.is_first_time:
		load_user_data()
		handle_key_remaps()
		handle_controller_axis_remaps()
		handle_controller_button_remaps()

		# Wait until all other nodes have processed _ready
		yield(get_tree(), "idle_frame")
		emit_signal("config_ready", config)
	config.connect("config_updated", self, "_on_config_updated")

func load_user_data():
	load_systems()
	load_emulators()
	load_game_data_files()

func load_systems():
	# Default systems
	_systems_raw = JSONUtils.map_array_by_key(JSONUtils.load_json_file(get_systems_file()), "name")
	
	# Custom systems
	var _custom_systems : Array = JSONUtils.load_json_file(get_custom_systems_file())
	for child in _custom_systems:
		if not _systems_raw.has(child["name"]):
			_systems_raw[child["name"]] = child
			_systems_raw[child["name"]]["#custom"] = true
		else:
			_systems_raw[child["name"]].merge(child, true)
			_systems_raw[child["name"]]["#modified"] = true
	for key in _systems_raw:
		if _systems_raw[key].has("extends"):
			_systems_raw[key].merge(_systems_raw[_systems_raw[key]["extends"]])
	
	set_system_renaming()

func load_emulators():
	# Default emulators
	emulators_map = JSONUtils.map_array_by_key(JSONUtils.load_json_file(get_emulators_file()), "name")
	# Custom emulators
	var _custom_emulators : Array = JSONUtils.load_json_file(get_custom_emulators_file())
	for child in _custom_emulators:
		if not emulators_map.has(child["name"]):
			emulators_map[child["name"]] = child
			emulators_map[child["name"]]["#custom"] = true
		else:
			emulators_map[child["name"]].merge(child, true)
			emulators_map[child["name"]]["#modified"] = true
	JSONUtils.make_system_specific(emulators_map, FileUtils.get_os_string())

func set_system_renaming():
	for name in config.system_names:
		var renames = config.get_system_rename_options(name)
		for rename in renames:
			if rename != config.system_names[name]:
				_system_renames[name] = config.system_names[name]
				_systems_raw.erase(rename)

func _get_scancode(e: InputEventKey):
	return e.physical_scancode if e.scancode == 0 else e.scancode

func handle_key_remaps():
	var keys := config.input_key_map
	# Add implicit mappings as well (aka existing Godot actions that manage UI events)
	for key in keys:
		for ev in InputMap.get_action_list(key):
			if ev is InputEventKey:
				InputMap.action_erase_event(key, ev)
				if key in _implicit_mappings:
					InputMap.action_erase_event(_implicit_mappings[key], ev)
		for code in keys[key]:
			handle_key_remap(key, 0, code)
			if _implicit_mappings.has(key):
				handle_key_remap(_implicit_mappings[key], 0, code)
	# Signal ControllerIcons to update icons
	ControllerIcons.refresh()

func handle_key_remap(key: String, old: int, new: int):
	# Find existing actions to remove them first
	var events := InputMap.get_action_list(key)
	for e in events:
		if e is InputEventKey and _get_scancode(e) == old:
			InputMap.action_erase_event(key, e)
			break
	# Now add the new one
	var key_event := InputEventKey.new()
	key_event.physical_scancode = new
	InputMap.action_add_event(key, key_event)

func handle_controller_button_remaps():
	var keys := config.input_controller_map
	# Add implicit mappings as well (aka existing Godot actions that manage UI events)
	for key in keys:
		for ev in InputMap.get_action_list(key):
			if ev is InputEventJoypadButton:
				InputMap.action_erase_event(key, ev)
				if key in _implicit_mappings:
					InputMap.action_erase_event(_implicit_mappings[key], ev)
		for button in keys[key]:
			handle_controller_button_remap(key, 0, button)
			if _implicit_mappings.has(key):
				handle_controller_button_remap(_implicit_mappings[key], 0, button)

	# Signal ControllerIcons to update icons
	ControllerIcons.refresh()

func handle_controller_axis_remaps():
	# Handle axis remaps
	var main_axis : int
	var sec_axis : int
	match config.input_controller_main_axis:
		"right":
			main_axis = 2
		"left", _:
			main_axis = 0
	match config.input_controller_secondary_axis:
		"right":
			sec_axis = 2
		"left", _:
			sec_axis = 0

	var data := {
		"rh_left": [main_axis, -1],
		"rh_right": [main_axis, 1],
		"rh_up": [main_axis+1, -1],
		"rh_down": [main_axis+1, 1],
		"rh_rstick_left": [sec_axis, -1],
		"rh_rstick_right": [sec_axis, 1],
		"rh_rstick_up": [sec_axis+1, -1],
		"rh_rstick_down": [sec_axis+1, 1]
	}
	for key in data:
		for ev in InputMap.get_action_list(key):
			if ev is InputEventJoypadMotion:
				InputMap.action_erase_event(key, ev)
				if key in _implicit_mappings:
					InputMap.action_erase_event(_implicit_mappings[key], ev)
		var ev := InputEventJoypadMotion.new()
		ev.axis = data[key][0]
		ev.axis_value = data[key][1]
		InputMap.action_add_event(key, ev)
		if _implicit_mappings.has(key):
			InputMap.action_add_event(_implicit_mappings[key], ev)

	# Signal ControllerIcons to update icons
	ControllerIcons.refresh()

func handle_controller_button_remap(key: String, old: int, new: int):
	# Find existing actions to remove them first
	var events := InputMap.get_action_list(key)
	for e in events:
		if e is InputEventJoypadButton and e.button_index == old:
			InputMap.action_erase_event(key, e)
			break
	# Now add the new one
	var event := InputEventJoypadButton.new()
	event.button_index = new
	InputMap.action_add_event(key, event)

func load_config_file():
	var err = config.load_config_from_path(get_config_file())
	if err == ERR_FILE_NOT_FOUND:
		config.save_config_to_path(get_config_file(), true)
	elif err == ERR_FILE_CORRUPT:
		print("File is corrupt!")
		config.save_config_to_path(get_config_file(), true)
		# TODO: behavior for when file is corrupt

func _get_credential(key: String) -> String:
	var json : Dictionary = JSONUtils.load_json_file(get_config_dir() + "/rh_credentials.json")
	if not json.empty() and json.has(key):
		return json[key]
	return ""

func _set_credential(key: String, value: String):
	var json : Dictionary = JSONUtils.load_json_file(get_config_dir() + "/rh_credentials.json")
	json[key] = value
	JSONUtils.save_json_file(json, get_config_dir() + "/rh_credentials.json")

func _on_config_updated(key, old_value, new_value):
	match key:
		ConfigData.KEY_GAMES_DIR:
			load_game_data_files()
		ConfigData.KEY_INPUT_KEY_MAP:
			handle_key_remaps()
		ConfigData.KEY_INPUT_CONTROLLER_MAP:
			handle_controller_button_remaps()
		ConfigData.KEY_INPUT_CONTROLLER_MAIN_AXIS, ConfigData.KEY_INPUT_CONTROLLER_SECONDARY_AXIS:
			handle_controller_axis_remaps()

	emit_signal("config_updated", key, old_value, new_value)

func load_game_data_files():
	games.clear()
	systems.clear()
	if _dir.open(config.games_dir) or _dir.list_dir_begin(true):
		print("Error when opening game directory " + config.games_dir)
		return
	var file_name = _dir.get_next()
	while file_name != "":
		if _dir.current_is_dir() and \
			((_systems_raw.has(file_name) and not _systems_raw[file_name].has("#delete")) or \
			_system_renames.has(file_name)):
			load_system_gamelists_files(config.games_dir + "/" + file_name, file_name)
		# We are not interested in files, only folders
		file_name = _dir.get_next()
	_dir.list_dir_end()
	# Finally order the games array
	games.sort_custom(RetroHubGameData, "sort")

func load_system_gamelists_files(folder_path: String, system_name: String):
	var renamed_system = _system_renames[system_name] if _system_renames.has(system_name) else system_name
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
			if is_file_from_system(file_name, renamed_system):
				if not systems.has(renamed_system):
					var system := RetroHubSystemData.new()
					system.name = renamed_system
					system.fullname = _systems_raw[renamed_system]["fullname"]
					system.platform = _systems_raw[renamed_system]["platform"]
					system.category = RetroHubSystemData.category_to_idx(_systems_raw[renamed_system]["category"])
					system.num_games = 1
					systems[renamed_system] = system
				else:
					systems[renamed_system].num_games += 1

				var game := RetroHubGameData.new()
				game.path = full_path
				game.system = systems[renamed_system]
				game.system_path = system_name
				game.has_metadata = true
				# Check if metadata exists, in the form of a .json file
				var metadata_path = get_game_data_path_from_file(system_name, full_path)
				if dir.file_exists(metadata_path):
					if not fetch_game_data(metadata_path, game):
						print("Metadata file corrupt!")
						game.name = file_name
						game.age_rating = "0/0/0"
						game.has_metadata = false
				else:
					game.name = file_name
					game.age_rating = "0/0/0"
					game.has_metadata = false
				games.push_back(game)
		file_name = dir.get_next()
	dir.list_dir_end()

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
	game.release_date = data["release_date"]
	game.developer = data["developer"]
	game.publisher = data["publisher"]
	game.genres = data["genres"]
	game.num_players = data["num_players"]
	game.age_rating = data["age_rating"]
	game.favorite = data["favorite"]
	game.play_count = data["play_count"]
	game.last_played = data["last_played"]
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
	game_data_raw["release_date"] = game_data.release_date
	game_data_raw["developer"] = game_data.developer
	game_data_raw["publisher"] = game_data.publisher
	game_data_raw["genres"] = game_data.genres
	game_data_raw["num_players"] = game_data.num_players
	game_data_raw["age_rating"] = game_data.age_rating
	game_data_raw["favorite"] = game_data.favorite
	game_data_raw["play_count"] = game_data.play_count
	game_data_raw["last_played"] = game_data.last_played
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
	var theme_raw : Dictionary = JSONUtils.load_json_file("res://theme.json")
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
	# If the config file doesn't exist, don't try reading it
	if not _dir.file_exists(theme_config_path):
		return;
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
		FileUtils.ensure_path(theme_config_path)
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
			var filepathOut = get_config_dir() + "/rh_" + filename;
			if(_file.open(filepathOut, File.WRITE)):
				print("Error when opening file " + filepathOut + " for saving")
				return
			_file.store_string(JSON.print([], "\t"))
			_file.close()
		
		# Bootstrap credentials file
		JSONUtils.save_json_file({}, get_config_dir() + "/rh_credentials.json")

func save_config():
	config.save_config_to_path(get_config_file())
	save_theme_config()

func _restore_keys(dict: Dictionary, keys: Array):
	for key in keys:
		dict[key] = true

func save_system(system_raw: Dictionary):
	# Remove internal keys
	var restore_keys := []
	for key in ["#custom", "#modified"]:
		if system_raw.erase(key):
			restore_keys.push_back(key)

	# Find original config and modify it
	var system_config : Array = JSONUtils.load_json_file(get_custom_systems_file())
	var idx := 0
	for child in system_config:
		if child["name"] == system_raw["name"]:
			system_config[idx] = system_raw
			JSONUtils.save_json_file(system_config, get_custom_systems_file())
			_restore_keys(system_raw, restore_keys)
			return
		idx += 1
	# If not found, simply append info
	system_config.push_back(system_raw)
	JSONUtils.save_json_file(system_config, get_custom_systems_file())
	_restore_keys(system_raw, restore_keys)

func restore_system(system_raw: Dictionary):
	# Find original config and modify it
	var system_config : Array = JSONUtils.load_json_file(get_custom_systems_file())
	for child in system_config:
		if child["name"] == system_raw["name"]:
			system_config.erase(child)
			JSONUtils.save_json_file(system_config, get_custom_systems_file())
			# Now reload information
			var system_defaults : Array = JSONUtils.load_json_file(get_systems_file())
			for default_child in system_defaults:
				if default_child["name"] == system_raw["name"]:
					return default_child

func remove_custom_system(system_raw: Dictionary):
	if not system_raw.has("#custom"):
		print("Tried to delete default system!")
		return
	_systems_raw.erase(system_raw["name"])
	# Find original config and modify it
	var system_config : Array = JSONUtils.load_json_file(get_custom_systems_file())
	for child in system_config:
		if child["name"] == system_raw["name"]:
			system_config.erase(child)
			JSONUtils.save_json_file(system_config, get_custom_systems_file())
			return

func save_emulator(emulator_raw: Dictionary):
	# Remove internal keys
	var restore_keys := []
	for key in ["#custom", "#modified"]:
		if emulator_raw.erase(key):
			restore_keys.push_back(key)

	# Find original config and modify it
	var emulator_config : Array = JSONUtils.load_json_file(get_custom_emulators_file())
	var idx := 0
	for child in emulator_config:
		if child["name"] == emulator_raw["name"]:
			emulator_config[idx] = emulator_raw
			JSONUtils.save_json_file(emulator_config, get_custom_emulators_file())
			_restore_keys(emulator_raw, restore_keys)
			return
		idx += 1
	# If not found, simply append info
	emulator_config.push_back(emulator_raw)
	JSONUtils.save_json_file(emulator_config, get_custom_emulators_file())
	_restore_keys(emulator_raw, restore_keys)

func restore_emulator(emulator_raw: Dictionary):
	# Find original config and modify it
	var emulator_config : Array = JSONUtils.load_json_file(get_custom_emulators_file())
	for child in emulator_config:
		if child["name"] == emulator_raw["name"]:
			emulator_config.erase(child)
			JSONUtils.save_json_file(emulator_config, get_custom_emulators_file())
			# Now reload information
			var system_defaults : Array = JSONUtils.load_json_file(get_emulators_file())
			for default_child in system_defaults:
				if default_child["name"] == emulator_raw["name"]:
					JSONUtils.make_system_specific(default_child, FileUtils.get_os_string())
					return default_child

func remove_custom_emulator(emulator_raw: Dictionary):
	if not emulator_raw.has("#custom"):
		print("Tried to delete default emulator!")
		return
	emulators_map.erase(emulator_raw["name"])
	# Find original config and modify it
	var emulator_config : Array = JSONUtils.load_json_file(get_custom_emulators_file())
	for child in emulator_config:
		if child["name"] == emulator_raw["name"]:
			emulator_config.erase(child)
			JSONUtils.save_json_file(emulator_config, get_custom_emulators_file())
			return

func get_config_dir() -> String:
	var path : String
	match FileUtils.get_os_id():
		FileUtils.OS_ID.WINDOWS:
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
	return "res://base_config/systems.json"

func get_emulators_file() -> String:
	return "res://base_config/emulators.json"

func get_custom_systems_file() -> String:
	return get_config_dir() + "/rh_systems.json"

func get_custom_emulators_file() -> String:
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
