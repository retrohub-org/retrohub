extends Control

var prev_focus : Control = null
var hyper_focused_control : Control = null

var _joypad_echo_pre_delay := Timer.new()
var _joypad_echo_delay := Timer.new()
var _joypad_last_event = null
var _joypad_motion_last_action := ""
var _joypad_motion_last_value := 0.0
var _event_handled := false

func _init():
	#warning-ignore:return_value_discarded
	ControllerIcons.connect("input_type_changed", Callable(self, "_on_input_type_changed"))

func _ready():
	#warning-ignore:return_value_discarded
	RetroHubConfig.connect("config_updated", Callable(self, "_on_config_updated"))
	await get_tree().process_frame
	move_to_front()
	_joypad_echo_pre_delay.wait_time = RetroHubConfig.config.input_controller_echo_pre_delay
	_joypad_echo_delay.wait_time = RetroHubConfig.config.input_controller_echo_delay
	_joypad_echo_pre_delay.one_shot = true
	#warning-ignore:return_value_discarded
	_joypad_echo_pre_delay.connect("timeout", Callable(self, "_on_joypad_echo_pre_delay_timeout"))
	#warning-ignore:return_value_discarded
	_joypad_echo_delay.connect("timeout", Callable(self, "_on_joypad_echo_delay_timeout"))
	add_child(_joypad_echo_pre_delay)
	add_child(_joypad_echo_delay)

func _on_config_updated(key: String, _old, new):
	match key:
		ConfigData.KEY_INPUT_CONTROLLER_ECHO_PRE_DELAY:
			_joypad_echo_pre_delay.wait_time = new
		ConfigData.KEY_INPUT_CONTROLLER_ECHO_DELAY:
			_joypad_echo_delay.wait_time = new

func _on_input_type_changed(input_type):
	set_process(input_type == ControllerIcons.InputType.CONTROLLER)

func _on_joypad_echo_pre_delay_timeout():
	_joypad_echo_delay.start()
	_on_joypad_echo_delay_timeout()

func _on_joypad_echo_delay_timeout():
	Input.parse_input_event(_joypad_last_event)

#func _input(event):
#	_event_handled = false
#	RetroHub._is_echo = false
#	if hyper_focused_control:
#		get_viewport().set_input_as_handled()
#	if event is InputEventKey:
#		RetroHub._is_echo = event.is_echo()
#	if event is InputEventJoypadButton:
#		_input_button(event)
#	elif event is InputEventJoypadMotion:
#		_input_motion(event)
#	elif event is InputEventAction:
#		_input_hyper_focused(event)

func _input_button(event: InputEventJoypadButton):
	_input_ui_movement_button(event)
	var control := get_viewport().gui_get_focus_owner()
	if hyper_focused_control:
		_input_hyper_focused(event)
	if RetroHubUI.is_virtual_keyboard_visible():
		return
	if event.is_action_released("rh_accept"):
		if (control is LineEdit and control.editable) or (control is TextEdit and not control.readonly):
			if control.get_parent() and control.get_parent() is SpinBox:
				hyper_focused_control = control.get_parent()
				control.theme_type_variation = "HyperFocused"
				control.caret_column = control.text.length()
				return
			if not RetroHubConfig.config.virtual_keyboard_show_on_controller:
				return
			if prev_focus != control:
				if control is LineEdit:
					control.caret_column = control.text.length()
				else:
					control.set_caret_line(control.text.length())
					control.set_caret_column(control.text.length())
			prev_focus = control
			RetroHubUI.show_virtual_keyboard()
	if event.is_action_pressed("rh_back"):
		if hyper_focused_control:
			if hyper_focused_control is SpinBox:
				hyper_focused_control.get_line_edit().theme_type_variation = ""
			else:
				hyper_focused_control.theme_type_variation = ""
			hyper_focused_control = null

func _input_motion(event: InputEventJoypadMotion):
	_input_ui_movement_motion(event)
	_input_hyper_focused(event)


func _input_hyper_focused(event):
	if hyper_focused_control and not _event_handled:
		match hyper_focused_control.get_class():
			"SpinBox":
				_input_motion_spinbox(event)

