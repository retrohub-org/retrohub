extends Control

@onready var n_viewport_container := $SubViewportContainer
@onready var n_viewport := $SubViewportContainer/SubViewport

@onready var n_config_popup := $ConfigPopup
@onready var n_keyboard_popup := %Keyboard

@onready var viewport_orig_size := Vector2(
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height")
)

var is_popup_open : bool = false

func _enter_tree():
	load("res://scenes/ui_nodes/AccessibilityFocus.gd").take_over_path("res://addons/retrohub_theme_helper/ui/AccessibilityFocus.gd")

func _raw_input(event: InputEvent):
	if not RetroHub._running_game:
		if event.is_action_pressed("rh_menu") and not RetroHubConfig.config.is_first_time \
			and not RetroHubUI.is_virtual_keyboard_visible():
			if not $ConfigPopup.visible:
				get_viewport().set_input_as_handled()
				$ConfigPopup.open_config()

func _ready():
	closed_popup(null)
	#warning-ignore:return_value_discarded
	RetroHub._theme_load.connect(_on_theme_load)
	RetroHub._theme_unload.connect(_on_theme_unload)
	#warning-ignore:return_value_discarded
	RetroHub._game_loaded.connect(_on_game_loaded)
	#warning-ignore:return_value_discarded
	RetroHubConfig.config_updated.connect(_on_config_updated)

	# Add popups to UI singleton
	RetroHubUI._n_theme_viewport = n_viewport
	RetroHubUI._n_config_popup = n_config_popup
	RetroHubUI._n_virtual_keyboard = n_keyboard_popup

	# Handle viewport changes
	#warning-ignore:return_value_discarded
	get_viewport().size_changed.connect(_on_vp_size_changed)
	_on_vp_size_changed()

	# Wait an idle frame for the config to load
	await get_tree().process_frame
	if RetroHubConfig.config.is_first_time:
		show_first_time_popup()
	setup_controller_remap(RetroHubConfig.config.custom_input_remap)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		RetroHub.quit()

func _on_config_updated(key: String, _old, new):
	match key:
		ConfigData.KEY_CUSTOM_INPUT_REMAP:
			setup_controller_remap(new)
		ConfigData.KEY_FULLSCREEN:
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (new) else Window.MODE_WINDOWED
		ConfigData.KEY_VSYNC:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if (new) else DisplayServer.VSYNC_DISABLED)
		ConfigData.KEY_RENDER_RESOLUTION:
			_on_vp_size_changed()

func setup_controller_remap(remap_str: String):
	if not remap_str.is_empty():
		if Input.is_joy_known(0):
			Input.remove_joy_mapping(Input.get_joy_guid(0))
		Input.add_joy_mapping(remap_str, true)

func show_first_time_popup():
	var first_time_popup : Window = load("res://scenes/popups/first_time/FirstTimePopups.tscn").instantiate()
	add_child(first_time_popup)
	#warning-ignore:return_value_discarded
	first_time_popup.about_to_popup.connect(opened_popup)
	#warning-ignore:return_value_discarded
	first_time_popup.visibility_changed.connect(closed_popup.bind(first_time_popup))
	# Wait a frame for the window to be at the right resolution
	await get_tree().process_frame
	first_time_popup.popup_centered()

func _on_vp_size_changed() -> void:
	var viewport_size := Vector2(
		viewport_orig_size.y * get_viewport().size.aspect(),
		viewport_orig_size.y
	)
	# FIXME: Due to changes in Godot 4, render_resolution stopped working. Investigate
	var mult := RetroHubConfig.config.render_resolution / 100.0
	n_viewport.size = get_viewport().size * mult
	n_viewport.set_size_2d_override(viewport_size)

func _on_theme_load(theme_data: RetroHubTheme):
	n_viewport.set_theme(theme_data.entry_scene)
	print("Loaded theme")
	RetroHub._theme_processing_done = true

func _on_theme_unload():
	n_viewport.clear_theme()
	print("Unloaded theme")
	RetroHub._theme_processing_done = true

func _on_game_loaded(_game_data: RetroHubGameData):
	var game_launched_child : PackedScene = load("res://scenes/game_launched/GameLaunched.tscn")
	n_viewport.clear_theme()
	n_viewport.set_theme(game_launched_child)
	print("Loaded game")

func set_theme_input_enabled(enabled : bool):
	n_viewport_container.set_process_input(enabled)
	n_viewport_container.set_process_unhandled_input(enabled)

func opened_popup():
	$DarkenOverlay.visible = true
	set_theme_input_enabled(false)
	is_popup_open = true

func closed_popup(popup: Window = null):
	if popup and popup.visible:
		return

	$DarkenOverlay.visible = false
	set_theme_input_enabled(true)
	is_popup_open = false
