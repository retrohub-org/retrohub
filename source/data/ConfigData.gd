extends Resource
class_name ConfigData

signal config_updated(key, old_value, new_value)

var _config_changed := false
var _old_config : Dictionary

# Games directory
var config_version : int = 2
var is_first_time : bool = true: set = _set_is_first_time
var games_dir : String = FileUtils.get_home_dir().path_join("ROMS"): set = _set_games_dir
var current_theme : String = "default": set = _set_current_theme
var lang : String = "en": set = _set_lang
var fullscreen : bool = true: set = _set_fullscreen
var vsync : bool = true: set = _set_vsync
var render_resolution : int = 100: set = _set_render_resolution
var region : String = "usa": set = _set_region
var rating_system : String = "esrb": set = _set_rating_system
var date_format : String = "mm/dd/yyyy": set = _set_date_format
var system_names : Dictionary = ConfigData.default_system_names(): set = _set_system_names
var scraper_hash_file_size : int = 64: set = _set_scraper_hash_file_size
var scraper_ss_use_custom_account : bool = false: set = _set_scraper_ss_use_custom_account
var scraper_ss_max_threads : int = 6: set = _set_scraper_ss_max_threads
var custom_input_remap : String = "": set = _set_custom_input_remap
var input_key_map : Dictionary = ConfigData.default_input_key_map(): set = _set_input_key_map
var input_controller_map : Dictionary = ConfigData.default_input_controller_map(): set = _set_input_controller_map
var input_controller_main_axis : String = "left": set = _set_input_controller_main_axis
var input_controller_secondary_axis : String = "right": set = _set_input_controller_secondary_axis
var input_controller_icon_type : String = "auto": set = _set_input_controller_icon_type
var input_controller_echo_pre_delay: float = 0.75: set = _set_input_controller_echo_pre_delay
var input_controller_echo_delay: float = 0.15: set = _set_input_controller_echo_delay
var virtual_keyboard_layout : String = "qwerty": set = _set_virtual_keyboard_layout
var virtual_keyboard_type : String = ConfigData.default_virtual_keyboard_type(): set = _set_virtual_keyboard_type
var virtual_keyboard_show_on_controller : bool = true: set = _set_virtual_keyboard_show_on_controller
var virtual_keyboard_show_on_mouse : bool = false: set = _set_virtual_keyboard_show_on_mouse
var accessibility_screen_reader_enabled : bool = true: set = _set_accessibility_screen_reader_enabled
var custom_gamemedia_dir : String = "": set = _set_custom_gamemedia_dir
var ui_volume : int = 100: set = _set_ui_volume
var integration_rcheevos_enabled : bool = false: set = _set_integration_rcheevos_enabled

const KEY_CONFIG_VERSION = "config_version"
const KEY_IS_FIRST_TIME = "is_first_time"
const KEY_GAMES_DIR = "games_dir"
const KEY_CURRENT_THEME = "current_theme"
const KEY_LANG = "lang"
const KEY_FULLSCREEN = "fullscreen"
const KEY_VSYNC = "vsync"
const KEY_RENDER_RESOLUTION = "render_resolution"
const KEY_REGION = "region"
const KEY_RATING_SYSTEM = "rating_system"
const KEY_DATE_FORMAT = "date_format"
const KEY_SYSTEM_NAMES = "system_names"
const KEY_SCRAPER_HASH_FILE_SIZE = "scraper_hash_file_size"
const KEY_SCRAPER_SS_USE_CUSTOM_ACCOUNT = "scraper_ss_use_custom_account"
const KEY_SCRAPER_SS_MAX_THREADS = "scraper_ss_max_threads"
const KEY_CUSTOM_INPUT_REMAP = "custom_input_remap"
const KEY_INPUT_KEY_MAP = "input_key_map"
const KEY_INPUT_CONTROLLER_MAP = "input_controller_map"
const KEY_INPUT_CONTROLLER_MAIN_AXIS = "input_controller_main_axis"
const KEY_INPUT_CONTROLLER_SECONDARY_AXIS = "input_controller_secondary_axis"
const KEY_INPUT_CONTROLLER_ICON_TYPE = "input_controller_icon_type"
const KEY_INPUT_CONTROLLER_ECHO_PRE_DELAY = "input_controller_echo_pre_delay"
const KEY_INPUT_CONTROLLER_ECHO_DELAY = "input_controller_echo_delay"
const KEY_VIRTUAL_KEYBOARD_LAYOUT = "virtual_keyboard_layout"
const KEY_VIRTUAL_KEYBOARD_TYPE = "virtual_keyboard_type"
const KEY_VIRTUAL_KEYBOARD_SHOW_ON_CONTROLLER = "virtual_keyboard_show_on_controller"
const KEY_VIRTUAL_KEYBOARD_SHOW_ON_MOUSE = "virtual_keyboard_show_on_mouse"
const KEY_ACCESSIBILITY_SCREEN_READER_ENABLED = "accessibility_screen_reader_enabled"
const KEY_CUSTOM_GAMEMEDIA_DIR = "custom_gamemedia_dir"
const KEY_UI_VOLUME = "ui_volume"
const KEY_INTEGRATION_RCHEEVOS_ENABLED = "integration_rcheevos_enabled"


