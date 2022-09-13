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

var running_game := false
var running_game_pid := -1

var curr_game_data : RetroHubGameData = null
var curr_system_data : RetroHubSystemData = null

var is_echo : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	RetroHubConfig.connect("config_ready", self, "_on_config_ready")
	RetroHubConfig.connect("config_updated", self, "_on_config_updated")
	emit_signal("app_initializing", true)

func _on_config_ready(config_data: ConfigData):
	_load_theme()

func _on_config_updated(key: String, old_value, new_value):
	if key == ConfigData.KEY_CURRENT_THEME:
		_load_theme()

func _on_game_scrape_finished(game_data : RetroHubGameData):
	print("Game finished scraping!")

func _process(delta):
	if running_game:
		if running_game_pid == -1 or not OS.is_process_running(running_game_pid):
			stop_game()

func _on_app_closing():
	emit_signal("app_closing")

func _on_app_received_focus():
	if running_game:
		emit_signal("app_running_received_focus")
	else:
		emit_signal("app_received_focus")

func _on_app_lost_focus():
	if running_game:
		emit_signal("app_running_lost_focus")
	else:
		emit_signal("app_lost_focus")

func _load_theme():
	# Signal themes
	print("Config is ready, parsing metadata...")
	var systems : Dictionary = RetroHubConfig.systems
	var games : Array = RetroHubConfig.games
	RetroHubConfig.unload_theme()
	if not RetroHubConfig.load_theme():
		return
	emit_signal("_theme_loaded", RetroHubConfig.theme_data)
	RetroHubConfig.load_theme_config()

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

func is_input_echo() -> bool:
	return is_echo

func is_main_app() -> bool:
	return true

func quit():
	RetroHubConfig.save_config()
	get_tree().quit()

func launch_game() -> void:
	if not curr_game_data:
		printerr("No game data selected!")
		return

	curr_system_data = RetroHubConfig.systems[curr_game_data.system_name]
	print("Launching game ", curr_game_data.name)
	emit_signal("_game_loaded", curr_game_data)
	running_game = true
	running_game_pid = _launch_game_process()
	RetroHubConfig.unload_theme()

func _launch_game_process() -> int:
	var system_emulators = RetroHubConfig._systems_raw[curr_system_data.name]["emulator"]
	var emulators = RetroHubConfig.emulators_map
	var emulator
	for system_emulator in system_emulators:
		if system_emulator is Dictionary and system_emulator.has("retroarch"):
			var system_cores : Array = system_emulator["retroarch"]
			emulator = RetroHubRetroArchEmulator.new(emulators["retroarch"], curr_game_data, system_cores)
			break
		else:
			emulator = RetroHubGenericEmulator.new(emulators[system_emulator], curr_game_data)
			break

	return emulator.launch_game()

func stop_game() -> void:
	print("Stopping game")
	OS.move_window_to_foreground()
	running_game = false
	running_game_pid = -1
	_load_theme()
	yield(get_tree(), "idle_frame")
	emit_signal("app_returning", curr_system_data, curr_game_data)

func request_theme_reload():
	yield(get_tree(), "idle_frame")
	_load_theme()