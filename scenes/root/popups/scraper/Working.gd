extends Control

onready var n_label = $"%WorkingLabel"
onready var n_progress = $"%WorkingProgress"
onready var base_text = n_label.text

func _ready():
	RetroHubMediaHelper.connect("game_scrape_step", self, "_on_game_scrape_step")

func set_entry(game_entry: Control):
	pass

func _on_game_scrape_step(curr: int, total: int, description: String):
	n_label.text = base_text % description
	n_progress.max_value = total
	n_progress.value = curr
