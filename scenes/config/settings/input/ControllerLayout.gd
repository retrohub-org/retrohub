extends WindowDialog

export(Color) var unknown_mapping : Color
export(Color) var current_mapping : Color
export(Color) var known_mapping : Color

# Code adapted from Godot "Joypads Demo / Tool"
# https://godotengine.org/asset-library/asset/140
class JoyMapping:
	enum TYPE {NONE, BTN, AXIS}

	const PLATFORMS = {
		# From gamecontrollerdb
		"Windows": "Windows",
		"OSX": "Mac OS X",
		"X11": "Linux",
		"Android": "Android",
		"iOS": "iOS",
		# Godot customs
		"HTML5": "Javascript",
		"UWP": "UWP",
		# 4.x compat
		"Linux": "Linux",
		"FreeBSD": "Linux",
		"NetBSD": "Linux",
		"BSD": "Linux",
		"macOS": "Mac OS X",
	}

	const BASE = {
		# Buttons
		"a": JOY_XBOX_A,
		"b": JOY_XBOX_B,
		"y": JOY_XBOX_Y,
		"x": JOY_XBOX_X,
		"start": JOY_START,
		"back": JOY_SELECT,
		"leftshoulder": JOY_L,
		"rightshoulder": JOY_R,
		"lefttrigger": JOY_ANALOG_L2,
		"righttrigger": JOY_ANALOG_R2,
		"leftstick": JOY_BUTTON_8,
		"rightstick": JOY_BUTTON_9,
		"dpup": JOY_DPAD_UP,
		"dpdown": JOY_DPAD_DOWN,
		"dpleft": JOY_DPAD_LEFT,
		"dpright": JOY_DPAD_RIGHT,

		# Axis
		"lefty": JOY_AXIS_1,
		"leftx": JOY_AXIS_0,
		"righty": JOY_AXIS_3,
		"rightx": JOY_AXIS_2,
	}

	var type = TYPE.NONE
	var idx = -1

	func _init(p_type = TYPE.NONE, p_idx = -1):
		type = p_type
		idx = p_idx

	func _to_string():
		if type == TYPE.NONE:
			return ""
		var ts = "b" if type == TYPE.BTN else "a"
		var prefix = ""
		return "%s%s%d" % [prefix, ts, idx]

const DEADZONE = 0.6
const DEADZONE_IDLE = 0.2

var joy_guid = ""
var joy_name = ""

var steps = JoyMapping.BASE.keys()
var curr_step = -1
var cur_mapping = {}
var last_axis := -1
var done := false

onready var joy_inputs := [
	$"%A", $"%B", $"%Y", $"%X",
	$"%Start", $"%Select",
	$"%L1", $"%R1",
	$"%L2", $"%R2",
	$"%L3", $"%R3",
	$"%UpDPAD", $"%DownDPAD",
	$"%LeftDPAD", $"%RightDPAD",
	$"%YAxisLStick", $"%XAxisLStick",
	$"%YAxisRStick", $"%XAxisRStick"
]

var joy_descriptions := [
	"South Button", "East Button", "North Button", "West Button",
	"Start/Options Button", "Select/View Button",
	"Left Bumper", "Right Bumper",
	"Left Trigger", "Right Trigger",
	"Left Stick Click", "Right Stick Click",
	"Up DPAD", "Down DPAD",
	"Left DPAD", "Right DPAD",
	"Up/Down on Left Stick", "Left/Right on Left Stick",
	"Up/Down on Right Stick", "Left/Right on Right Stick"
]

onready var joy_half_axis := [
	$"%UpLStick", $"%DownLStick",
	$"%LeftLStick", $"%RightLStick",
	$"%UpRStick", $"%DownRStick",
	$"%LeftRStick", $"%RightRStick"
]

onready var n_lbl_press := $"%Press"
onready var n_lbl_move := $"%Move"
onready var n_lbl_done := $"%Done"
onready var n_btn_skip := $"%SkipButton"
onready var n_btn_done := $"%DoneButton"
onready var n_btn_prev := $"%PreviousButton"
onready var n_btn_reset := $"%ResetButton"
onready var n_press_progress := $"%PressProgress"
onready var n_timer := $"%Timer"
onready var n_action_desc := $"%ActionDescription"

