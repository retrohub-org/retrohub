extends Button

class_name RetroHubScraperGameEntry

signal game_selected(entry)

enum State {
	SUCCESS,
	WORKING,
	WAITING,
	WARNING,
	ERROR,
}

const FETCH_METADATA = 1
const FETCH_MEDIA = 2

const CHECK_HASH = 1
const CHECK_SEARCH = 2

var game_data : RetroHubGameData setget set_game_data
var state : int setget set_state
var data

var fetch_mode
var check_mode

func set_game_data(_game_data: RetroHubGameData):
	game_data = _game_data
	text = game_data.path.get_file()

func set_state(_state: int):
	state = _state
	match state:
		State.SUCCESS:
			set_font_color(RetroHubUI.color_success)
			text = game_data.name
			icon = preload("res://assets/icons/success.svg")
		State.WORKING:
			set_font_color(RetroHubUI.color_pending)
			icon = preload("res://assets/icons/downloading.svg")
		State.WAITING:
			set_font_color(RetroHubUI.color_unavailable)
			icon = preload("res://assets/icons/loading.svg")
		State.WARNING:
			set_font_color(RetroHubUI.color_warning)
			icon = preload("res://assets/icons/warning.svg")
		State.ERROR:
			set_font_color(RetroHubUI.color_error)
			icon = preload("res://assets/icons/error.svg")
		_:
			set_font_color(Color("ffffff"))
			icon = null
	if pressed:
		emit_signal("game_selected", self)

func set_font_color(color: Color):
	add_color_override("font_color", color)
	add_color_override("font_color_hover", color)
	add_color_override("font_color_focus", color)


func _on_GameEntry_toggled(button_pressed):
	if button_pressed:
		emit_signal("game_selected", self)
