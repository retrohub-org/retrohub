extends Control

signal cancel_entry(game_entry)

var game_entry

func set_entry(_game_entry: Control):
	game_entry = _game_entry


func _on_WaitingCancelButton_pressed():
	emit_signal("cancel_entry", game_entry)
