extends PopupPanel

signal remap_done(action, old_axis, new_axis)

onready var n_icons := [
	$"%LStick", $"%RStick"
]

var mappings := [
	JOY_ANALOG_LX, JOY_ANALOG_RX
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
		focus_holder = icon
	else:
		focus_holder = n_icons[0]

	# Set intended position and popup
	rect_global_position = pos
	popup()

	# Popup internally tries to focus, so wait until it's shown to grab focus
	yield(get_tree(), "idle_frame")
	focus_holder.grab_focus()

func _find_axis_from_action(raw_action: String):
	for event in InputMap.get_action_list(raw_action):
		if event is InputEventJoypadMotion:
			if event.axis == JOY_ANALOG_LX or event.axis == JOY_ANALOG_LY:
				return JOY_ANALOG_LX
			elif event.axis == JOY_ANALOG_RX or event.axis == JOY_ANALOG_RY:
				return JOY_ANALOG_RX
	return -1


func _on_ControllerButtonRemap_popup_hide():
	# Enable all the button from previous cases
	for icon in n_icons:
		icon.disabled = false


func _on_Icon_pressed(axis):
	var axis_name := "right" if old_axis == JOY_ANALOG_RX else "left"
	emit_signal("remap_done", action, axis_name, axis)
	hide()
