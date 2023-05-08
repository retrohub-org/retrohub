extends Control

signal cancel_entry(game_entry)

@onready var n_waiting_cancel_button := $"%WaitingCancelButton"

var game_entry : RetroHubScraperGameEntry

func grab_focus():
	n_waiting_cancel_button.grab_focus()

func set_entry(_game_entry: RetroHubScraperGameEntry):
	game_entry = _game_entry


func _on_WaitingCancelButton_pressed():
	emit_signal("cancel_entry", game_entry)
