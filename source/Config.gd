extends Node

signal config_ready(config_data)
signal config_updated(key, old_value, new_value)

signal theme_config_ready
signal theme_config_updated(key, old_value, new_value)

signal game_data_updated(game_data)

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
var emulators_paths : Dictionary
var _should_save := false

var _is_sc := false

const CONTROLLER_AXIS_FLAG : int = (1 << 8)

var _implicit_mappings := {
	"rh_accept": "ui_accept",
	"rh_back": "ui_cancel",
	"rh_left": "ui_left",
	"rh_right": "ui_right",
	"rh_up": "ui_up",
	"rh_down": "ui_down"
}

func _enter_tree():
	_determine_sc_mode()

func _ready():
	get_window().min_size = Vector2(1024, 576)
	if FileUtils.get_os_id() == FileUtils.OS_ID.UNSUPPORTED:
		OS.alert("Current OS is unsupported! You're on your own!")

	# Load configuration files
	_bootstrap_config_dir()
	_load_config_file()

	if not config.is_first_time:
		_load_user_data()
		_handle_key_remaps()
		_handle_controller_axis_remaps()
		_handle_controller_button_remaps()

		# Wait until all other nodes have processed _ready
		await get_tree().process_frame
		emit_signal("config_ready", config)
	#warning-ignore:return_value_discarded
	config.config_updated.connect(_on_config_updated)

func _load_user_data():
	_load_systems()
	_load_emulators()
	_load_game_data_files()

func _load_systems():
	# Default systems
	_systems_raw = JSONUtils.map_array_by_key(JSONUtils.load_json_file(_get_systems_file()), "name")

	# Custom systems
	var _custom_systems : Array = JSONUtils.load_json_file(_get_custom_systems_file())
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

	_set_system_renaming()

func _load_emulators():
	# Default emulators
	emulators_map = JSONUtils.map_array_by_key(JSONUtils.load_json_file(_get_emulators_file()), "name")
	# Custom emulators
	var _custom_emulators : Array = JSONUtils.load_json_file(_get_custom_emulators_file())
	for child in _custom_emulators:
		if not emulators_map.has(child["name"]):
			emulators_map[child["name"]] = child
			emulators_map[child["name"]]["#custom"] = true
		else:
			if child.has("#delete"):
				emulators_map.erase(child["name"])
			else:
				emulators_map[child["name"]].merge(child, true)
				emulators_map[child["name"]]["#modified"] = true
	JSONUtils.make_system_specific(emulators_map, FileUtils.get_os_string())
	# Load emulator paths
	emulators_paths = JSONUtils.load_json_file(_get_emulator_paths_file())

func _set_system_renaming():
	for system_name in config.system_names:
		var renames := ConfigData.get_system_rename_options(system_name)
		for rename in renames:
			if rename != config.system_names[system_name]:
				_system_renames[system_name] = config.system_names[system_name]
				#warning-ignore:return_value_discarded
				_systems_raw.erase(rename)

func _get_scancode(e: InputEventKey):
	return e.physical_keycode if e.keycode == 0 else e.keycode

func _handle_key_remaps():
	var keys := config.input_key_map
	# Add implicit mappings as well (aka existing Godot actions that manage UI events)
	for key in keys:
		for ev in InputMap.action_get_events(key):
			if ev is InputEventKey:
				InputMap.action_erase_event(key, ev)
				if key in _implicit_mappings:
					for impl_ev in InputMap.action_get_events(_implicit_mappings[key]):
						if impl_ev is InputEventKey:
							InputMap.action_erase_event(_implicit_mappings[key], impl_ev)
		for code in keys[key]:
			_handle_key_remap(key, code)
			if _implicit_mappings.has(key):
				_handle_key_remap(_implicit_mappings[key], code)
	# Signal ControllerIcons to update icons
	ControllerIcons.refresh()

