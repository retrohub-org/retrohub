extends PopupPanel

signal remap_done(action, old_button, new_button)

@onready var n_icons := [
	%A, %B, %Y, %X,
	%LB, %RB, %LT, %RT,
	%Select, %Start,
	%LStick, %RStick
]

var mappings := [
	JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_Y, JOY_BUTTON_X,
	JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER,
	RetroHubConfig.CONTROLLER_AXIS_FLAG | JOY_AXIS_TRIGGER_LEFT,
	RetroHubConfig.CONTROLLER_AXIS_FLAG | JOY_AXIS_TRIGGER_RIGHT,
	JOY_BUTTON_BACK, JOY_BUTTON_START,
	JOY_BUTTON_LEFT_STICK, JOY_BUTTON_RIGHT_STICK
]

var action : String
var old_button : int

func start(curr_action: String, pos: Vector2i):
	action = curr_action
	old_button = _find_button_from_action(curr_action)

	# If we have a valid existing button idx, disable it
	var map_idx := mappings.find(old_button)
	var focus_holder
	if map_idx != -1:
		var icon : Button = n_icons[map_idx]
		icon.disabled = true
		icon.focus_mode = Control.FOCUS_NONE
		focus_holder = n_icons[map_idx+1 if map_idx+1 < n_icons.size() else 0]
	else:
		focus_holder = n_icons[0]

	# Set intended position and popup
	position = pos
	popup()

	# Popup internally tries to focus, so wait until it's shown to grab focus
	await get_tree().process_frame
	focus_holder.grab_focus()
	TTS.speak("Choose the new button for this action")

func _find_button_from_action(raw_action: String):
	for event in InputMap.action_get_events(raw_action):
		if event is InputEventJoypadButton:
			return event.button_index
		elif event is InputEventJoypadMotion:
			return event.axis | RetroHubConfig.CONTROLLER_AXIS_FLAG
	return -1


func _on_ControllerButtonRemap_popup_hide():
	# Enable all the button from previous cases
	for icon in n_icons:
		icon.disabled = false
		icon.focus_mode = Control.FOCUS_ALL


func _on_Icon_pressed(button_idx):
	emit_signal("remap_done", action, old_button, button_idx)
	hide()

func tts_text(focused: Control) -> String:
	if focused is ControllerButton:
		return focused.get_tts_string() + " button"
	return ""