const _keys = [
	KEY_CONFIG_VERSION,
	KEY_IS_FIRST_TIME,
	KEY_GAMES_DIR,
	KEY_CURRENT_THEME,
	KEY_LANG,
	KEY_FULLSCREEN,
	KEY_VSYNC,
	KEY_RENDER_RESOLUTION,
	KEY_REGION,
	KEY_RATING_SYSTEM,
	KEY_DATE_FORMAT,
	KEY_SYSTEM_NAMES,
	KEY_SCRAPER_HASH_FILE_SIZE,
	KEY_SCRAPER_SS_USE_CUSTOM_ACCOUNT,
	KEY_SCRAPER_SS_MAX_THREADS,
	KEY_CUSTOM_INPUT_REMAP,
	KEY_INPUT_KEY_MAP,
	KEY_INPUT_CONTROLLER_MAP,
	KEY_INPUT_CONTROLLER_MAIN_AXIS,
	KEY_INPUT_CONTROLLER_SECONDARY_AXIS,
	KEY_INPUT_CONTROLLER_ICON_TYPE,
	KEY_INPUT_CONTROLLER_ECHO_PRE_DELAY,
	KEY_INPUT_CONTROLLER_ECHO_DELAY,
	KEY_VIRTUAL_KEYBOARD_LAYOUT,
	KEY_VIRTUAL_KEYBOARD_TYPE,
	KEY_VIRTUAL_KEYBOARD_SHOW_ON_CONTROLLER,
	KEY_VIRTUAL_KEYBOARD_SHOW_ON_MOUSE,
	KEY_ACCESSIBILITY_SCREEN_READER_ENABLED,
	KEY_CUSTOM_GAMEMEDIA_DIR,
	KEY_UI_VOLUME,
	KEY_INTEGRATION_RCHEEVOS_ENABLED
]

var _should_save : bool = true

static func default_system_names() -> Dictionary:
	return {
		"genesis": "genesis",
		"nes": "nes",
		"snes": "snes",
		"tg16": "tg16",
		"tg-cd": "tg-cd",
		"odyssey2": "odyssey2"
	}

static func get_system_rename_options(system: String) -> Array:
	match system:
		"genesis":
			return ["genesis", "megadrive"]
		"nes":
			return ["nes", "famicom"]
		"snes":
			return ["snes", "sfc"]
		"tg16":
			return ["tg16", "pcengine"]
		"tg-cd":
			return ["tg-cd", "pcenginecd"]
		"odyssey2":
			return ["odyssey2", "videopac"]
		_:
			return [system]


static func default_input_key_map() -> Dictionary:
	return {
		"rh_accept": [KEY_ENTER],
		"rh_back": [KEY_BACKSPACE],
		"rh_major_option": [KEY_CTRL],
		"rh_minor_option": [KEY_ALT],
		"rh_menu": [KEY_ESCAPE],
		"rh_theme_menu": [KEY_SHIFT],
		"rh_up": [KEY_UP, KEY_W],
		"rh_down": [KEY_DOWN, KEY_S],
		"rh_left": [KEY_LEFT, KEY_A],
		"rh_right": [KEY_RIGHT, KEY_D],
		"rh_left_shoulder": [KEY_Q],
		"rh_right_shoulder": [KEY_E]
	}

