extends Control

onready var n_input_tab := $"%InputTab"

onready var n_kb_reset := $"%KBReset"

onready var n_cn_reset := $"%CNReset"
onready var n_cn_start_layout := $"%CNStartLayout"
onready var n_cn_clear_layout := $"%CNClearLayout"
onready var n_cn_icon_type := $"%CNIconType"
onready var n_cn_pre_delay := $"%CNPreDelay"
onready var n_cn_delay := $"%CNDelay"

onready var n_vkb_layout := $"%VirtualKeyboardLayout"
onready var n_vkb_show_on_controller := $"%VirtualKeyboardOnController"
onready var n_vkb_show_on_mouse := $"%VirtualKeyboardOnMouse"

onready var n_controller_layout_popup := $"%ControllerLayout"
onready var n_key_remap_popup := $"%KeyboardRemap"
onready var n_ctrl_button_remap_popup := $"%ControllerButtonRemap"
onready var n_ctrl_axis_remap_popup := $"%ControllerAxisRemap"

func _ready():
	#warning-ignore:return_value_discarded
	RetroHubConfig.connect("config_ready", self, "_on_config_ready")
	#warning-ignore:return_value_discarded
	RetroHubConfig.connect("config_updated", self, "_on_config_updated")
	#warning-ignore:return_value_discarded
	ControllerIcons.connect("input_type_changed", self, "_on_input_type_changed")

	n_cn_icon_type.get_popup().max_height = RetroHubUI.max_popupmenu_height + 50

func grab_focus():
	# Keyboard
	if n_input_tab.current_tab == 0:
		n_kb_reset.grab_focus()
	# Controller
	elif n_input_tab.current_tab == 1:
		n_cn_reset.grab_focus()
	elif n_input_tab.current_tab == 2:
		n_vkb_layout.grab_focus()

func _on_config_ready(config_data: ConfigData):
	n_cn_clear_layout.disabled = config_data.custom_input_remap.empty()
	match RetroHubConfig.config.input_controller_icon_type:
		"xbox360":
			n_cn_icon_type.selected = 1
		"xboxone":
			n_cn_icon_type.selected = 2
		"xboxseries":
			n_cn_icon_type.selected = 3
		"ps3":
			n_cn_icon_type.selected = 4
		"ps4":
			n_cn_icon_type.selected = 5
		"ps5":
			n_cn_icon_type.selected = 6
		"switch":
			n_cn_icon_type.selected = 7
		"joycon":
			n_cn_icon_type.selected = 8
		"steam":
			n_cn_icon_type.selected = 9
		"steamdeck":
			n_cn_icon_type.selected = 10
		"luna":
			n_cn_icon_type.selected = 11
		"stadia":
			n_cn_icon_type.selected = 12
		"auto", _:
			n_cn_icon_type.selected = 0
	n_cn_pre_delay.value = config_data.input_controller_echo_pre_delay
	n_cn_delay.value = config_data.input_controller_echo_delay
	match config_data.virtual_keyboard_layout:
		"qwertz":
			n_vkb_layout.selected = 1
		"azerty":
			n_vkb_layout.selected = 2
		"qwerty", _:
			n_vkb_layout.selected = 0
	n_vkb_show_on_controller.pressed = config_data.virtual_keyboard_show_on_controller
	n_vkb_show_on_mouse.pressed = config_data.virtual_keyboard_show_on_mouse

func _on_config_updated(key: String, _old_value, new_value):
	match key:
		ConfigData.KEY_CUSTOM_INPUT_REMAP:
			n_cn_clear_layout.disabled = new_value.empty()

func _on_input_type_changed(input_type: int):
	n_cn_start_layout.disabled = Input.get_connected_joypads().empty()
	if not is_visible_in_tree():
		n_input_tab.current_tab = input_type

func _on_hide():
	RetroHubConfig.save_config()


func _on_StartLayout_pressed():
	n_controller_layout_popup.popup_centered()


