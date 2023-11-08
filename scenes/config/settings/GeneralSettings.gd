extends Control

@onready var n_intro_lbl := %IntroLabel
@onready var n_game_lib_dir := %GameLibDir
@onready var n_set_game_path := %SetGamePath
@onready var n_themes := %Themes
@onready var n_language := %Language
@onready var n_first_time_wizard_warning := %FirstTimeWizardWarning

@onready var n_ui_volume_label := %UIVolumeLabel
@onready var n_ui_volume := %UIVolume

@onready var n_graphics_mode := %GraphicsMode
@onready var n_vsync := %VSync
@onready var n_render_res_label := %RenderResLabel
@onready var n_render_res := %RenderRes
@onready var n_screen_reader := %ScreenReader

var theme_id_map := {}

func _ready():
	#warning-ignore:return_value_discarded
	RetroHubConfig.config_ready.connect(_on_config_ready)
	#warning-ignore:return_value_discarded
	RetroHubConfig.config_updated.connect(_on_config_updated)

func grab_focus():
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_intro_lbl.grab_focus()
	else:
		n_set_game_path.grab_focus()

func set_themes():
	n_themes.clear()
	theme_id_map.clear()
	var id := 0
	var file := FileAccess.open("res://default_themes/themes.txt", FileAccess.READ)
	# Default themes
	if file:
		# Skip first line
		#warning-ignore:return_value_discarded
		file.get_line()
		while file.get_position() < file.get_length():
			var theme_pck := file.get_line()
			if theme_pck.ends_with(".pck"):
				n_themes.add_item(theme_pck.get_file().get_basename(), id)
				if RetroHubConfig._get_default_themes_dir() in RetroHubConfig.theme_path and \
					theme_pck in RetroHubConfig.theme_path:
					n_themes.selected = id
				theme_id_map[id] = "res://default_themes/" + theme_pck
				id += 1
	n_themes.add_separator()
	id += 1
	# User themes
	var dir := DirAccess.open(RetroHubConfig._get_themes_dir())
	if dir and not dir.list_dir_begin(): # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := dir.get_next()
		while not next.is_empty():
			if not dir.current_is_dir() and next.ends_with(".pck"):
				n_themes.add_item(next, id)
				if not RetroHubConfig._get_default_themes_dir() in RetroHubConfig.theme_path and \
					next in RetroHubConfig.theme_path:
					n_themes.selected = id
				theme_id_map[id] = next
				id += 1
			next = dir.get_next()

func set_language(lang: String):
	match lang:
		"en":
			n_language.selected = 0

func _on_config_ready(config_data: ConfigData):
	n_game_lib_dir.text = config_data.games_dir
	n_graphics_mode.selected = 1 if config_data.fullscreen else 0
	n_vsync.set_pressed_no_signal(config_data.vsync)
	n_render_res.value = config_data.render_resolution
	n_ui_volume.value = config_data.ui_volume
	set_language(config_data.lang)
	n_screen_reader.set_pressed_no_signal(config_data.accessibility_screen_reader_enabled)

func _on_config_updated(key: String, _old_value, new_value):
	match key:
		ConfigData.KEY_GAMES_DIR:
			n_game_lib_dir.text = new_value
		ConfigData.KEY_LANG:
			set_language(new_value)

func _on_Themes_item_selected(index):
	var theme_path : String = theme_id_map[index]
	RetroHubConfig.config.current_theme = theme_path

	# FIXME: Theme hot-reloading is disabled until nasty GDScript bug is solved
	RetroHubUI.show_warning("Theme reloading is temporarily disabled for this version due to an internal bug in RetroHub's engine (Godot).\n \nYou'll have to restart RetroHub manually to switch themes.")

func _on_SetThemePath_pressed():
	#warning-ignore:return_value_discarded
	OS.shell_open(RetroHubConfig._get_themes_dir())

func _on_SetGamePath_pressed():
	RetroHubUI.filesystem_filters([])
	RetroHubUI.request_folder_load(FileUtils.get_home_dir() if n_game_lib_dir.text.is_empty() else n_game_lib_dir.text)
	var path : String = await RetroHubUI.path_selected
	# Only save if path is different and existent, to prevent theme reloads
	if not path.is_empty() and n_game_lib_dir.text != path:
		n_game_lib_dir.text = path
		RetroHubConfig.config.games_dir = path

func _on_Language_item_selected(index):
	match index:
		0:	# English (en)
			RetroHubConfig.config.lang = "en"

func _on_AppSettings_hide():
	RetroHubConfig._save_config()


func _on_AppSettings_visibility_changed():
	if is_visible_in_tree():
		set_themes()


func _on_FirstTimeWizardWarning_confirmed():
	RetroHubConfig.config.is_first_time = true
	RetroHubConfig.config.accessibility_screen_reader_enabled = true
	RetroHub.quit()


func _on_SetupWizardButton_pressed():
	n_first_time_wizard_warning.popup_centered()


func _on_GraphicsMode_item_selected(index):
	RetroHubConfig.config.fullscreen = index == 1
	RetroHubConfig._save_config()


func _on_VSync_toggled(button_pressed):
	RetroHubConfig.config.vsync = button_pressed
	RetroHubConfig._save_config()


func _on_RenderRes_value_changed(value):
	RetroHubConfig.config.render_resolution = value
	n_render_res_label.text = str(value) + "%"


func _on_ScreenReader_toggled(button_pressed):
	RetroHubConfig.config.accessibility_screen_reader_enabled = button_pressed
	RetroHubConfig._save_config()


func _on_ui_volume_value_changed(value):
	RetroHubConfig.config.ui_volume = value
	n_ui_volume_label.text = str(value) + "%"
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value / 100.0))