static func default_input_controller_map() -> Dictionary:
	return {
		"rh_accept": [JOY_BUTTON_A],
		"rh_back": [JOY_BUTTON_B],
		"rh_major_option": [JOY_BUTTON_X],
		"rh_minor_option": [JOY_BUTTON_Y],
		"rh_menu": [JOY_BUTTON_START],
		"rh_theme_menu": [JOY_BUTTON_BACK],
		"rh_up": [JOY_BUTTON_DPAD_UP],
		"rh_down": [JOY_BUTTON_DPAD_DOWN],
		"rh_left": [JOY_BUTTON_DPAD_LEFT],
		"rh_right": [JOY_BUTTON_DPAD_RIGHT],
		"rh_left_shoulder": [JOY_BUTTON_LEFT_SHOULDER],
		"rh_right_shoulder": [JOY_BUTTON_RIGHT_SHOULDER]
	}

static func default_virtual_keyboard_type() -> String:
	if FileUtils.is_steam_deck():
		return "steam"
	else:
		return "builtin"

func _get_stored_version(config: Dictionary) -> int:
	if config.has(KEY_CONFIG_VERSION):
		return int(config[KEY_CONFIG_VERSION])
	else:
		return 0

func _set_is_first_time(_is_first_time):
	mark_for_saving()
	is_first_time = _is_first_time

func _set_games_dir(_games_dir):
	mark_for_saving()
	games_dir = _games_dir

func _set_current_theme(_current_theme):
	mark_for_saving()
	if "res://default_themes" in _current_theme:
		current_theme = _current_theme.get_file().get_basename()
	else:
		current_theme = _current_theme

func _set_lang(_lang):
	mark_for_saving()
	lang = _lang

func _set_fullscreen(_fullscreen):
	mark_for_saving()
	fullscreen = _fullscreen

	if _should_save:
		var mode := DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		_handle_internal_config("display", "window/size/mode", mode)

func _set_vsync(_vsync):
	mark_for_saving()
	vsync = _vsync
	
	if _should_save:
		var mode := DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
		_handle_internal_config("display", "window/vsync/vsync_mode", mode)

func _set_render_resolution(_render_resolution):
	mark_for_saving()
	render_resolution = _render_resolution

func _set_region(_region):
	mark_for_saving()
	region = _region

func _set_rating_system(_rating_system):
	mark_for_saving()
	rating_system = _rating_system

func _set_date_format(_date_format):
	mark_for_saving()
	date_format = _date_format

func _set_system_names(_system_names):
	mark_for_saving()
	system_names = _system_names.duplicate(true)

func _set_scraper_hash_file_size(_scraper_hash_file_size):
	mark_for_saving()
	scraper_hash_file_size = _scraper_hash_file_size

func _set_scraper_ss_use_custom_account(_scraper_ss_use_custom_account):
	mark_for_saving()
	scraper_ss_use_custom_account = _scraper_ss_use_custom_account

func _set_scraper_ss_max_threads(_scraper_ss_max_threads):
	mark_for_saving()
	scraper_ss_max_threads = _scraper_ss_max_threads

func _set_custom_input_remap(_custom_input_remap):
	mark_for_saving()
	custom_input_remap = _custom_input_remap

func _set_input_key_map(_input_key_map):
	mark_for_saving()
	input_key_map = _input_key_map.duplicate(true)

	# Change all values to int
	for key in input_key_map:
		var arr_int := []
		for val in input_key_map[key]:
			arr_int.push_back(int(val))
		input_key_map[key] = arr_int

func _set_input_controller_map(_input_controller_map):
	mark_for_saving()
	input_controller_map = _input_controller_map.duplicate(true)

	# Change all values to int
	for key in input_controller_map:
		var arr_int := []
		for val in input_controller_map[key]:
			arr_int.push_back(int(val))
		input_controller_map[key] = arr_int

func _set_input_controller_main_axis(_input_controller_main_axis):
	mark_for_saving()
	input_controller_main_axis = _input_controller_main_axis

func _set_input_controller_secondary_axis(_input_controller_secondary_axis):
	mark_for_saving()
	input_controller_secondary_axis = _input_controller_secondary_axis

func _set_input_controller_icon_type(_input_controller_icon_type):
	mark_for_saving()
	input_controller_icon_type = _input_controller_icon_type

func _set_input_controller_echo_pre_delay(_input_controller_echo_pre_delay):
	mark_for_saving()
	input_controller_echo_pre_delay = _input_controller_echo_pre_delay

