extends Popup

onready var n_main = $TabContainer
onready var n_game_settings = $TabContainer/Game

func _input(event: InputEvent):
	if event.is_action_pressed("rh_menu") and not RetroHubConfig.config.is_first_time:
		get_tree().set_input_as_handled()
		if not visible:
			popup()
			n_game_settings.set_game_data(RetroHub.curr_game_data)
		else:
			hide()
			RetroHubConfig.save_theme_config()

func _unhandled_input(event):
	if event.is_action_pressed("rh_left_shoulder"):
		get_tree().set_input_as_handled()
		if n_main.current_tab == 0:
			n_main.current_tab = n_main.get_tab_count() - 1
		else:
			n_main.current_tab -= 1
		n_main.get_current_tab_control().grab_focus()
	if event.is_action_pressed("rh_right_shoulder"):
		get_tree().set_input_as_handled()
		n_main.current_tab = (n_main.current_tab + 1) % n_main.get_tab_count()
		n_main.get_current_tab_control().grab_focus()
