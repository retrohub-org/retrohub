extends Control

onready var n_label = $"%ErrorLabel"
onready var base_text = n_label.text

func set_entry(game_entry: Control):
	n_label.text = base_text % [game_entry.game_data.path.get_file(), game_entry.data]
