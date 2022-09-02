extends Control

onready var n_game_metadata_editor = $"%GameMetadataEditor"

func set_entry(game_entry: Control):
	n_game_metadata_editor.game_data = game_entry.game_data