func _handle_key_remap(key: String, new: Key):
	# ui_up/ui_down are replaced by ui_focus_next/ui_focus_prev when screen readers are enabled
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		match key:
			"ui_up":
				key = "ui_focus_prev"
			"ui_down":
				key = "ui_focus_next"
	# Now add the new one
	var key_event := InputEventKey.new()
	key_event.physical_keycode = new
	InputMap.action_add_event(key, key_event)

func _handle_controller_button_remaps():
	var keys := config.input_controller_map
	# Add implicit mappings as well (aka existing Godot actions that manage UI events)
	for key in keys:
		for ev in InputMap.action_get_events(key):
			# TODO: Figure out axis inputs
			if ev is InputEventJoypadButton:
				InputMap.action_erase_event(key, ev)
				if key in _implicit_mappings:
					for impl_ev in InputMap.action_get_events(_implicit_mappings[key]):
						if impl_ev is InputEventJoypadButton:
							InputMap.action_erase_event(_implicit_mappings[key], impl_ev)
		for button in keys[key]:
			_handle_controller_button_remap(key, 0, button)
			if _implicit_mappings.has(key):
				_handle_controller_button_remap(_implicit_mappings[key], 0, button)

	# Signal ControllerIcons to update icons
	ControllerIcons.refresh()

func _handle_controller_axis_remaps():
	# Handle axis remaps
	var main_axis : int
	var sec_axis : int
	match config.input_controller_main_axis:
		"right":
			main_axis = JOY_AXIS_RIGHT_X
		"left", _:
			main_axis = JOY_AXIS_LEFT_X
	match config.input_controller_secondary_axis:
		"right":
			sec_axis = JOY_AXIS_RIGHT_X
		"left", _:
			sec_axis = JOY_AXIS_LEFT_X

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
		for ev in InputMap.action_get_events(key):
			if ev is InputEventJoypadMotion:
				InputMap.action_erase_event(key, ev)
				if key in _implicit_mappings:
					for impl_ev in InputMap.action_get_events(_implicit_mappings[key]):
						if impl_ev is InputEventJoypadMotion:
							InputMap.action_erase_event(_implicit_mappings[key], impl_ev)
		var ev := InputEventJoypadMotion.new()
		ev.axis = data[key][0]
		ev.axis_value = data[key][1]
		InputMap.action_add_event(key, ev)
		if _implicit_mappings.has(key):
			# ui_up/ui_down are replaced by ui_focus_next/ui_focus_prev when screen readers are enabled
			if RetroHubConfig.config.accessibility_screen_reader_enabled:
				match key:
					"rh_up":
						key = "ui_focus_prev"
						InputMap.action_add_event(key, ev)
					"rh_down":
						key = "ui_focus_next"
						InputMap.action_add_event(key, ev)
					_:
						InputMap.action_add_event(_implicit_mappings[key], ev)
			else:
				InputMap.action_add_event(_implicit_mappings[key], ev)

	# Signal ControllerIcons to update icons
	ControllerIcons.refresh()

func _handle_controller_button_remap(key: String, old: int, new: int):
	# Find existing actions to remove them first
	var events := InputMap.action_get_events(key)
	if key == "ui_up":
		events.append_array(InputMap.action_get_events("ui_focus_prev"))
	elif key == "ui_down":
		events.append_array(InputMap.action_get_events("ui_focus_next"))
	for e in events:
		if (old & CONTROLLER_AXIS_FLAG) and e is InputEventJoypadMotion and e.axis == (old & ~CONTROLLER_AXIS_FLAG):
			InputMap.action_erase_event(key, e)
			break
		elif e is InputEventJoypadButton and e.button_index == old:
			InputMap.action_erase_event(key, e)
			break
	# ui_up/ui_down are replaced by ui_focus_next/ui_focus_prev when screen readers are enabled
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		match key:
			"ui_up":
				key = "ui_focus_prev"
			"ui_down":
				key = "ui_focus_next"
	# Now add the new one
	var event : InputEvent
	if new & CONTROLLER_AXIS_FLAG:
		var axis := new & ~CONTROLLER_AXIS_FLAG
		event = InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = 1
	else:
		event = InputEventJoypadButton.new()
		event.button_index = new
	InputMap.action_add_event(key, event)

