extends Control

onready var n_game_lib_dir = $"%GameLibDir"
onready var n_set_game_path = $"%SetGamePath"
onready var n_themes = $"%Themes"
onready var n_language = $"%Language"
onready var n_region = $"%Region"
onready var n_rating_system = $"%RatingSystem"
onready var n_date_format = $"%DateFormat"
onready var n_first_time_wizard_warning = $"%FirstTimeWizardWarning"
onready var n_config_popup = $"../.."

var theme_id_map := {}

# Called when the node enters the scene tree for the first time.
func _ready():
	RetroHubConfig.connect("config_ready", self, "_on_config_ready")
	RetroHubConfig.connect("config_updated", self, "_on_config_updated")

func grab_focus():
	n_set_game_path.grab_focus()

func set_themes():
	n_themes.clear()
	theme_id_map.clear()
	var id = 0
	var file := File.new()
	# Default themes
	if not file.open("res://default_themes/themes.txt", File.READ):
		# Skip first line
		file.get_line()
		while file.get_position() < file.get_len():
			var theme := file.get_line()
			if theme.ends_with(".pck"):
				n_themes.add_item(theme.get_file().get_basename(), id)
				if RetroHubConfig.get_default_themes_dir() in RetroHubConfig.theme_path and \
					theme in RetroHubConfig.theme_path:
					n_themes.selected = id
				theme_id_map[id] = "res://default_themes/" + theme
				id += 1
	n_themes.add_separator()
	id += 1
	# User themes
	var dir := Directory.new()
	if not dir.open(RetroHubConfig.get_themes_dir()) and not dir.list_dir_begin(true):
		var next = dir.get_next()
		while not next.empty():
			if not dir.current_is_dir() and next.ends_with(".pck"):
				n_themes.add_item(next, id)
				if not RetroHubConfig.get_default_themes_dir() in RetroHubConfig.theme_path and \
					next in RetroHubConfig.theme_path:
					n_themes.selected = id
				theme_id_map[id] = next
				id += 1
			next = dir.get_next()

func set_language(lang: String):
	match lang:
		"en":
			n_language.selected = 0

func set_region(region: String):
	match region:
		"usa":
			n_region.selected = 0
		"eur":
			n_region.selected = 1
		"jpn":
			n_region.selected = 2

func set_rating_system(rating_system: String):
	match rating_system:
		"esrb":
			n_rating_system.selected = 0
		"pegi":
			n_rating_system.selected = 1
		"cero":
			n_rating_system.selected = 2

func set_date_format(date_format: String):
	match date_format:
		"mm/dd/yyyy":
			n_date_format.selected = 0
		"dd/mm/yyyy":
			n_date_format.selected = 1
		"yyyy/mm/dd":
			n_date_format.selected = 2

func _on_config_ready(config_data: ConfigData):
	n_game_lib_dir.text = config_data.games_dir
	set_language(config_data.lang)
	set_region(config_data.region)
	set_rating_system(config_data.rating_system)
	set_date_format(config_data.date_format)

func _on_config_updated(key: String, _old_value, new_value):
	match key:
		ConfigData.KEY_GAMES_DIR:
			n_game_lib_dir.text = new_value
		ConfigData.KEY_LANG:
			set_language(new_value)
		ConfigData.KEY_REGION:
			set_region(new_value)
		ConfigData.KEY_RATING_SYSTEM:
			set_rating_system(new_value)
		ConfigData.KEY_DATE_FORMAT:
			set_date_format(new_value)


func _on_Quit_pressed():
	RetroHub.quit()

func _on_Themes_item_selected(index):
	var theme_path = theme_id_map[index]
	RetroHubConfig.config.current_theme = theme_path


func _on_SetThemePath_pressed():
	OS.shell_open(RetroHubConfig.get_themes_dir())


func _on_SetGamePath_pressed():
	RetroHubUI.filesystem_filters([])
	RetroHubUI.request_folder_load(FileUtils.get_home_dir() if n_game_lib_dir.text.empty() else n_game_lib_dir.text)
	var path : String = yield(RetroHubUI, "path_selected")
	# Only save if path is different and existent, to prevent theme reloads
	if not path.empty() and n_game_lib_dir.text != path:
		n_game_lib_dir.text = path
		RetroHubConfig.config.games_dir = path


func _on_Language_item_selected(index):
	match index:
		0:	# English (en)
			RetroHubConfig.config.lang = "en"


func _on_Region_item_selected(index):
	match index:
		0:	# USA
			RetroHubConfig.config.region = "usa"
		1:	# Europe
			RetroHubConfig.config.region = "eur"
		2:	# Japan
			RetroHubConfig.config.region = "jpn"


func _on_RatingSystem_item_selected(index):
	match index:
		0:	# ESRB
			RetroHubConfig.config.rating_system = "esrb"
		1:	# PEGI
			RetroHubConfig.config.rating_system = "pegi"
		2:	# CERO
			RetroHubConfig.config.rating_system = "cero"


func _on_DateFormat_item_selected(index):
	match index:
		0:	# mm/dd/yyyy
			RetroHubConfig.config.date_format  = "mm/dd/yyyy"
		1:	# dd/mm/yyyy
			RetroHubConfig.config.date_format = "dd/mm/yyyy"
		2:	# yyyy/mm/dd
			RetroHubConfig.config.date_format = "yyyy/mm/dd"


func _on_AppSettings_hide():
	RetroHubConfig.save_config()


func _on_AppSettings_visibility_changed():
	if visible:
		set_themes()


func _on_FirstTimeWizardWarning_confirmed():
	RetroHubConfig.config.is_first_time = true
	n_config_popup.show_first_time_popup()


func _on_SetupWizardButton_pressed():
	n_first_time_wizard_warning.popup_centered()