func _input_motion_spinbox(event):
	var spin_box := hyper_focused_control as SpinBox
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_focus_prev"):
		spin_box.value += spin_box.step
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_focus_next"):
		spin_box.value -= spin_box.step

func _input_ui_movement_button(event: InputEventJoypadButton):
	if event == _joypad_last_event:
		RetroHub._is_echo = true
		return
	if event.is_action_released("ui_left") or event.is_action_released("ui_up") \
		or event.is_action_released("ui_right") or event.is_action_released("ui_down") \
		or event.is_action_released("ui_focus_prev") or event.is_action_released("ui_focus_next"):
		_joypad_echo_pre_delay.stop()
		_joypad_echo_delay.stop()
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up") \
		or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down") \
		or event.is_action_pressed("ui_focus_prev") or event.is_action_pressed("ui_focus_next"):
		if _joypad_echo_pre_delay.is_stopped():
			_joypad_last_event = event
			_joypad_echo_pre_delay.start()

func _input_ui_movement_motion(event: InputEventJoypadMotion):
	if event == _joypad_last_event:
		RetroHub._is_echo = true
		return
	var action : String
	# Godot uses the same action for both directions of an axis, for some reason...
	if event.is_action("ui_left"):
		if event.axis_value < 0.0:
			action = "ui_left"
		else:
			action = "ui_right"
	elif event.is_action("ui_up"):
		if event.axis_value < 0.0:
			action = "ui_up"
		else:
			action = "ui_down"
	elif event.is_action("ui_focus_prev"):
		if event.axis_value < 0.0:
			action = "ui_focus_prev"
		else:
			action = "ui_focus_next"
	# This only happens with input bounces (releasing the stick)
	elif event.is_action("ui_right"):
		action = "ui_right"
	elif event.is_action("ui_down"):
		action = "ui_down"
	elif event.is_action("ui_focus_next"):
		action = "ui_focus_next"
	else:
		return
	var deadzone := InputMap.action_get_deadzone(action)
	# If event is the same
	if action == _joypad_motion_last_action:
		_mark_event_as_handled()
		# If event falls behind deadzone, it's considered released
		if abs(event.get_axis_value()) < deadzone:
			_joypad_echo_pre_delay.stop()
			_joypad_echo_delay.stop()
			_joypad_motion_last_action = ""
			_joypad_motion_last_value = 0.0
		# Else record this event strength
		_joypad_motion_last_value = abs(event.axis_value)
	# Event is different
	elif not _joypad_motion_last_action.is_empty():
		# Is it stronger than current event?
		_mark_event_as_handled()
		if abs(event.axis_value) > _joypad_motion_last_value and abs(event.axis_value) > deadzone:
			_mark_event_as_handled()
			# Switch to new event
			_joypad_last_event = _generate_motion_event(action)
			_joypad_echo_pre_delay.start()
			_joypad_echo_delay.stop()
			_joypad_motion_last_action = action
			_joypad_motion_last_value = abs(event.axis_value)
		# Else is it the opposite event of last frame (happens when stick is released fast and bounces)
		elif _is_action_opposite(action, _joypad_motion_last_action):
			_joypad_echo_pre_delay.stop()
			_joypad_echo_delay.stop()
			_joypad_motion_last_action = ""
			_joypad_motion_last_value = 0.0
	# No current event, set this one if surpasses deadzone
	elif _joypad_motion_last_action.is_empty() and abs(event.axis_value) > deadzone:
		_joypad_last_event = _generate_motion_event(action)
		_joypad_echo_pre_delay.start()
		_joypad_echo_delay.stop()
		_joypad_motion_last_action = action
		_joypad_motion_last_value = abs(event.axis_value)

func _generate_motion_event(action: String):
	var event := InputEventAction.new()
	event.button_pressed = true
	event.action = action
	return event

func _is_action_opposite(action1: String, action2: String):
	match action1:
		"ui_left":
			return action2 == "ui_right"
		"ui_right":
			return action2 == "ui_left"
		"ui_up":
			return action2 == "ui_down"
		"ui_down":
			return action2 == "ui_up"
		"ui_focus_prev":
			return action2 == "ui_focus_next"
		"ui_focus_next":
			return action2 == "ui_focus_prev"
	return false

func _mark_event_as_handled():
	get_viewport().set_input_as_handled()
	_event_handled = true
