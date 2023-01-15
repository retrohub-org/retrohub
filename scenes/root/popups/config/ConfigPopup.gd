extends Popup

export(ButtonGroup) var tab_button_group : ButtonGroup

onready var n_main := $"%SettingsTab"
onready var n_game_tab := $"%GameTab"

onready var n_game = $"%GameSettings"

onready var n_root = $".."

var last_tab : Control = null

func _ready():
	last_tab = n_game_tab

func _input(event: InputEvent):
	if not RetroHub.running_game:
		if event.is_action_pressed("rh_menu") and not RetroHubConfig.config.is_first_time:
			get_tree().set_input_as_handled()
			if not visible:
				popup()
				n_game.set_game_data(RetroHub.curr_game_data)
			else:
				hide()
				RetroHubConfig.save_theme_config()

func show_first_time_popup():
	hide()
	n_root.show_first_time_popup()

func _on_Tab_pressed(idx: int):
	n_main.current_tab = idx
	_on_SettingsTab_focus_entered()

func _on_Tab_focus_entered(idx: int):
	n_main.current_tab = idx
	last_tab = get_focus_owner()

func _on_QuitTab_pressed():
	n_main.current_tab = 0

func _on_ConfigPopup_about_to_show():
	yield(get_tree(), "idle_frame")
	if last_tab:
		last_tab.grab_focus()

func _on_ScrollContainer_focus_entered():
	last_tab.grab_focus()

func _on_SettingsTab_focus_entered():
	n_main.get_current_tab_control().grab_focus()