func _set_input_controller_echo_delay(_input_controller_echo_delay):
	mark_for_saving()
	input_controller_echo_delay = _input_controller_echo_delay

func _set_virtual_keyboard_layout(_virtual_keyboard_layout):
	mark_for_saving()
	virtual_keyboard_layout = _virtual_keyboard_layout

func _set_virtual_keyboard_type(_virtual_keyboard_type):
	mark_for_saving()
	virtual_keyboard_type = _virtual_keyboard_type

func _set_virtual_keyboard_show_on_controller(_virtual_keyboard_show_on_controller):
	mark_for_saving()
	virtual_keyboard_show_on_controller = _virtual_keyboard_show_on_controller

func _set_virtual_keyboard_show_on_mouse(_virtual_keyboard_show_on_mouse):
	mark_for_saving()
	virtual_keyboard_show_on_mouse = _virtual_keyboard_show_on_mouse

func _set_accessibility_screen_reader_enabled(_accessibility_screen_reader_enabled):
	mark_for_saving()
	accessibility_screen_reader_enabled = _accessibility_screen_reader_enabled

func _set_custom_gamemedia_dir(_custom_gamemedia_dir):
	mark_for_saving()
	custom_gamemedia_dir = _custom_gamemedia_dir

func _set_ui_volume(_ui_volume):
	mark_for_saving()
	ui_volume = _ui_volume

func _set_integration_rcheevos_enabled(_integration_rcheevos_enabled):
	mark_for_saving()
	integration_rcheevos_enabled = _integration_rcheevos_enabled

func mark_for_saving():
	if _should_save:
		_config_changed = true

func load_config_from_path(path: String) -> int:
	# Open file
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Error opening config file " + path + " for reading!")
		return FileAccess.get_open_error()

	# Parse file
	var json = JSON.new()
	if json.parse(file.get_as_text()):
		push_error("Error parsing config file!")
		return ERR_FILE_CORRUPT

	var json_result : Dictionary = json.get_data()
	# Pre-process configuration due to app updates
	process_raw_config_changes(json_result)

	# Dictionary ready for retrieval
	_old_config = json_result

	_should_save = false
	for key in _keys:
		# Config version should not be loaded
		if key == KEY_CONFIG_VERSION: continue
		if _old_config.has(key):
			set(key, _old_config[key])
		else:
			process_new_change(key)
			_config_changed = true
	_should_save = true

	return OK

func save_config_to_path(path: String, force_save: bool = false) -> int:
	if not _config_changed and not force_save:
		return OK

	# Open file
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Error opening config file " + path + "for saving!")
		return FileAccess.get_open_error()

	# Construct dict and save config
	var dict := {}
	for key in _keys:
		dict[key] = get(key)

	# Save JSON to file
	var json_output := JSON.stringify(dict, "\t", false)
	file.store_string(json_output)
	file.close()
	_config_changed = false

	# Now signal any changes that ocurred to the config file
	for key in _keys:
		if _old_config.has(key):
			if _old_config[key] is Dictionary:
				if _old_config[key].values().hash() != get(key).values().hash():
					emit_signal("config_updated", key, _old_config[key], get(key))
			elif _old_config[key] != get(key):
				emit_signal("config_updated", key, _old_config[key], get(key))
		else:
			emit_signal("config_updated", key, null, get(key))

	_old_config = dict.duplicate(true)
	return OK

func process_new_change(key: String):
	match key:
		KEY_ACCESSIBILITY_SCREEN_READER_ENABLED:
			accessibility_screen_reader_enabled = is_first_time

