extends Popup

export(Color) var color_current := Color(1, 1, 1, 1)
export(Color) var color_next := Color(0.5, 0.5, 0.5, 1)
export(Color) var color_prev := Color(0.4, 0.8, 0.4, 1)

onready var n_sidebar := $"%Sidebar"

onready var n_main_content := $"%MainContent"

onready var num_sections := n_sidebar.get_child_count()

func reset_section():
	n_main_content.current_tab = 0
	_on_MainContent_tab_changed(0)

func advance_section():
	if n_main_content.current_tab == n_main_content.get_tab_count() - 1:
		RetroHubConfig.config.is_first_time = false
		RetroHubConfig.save_config()
		hide()
	n_main_content.current_tab += 1


func _on_FirstTimePopup_about_to_show():
	reset_section()


func _on_MainContent_tab_changed(tab):
	n_main_content.get_tab_control(tab).grab_focus()
	
	var counter = 0
	for child in n_sidebar.get_children():
		if counter == tab:
			child.modulate = color_current
		elif counter < tab:
			child.modulate = color_prev
		else:
			child.modulate = color_next
		counter += 1


func _on_FirstTimePopup_popup_hide():
	RetroHubConfig.emit_signal("config_ready", RetroHubConfig.config)
	get_parent().remove_child(self)
	queue_free()
