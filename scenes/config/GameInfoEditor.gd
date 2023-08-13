extends Control

signal change_ocurred

@onready var n_intro_lbl := %IntroLabel
@onready var n_favorite := %Favorite
@onready var n_num_times_played := %NumTimesPlayed

var game_data : RetroHubGameData: set = set_game_data

@export var disable_edits := false

func _ready():
	#warning-ignore:return_value_discarded
	RetroHubConfig.game_data_updated.connect(_on_game_data_updated)

func _on_game_data_updated(_game_data: RetroHubGameData):
	if game_data == _game_data:
		discard_changes()

func set_game_data(_game_data: RetroHubGameData) -> void:
	game_data = _game_data
	discard_changes()

func discard_changes():
	if game_data:
		set_edit_nodes_enabled(true)
		n_favorite.set_pressed_no_signal(game_data.favorite)
		n_num_times_played.value = game_data.play_count
	else:
		set_edit_nodes_enabled(false)
		n_favorite.set_pressed_no_signal(false)
		n_num_times_played.value = 0

func set_edit_nodes_enabled(enabled: bool):
	if disable_edits:
		enabled = false
	n_favorite.disabled = !enabled
	n_num_times_played.editable = enabled

func save_changes():
	if game_data:
		game_data.favorite = n_favorite.button_pressed
		game_data.play_count = n_num_times_played.value

func grab_focus():
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_intro_lbl.grab_focus()
	else:
		n_favorite.grab_focus()

func _on_change_ocurred(_tmp = null):
	emit_signal("change_ocurred")