func process_raw_config_changes(config: Dictionary):
	## Before config version was introduced
	# Scraper credentials were moved to a dedicated file
	var creds := [
		"scraper_ss_username",
		"scraper_ss_password"
	]

	for cred in creds:
		if config.has(cred):
			RetroHubConfig._set_credential(cred, config[cred])
			#warning-ignore:return_value_discarded
			config.erase(cred)
			_should_save = true

	# Old raw configs that were renamed
	if config.has(KEY_INPUT_CONTROLLER_MAIN_AXIS) and config[KEY_INPUT_CONTROLLER_MAIN_AXIS] is float:
		_should_save = true
		match int(config[KEY_INPUT_CONTROLLER_MAIN_AXIS]):
			JOY_AXIS_RIGHT_X:
				config[KEY_INPUT_CONTROLLER_MAIN_AXIS] = "right"
			JOY_AXIS_LEFT_X, _:
				config[KEY_INPUT_CONTROLLER_MAIN_AXIS] = "left"

	if config.has(KEY_INPUT_CONTROLLER_SECONDARY_AXIS) and config[KEY_INPUT_CONTROLLER_SECONDARY_AXIS] is float:
		_should_save = true
		match int(config[KEY_INPUT_CONTROLLER_SECONDARY_AXIS]):
			JOY_AXIS_RIGHT_X:
				config[KEY_INPUT_CONTROLLER_SECONDARY_AXIS] = "right"
			JOY_AXIS_LEFT_X, _:
				config[KEY_INPUT_CONTROLLER_SECONDARY_AXIS] = "left"

	if config.has(KEY_INPUT_CONTROLLER_ICON_TYPE) and config[KEY_INPUT_CONTROLLER_ICON_TYPE] is float:
		_should_save = true
		match int(config[KEY_INPUT_CONTROLLER_ICON_TYPE]):
			1:
				config[KEY_INPUT_CONTROLLER_ICON_TYPE] = "xbox360"
			2:
				config[KEY_INPUT_CONTROLLER_ICON_TYPE] = "xboxone"
			3:
				config[KEY_INPUT_CONTROLLER_ICON_TYPE] = "xboxseries"
			4:
				config[KEY_INPUT_CONTROLLER_ICON_TYPE] = "ps3"
			5:
				config[KEY_INPUT_CONTROLLER_ICON_TYPE] = "ps4"
			6:
				config[KEY_INPUT_CONTROLLER_ICON_TYPE] = "ps5"
			7:
				config[KEY_INPUT_CONTROLLER_ICON_TYPE] = "switch"
			8:
				config[KEY_INPUT_CONTROLLER_ICON_TYPE] = "joycon"
			9:
				config[KEY_INPUT_CONTROLLER_ICON_TYPE] = "steam"
			10:
				config[KEY_INPUT_CONTROLLER_ICON_TYPE] = "steamdeck"
			11:
				config[KEY_INPUT_CONTROLLER_ICON_TYPE] = "luna"
			12:
				config[KEY_INPUT_CONTROLLER_ICON_TYPE] = "stadia"
			13:
				config[KEY_INPUT_CONTROLLER_ICON_TYPE] = "ouya"
			0, _:
				config[KEY_INPUT_CONTROLLER_ICON_TYPE] = "auto"

	var version := _get_stored_version(config)
	while version < config_version:
		_should_save = true
		_config_changed = true
		_handle_config_update(config, version)
		version += 1

func _handle_config_update(config: Dictionary, version: int):
	match version:
		1:
			# Some configs are now stored in Godot format, allowing some
			# properties to be set on launch time (e.g. fullscreen)
			_set_fullscreen(fullscreen)
			_set_vsync(vsync)
			# Manually set these properties one last time, in order to
			# be completely transparent to the user
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if (RetroHubConfig.config.fullscreen)
				else DisplayServer.WINDOW_MODE_WINDOWED
			)
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ENABLED if (RetroHubConfig.config.vsync)
				else DisplayServer.VSYNC_DISABLED)
		0:
			# First config version; RetroHub port from Godot 3 to Godot 4
			# Input remaps have to be reset
			config[KEY_INPUT_KEY_MAP] = input_key_map
			config[KEY_CUSTOM_INPUT_REMAP] = custom_input_remap
			config[KEY_INPUT_CONTROLLER_MAP] = input_controller_map
			RetroHubUI.call_deferred("show_warning", "The following settings had to be reset due to incompatible changes in RetroHub:\n \n- Keyboard/controller remaps\n- Controller custom layout\n \nPlease reconfigure these in the Settings menu if desired.")

func _handle_internal_config(section: String, key: String, value: Variant) -> void:
	var internal_config_file : String = ProjectSettings.get("application/config/project_settings_override")
	if not internal_config_file or internal_config_file.is_empty():
		push_error("Internal config file path not found!")
		return
	var internal_config := ConfigFile.new()
	if FileAccess.file_exists(internal_config_file) and internal_config.load(internal_config_file):
		push_error("Failed loading internal config file!")
		return
	internal_config.set_value(section, key, value)
	if internal_config.save(internal_config_file):
		push_error("Failed saving internal config file!")