func _load_config_file():
	match config.load_config_from_path(_get_config_file()):
		ERR_FILE_NOT_FOUND:
			if config.save_config_to_path(_get_config_file(), true):
				push_error("Failed to save config file")
		ERR_FILE_CORRUPT:
			push_error("File is corrupt!")
			if config.save_config_to_path(_get_config_file(), true):
				push_error("Failed to save config file")
			# TODO: behavior for when file is corrupt

func _get_credential(key: String) -> String:
	var json : Dictionary = JSONUtils.load_json_file(_get_config_dir().path_join("rh_credentials.json"))
	if not json.is_empty() and json.has(key):
		return json[key]
	return ""

func _set_credential(key: String, value: String):
	var json : Dictionary = JSONUtils.load_json_file(_get_config_dir().path_join("rh_credentials.json"))
	json[key] = value
	JSONUtils.save_json_file(json, _get_config_dir().path_join("rh_credentials.json"))

func _on_config_updated(key, old_value, new_value):
	match key:
		ConfigData.KEY_GAMES_DIR:
			_load_game_data_files()
		ConfigData.KEY_INPUT_KEY_MAP:
			_handle_key_remaps()
		ConfigData.KEY_INPUT_CONTROLLER_MAP:
			_handle_controller_button_remaps()
		ConfigData.KEY_INPUT_CONTROLLER_MAIN_AXIS, ConfigData.KEY_INPUT_CONTROLLER_SECONDARY_AXIS:
			_handle_controller_axis_remaps()
		ConfigData.KEY_ACCESSIBILITY_SCREEN_READER_ENABLED:
			_handle_key_remaps()
			_handle_controller_button_remaps()
			_handle_controller_axis_remaps()

	emit_signal("config_updated", key, old_value, new_value)

func _load_game_data_files():
	games.clear()
	systems.clear()
	var dir := DirAccess.open(config.games_dir)
	if not dir or dir.list_dir_begin(): # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		push_error("Error when opening game directory " + config.games_dir)
		return
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and \
			((_systems_raw.has(file_name) and not _systems_raw[file_name].has("#delete")) or \
			_system_renames.has(file_name)):
			_load_system_gamelists_files(config.games_dir.path_join(file_name), file_name)
		# We are not interested in files, only folders
		file_name = dir.get_next()
	dir.list_dir_end()
	# Finally order the games array
	games.sort_custom(Callable(RetroHubGameData, "sort"))

func _load_system_gamelists_files(folder_path: String, system_name: String):
	var renamed_system : String = _system_renames[system_name] if _system_renames.has(system_name) else system_name
	print("Loading games from directory " + folder_path)
	var dir := DirAccess.open(folder_path)
	if not dir or dir.list_dir_begin() :# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		push_error("Error when opening game directory " + folder_path)
		return
	var file_name := dir.get_next()
	while file_name != "":
		var full_path := folder_path.path_join(file_name)
		if dir.current_is_dir():
			# Recurse
			# TODO: prevent infinite recursion with shortcuts/symlinks
			_load_system_gamelists_files(full_path, system_name)
		else:
			if _is_file_from_system(file_name, renamed_system):
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
				var metadata_path := _get_game_data_path_from_file(system_name, full_path)
				if dir.file_exists(metadata_path):
					if not _fetch_game_data(metadata_path, game):
						push_error("Metadata file corrupt!")
						game.name = file_name
						game.age_rating = "0/0/0"
						game.has_metadata = false
				else:
					_fill_default_game_data(game, file_name)
				games.push_back(game)
		file_name = dir.get_next()
	dir.list_dir_end()

