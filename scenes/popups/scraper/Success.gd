extends Control

@onready var n_game_metadata_editor := %GameMetadataEditor
@onready var n_no_data := %NoData

@onready var n_game_entries := %GameEntries

func grab_focus():
	if n_game_metadata_editor.visible:
		n_game_metadata_editor.grab_focus()
	else:
		n_game_entries.grab_focus()

func set_entry(game_entry: RetroHubScraperGameEntry):
	if(game_entry.data):
		n_game_metadata_editor.visible = true
		n_no_data.visible = false
		n_game_metadata_editor.game_data = game_entry.game_data
	else:
		n_game_metadata_editor.visible = false
		n_no_data.visible = true
