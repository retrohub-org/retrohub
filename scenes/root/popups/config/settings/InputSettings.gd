extends Control

onready var n_input_type := $"%InputType"
onready var n_start_remap := $"%StartRemap"
onready var n_clear_remap := $"%ClearRemap"
onready var n_kb_actions := $"%KeyboardActions"
onready var n_cn_actions := $"%ControllerActions"

onready var n_popup_controller_remapper := $"%ControllerRemapper"
onready var n_clear_remap_popup := $"%ClearRemapPopup"

# Called when the node enters the scene tree for the first time.
func _ready():
	RetroHubConfig.connect("config_ready", self, "_on_config_ready")
	RetroHubConfig.connect("config_updated", self, "_on_config_updated")
	ControllerIcons.connect("input_type_changed", self, "_on_input_type_changed")

func grab_focus():
	n_start_remap.grab_focus()

func _on_config_ready(config_data: ConfigData):
	n_clear_remap.disabled = config_data.custom_input_remap.empty()

func _on_config_updated(key: String, _old_value, new_value):
	match key:
		ConfigData.KEY_CUSTOM_INPUT_REMAP:
			n_clear_remap.disabled = new_value.empty()

func _on_input_type_changed(input_type: int):
	n_start_remap.disabled = Input.get_connected_joypads().empty()
	n_kb_actions.visible = input_type == ControllerIcons.InputType.KEYBOARD_MOUSE
	n_cn_actions.visible = input_type == ControllerIcons.InputType.CONTROLLER

	match input_type:
		ControllerIcons.InputType.KEYBOARD_MOUSE:
			n_input_type.text = "Keyboard & Mouse"
		ControllerIcons.InputType.CONTROLLER:
			n_input_type.text = "Game Controller"

func _on_hide():
	RetroHubConfig.save_config()


func _on_StartRemap_pressed():
	n_popup_controller_remapper.popup_centered()


func _on_ClearRemap_pressed():
	RetroHubConfig.config.custom_input_remap = ""
	RetroHubConfig.save_config()
	n_clear_remap_popup.popup_centered()
	n_clear_remap.disabled = true


func _on_ControllerRemapper_popup_hide():
	n_clear_remap.disabled = RetroHubConfig.config.custom_input_remap == ""
