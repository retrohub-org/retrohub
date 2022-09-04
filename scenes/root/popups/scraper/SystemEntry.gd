extends VBoxContainer

export(PackedScene) var game_entry_instance : PackedScene

onready var n_label := $"%Label"
onready var n_children := $"%Children"

var system_name : String setget set_system_name

func grab_focus():
	if n_children.get_child_count() > 0:
		n_children.get_child(0).pressed = true

func set_system_name(_system_name : String):
	system_name = _system_name
	n_label.text = system_name

func add_game_entry(game_data: RetroHubGameData, group: ButtonGroup):
	var game_entry : RetroHubScraperGameEntry = game_entry_instance.instance()
	n_children.add_child(game_entry)
	game_entry.game_data = game_data
	game_entry.fetch_mode = RetroHubScraperGameEntry.FETCH_METADATA | RetroHubScraperGameEntry.FETCH_MEDIA
	game_entry.check_mode = RetroHubScraperGameEntry.CHECK_HASH
	game_entry.state = RetroHubScraperGameEntry.State.WAITING
	game_entry.group = group
	return game_entry
