extends Node

signal app_initializing
signal app_closing
signal app_received_focus
signal app_lost_focus
signal app_returning(system_data, game_data)

signal system_receive_start()
signal system_received(system_data)
signal system_receive_end()

signal game_receive_start()
signal game_received(game_data)
signal game_receive_end()

signal game_media_received(game_data, game_media_data)

signal _theme_loaded(theme)
signal _game_loaded(game_data)

var _running_game := false
var _running_game_pid := -1

var curr_game_data : RetroHubGameData = null

var launched_system_data : RetroHubSystemData = null
var launched_game_data : RetroHubGameData = null

var _is_echo : bool = false

const version_major := 0
const version_minor := 0
const version_patch := 7
const version_extra := "-alpha"
const version_str := "%d.%d.%d%s" % [version_major, version_minor, version_patch, version_extra]

# Called when the node enters the scene tree for the first time.
func _ready():
	RetroHubConfig.connect("config_ready", self, "_on_config_ready")
	RetroHubConfig.connect("config_updated", self, "_on_config_updated")
	emit_signal("app_initializing", true)

func _on_config_ready(config_data: ConfigData):
	if not config_data.is_first_time:
		load_theme()

func _on_config_updated(key: String, old_value, new_value):
	if key == ConfigData.KEY_CURRENT_THEME:
		load_theme()

func _on_game_scrape_finished(game_data : RetroHubGameData):
	print("Game finished scraping!")

func _process(delta):
	if _running_game:
		if _running_game_pid == -1 or not OS.is_process_running(_running_game_pid):
			stop_game()

func _on_app_closing():
	emit_signal("app_closing")

func _on_app_received_focus():
	emit_signal("app_received_focus")

func _on_app_lost_focus():
	emit_signal("app_lost_focus")

func load_theme():
	# Signal themes
	print("Config is ready, parsing metadata...")
	var systems : Dictionary = RetroHubConfig.systems
	var games : Array = RetroHubConfig.games
	RetroHubConfig.unload_theme()
	if not RetroHubConfig.load_theme():
		return
	RetroHubMedia._start_thread()
	emit_signal("_theme_loaded", RetroHubConfig.theme_data)
	# Load theme config
	RetroHubConfig.load_theme_config()

	if not systems.empty():
		emit_signal("system_receive_start")
		for system in systems.values():
			emit_signal("system_received", system)
		emit_signal("system_receive_end")

		emit_signal("game_receive_start")
		for game in games:
			emit_signal("game_received", game)
		emit_signal("game_receive_end")

func set_curr_game_data(game_data: RetroHubGameData) -> void:
	curr_game_data = game_data


func is_main_app() -> bool:
	return true

func _is_dev_env() -> bool:
	return not OS.has_feature("standalone")

func is_input_echo() -> bool:
	return _is_echo

func quit():
	RetroHubConfig.save_config()
	RetroHubMedia._stop_thread()
	get_tree().quit()

func launch_game() -> void:
	if not curr_game_data:
		printerr("No game data selected!")
		return

	launched_game_data = curr_game_data
	_update_game_statistics()
	launched_system_data = launched_game_data.system
	print("Launching game ", launched_game_data.name)
	RetroHubMedia._stop_thread()
	emit_signal("_game_loaded", launched_game_data)
	_running_game = true
	_running_game_pid = _launch_game_process()
	RetroHubConfig.unload_theme()

func _launch_game_process() -> int:
	var system_emulators = RetroHubConfig._systems_raw[launched_system_data.name]["emulator"]
	var emulators = RetroHubConfig.emulators_map
	var emulator
	for system_emulator in system_emulators:
		if system_emulator is Dictionary and system_emulator.has("retroarch"):
			var system_cores : Array = system_emulator["retroarch"]
			emulator = RetroHubRetroArchEmulator.new(emulators["retroarch"], launched_game_data, system_cores)
			break
		else:
			emulator = RetroHubGenericEmulator.new(emulators[system_emulator], launched_game_data)
			break

	if emulator:
		return emulator.launch_game()
	else:
		return -1

func _update_game_statistics():
	var time_dict := Time.get_datetime_dict_from_system()
	launched_game_data.last_played = RegionUtils.globalize_date_dict(time_dict)
	launched_game_data.play_count += 1
	RetroHubConfig.save_game_data(launched_game_data)


func stop_game() -> void:
	print("Stopping game")
	OS.move_window_to_foreground()
	_running_game = false
	_running_game_pid = -1
	load_theme()
	yield(get_tree(), "idle_frame")
	emit_signal("app_returning", launched_system_data, launched_game_data)

func request_theme_reload():
	yield(get_tree(), "idle_frame")
	load_theme()
