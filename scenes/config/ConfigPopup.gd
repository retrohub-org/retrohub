extends Popup

onready var n_main := $"%SettingsTab"
onready var n_game_tab := $"%GameTab"
onready var n_panel_container := $"%PanelContainer"

onready var n_game := $"%GameSettings"

onready var n_tab_buttons := [
	$"%QuitTab", $"%GameTab", $"%ScraperTab",
	$"%ThemeTab", $"%GeneralTab", $"%InputTab",
	$"%RegionTab", $"%SystemsTab", $"%EmulatorsTab",
	$"%AboutTab"
]

var last_tab : Control = null
var should_reload_theme := false

func _ready():
	last_tab = n_game_tab
	n_panel_container.get_parent().rect_min_size.y = n_panel_container.rect_size.y
	n_panel_container.get_parent().minimum_size_changed()

func _input(event: InputEvent):
	if not RetroHub._running_game:
		var modal_top := get_viewport().get_modal_stack_top()
		if modal_top == null or modal_top == self:
			if event.is_action_pressed("rh_menu") and not RetroHubConfig.config.is_first_time:
				get_tree().set_input_as_handled()
				if not visible:
					popup()
				else:
					hide()
			if visible and event.is_action_pressed("rh_back"):
				# If using the default Backspace key, don't consume event if inside a
				# text field, otherwise deleting text becomes impossible
				if event is InputEventKey and event.scancode == KEY_BACKSPACE and (get_focus_owner() is TextEdit \
					or get_focus_owner() is LineEdit):
					return
				get_tree().set_input_as_handled()
				if not last_tab:
					last_tab = n_game_tab
				last_tab.grab_focus()

func _on_Tab_pressed(idx: int):
	n_main.current_tab = idx
	_on_SettingsTab_focus_entered()
	_handle_buttons()

func _on_Tab_focus_entered(idx: int):
	n_main.current_tab = idx
	last_tab = get_focus_owner()
	_handle_buttons()

func _handle_buttons():
	for button in n_tab_buttons:
		if button.get_child_count() == 0:
			continue
		button.get_child(0).modulate = RetroHubUI.color_theme_accent if button.pressed else Color.white

func _on_QuitTab_pressed():
	n_main.current_tab = 0

func _on_ConfigPopup_about_to_show():
	n_game.set_game_data(RetroHub.curr_game_data)
	yield(get_tree(), "idle_frame")
	TTS.speak("Configuration opened.")
	if last_tab:
		last_tab.grab_focus()
		TTS.speak("Currently selected tab. " + tts_text(last_tab), false)

func _on_ScrollContainer_focus_entered():
	last_tab.grab_focus()
	last_tab.set_pressed_no_signal(false)
	_handle_buttons()

func _on_SettingsTab_focus_entered():
	n_main.get_current_tab_control().grab_focus()
	if last_tab:
		last_tab.set_pressed_no_signal(true)
		_handle_buttons()


func _on_ConfigPopup_popup_hide():
	if should_reload_theme:
		RetroHubConfig.load_user_data()
		RetroHub.load_theme()
	should_reload_theme = false
	RetroHubConfig.save_theme_config()
	TTS.speak("Configuration closed.")


func _on_theme_reload():
	should_reload_theme = true

func tts_text(focused_node: Node) -> String:
	# Tab buttons got focused?
	if focused_node in n_tab_buttons:
		return (focused_node.get_child(0).get_child(0) as Label).text
	return ""
