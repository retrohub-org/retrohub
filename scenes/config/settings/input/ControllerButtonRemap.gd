extends PopupPanel

signal remap_done(action, old_button, new_button)

@onready var n_icons := [
	$"%A", $"%B", $"%Y", $"%X",
	$"%LB", $"%RB", $"%LT", $"%RT",
	$"%Select", $"%Start",
	$"%LStick", $"%RStick"
]

var mappings := [
	JOY_XBOX_A, JOY_XBOX_B, JOY_XBOX_Y, JOY_XBOX_X,
	JOY_L, JOY_R, JOY_L2, JOY_R2,
	JOY_SELECT, JOY_START,
	JOY_L3, JOY_R3
]

var action : String
var old_button : int

func start(curr_action: String, pos: Vector2):
	action = curr_action
	old_button = _find_button_from_action(curr_action)

	# If we have a valid existing button idx, disable it
	var map_idx := mappings.find(old_button)
	var focus_holder
	if map_idx != -1:
		var icon : Button = n_icons[map_idx]
		icon.disabled = true
		icon.focus_mode = FOCUS_NONE
		focus_holder = n_icons[map_idx+1 if map_idx+1 < n_icons.size() else 0]
	else:
		focus_holder = n_icons[0]

	# Set intended position and popup
	global_position = pos
	popup()

	# Popup internally tries to focus, so wait until it's shown to grab focus
	await get_tree().idle_frame
	focus_holder.grab_focus()
	TTS.speak("Choose the new button for this action")

func _find_button_from_action(raw_action: String):
	for event in InputMap.action_get_events(raw_action):
		if event is InputEventJoypadButton:
			return event.button_index
	return -1


func _on_ControllerButtonRemap_popup_hide():
	# Enable all the button from previous cases
	for icon in n_icons:
		icon.disabled = false
		icon.focus_mode = FOCUS_ALL


func _on_Icon_pressed(button_idx):
	emit_signal("remap_done", action, old_button, button_idx)
	hide()

func tts_text(focused: Control) -> String:
	if focused is ControllerButton:
		return focused.get_tts_string() + " button"
	return ""
