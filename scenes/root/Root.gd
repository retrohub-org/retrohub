extends Control

onready var n_viewport_container : ViewportContainer = $ViewportContainer
onready var n_viewport : Viewport = $ViewportContainer/Viewport

onready var n_config_popup : Popup = $ConfigPopup
onready var n_filesystem_popup : Popup = $FileSystemPopup

onready var popup_nodes := [
	n_config_popup,
	n_filesystem_popup
]

onready var viewport_orig_size := n_viewport.size

var n_last_focused : Control
var is_popup_open : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	closed_popup()
	RetroHub.connect("_theme_loaded", self, "_on_theme_loaded")
	RetroHub.connect("_game_loaded", self, "_on_game_loaded")
	RetroHubConfig.connect("config_ready", self, "_on_config_ready")

	# Add popups to UI singleton
	RetroHubUI._n_filesystem_popup = n_filesystem_popup

	get_viewport().connect("size_changed", self, "_on_vp_size_changed")
	n_viewport.connect("gui_focus_changed", self, "_on_vp_gui_focus_changed")
	_on_vp_size_changed()

func _on_config_ready(config_data: ConfigData):
	if config_data.is_first_time:
		show_first_time_popup()

func show_first_time_popup():
	var first_time_popup := preload("res://scenes/root/popups/first_time/FirstTimePopups.tscn").instance()
	add_child(first_time_popup)
	popup_nodes.push_back(first_time_popup)
	first_time_popup.connect("about_to_show", self, "opened_popup")
	first_time_popup.connect("popup_hide", self, "closed_popup")
	first_time_popup.connect("popup_hide", self, "_on_first_time_popup_closed", [first_time_popup])
	first_time_popup.popup()

func _on_vp_size_changed() -> void:
	print("New size: ", get_viewport().size)
	n_viewport.size = get_viewport().size
	n_viewport.size_override_stretch = true
	n_viewport.set_size_override(true, viewport_orig_size)

func _on_vp_gui_focus_changed(control: Control) -> void:
	if not is_popup_open:
		n_last_focused = control

func _on_theme_loaded(theme_data: RetroHubTheme):
	n_viewport.set_theme(theme_data.entry_scene)
	print("Loaded theme")

func _on_game_loaded(game_data: RetroHubGameData):
	var game_launched_child = load("res://scenes/game_launched/GameLaunched.tscn").instance()
	n_viewport.set_theme(game_launched_child)
	game_launched_child.game_data = game_data
	print("Loaded game")

func set_theme_input_enabled(enabled : bool):
	n_viewport_container.set_process_input(enabled)
	n_viewport_container.set_process_unhandled_input(enabled)

func opened_popup():
	$DarkenOverlay.visible = true
	set_theme_input_enabled(false)
	is_popup_open = true

func closed_popup():
	for node in popup_nodes:
		if node.visible == true:
			return

	$DarkenOverlay.visible = false
	set_theme_input_enabled(true)
	is_popup_open = false
	if is_instance_valid(n_last_focused):
		n_last_focused.grab_focus()

func _on_first_time_popup_closed(popup):
	popup_nodes.remove(popup_nodes.find_last(popup))
