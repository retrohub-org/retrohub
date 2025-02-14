extends Control

var _n_theme_viewport : Viewport
var _n_filesystem_popup : FileDialog: set = _set_filesystem_popup
var _n_virtual_keyboard : Window: set = _set_virtual_keyboard
var _n_config_popup : Window: set = _set_config_popup
var _n_warning_popup : AcceptDialog: set = _set_warning_popup

var color_theme_accent := Color("ffbb89")

var color_success := Color("41eb83")
var color_warning := Color("ffd24a")
var color_error := Color("ff5d5d")
var color_pending := Color("dddddd")
var color_unavailable := Color("999999")

const max_popupmenu_height := 300

var _steamdeck_keyboard_up := false

enum AudioKeys {
	ACTIVATED,
	CHECK_BUTTON_OFF,
	CHECK_BUTTON_ON,
	KEYBOARD_TYPE,
	MENU_ENTER,
	MENU_IN,
	MENU_OUT,
	NAVIGATION,
	SLIDE,
	SLIDER_TICK,
}

@onready var audio_player := AudioStreamPlayer.new()
@onready var audio_player_low := AudioStreamPlayer.new()
var audio_streams : Array[AudioStream]

enum Icons {
	DOWNLOADING,
	ERROR,
	FAILURE,
	IMAGE_DOWNLOADING,
	LOAD,
	LOADING,
	SETTINGS,
	SUCCESS,
	VISIBILITY_HIDDEN,
	VISIBILITY_VISIBLE,
	WARNING
}

enum ConfigTabs {
	QUIT,
	GAME,
	SCRAPER,
	THEME,
	SETTINGS_GENERAL,
	SETTINGS_INPUT,
	SETTINGS_REGION,
	SETTINGS_SYSTEMS,
	SETTINGS_EMULATORS,
	SETTINGS_ABOUT
}

signal path_selected(file)

func _input(event):
	if not event is InputEventKey:
		_steamdeck_keyboard_up = false
		ControllerIcons.set_process_input(true)

func _ready():
	add_child(audio_player)
	add_child(audio_player_low)
	audio_player.bus = "[RetroHub] UI Sounds"
	audio_player_low.bus = "[RetroHub] UI Sounds"
	for key in AudioKeys.keys():
		var path = "res://assets/sounds/%s.wav" % key.to_lower()
		audio_streams.push_back(load(path))

func _set_filesystem_popup(popup: FileDialog):
	_n_filesystem_popup = popup
	#warning-ignore:return_value_discarded
	_n_filesystem_popup.file_selected.connect(_on_popup_selected)
	#warning-ignore:return_value_discarded
	_n_filesystem_popup.dir_selected.connect(_on_popup_selected)
	#warning-ignore:return_value_discarded
	_n_filesystem_popup.visibility_changed.connect(_on_visibility_changed)

func _set_virtual_keyboard(keyboard: Window):
	_n_virtual_keyboard = keyboard

func _set_config_popup(config_popup: Window):
	_n_config_popup = config_popup

func _set_warning_popup(warning_popup: AcceptDialog):
	_n_warning_popup = warning_popup

func _on_popup_selected(file: String):
	emit_signal("path_selected", file)

func _on_visibility_changed():
	if not _n_filesystem_popup.visible:
		emit_signal("path_selected", "")

func filesystem_filters(filters: Array = []):
	_n_filesystem_popup.filters = filters

func request_file_load(base_path: String) -> void:
	_n_filesystem_popup.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_n_filesystem_popup.current_dir = base_path
	_n_filesystem_popup.popup_centered()

func request_folder_load(base_path: String) -> void:
	_n_filesystem_popup.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_n_filesystem_popup.current_dir = base_path
	_n_filesystem_popup.popup_centered()

func load_app_icon(icon: int) -> Texture2D:
	var path : String = "res://assets/icons/%s.svg" % Icons.keys()[icon].to_lower()
	return (load(path) as Texture2D)

func show_virtual_keyboard() -> void:
	match RetroHubConfig.config.virtual_keyboard_type:
		"steam":
			var focused_control := get_viewport().gui_get_focus_owner()
			var _rect_pos := focused_control.global_position
			var _rect_size := focused_control.size
			var uri := "steam://open/keyboard?XPosition=%d&YPosition=%d&Width=%d&Height=%d&Mode=%d" % [
				int(_rect_pos.x), int(_rect_pos.y),
				int(_rect_size.x), int(_rect_size.y),
				1 if focused_control is TextEdit else 0
			]
			OS.shell_open(uri)
			_steamdeck_keyboard_up = true
			ControllerIcons.set_process_input(false)
		"builtin", _:
			_n_virtual_keyboard.show_keyboard(get_true_focused_control())

func is_virtual_keyboard_visible() -> bool:
	match RetroHubConfig.config.virtual_keyboard_type:
		"steam":
			# There's no good way to know if the keyboard is trully up or not.
			# Steam hijacks control from the app, so any _input we receive must
			# mean the keyboard was closed.
			return _steamdeck_keyboard_up
		"builtin", _:
			return _n_virtual_keyboard.visible

func is_event_from_virtual_keyboard() -> bool:
	match RetroHubConfig.config.virtual_keyboard_type:
		"steam":
			# There's no good way to know if the keyboard is trully up or not.
			# Steam hijacks control from the app, so any _input we receive must
			# mean the keyboard was closed.
			return _steamdeck_keyboard_up
		"builtin", _:
			return _n_virtual_keyboard.sendingEvent

func hide_virtual_keyboard() -> void:
	_n_virtual_keyboard.hide_keyboard()

func open_app_config(tab: int = -1):
	if _n_config_popup:
		if tab != -1:
			tab = int(clamp(tab, 0, _n_config_popup.n_tab_buttons.size()))
			_n_config_popup.n_tab_buttons[tab].grab_focus()
			_n_config_popup.n_tab_buttons[tab].button_pressed = true
			_n_config_popup._on_Tab_pressed(tab)
		_n_config_popup.open_config()

func show_warning(text: String):
	if _n_warning_popup:
		_n_warning_popup.get_node("%WarningLabel").text = text
		_n_warning_popup.popup_centered()
		await get_tree().process_frame
		_n_warning_popup.get_ok_button().grab_focus()

func get_focused_window() -> Window:
	var win_id := DisplayServer.get_top_popup_or_focused_window()
	var win : Window = instance_from_id(win_id)
	return win

func get_true_focused_control() -> Control:
	# Find currently focused "real" window
	var win := get_focused_window()
	if win == null:
		return get_viewport().gui_get_focus_owner()

	while win:
		if win.get_top_popup_or_focused_window() == null:
			# Found the innermost viewport
			if win == $"/root":
				return _n_theme_viewport.gui_get_focus_owner()
			else:
				return win.gui_get_focus_owner()
		win = win.get_top_popup_or_focused_window()
	return get_viewport().gui_get_focus_owner()

func play_sound(key: AudioKeys, override : bool = true):
	if override:
		audio_player_low.stop()
		audio_player.stream = audio_streams[key]
		audio_player.play()
	else:
		audio_player_low.stream = audio_streams[key]
		audio_player_low.play()
