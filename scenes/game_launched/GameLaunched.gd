extends CenterContainer

var game_data : RetroHubGameData setget set_game_data
var label_text : String

var low_cpu_mode_orig : bool
var low_cpu_mode_sleep_orig : int

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

func _ready():
	label_text = $Label.text

func set_game_data(_game_data : RetroHubGameData):
	game_data = _game_data
	
	$Label.text = label_text % game_data.name
