extends Control
class_name TabContainerHandler

## Allows switching tabs with left/right slide keybinds

signal tab_changed(tab_container)

export(bool) var signal_tab_change := false

var tab : TabContainer

func _ready():
	# This _ready is called before parent, we need to wait a frame for parent to initialize
	yield(get_tree(), "idle_frame")
	tab = get_child(0) if get_child_count() > 0 else null
	if not tab or not tab is TabContainer:
		push_error("TabContainerHandler has no TabContainer child! Queueing free...")
		queue_free()

func _unhandled_input(event):
	if is_visible_in_tree():
		if event.is_action_pressed("rh_left_shoulder"):
			get_tree().set_input_as_handled()
			if tab.current_tab > 0:
				tab.current_tab -= 1
			else:
				tab.current_tab = tab.get_tab_count() - 1
			handle_focus()
		elif event.is_action_pressed("rh_right_shoulder"):
			get_tree().set_input_as_handled()
			if tab.current_tab < tab.get_tab_count() - 1:
				tab.current_tab += 1
			else:
				tab.current_tab = 0
			handle_focus()

func handle_focus():
	if signal_tab_change:
		emit_signal("tab_changed", tab)
	elif tab.get_current_tab_control().focus_mode != FOCUS_NONE:
		tab.get_current_tab_control().grab_focus()