func _fill_default_game_data(game: RetroHubGameData, file_name: String):
	match game.system.name:
		"ps3":
			# PS3 games are stored in a folder with the same name as the game. Try to find it.
			var path := game.path.get_base_dir()
			while not path.is_empty():
				if not path.ends_with("PS3_GAME"):
					game.name = path.get_file()
					break
				path = path.get_base_dir()
			if path.is_empty():
				game.name = file_name
		_:
			game.name = file_name

	game.age_rating = "0/0/0"
	game.has_metadata = false

func _make_system_folder(system_raw: Dictionary):
	var path : String = config.games_dir.path_join(system_raw["name"])
	if not DirAccess.dir_exists_absolute(path):
		if DirAccess.make_dir_recursive_absolute(path):
			push_error("Failed to create system folder " + path)

func _fetch_game_data(path: String, game: RetroHubGameData) -> bool:
	var data : Dictionary = JSONUtils.load_json_file(path)
	if data.is_empty():
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
	if data.has("emulator"):
		game.emulator = data["emulator"]
	if data.has("box_texture_regions"):
		for key in data["box_texture_regions"]:
			var region_data : PackedFloat64Array = data["box_texture_regions"][key].split_floats(";")
			if region_data.size() < 4: continue
			var key_idx : int = RetroHubGameData.BoxTextureRegions.keys().find(key.to_upper())
			if key_idx == -1: key_idx = int(key)
			game.box_texture_regions[key_idx] = Rect2(region_data[0], region_data[1], region_data[2], region_data[3])
	else:
		# Update older game data with ScreenScraper box texture regions
		RetroHubScreenScraperScraper._process_box_texture_regions(game)
		_save_game_data(game)

	return true

func _get_game_data_path_from_file(system_name: String, file_name: String) -> String:
	return _get_gamelists_dir().path_join(system_name).path_join(file_name.get_file().trim_suffix(file_name.get_extension()) + "json")

func _save_game_data(game_data: RetroHubGameData, system_folder_name : String = "", signal_changes : bool = true) -> bool:
	var metadata_path : String
	if system_folder_name.is_empty():
		metadata_path = _get_game_data_path_from_file(game_data.system.name, game_data.path)
	else:
		metadata_path = _get_game_data_path_from_file(system_folder_name, game_data.path)
	FileUtils.ensure_path(metadata_path)
	var game_data_raw := {
		"name": game_data.name,
		"description": game_data.description,
		"rating": game_data.rating,
		"release_date": game_data.release_date,
		"developer": game_data.developer,
		"publisher": game_data.publisher,
		"genres": game_data.genres,
		"num_players": game_data.num_players,
		"age_rating": game_data.age_rating,
		"favorite": game_data.favorite,
		"play_count": game_data.play_count,
		"last_played": game_data.last_played,
		"has_media": game_data.has_media,
		"emulator": game_data.emulator
	}

	var box_texture_regions : Dictionary = {}
	for key in game_data.box_texture_regions.keys():
		var region_data := "%f;%f;%f;%f" % [
			game_data.box_texture_regions[key].position.x,
			game_data.box_texture_regions[key].position.y,
			game_data.box_texture_regions[key].size.x,
			game_data.box_texture_regions[key].size.y
		]
		var key_name : String = RetroHubGameData.BoxTextureRegions.keys()[key]
		box_texture_regions[key_name.to_lower()] = region_data
	game_data_raw["box_texture_regions"] = box_texture_regions

	var file := FileAccess.open(metadata_path, FileAccess.WRITE)
	if not file:
		push_error("Error when opening file %s!" % metadata_path)
		return false

	file.store_string(JSON.stringify(game_data_raw, "\t", false))
	file.close()

	if signal_changes:
		emit_signal("game_data_updated", game_data)
	return true


