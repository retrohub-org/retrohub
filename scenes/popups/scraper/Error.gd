extends Control

signal retry_entry(game_entry, req)

@onready var n_label := %ErrorLabel
@onready var n_retry := %ErrorRetryButton

@onready var base_text : String = n_label.text

var game_entry : RetroHubScraperGameEntry
var req

func grab_focus():
	n_retry.grab_focus()

func set_entry(_game_entry: RetroHubScraperGameEntry):
	game_entry = _game_entry
	n_label.text = base_text % [game_entry.game_data.path.get_file(), game_entry.data[0]]
	req = game_entry.data[1]

func _on_ErrorRetryButton_pressed():
	emit_signal("retry_entry", game_entry, req)
