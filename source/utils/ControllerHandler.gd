extends Control

var prev_focus : Control = null

func _init():
	ControllerIcons.connect("input_type_changed", self, "_on_input_type_changed")

func _on_input_type_changed(input_type):
	set_process(input_type == ControllerIcons.InputType.CONTROLLER)

func _input(event):
	if event is InputEventJoypadButton:
		_input_button(event)
	elif event is InputEventJoypadMotion:
		_input_motion(event)

func _input_button(event: InputEventJoypadButton):
	var control := get_focus_owner()
	if event.is_action_pressed("rh_accept"):
		if control is LineEdit or control is TextEdit:
			if prev_focus != control:
				if control is LineEdit:
					control.caret_position = control.text.length()
				else:
					control.cursor_set_line(control.text.length())
					control.cursor_set_column(control.text.length())
			prev_focus = control
			RetroHubUI.show_virtual_keyboard()

func _input_motion(event: InputEventJoypadMotion):
	pass