func _is_file_from_system(file_name: String, system_name: String) -> bool:
	var extensions : Array = _systems_raw[system_name]["extension"]
	var file_extension := ("." + file_name.get_extension()).to_lower()
	for extension in extensions:
		# Defined as an extension
		if extension.begins_with("."):
			if extension.to_lower() == file_extension:
				return true
		# Defined as exact file name
		else:
			if extension.to_lower() == file_name.to_lower():
				return true

	return false

func _load_theme() -> bool:
	var current_theme := config.current_theme
	if current_theme.ends_with(".pck"):
		theme_path = _get_themes_dir().path_join(current_theme)
	else:
		theme_path = _get_default_themes_dir().path_join(current_theme + ".pck")
	if not ProjectSettings.is_pack_loaded(theme_path):
		if not ProjectSettings.load_resource_pack(theme_path, false):
			push_error("Error when loading theme " + theme_path)
			return false

	_load_theme_data()
	if theme_data.entry_scene:
		return true
	else:
		return false

func _load_theme_data():
	var theme_raw : Dictionary = JSONUtils.load_json_file("res://theme.json")
	if theme_raw.is_empty() or not theme_raw.has("id"):
		push_error("Error when loading theme data!")
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
		theme_data.entry_scene = load(theme_raw["entry_scene"])
	if theme_raw.has("config_scene"):
		theme_data.config_scene = load(theme_raw["config_scene"])
	if theme_raw.has("app_theme"):
		theme_data.app_theme = load(theme_raw["app_theme"])

func _unload_theme():
	if theme_data:
		save_theme_config()

		theme_data = null
		if not ProjectSettings.unload_resource_pack(theme_path):
			push_error("Error when unloading theme " + theme_path)
			return

func get_theme_config(key, default_value):
	if not _theme_config.has(key):
		return default_value
	return _theme_config[key]

func set_theme_config(key, value):
	_theme_config_changed = true
	_theme_config[key] = value

func _load_theme_config():
	_theme_config = {}
	_theme_config_changed = false
	var theme_config_path := _get_theme_config_dir().path_join("config.json")
	# If the config file doesn't exist, don't try reading it
	if not FileAccess.file_exists(theme_config_path):
		return
	var json = JSONUtils.load_json_file(theme_config_path)
	if json:
		_theme_config = json
		_theme_config_old = _theme_config.duplicate()
	else:
		push_error("Error when parsing theme config at %s" % theme_config_path)
	emit_signal("theme_config_ready")

func save_theme_config():
	if _theme_config_changed:
		var theme_config_path := _get_theme_config_dir().path_join("config.json")
		FileUtils.ensure_path(theme_config_path)
		var file := FileAccess.open(theme_config_path, FileAccess.WRITE)
		if not file:
			push_error("Error when saving theme config at %s" % theme_config_path)
			return
		file.store_string(JSON.stringify(_theme_config, "\t", false))
		file.close()

		for key in _theme_config:
			if not _theme_config_old.has(key):
				emit_signal("theme_config_updated", key, "", _theme_config[key])
			elif _theme_config_old[key] != _theme_config[key]:
				emit_signal("theme_config_updated", key, _theme_config_old[key], _theme_config[key])

		_theme_config_changed = false

func _exit_tree():
	_save_config()

func _bootstrap_config_dir():
	# Create directories
	if not DirAccess.dir_exists_absolute(_get_config_dir()):
		print("First time!")
		# Create base directories
		var paths := [_get_config_dir(), _get_themes_dir(), _get_gamelists_dir(), _get_gamemedia_dir()]
		for path in paths:
			if DirAccess.make_dir_recursive_absolute(path):
				push_error("Error when creating directory " + path)

		# Bootstrap system specific configs
		for filename: String in [
			"rh_emulators.json",
			"rh_systems.json",
			"_emulator_paths.json"
			]:
			var filepath_out := _get_config_dir().path_join(filename)
			var file := FileAccess.open(filepath_out, FileAccess.WRITE)
			if not file:
				push_error("Error when opening file " + filepath_out + " for saving")
				return
			file.store_string(JSON.stringify([], "\t"))
			file.close()

		# Bootstrap credentials file
		JSONUtils.save_json_file({}, _get_config_dir().path_join("rh_credentials.json"))

