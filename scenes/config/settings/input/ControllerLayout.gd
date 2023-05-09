extends Window

@export var unknown_mapping : Color
@export var current_mapping : Color
@export var known_mapping : Color

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
		"a": JOY_BUTTON_A,
		"b": JOY_BUTTON_B,
		"y": JOY_BUTTON_Y,
		"x": JOY_BUTTON_X,
		"start": JOY_BUTTON_START,
		"back": JOY_BUTTON_BACK,
		"leftshoulder": JOY_BUTTON_LEFT_SHOULDER,
		"rightshoulder": JOY_BUTTON_RIGHT_SHOULDER,
		"leftstick": JOY_BUTTON_LEFT_STICK,
		"rightstick": JOY_BUTTON_RIGHT_STICK,
		"dpup": JOY_BUTTON_DPAD_UP,
		"dpdown": JOY_BUTTON_DPAD_DOWN,
		"dpleft": JOY_BUTTON_DPAD_LEFT,
		"dpright": JOY_BUTTON_DPAD_RIGHT,

		# Axis
		"lefty": JOY_AXIS_LEFT_Y,
		"leftx": JOY_AXIS_LEFT_X,
		"righty": JOY_AXIS_RIGHT_Y,
		"rightx": JOY_AXIS_RIGHT_X,
		"lefttrigger": JOY_AXIS_TRIGGER_LEFT,
		"righttrigger": JOY_AXIS_TRIGGER_RIGHT,
	}

	var type : int = TYPE.NONE
	var idx := -1

	func _init(p_type = TYPE.NONE, p_idx = -1):
		type = p_type
		idx = p_idx

	func _to_string():
		if type == TYPE.NONE:
			return ""
		var ts := "b" if type == TYPE.BTN else "a"
		var prefix := ""
		return "%s%s%d" % [prefix, ts, idx]

const DEADZONE = 0.6
const DEADZONE_IDLE = 0.2

var joy_guid := ""
var joy_name := ""

var steps := JoyMapping.BASE.keys()
var curr_step := -1
var cur_mapping := {}
var last_axis := -1
var done := false
var tts_joy_axis_utterance = null

