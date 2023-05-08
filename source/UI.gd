extends Control

var _n_filesystem_popup : FileDialog: set = _set_filesystem_popup
var _n_virtual_keyboard : PopupPanel: set = _set_virtual_keyboard
var _n_config_popup : Popup: set = _set_config_popup
var _n_warning_popup : AcceptDialog: set = _set_warning_popup

var color_theme_accent := Color("ffbb89")

var color_success := Color("41eb83")
var color_warning := Color("ffd24a")
var color_error := Color("ff5d5d")
var color_pending := Color("dddddd")
var color_unavailable := Color("999999")

const max_popupmenu_height := 300

var _steamdeck_keyboard_up := false

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

func _set_filesystem_popup(popup: FileDialog):
	_n_filesystem_popup = popup
	#warning-ignore:return_value_discarded
	_n_filesystem_popup.connect("file_selected", Callable(self, "_on_popup_selected"))
	#warning-ignore:return_value_discarded
	_n_filesystem_popup.connect("dir_selected", Callable(self, "_on_popup_selected"))
	#warning-ignore:return_value_discarded
	_n_filesystem_popup.connect("popup_hide", Callable(self, "_on_popup_hide"))

func _set_virtual_keyboard(keyboard: PopupPanel):
	_n_virtual_keyboard = keyboard

func _set_config_popup(config_popup: Popup):
	_n_config_popup = config_popup

func _set_warning_popup(warning_popup: AcceptDialog):
	_n_warning_popup = warning_popup

func _on_popup_selected(file: String):
	emit_signal("path_selected", file)

func _on_popup_hide():
	emit_signal("path_selected", "")

func filesystem_filters(filters: Array = []):
	_n_filesystem_popup.filters = filters

func request_file_load(base_path: String) -> void:
	_n_filesystem_popup.mode = FileDialog.FILE_MODE_OPEN_FILE
	_n_filesystem_popup.current_dir = base_path
	_n_filesystem_popup.popup()

func request_folder_load(base_path: String) -> void:
	_n_filesystem_popup.mode = FileDialog.FILE_MODE_OPEN_DIR
	_n_filesystem_popup.current_dir = base_path
	_n_filesystem_popup.popup()

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
			_n_virtual_keyboard.show()

func is_virtual_keyboard_visible() -> bool:
	match RetroHubConfig.config.virtual_keyboard_type:
		"steam":
			# There's no good way to know if the keyboard is trully up or not.
			# Steam hijacks control from the app, so any _input we receive must
			# mean the keyboard was closed.
			return _steamdeck_keyboard_up
		"builtin", _:
			return _n_virtual_keyboard.keyboardVisible

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
	_n_virtual_keyboard.hide()

func open_app_config(tab: int = -1):
	if _n_config_popup:
		if tab != -1:
			tab = int(clamp(tab, 0, _n_config_popup.n_tab_buttons.size()))
			_n_config_popup.n_tab_buttons[tab].grab_focus()
			_n_config_popup.n_tab_buttons[tab].button_pressed = true
			_n_config_popup._on_Tab_pressed(tab)
		_n_config_popup.popup()

func show_warning(text: String):
	if _n_warning_popup:
		_n_warning_popup.get_node("%WarningLabel").text = text
		_n_warning_popup.popup_centered()
		await get_tree().idle_frame
		_n_warning_popup.get_ok_button().grab_focus()