func _save_config():
	if config.save_config_to_path(_get_config_file()):
		push_error("Error when saving config to " + _get_config_file())
	save_theme_config()
	if _should_save:
		_should_save = false
		JSONUtils.save_json_file(emulators_paths, _get_emulator_paths_file())

func _restore_keys(dict: Dictionary, keys: Array):
	for key in keys:
		dict[key] = true

func _save_system(system_raw: Dictionary):
	# Remove internal keys
	var restore_keys := []
	for key in ["#custom", "#modified"]:
		if system_raw.erase(key):
			restore_keys.push_back(key)

	# Find original config and modify it
	var system_config : Array = JSONUtils.load_json_file(_get_custom_systems_file())
	var idx := 0
	for child in system_config:
		if child["name"] == system_raw["name"]:
			system_config[idx] = system_raw
			JSONUtils.save_json_file(system_config, _get_custom_systems_file())
			_restore_keys(system_raw, restore_keys)
			return
		idx += 1
	# If not found, simply append info
	system_config.push_back(system_raw)
	JSONUtils.save_json_file(system_config, _get_custom_systems_file())
	_restore_keys(system_raw, restore_keys)

func _restore_system(system_raw: Dictionary):
	# Find original config and modify it
	var system_config : Array = JSONUtils.load_json_file(_get_custom_systems_file())
	for child in system_config:
		if child["name"] == system_raw["name"]:
			system_config.erase(child)
			JSONUtils.save_json_file(system_config, _get_custom_systems_file())
			# Now reload information
			var system_defaults : Array = JSONUtils.load_json_file(_get_systems_file())
			for default_child in system_defaults:
				if default_child["name"] == system_raw["name"]:
					if default_child.has("extends") and _systems_raw.has(default_child["extends"]):
						default_child.merge(_systems_raw[default_child["extends"]])
					return default_child

func _remove_custom_system(system_raw: Dictionary):
	if not system_raw.has("#custom"):
		push_error("Tried to delete default system!")
		return
	#warning-ignore:return_value_discarded
	_systems_raw.erase(system_raw["name"])
	# Find original config and modify it
	var system_config : Array = JSONUtils.load_json_file(_get_custom_systems_file())
	for child in system_config:
		if child["name"] == system_raw["name"]:
			system_config.erase(child)
			JSONUtils.save_json_file(system_config, _get_custom_systems_file())
			return

func _save_emulator(emulator_raw: Dictionary):
	# Remove internal keys
	var restore_keys := []
	for key in ["#custom", "#modified"]:
		if emulator_raw.erase(key):
			restore_keys.push_back(key)

	# Find original config and modify it
	var emulator_config : Array = JSONUtils.load_json_file(_get_custom_emulators_file())
	var idx := 0
	for child in emulator_config:
		if child["name"] == emulator_raw["name"]:
			emulator_config[idx] = emulator_raw
			JSONUtils.save_json_file(emulator_config, _get_custom_emulators_file())
			_restore_keys(emulator_raw, restore_keys)
			return
		idx += 1
	# If not found, simply append info
	emulator_config.push_back(emulator_raw)
	JSONUtils.save_json_file(emulator_config, _get_custom_emulators_file())
	_restore_keys(emulator_raw, restore_keys)

