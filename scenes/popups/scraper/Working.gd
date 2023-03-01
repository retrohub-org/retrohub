extends Control

signal cancel_entry(game_entry)

onready var n_label = $"%WorkingLabel"
onready var n_progress = $"%WorkingProgress"
onready var n_cancel = $"%WorkingCancelButton"

var game_entry : RetroHubScraperGameEntry

func grab_focus():
	n_cancel.grab_focus()

func set_entry(_game_entry: RetroHubScraperGameEntry):
	game_entry = _game_entry
	set_text()


func _on_WorkingCancelButton_pressed():
	emit_signal("cancel_entry", game_entry)


func _on_ScraperPopup_scrape_step(_game_entry: RetroHubScraperGameEntry):
	if game_entry == _game_entry:
		# FIXME: This has to be deferred; if not, when the user spams cancel request on media and retry,
		# Godot crashes somewhere on the draw code for the n_label. Investigate further..?
		call_deferred("set_text")

func set_text():
	n_label.text = game_entry.description
	n_progress.value = game_entry.curr
	n_progress.max_value = game_entry.total
