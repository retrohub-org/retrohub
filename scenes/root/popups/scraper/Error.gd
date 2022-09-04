extends Control

signal retry_entry(game_entry)

onready var n_label = $"%ErrorLabel"
onready var base_text = n_label.text

var game_entry

func set_entry(_game_entry: Control):
	game_entry = _game_entry
	n_label.text = base_text % [game_entry.game_data.path.get_file(), game_entry.data]


func _on_ErrorRetryButton_pressed():
	emit_signal("retry_entry", game_entry)
