extends Control
class_name TabContainerHandler

## Allows switching tabs with left/right slide keybinds
## Also implements focus

signal tab_changed(tab_container, enter_tab)

@export var signal_tab_change := false

var tab : TabContainer

var _focused := false

func _ready():
	# This _ready is called before parent, we need to wait a frame for parent to initialize
	await get_tree().process_frame
	tab = get_child(0) if get_child_count() > 0 else null
	if not tab or not tab is TabContainer:
		push_error("TabContainerHandler has no TabContainer child! Queueing free...")
		queue_free()
	tab.tab_clicked.connect(_on_tab_clicked)
	tab.get_tab_bar().focus_entered.connect(_on_focus_entered)
	tab.get_tab_bar().focus_exited.connect(_on_focus_exited)

func _on_focus_entered():
	_focused = true

func _on_focus_exited():
	_focused = false

func _input(event):
	if is_visible_in_tree():
		if event.is_action_pressed("rh_left_shoulder") or \
			(_focused and event.is_action_pressed("ui_left")):
			if is_key_event_on_text(event):
				return
			get_viewport().set_input_as_handled()
			if tab.current_tab > 0:
				tab.current_tab -= 1
			else:
				tab.current_tab = tab.get_tab_count() - 1
			handle_focus(not _focused)
		elif event.is_action_pressed("rh_right_shoulder") or \
			(_focused and event.is_action_pressed("ui_right")):
			if is_key_event_on_text(event):
				return
			get_viewport().set_input_as_handled()
			if tab.current_tab < tab.get_tab_count() - 1:
				tab.current_tab += 1
			else:
				tab.current_tab = 0
			handle_focus(not _focused)
		elif _focused and (event.is_action_pressed("ui_down") or \
			event.is_action_pressed("rh_accept")):
			get_viewport().set_input_as_handled()
			handle_focus(true)
		elif _focused and event.is_action_pressed("ui_up"):
			get_viewport().set_input_as_handled()

func is_key_event_on_text(event: InputEvent):
	if event is InputEventKey:
		var control := get_viewport().gui_get_focus_owner()
		return (control is LineEdit or control is TextEdit) and control.editable
	return false

func _on_tab_clicked(_tab_idx: int):
	handle_focus(not _focused)

func handle_focus(enter_tab: bool):
	if not enter_tab:
		RetroHubUI.play_sound(RetroHubUI.AudioKeys.SLIDE)
	await get_tree().process_frame
	if signal_tab_change:
		emit_signal("tab_changed", tab, enter_tab)
	elif enter_tab and tab.get_current_tab_control().focus_mode != FOCUS_NONE:
		tab.get_current_tab_control().grab_focus()

func tts_text(focused: Control):
	if self == focused:
		var text := tab.get_tab_title(tab.current_tab)
		# This is called before the focused callback. We can use this to know if
		# it's the first time the tabs are being focused,
		if not _focused:
			var format_str := " tab. Press the %s and %s %s to switch tabs."
			match ControllerIcons._last_input_type:
				ControllerIcons.InputType.KEYBOARD_MOUSE:
					text += format_str % [
						ControllerIcons.parse_path_to_tts("rh_left_shoulder"),
						ControllerIcons.parse_path_to_tts("rh_right_shoulder"),
						"keys"
					]
				ControllerIcons.InputType.CONTROLLER:
					text += format_str % [
						ControllerIcons.parse_path_to_tts("rh_left_shoulder"),
						ControllerIcons.parse_path_to_tts("rh_right_shoulder"),
						"buttons"
					]
		return text
	return ""
