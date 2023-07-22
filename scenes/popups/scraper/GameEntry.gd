extends Button

class_name RetroHubScraperGameEntry

signal game_selected(entry, by_app)

enum State {
	SUCCESS,
	WORKING,
	WAITING,
	WARNING,
	ERROR,
}

var game_data : RetroHubGameData: set = set_game_data
var state : int: set = set_state
var data

# Info status
var curr := 0
var total := 0
var description := ""

func _on_GameEntry_toggled(_pressed):
	if _pressed:
		emit_signal("game_selected", self, false)

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
	if button_pressed:
		emit_signal("game_selected", self, true)

func set_font_color(color: Color):
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_color_hover", color)
	add_theme_color_override("font_color_focus", color)