func _restore_emulator(emulator_raw: Dictionary):
	# Find original config and modify it
	var emulator_config : Array = JSONUtils.load_json_file(_get_custom_emulators_file())
	for child in emulator_config:
		if child["name"] == emulator_raw["name"]:
			emulator_config.erase(child)
			JSONUtils.save_json_file(emulator_config, _get_custom_emulators_file())
			# Now reload information
			var system_defaults : Array = JSONUtils.load_json_file(_get_emulators_file())
			for default_child in system_defaults:
				if default_child["name"] == emulator_raw["name"]:
					JSONUtils.make_system_specific(default_child, FileUtils.get_os_string())
					return default_child

func _remove_custom_emulator(emulator_raw: Dictionary):
	if not emulator_raw.has("#custom"):
		push_error("Tried to delete default emulator!")
		return
	#warning-ignore:return_value_discarded
	emulators_map.erase(emulator_raw["name"])
	# Find original config and modify it
	var emulator_config : Array = JSONUtils.load_json_file(_get_custom_emulators_file())
	for child in emulator_config:
		if child["name"] == emulator_raw["name"]:
			emulator_config.erase(child)
			JSONUtils.save_json_file(emulator_config, _get_custom_emulators_file())
			return

func _determine_sc_mode():
	# This functionality is not exposed on exported projects, so
	# we replicate it from engine code
	var exe_path := OS.get_executable_path().get_base_dir()
	if FileUtils.get_os_id() == FileUtils.OS_ID.MACOS:
		if exe_path.ends_with("MacOS") and exe_path.path_join("..").simplify_path().ends_with("Contents"):
			exe_path = exe_path.path_join("../../..").simplify_path()

	if FileAccess.file_exists(exe_path.path_join("._sc_")) or FileAccess.file_exists(exe_path.path_join("_sc_")):
		_is_sc = true

func _get_emulator_path(emulator_name: String, key: String) -> String:
	if emulators_paths.has(emulator_name) and emulators_paths[emulator_name].has(key):
		return emulators_paths[emulator_name][key]
	return ""

func _set_emulator_path(emulator_name: String, key: String, value: String) -> void:
	if value.is_empty():
		if emulators_paths.has(emulator_name):
			emulators_paths[emulator_name].erase(key)
			if emulators_paths[emulator_name].is_empty():
				emulators_paths.erase(emulator_name)
			_should_save = true
		return

	if not emulators_paths.has(emulator_name):
		emulators_paths[emulator_name] = {}
	emulators_paths[emulator_name][key] = value
	_should_save = true

func _get_config_dir() -> String:
	var path : String
	if _is_sc:
		return OS.get_executable_path().get_base_dir().path_join("config")

	match FileUtils.get_os_id():
		FileUtils.OS_ID.WINDOWS:
			path = FileUtils.get_home_dir().path_join("RetroHub")
			if RetroHub._is_dev_env():
				path += "-Dev"
			return path
		_:
			path = FileUtils.get_home_dir().path_join(".retrohub")
			if RetroHub._is_dev_env():
				path += "-dev"
	return path

func _get_config_file() -> String:
	return _get_config_dir().path_join("rh_config.json")

func _get_systems_file() -> String:
	return "res://base_config/systems.json"

func _get_emulators_file() -> String:
	return "res://base_config/emulators.json"

func _get_emulator_paths_file() -> String:
	return _get_config_dir().path_join("_emulator_paths.json")

func _get_custom_systems_file() -> String:
	return _get_config_dir().path_join("rh_systems.json")

func _get_custom_emulators_file() -> String:
	return _get_config_dir().path_join("rh_emulators.json")

func _get_default_themes_dir() -> String:
	return "res://default_themes"

func _get_themes_dir() -> String:
	return _get_config_dir().path_join("themes")

func _get_theme_config_dir() -> String:
	return _get_themes_dir().path_join("config").path_join(theme_data.id if theme_data else "")

func _get_gamelists_dir() -> String:
	return _get_config_dir().path_join("gamelists")

func _get_gamemedia_dir() -> String:
	if not config.custom_gamemedia_dir.is_empty():
		return config.custom_gamemedia_dir
	return _get_config_dir().path_join("gamemedia")
