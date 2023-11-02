extends Control

@onready var n_save_btn := %Save
@onready var n_discard_btn := %Discard

@onready var n_editor_tab := %EditorTab
@onready var n_game_metadata_editor := %Metadata
@onready var n_game_info_editor := %Info
@onready var n_game_emulator_editor := %Emulator

func set_game_data(game_data: RetroHubGameData) -> void:
	n_editor_tab.current_tab = 0
	n_game_metadata_editor.game_data = game_data
	n_game_info_editor.game_data = game_data
	n_game_emulator_editor.game_data = game_data
	_on_reset_state()

func grab_focus():
	# FIXME: For some reason, right shoulder button focus without problem,
	# but left shoulder button doesn't. Godot bug?
	# Yielding a frame
	await get_tree().process_frame
	match n_editor_tab.current_tab:
		0:
			n_game_metadata_editor.grab_focus()
		1:
			n_game_info_editor.grab_focus()
		2:
			n_game_emulator_editor.grab_focus()

func _on_change_ocurred():
	n_save_btn.disabled = false
	n_discard_btn.disabled = false


func _on_reset_state():
	n_save_btn.disabled = true
	n_discard_btn.disabled = true


func _on_save_pressed():
	n_game_metadata_editor.save_changes()
	n_game_info_editor.save_changes()
	n_game_emulator_editor.save_changes()
	if RetroHubConfig._save_game_data(n_game_metadata_editor.game_data):
		_on_reset_state()


func _on_discard_pressed():
	n_game_metadata_editor.discard_changes()
	n_game_info_editor.discard_changes()
	n_game_emulator_editor.discard_changes()
	_on_reset_state()


func _on_editor_tab_changed(tab_container, enter_tab):
	self.grab_focus()


func _on_h_separator_focus_entered():
	# Focus comes from above
	self.grab_focus()


func _on_editor_tab_focus_entered():
	# Focus comes from below
	match n_editor_tab.current_tab:
		0:
			%Metadata.get_node("ScrollContainer/VBoxContainer/HBoxContainer8/VBoxContainer/HBoxContainer2/VariablePlayersMax").grab_focus()
		1:
			%Info.get_node("ScrollContainer/VBoxContainer/HBoxContainer2/NumTimesPlayed").grab_focus()
		2:
			if RetroHubConfig.config.accessibility_screen_reader_enabled:
				%Emulator.get_node("ScrollContainer/VBoxContainer/DisclaimerLabel").grab_focus()
			else:
				%Emulator.get_node("ScrollContainer/VBoxContainer/HBoxContainer2/EmulatorOptions").grab_focus()
