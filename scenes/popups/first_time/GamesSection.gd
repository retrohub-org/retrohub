extends Control

signal advance_section

@onready var n_intro_lbl := %IntroLabel
@onready var n_path := %Path
@onready var n_choose_dir := %ChooseDir
@onready var n_custom_media_container := %CustomMediaContainer
@onready var n_use_custom_media := %UseCustomMedia
@onready var n_media_path := %MediaPath
@onready var n_media_choose_dir := %MediaChooseDir
@onready var n_media_warning_empty := %MediaWarningEmpty

@onready var n_next_button := %NextButton

func _ready():
	set_path(RetroHubConfig.config.games_dir)
	set_media_path(RetroHubConfig.config.custom_gamemedia_dir)
	n_use_custom_media.set_pressed_no_signal(RetroHubConfig.config.custom_gamemedia_dir.is_empty())
	_on_use_custom_media_toggled(n_use_custom_media.button_pressed)

func grab_focus():
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_intro_lbl.grab_focus()
	else:
		n_choose_dir.grab_focus()

func _on_NextButton_pressed():
	RetroHubConfig.config.games_dir = n_path.text
	RetroHubConfig.config.custom_gamemedia_dir = n_media_path.text if not n_use_custom_media.button_pressed else ""
	RetroHubConfig._load_game_data_files()
	emit_signal("advance_section")

func _on_ChooseDir_pressed():
	RetroHubUI.request_folder_load(n_path.text)
	set_path(await RetroHubUI.path_selected)

func set_path(path: String):
	if not path.is_empty():
		n_path.text = path
	query_next_btn()

func _on_use_custom_media_toggled(toggled_on: bool):
	n_custom_media_container.visible = not toggled_on
	check_empty_media()
	query_next_btn()

func check_empty_media():
	if n_use_custom_media.button_pressed:
		n_media_warning_empty.visible = false
		return
	var dir := DirAccess.open(n_media_path.text)
	dir.include_navigational = false
	n_media_warning_empty.visible = not (dir.get_files().is_empty() and dir.get_directories().is_empty())

func query_next_btn():
	n_next_button.disabled = n_path.text.is_empty() or \
		(not n_use_custom_media.button_pressed and (n_media_path.text.is_empty() or not DirAccess.dir_exists_absolute(n_media_path.text)))

func _on_media_choose_dir_pressed():
	RetroHubUI.request_folder_load(n_media_path.text)
	set_media_path(await RetroHubUI.path_selected)

func set_media_path(path: String):
	if not path.is_empty():
		n_media_path.text = path
	check_empty_media()
	query_next_btn()
