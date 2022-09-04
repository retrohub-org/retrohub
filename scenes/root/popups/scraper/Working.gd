extends Control

signal cancel_entry(game_entry)

onready var n_label = $"%WorkingLabel"
onready var n_progress = $"%WorkingProgress"
onready var base_text = n_label.text

var game_entry

func _ready():
	RetroHubMediaHelper.connect("game_scrape_step", self, "_on_game_scrape_step")

func set_entry(_game_entry: Control):
	game_entry = _game_entry

func _on_game_scrape_step(curr: int, total: int, description: String):
	n_label.text = base_text % description
	n_progress.max_value = total
	n_progress.value = curr



func _on_WorkingCancelButton_pressed():
	emit_signal("cancel_entry", game_entry)