func _on_ClearLayout_pressed():
	var splits := RetroHubConfig.config.custom_input_remap.split(",")
	if splits.size() > 1:
		Input.remove_joy_mapping(splits[0])
	RetroHubConfig.config.custom_input_remap = ""
	RetroHubConfig.save_config()
	n_cn_clear_layout.disabled = true


func _on_ControllerLayout_popup_hide():
	n_cn_clear_layout.disabled = RetroHubConfig.config.custom_input_remap == ""


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
	if  not new_button in map[key]:
		map[key].push_back(new_button)
	# Now, find keys with the new code, and replace with old code
	for _key in map:
		if key == _key:
			continue
		if new_button in map[_key]:
			map[_key].erase(new_button)
			if not old_button in map[_key]:
				map[_key].push_back(old_button)
	RetroHubConfig.config.mark_for_saving()
	RetroHubConfig.save_config()

func _on_CNAxis_pressed(axis):
	var button := get_focus_owner()
	var pos := button.rect_global_position - Vector2(n_ctrl_button_remap_popup.rect_size.x + 10, 0)
	n_ctrl_axis_remap_popup.start(axis, pos)

func _on_ControllerAxisRemap_remap_done(action, old_axis, new_axis):
	# There's only two movement sticks, they will always switch places
	var is_main : bool = action == "rh_left"
	RetroHubConfig.config.input_controller_main_axis = new_axis if is_main else old_axis
	RetroHubConfig.config.input_controller_secondary_axis = old_axis if is_main else new_axis
	RetroHubConfig.save_config()


func _on_CNIconType_item_selected(index):
	match index:
		1:
			RetroHubConfig.config.input_controller_icon_type = "xbox360"
		2:
			RetroHubConfig.config.input_controller_icon_type = "xboxone"
		3:
			RetroHubConfig.config.input_controller_icon_type = "xboxseries"
		4:
			RetroHubConfig.config.input_controller_icon_type = "ps3"
		5:
			RetroHubConfig.config.input_controller_icon_type = "ps4"
		6:
			RetroHubConfig.config.input_controller_icon_type = "ps5"
		7:
			RetroHubConfig.config.input_controller_icon_type = "switch"
		8:
			RetroHubConfig.config.input_controller_icon_type = "joycon"
		9:
			RetroHubConfig.config.input_controller_icon_type = "steam"
		10:
			RetroHubConfig.config.input_controller_icon_type = "steamdeck"
		11:
			RetroHubConfig.config.input_controller_icon_type = "luna"
		12:
			RetroHubConfig.config.input_controller_icon_type = "stadia"
		0, _:
			RetroHubConfig.config.input_controller_icon_type = "auto"
	ControllerIcons.refresh()

func _on_CNPreDelay_value_changed(value):
	RetroHubConfig.config.input_controller_echo_pre_delay = value


func _on_CNDelay_value_changed(value):
	RetroHubConfig.config.input_controller_echo_delay = value


func _on_KBReset_pressed():
	RetroHubConfig.config.input_key_map = ConfigData.default_input_key_map()
	RetroHubConfig.save_config()


func _on_CNReset_pressed():
	RetroHubConfig.config.input_controller_map = ConfigData.default_input_controller_map()
	RetroHubConfig.config.input_controller_main_axis = "left"
	RetroHubConfig.config.input_controller_secondary_axis = "right"
	RetroHubConfig.save_config()


func _on_VirtualKeyboardLayout_item_selected(index):
	match index:
		1:
			RetroHubConfig.config.virtual_keyboard_layout = "qwertz"
		2:
			RetroHubConfig.config.virtual_keyboard_layout = "azerty"
		0, _:
			RetroHubConfig.config.virtual_keyboard_layout = "qwerty"

func _on_VirtualKeyboardOnController_toggled(button_pressed):
	RetroHubConfig.config.virtual_keyboard_show_on_controller = button_pressed


func _on_VirtualKeyboardOnMouse_toggled(button_pressed):
	RetroHubConfig.config.virtual_keyboard_show_on_mouse = button_pressed