@onready var joy_inputs := [
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

@onready var joy_half_axis := [
	$"%UpLStick", $"%DownLStick",
	$"%LeftLStick", $"%RightLStick",
	$"%UpRStick", $"%DownRStick",
	$"%LeftRStick", $"%RightRStick"
]

@onready var n_lbl_press := $"%Press"
@onready var n_lbl_move := $"%Move"
@onready var n_lbl_done := $"%Done"
@onready var n_btn_skip := $"%SkipButton"
@onready var n_btn_done := $"%DoneButton"
@onready var n_btn_prev := $"%PreviousButton"
@onready var n_btn_reset := $"%ResetButton"
@onready var n_press_progress := $"%PressProgress"
@onready var n_timer := $"%Timer"
@onready var n_action_desc := $"%ActionDescription"

@onready var lbl_press_orig_text : String = n_lbl_press.text
@onready var lbl_move_orig_text : String = n_lbl_move.text

func _ready():
	RetroHubConfig.connect("config_ready", Callable(self, "_on_config_ready"))
	RetroHubConfig.connect("config_updated", Callable(self, "_on_config_updated"))
	TTS.connect("utterance_end", Callable(self, "_on_tts_utterance_end"))

func _on_config_ready(config: ConfigData):
	handle_text_remap(config.accessibility_screen_reader_enabled)

func _on_config_updated(key: String, old, new):
	if key == ConfigData.KEY_ACCESSIBILITY_SCREEN_READER_ENABLED:
		handle_text_remap(new)

func _on_tts_utterance_end(utterance):
	tts_joy_axis_utterance = null

func handle_text_remap(is_screen_reader: bool):
	var word := "requested" if is_screen_reader else "highlighted"
	n_lbl_press.text = lbl_press_orig_text % word
	n_lbl_move.text = lbl_move_orig_text % word

func _input(event):
	if curr_step == -1:
		return
	if done:
		_input_done(event)
	elif event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()
		var motion := event as InputEventJoypadMotion
		if abs(motion.axis_value) > DEADZONE:
			var idx := motion.axis
			if last_axis != idx:
				last_axis = idx
				var map := JoyMapping.new(JoyMapping.TYPE.AXIS, idx)
				cur_mapping[steps[curr_step]] = map
				n_timer.start()
		elif abs(motion.axis_value) > DEADZONE_IDLE or \
			(motion.axis == last_axis and motion.axis_value < DEADZONE):
			n_timer.stop()
			last_axis = -1
	elif event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()
		if event.pressed:
			var btn := event as InputEventJoypadButton
			var map := JoyMapping.new(JoyMapping.TYPE.BTN, btn.button_index)
			cur_mapping[steps[curr_step]] = map
			n_timer.start()
		else:
			n_timer.stop()

func _input_done(event):
	if event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()
		if event.pressed:
			var controller_tts := ControllerIcons.parse_path_to_tts(
				ControllerIcons._convert_joypad_button_to_path(event.button_index)
			)
			TTS.speak(controller_tts)
		match event.button_index:
			JOY_BUTTON_A:
				$"%A".modulate = current_mapping if event.pressed else known_mapping
			JOY_BUTTON_B:
				$"%B".modulate = current_mapping if event.pressed else known_mapping
			JOY_BUTTON_Y:
				$"%Y".modulate = current_mapping if event.pressed else known_mapping
			JOY_BUTTON_X:
				$"%X".modulate = current_mapping if event.pressed else known_mapping
			JOY_BUTTON_LEFT_SHOULDER:
				$"%L1".modulate = current_mapping if event.pressed else known_mapping
			JOY_BUTTON_RIGHT_SHOULDER:
				$"%R1".modulate = current_mapping if event.pressed else known_mapping
			JOY_AXIS_TRIGGER_LEFT:
				$"%L2".modulate = current_mapping if event.pressed else known_mapping
			JOY_AXIS_TRIGGER_RIGHT:
				$"%R2".modulate = current_mapping if event.pressed else known_mapping
			JOY_BUTTON_LEFT_STICK:
				$"%L3".modulate = current_mapping if event.pressed else known_mapping
			JOY_BUTTON_RIGHT_STICK:
				$"%R3".modulate = current_mapping if event.pressed else known_mapping
			JOY_BUTTON_BACK:
				$"%Select".modulate = current_mapping if event.pressed else known_mapping
			JOY_BUTTON_START:
				$"%Start".modulate = current_mapping if event.pressed else known_mapping
			JOY_BUTTON_DPAD_UP:
				$"%UpDPAD".modulate = current_mapping if event.pressed else known_mapping
			JOY_BUTTON_DPAD_DOWN:
				$"%DownDPAD".modulate = current_mapping if event.pressed else known_mapping
			JOY_BUTTON_DPAD_LEFT:
				$"%LeftDPAD".modulate = current_mapping if event.pressed else known_mapping
			JOY_BUTTON_DPAD_RIGHT:
				$"%RightDPAD".modulate = current_mapping if event.pressed else known_mapping
	elif event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()
		match event.axis:
			JOY_AXIS_LEFT_Y:
				$"%UpLStick".modulate = known_mapping.lerp(current_mapping, max(0, -event.axis_value))
				$"%DownLStick".modulate = known_mapping.lerp(current_mapping, max(0, event.axis_value))
				if event.axis_value < -0.5 and not tts_joy_axis_utterance:
					tts_joy_axis_utterance = TTS.speak("Up on Left Stick", false)
				elif event.axis_value > 0.5 and not tts_joy_axis_utterance:
					tts_joy_axis_utterance = TTS.speak("Down on Left Stick", false)
			JOY_AXIS_LEFT_X:
				$"%LeftLStick".modulate = known_mapping.lerp(current_mapping, max(0, -event.axis_value))
				$"%RightLStick".modulate = known_mapping.lerp(current_mapping, max(0, event.axis_value))
				if event.axis_value < -0.5 and not tts_joy_axis_utterance:
					tts_joy_axis_utterance = TTS.speak("Left on Left Stick", false)
				elif event.axis_value > 0.5 and not tts_joy_axis_utterance:
					tts_joy_axis_utterance = TTS.speak("Right on Left Stick", false)
			JOY_AXIS_RIGHT_Y:
				$"%UpRStick".modulate = known_mapping.lerp(current_mapping, max(0, -event.axis_value))
				$"%DownRStick".modulate = known_mapping.lerp(current_mapping, max(0, event.axis_value))
				if event.axis_value < -0.5 and not tts_joy_axis_utterance:
					tts_joy_axis_utterance = TTS.speak("Up on Right Stick", false)
				elif event.axis_value > 0.5 and not tts_joy_axis_utterance:
					tts_joy_axis_utterance = TTS.speak("Down on Right Stick", false)
			JOY_AXIS_RIGHT_X:
				$"%LeftRStick".modulate = known_mapping.lerp(current_mapping, max(0, -event.axis_value))
				$"%RightRStick".modulate = known_mapping.lerp(current_mapping, max(0, event.axis_value))
				if event.axis_value < -0.5 and not tts_joy_axis_utterance:
					tts_joy_axis_utterance = TTS.speak("Left on Right Stick", false)
				elif event.axis_value > 0.5 and not tts_joy_axis_utterance:
					tts_joy_axis_utterance = TTS.speak("Right on Right Stick", false)

func _on_Timer_timeout():
	next()

func _process(_delta):
	if n_timer.is_stopped():
		n_press_progress.value = 0
	else:
		n_press_progress.value = n_timer.wait_time - n_timer.time_left

func create_mapping_string(mapping) -> String:
	var string := "%s,%s," % [joy_guid, joy_name]
	for k in mapping:
		var m = mapping[k]
		if typeof(m) == TYPE_OBJECT and m.type == JoyMapping.TYPE.NONE:
			continue
		string += "%s:%s," % [k, str(m)]
	var platform := "Unknown"
	if JoyMapping.PLATFORMS.keys().has(OS.get_name()):
		platform = JoyMapping.PLATFORMS[OS.get_name()]
	return string + "platform:" + platform

func _remap(mapping):
	var mapping_str := create_mapping_string(mapping)
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
		child.modulate = Color.WHITE
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
	await get_tree().process_frame
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_action_desc.grab_focus()
		# We control how TTS works for the first frame ever
		await get_tree().process_frame
		TTS.speak(n_lbl_press.text)
		TTS.speak(n_action_desc.text, false)
	else:
		n_btn_skip.grab_focus()

func mark_done():
	done = true
	for child in joy_inputs:
		child.modulate = known_mapping
	$"%YAxisLStick".modulate = Color.WHITE
	$"%XAxisLStick".modulate = Color.WHITE
	$"%YAxisRStick".modulate = Color.WHITE
	$"%XAxisRStick".modulate = Color.WHITE
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
	if n_lbl_done.focus_mode == Control.FOCUS_ALL:
		n_lbl_done.grab_focus()

func step():
	n_btn_prev.disabled = curr_step == 0
	if curr_step >= steps.size():
		_remap(cur_mapping)
	else:
		n_action_desc.text = joy_descriptions[curr_step]
		# Set the last button to known mapping
		if curr_step > 0:
			joy_inputs[curr_step-1].modulate = known_mapping
		joy_inputs[curr_step].modulate = current_mapping
		n_lbl_move.visible = curr_step > 15
		n_lbl_press.visible = curr_step <= 15
		if curr_step == 16:
			TTS.speak(n_lbl_move.text)
		TTS.speak(n_action_desc.text, curr_step != 16)

func next():
	curr_step += 1
	step()

func _on_SkipButton_pressed():
	# Use existing default value
	var key : String = steps[curr_step]
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
