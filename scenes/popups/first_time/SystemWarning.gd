extends AcceptDialog

@onready var n_lbl := $"%Label2"

func _on_SystemWarning_about_to_show():
	await get_tree().idle_frame
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_lbl.grab_focus()
	else:
		get_ok_button().grab_focus()
