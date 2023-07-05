extends Control

@onready var n_save_btn := %Save
@onready var n_discard_btn := %Discard

@onready var n_game_metadata_editor := %GameMetadataEditor

func set_game_data(game_data: RetroHubGameData) -> void:
	n_game_metadata_editor.game_data = game_data

func grab_focus():
	n_game_metadata_editor.grab_focus()

func _on_GameMetadataEditor_change_ocurred():
	n_save_btn.disabled = false
	n_discard_btn.disabled = false


func _on_GameMetadataEditor_reset_state():
	n_save_btn.disabled = true
	n_discard_btn.disabled = true