func _input(event):
	if curr_step == -1:
		return
	if done:
		_input_done(event)
	elif event is InputEventJoypadMotion:
		get_tree().set_input_as_handled()
		var motion = event as InputEventJoypadMotion
		if abs(motion.axis_value) > DEADZONE:
			var idx = motion.axis
			if last_axis != idx:
				last_axis = idx
				var map = JoyMapping.new(JoyMapping.TYPE.AXIS, idx)
				cur_mapping[steps[curr_step]] = map
				n_timer.start()
		elif abs(motion.axis_value) > DEADZONE_IDLE or \
			(motion.axis == last_axis and motion.axis_value < DEADZONE):
			n_timer.stop()
			last_axis = -1
	elif event is InputEventJoypadButton:
		get_tree().set_input_as_handled()
		if event.pressed:
			var btn = event as InputEventJoypadButton
			var map = JoyMapping.new(JoyMapping.TYPE.BTN, btn.button_index)
			cur_mapping[steps[curr_step]] = map
			n_timer.start()
		else:
			n_timer.stop()

func _input_done(event):
	if event is InputEventJoypadButton:
		get_tree().set_input_as_handled()
		match event.button_index:
			JOY_XBOX_A:
				$"%A".modulate = current_mapping if event.pressed else known_mapping
			JOY_XBOX_B:
				$"%B".modulate = current_mapping if event.pressed else known_mapping
			JOY_XBOX_Y:
				$"%Y".modulate = current_mapping if event.pressed else known_mapping
			JOY_XBOX_X:
				$"%X".modulate = current_mapping if event.pressed else known_mapping
			JOY_L:
				$"%L1".modulate = current_mapping if event.pressed else known_mapping
			JOY_R:
				$"%R1".modulate = current_mapping if event.pressed else known_mapping
			JOY_L2:
				$"%L2".modulate = current_mapping if event.pressed else known_mapping
			JOY_R2:
				$"%R2".modulate = current_mapping if event.pressed else known_mapping
			JOY_L3:
				$"%L3".modulate = current_mapping if event.pressed else known_mapping
			JOY_R3:
				$"%R3".modulate = current_mapping if event.pressed else known_mapping
			JOY_SELECT:
				$"%Select".modulate = current_mapping if event.pressed else known_mapping
			JOY_START:
				$"%Start".modulate = current_mapping if event.pressed else known_mapping
			JOY_DPAD_UP:
				$"%UpDPAD".modulate = current_mapping if event.pressed else known_mapping
			JOY_DPAD_DOWN:
				$"%DownDPAD".modulate = current_mapping if event.pressed else known_mapping
			JOY_DPAD_LEFT:
				$"%LeftDPAD".modulate = current_mapping if event.pressed else known_mapping
			JOY_DPAD_RIGHT:
				$"%RightDPAD".modulate = current_mapping if event.pressed else known_mapping
	elif event is InputEventJoypadMotion:
		get_tree().set_input_as_handled()
		match event.axis:
			JOY_ANALOG_LY:
				$"%UpLStick".modulate = known_mapping.linear_interpolate(current_mapping, max(0, -event.axis_value))
				$"%DownLStick".modulate = known_mapping.linear_interpolate(current_mapping, max(0, event.axis_value))
			JOY_ANALOG_LX:
				$"%LeftLStick".modulate = known_mapping.linear_interpolate(current_mapping, max(0, -event.axis_value))
				$"%RightLStick".modulate = known_mapping.linear_interpolate(current_mapping, max(0, event.axis_value))
			JOY_ANALOG_RY:
				$"%UpRStick".modulate = known_mapping.linear_interpolate(current_mapping, max(0, -event.axis_value))
				$"%DownRStick".modulate = known_mapping.linear_interpolate(current_mapping, max(0, event.axis_value))
			JOY_ANALOG_RX:
				$"%LeftRStick".modulate = known_mapping.linear_interpolate(current_mapping, max(0, -event.axis_value))
				$"%RightRStick".modulate = known_mapping.linear_interpolate(current_mapping, max(0, event.axis_value))

