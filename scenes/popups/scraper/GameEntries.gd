extends VBoxContainer

var last_entry : RetroHubScraperGameEntry = null
var focused : bool

func grab_focus():
	get_child(0).grab_focus()
	_on_GameEntries_focus_entered()

func _on_game_entry_selected(entry: RetroHubScraperGameEntry, by_app: bool):
	last_entry = entry
	if not by_app:
		focused = false

func _on_game_entry_focus_exited():
	if not get_focus_owner() is RetroHubScraperGameEntry:
		print("FFF")
		focused = false

func _on_GameEntries_focus_entered():
	if last_entry:
		last_entry.grab_focus()
	focused = true
