extends PopupPanel

signal remap_done(action, old_axis, new_axis)

@onready var n_icons := [
	%LStick, %RStick
]

var mappings := [
	JOY_AXIS_LEFT_X, JOY_AXIS_RIGHT_X
]

var action : String
var old_axis : int

func start(curr_action: String, pos: Vector2):
	action = curr_action
	old_axis = _find_axis_from_action(curr_action)

	# If we have a valid existing axis idx, disable it
	var map_idx := mappings.find(old_axis)
	var focus_holder
	if map_idx != -1:
		var icon : Button = n_icons[map_idx]
		icon.disabled = true
		icon.focus_mode = Control.FOCUS_NONE
		focus_holder = icon
	else:
		focus_holder = n_icons[0]

	# Set intended position and popup
	position = pos
	popup()

	# Popup internally tries to focus, so wait until it's shown to grab focus
	await get_tree().process_frame
	focus_holder.grab_focus()
	TTS.speak("Choose the new axis for this action")

func _find_axis_from_action(raw_action: String):
	for event in InputMap.action_get_events(raw_action):
		if event is InputEventJoypadMotion:
			if event.axis == JOY_AXIS_LEFT_X or event.axis == JOY_AXIS_LEFT_Y:
				return JOY_AXIS_LEFT_X
			elif event.axis == JOY_AXIS_RIGHT_X or event.axis == JOY_AXIS_RIGHT_Y:
				return JOY_AXIS_RIGHT_X
	return -1


func _on_ControllerButtonRemap_popup_hide():
	# Enable all the button from previous cases
	for icon in n_icons:
		icon.disabled = false
		icon.focus_mode = Control.FOCUS_ALL


func _on_Icon_pressed(axis):
	var axis_name := "right" if old_axis == JOY_AXIS_RIGHT_X else "left"
	emit_signal("remap_done", action, axis_name, axis)
	hide()

func tts_text(focused: Control) -> String:
	if focused is ControllerButton:
		return focused.get_tts_string() + " axis"
	return ""
