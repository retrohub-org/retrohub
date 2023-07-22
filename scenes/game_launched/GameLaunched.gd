extends Control

var low_cpu_mode_orig : bool
var low_cpu_mode_sleep_orig : int

@onready var n_emu_logo := %EmuLogo
@onready var n_game_name := %GameName
@onready var n_emu_name := %EmuName

@onready var n_kill_press_progress := %KillPressProgress
@onready var n_timer := %Timer

@onready var game_name_orig_text : String = n_game_name.text
@onready var emu_name_orig_text : String = n_emu_name.text

func _enter_tree():
	low_cpu_mode_orig = OS.low_processor_usage_mode
	low_cpu_mode_sleep_orig = OS.low_processor_usage_mode_sleep_usec

	OS.low_processor_usage_mode = true
	# 30 FPS
	OS.low_processor_usage_mode_sleep_usec = 1000000 / 30

func _exit_tree():
	# Restore old CPU mode settings
	OS.low_processor_usage_mode = low_cpu_mode_orig
	OS.low_processor_usage_mode_sleep_usec = low_cpu_mode_sleep_orig

func _notification(what):
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN:
			# 30 FPS
			OS.low_processor_usage_mode_sleep_usec = 1000000 / 30
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			# 10 FPS
			OS.low_processor_usage_mode_sleep_usec = 1000000 / 10
			n_timer.stop()

func _process(delta):
	if n_timer.is_stopped():
		n_kill_press_progress.value = 0
	else:
		n_kill_press_progress.value = n_timer.wait_time - n_timer.time_left

func _input(event):
	if get_window().has_focus():
		if event.is_action_released("rh_menu"):
			n_timer.stop()
		if event.is_action_pressed("rh_menu"):
			n_timer.start()

func set_info(logo_path: String, game_name: String, emu_name: String):
	n_emu_logo.texture = load(logo_path)
	n_game_name.text = game_name_orig_text % game_name
	n_emu_name.text = emu_name_orig_text % emu_name


func _on_Timer_timeout():
	RetroHub.kill_game_process()