func _on_Timer_timeout():
	next()

func _process(delta):
	if n_timer.is_stopped():
		n_press_progress.value = 0
	else:
		n_press_progress.value = n_timer.wait_time - n_timer.time_left

func create_mapping_string(mapping):
	var string = "%s,%s," % [joy_guid, joy_name]
	for k in mapping:
		var m = mapping[k]
		if typeof(m) == TYPE_OBJECT and m.type == JoyMapping.TYPE.NONE:
			continue
		string += "%s:%s," % [k, str(m)]
	var platform = "Unknown"
	if JoyMapping.PLATFORMS.keys().has(OS.get_name()):
		platform = JoyMapping.PLATFORMS[OS.get_name()]
	return string + "platform:" + platform

func remap(mapping):
	var mapping_str = create_mapping_string(mapping)
	RetroHubConfig.config.custom_input_remap = mapping_str
	RetroHubConfig.save_config()
	mark_done()

func reset():
	joy_guid = ""
	joy_name = ""
	cur_mapping = {}
	curr_step = -1
	done = false
	for child in joy_inputs:
		child.modulate = unknown_mapping
	for child in joy_half_axis:
		child.modulate = Color.white
	n_lbl_press.visible = true
	n_lbl_move.visible = false
	n_lbl_done.visible = false
	n_btn_skip.visible = true
	n_btn_done.visible = false
	n_btn_prev.visible = true
	n_btn_reset.visible = false
	n_action_desc.visible = true

func start():
	# Disable custom controller handler while this popup is visible
	ControllerHandler.set_process_input(false)
	joy_guid = Input.get_joy_guid(0)
	joy_name = Input.get_joy_name(0)
	Input.remove_joy_mapping(joy_guid)
	curr_step = 0
	step()

func mark_done():
	done = true
	for child in joy_inputs:
		child.modulate = known_mapping
	$"%YAxisLStick".modulate = Color.white
	$"%XAxisLStick".modulate = Color.white
	$"%YAxisRStick".modulate = Color.white
	$"%XAxisRStick".modulate = Color.white
	for child in joy_half_axis:
		child.modulate = known_mapping
	n_lbl_press.visible = false
	n_lbl_move.visible = false
	n_lbl_done.visible = true
	n_btn_skip.visible = false
	n_btn_done.visible = true
	n_btn_prev.visible = false
	n_btn_reset.visible = true
	n_action_desc.visible = false

func step():
	n_btn_prev.disabled = curr_step == 0
	if curr_step >= steps.size():
		remap(cur_mapping)
	else:
		n_action_desc.text = joy_descriptions[curr_step]
		# Set the last button to known mapping
		if curr_step > 0:
			joy_inputs[curr_step-1].modulate = known_mapping
		joy_inputs[curr_step].modulate = current_mapping
		n_lbl_move.visible = curr_step > 15
		n_lbl_press.visible = curr_step <= 15

func next():
	curr_step += 1
	step()

func _on_SkipButton_pressed():
	# Use existing default value
	var key = steps[curr_step]
	var mapping : JoyMapping
	if curr_step > 15:
		# Axis
		mapping = JoyMapping.new(JoyMapping.TYPE.AXIS, JoyMapping.BASE[key])
	else:
		mapping = JoyMapping.new(JoyMapping.TYPE.BTN, JoyMapping.BASE[key])
	cur_mapping[key] = mapping
	curr_step += 1
	step()

func _on_ControllerLayout_popup_hide():
	ControllerHandler.set_process_input(true)
	reset()

func _on_ControllerLayout_about_to_show():
	reset()
	start()

func _on_DoneButton_pressed():
	hide()

func _on_ResetButton_pressed():
	reset()
	start()

func _on_PreviousButton_pressed():
	joy_inputs[curr_step].modulate = unknown_mapping
	curr_step -= 1
	step()
