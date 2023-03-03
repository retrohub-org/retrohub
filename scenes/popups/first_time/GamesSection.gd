extends Control

signal advance_section

onready var n_path := $"%Path"
onready var n_choose_dir := $"%ChooseDir"
onready var n_next_button := $"%NextButton"

func _ready():
	set_path(RetroHubConfig.config.games_dir)

func grab_focus():
	n_choose_dir.grab_focus()

func _on_NextButton_pressed():
	RetroHubConfig.config.games_dir = n_path.text
	RetroHubConfig.load_game_data_files()
	emit_signal("advance_section")

func _on_ChooseDir_pressed():
	RetroHubUI.request_folder_load(n_path.text)
	set_path(yield(RetroHubUI, "path_selected"))

func set_path(path: String):
	if not path.empty():
		n_path.text = path
	n_next_button.disabled = n_path.text.empty()
