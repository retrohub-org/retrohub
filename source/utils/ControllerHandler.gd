extends Control

var prev_focus : Control = null

var hyper_focused_control : Control = null

func _init():
	ControllerIcons.connect("input_type_changed", self, "_on_input_type_changed")

func _ready():
	yield(get_tree(), "idle_frame")
	raise()

func _on_input_type_changed(input_type):
	set_process(input_type == ControllerIcons.InputType.CONTROLLER)

func _input(event):
	if hyper_focused_control:
		get_tree().set_input_as_handled()
	if event is InputEventJoypadButton:
		_input_button(event)
	elif event is InputEventJoypadMotion:
		_input_motion(event)

func _input_button(event: InputEventJoypadButton):
	var control := get_focus_owner()
	if hyper_focused_control:
		_input_hyper_focused(event)
	if RetroHubUI.is_virtual_keyboard_visible():
		return
	if event.is_action_released("rh_accept"):
		if (control is LineEdit and control.editable) or (control is TextEdit and not control.readonly):
			if control.get_parent() and control.get_parent() is SpinBox:
				hyper_focused_control = control.get_parent()
				control.theme_type_variation = "HyperFocused"
				control.caret_position = control.text.length()
				return
			if not RetroHubConfig.config.virtual_keyboard_show_on_controller:
				return
			if prev_focus != control:
				if control is LineEdit:
					control.caret_position = control.text.length()
				else:
					control.cursor_set_line(control.text.length())
					control.cursor_set_column(control.text.length())
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
	if hyper_focused_control:
		_input_hyper_focused(event)
		
func _input_hyper_focused(event):
	match hyper_focused_control.get_class():
		"SpinBox":
			_input_motion_spinbox(event)

func _input_motion_spinbox(event):
	var spin_box = hyper_focused_control as SpinBox
	if event.is_action_pressed("rh_up"):
		spin_box.value += 1
	if event.is_action_pressed("rh_down"):
		spin_box.value -= 1
