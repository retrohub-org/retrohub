extends Control

onready var n_start_layout := $"%StartLayout"
onready var n_clear_layout := $"%ClearLayout"
onready var n_input_tab := $"%InputTab"

onready var n_popup_controller_layout := $"%ControllerLayout"
onready var n_clear_layout_popup := $"%ClearLayoutPopup"
onready var n_key_remap_popup := $"%KeyboardRemap"
onready var n_ctrl_button_remap_popup := $"%ControllerButtonRemap"

# Called when the node enters the scene tree for the first time.
func _ready():
	RetroHubConfig.connect("config_ready", self, "_on_config_ready")
	RetroHubConfig.connect("config_updated", self, "_on_config_updated")
	ControllerIcons.connect("input_type_changed", self, "_on_input_type_changed")

func grab_focus():
	n_start_layout.grab_focus()

func _on_config_ready(config_data: ConfigData):
	n_clear_layout.disabled = config_data.custom_input_remap.empty()

func _on_config_updated(key: String, _old_value, new_value):
	match key:
		ConfigData.KEY_CUSTOM_INPUT_REMAP:
			n_clear_layout.disabled = new_value.empty()

func _on_input_type_changed(input_type: int):
	n_start_layout.disabled = Input.get_connected_joypads().empty()
	if not is_visible_in_tree():
		n_input_tab.current_tab = input_type

func _on_hide():
	RetroHubConfig.save_config()


func _on_StartLayout_pressed():
	n_popup_controller_layout.popup_centered()


func _on_ClearLayout_pressed():
	RetroHubConfig.config.custom_input_remap = ""
	RetroHubConfig.save_config()
	n_clear_layout_popup.popup_centered()
	n_clear_layout.disabled = true


func _on_ControllerLayout_popup_hide():
	n_clear_layout.disabled = RetroHubConfig.config.custom_input_remap == ""


func _on_KB_pressed(input_key):
	n_key_remap_popup.start(input_key)

func _on_KeyboardRemap_key_remapped(key, old_code, new_code):
	# First, find the old keycode and switch it
	var keymap := RetroHubConfig.config.input_key_map
	if old_code in keymap[key]:
		keymap[key].erase(old_code)
	keymap[key].push_back(new_code)
	# Now, find keys with the new code, and replace with old code
	for _key in keymap:
		if key == _key:
			continue
		if new_code in keymap[_key]:
			keymap[_key].erase(new_code)
			keymap[_key].push_back(old_code)
	RetroHubConfig.config.mark_for_saving()
	RetroHubConfig.save_config()

func _on_CN_pressed(input_key):
	var button := get_focus_owner()
	var pos := button.rect_global_position - Vector2(n_ctrl_button_remap_popup.rect_size.x + 10, 0)
	n_ctrl_button_remap_popup.start(input_key, pos)

func _on_ControllerButtonRemap_remap_done(key, old_button, new_button):
	# First, find the old button and switch it
	var map := RetroHubConfig.config.input_controller_map
	if old_button in map[key]:
		map[key].erase(old_button)
	map[key].push_back(new_button)
	# Now, find keys with the new code, and replace with old code
	for _key in map:
		if key == _key:
			continue
		if new_button in map[_key]:
			map[_key].erase(new_button)
			map[_key].push_back(old_button)
	RetroHubConfig.config.mark_for_saving()
	RetroHubConfig.save_config()