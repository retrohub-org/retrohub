extends Control

signal change_ocurred
signal reset_state

@onready var n_intro_lbl := $"%IntroLabel"
@onready var n_name := $"%Name"
@onready var n_description := $"%Description"
@onready var n_rating_lbl := $"%RatingLabel"
@onready var n_rating := $"%Rating"
@onready var n_release_date := $"%ReleaseDate"
@onready var n_developer := $"%Developer"
@onready var n_publisher := $"%Publisher"
@onready var n_age_rating := $"%AgeRating"
@onready var n_genres := $"%Genres"
@onready var n_fixed_players := $"%FixedPlayers"
@onready var n_fixed_players_num := $"%FixedPlayersNum"
@onready var n_variable_players := $"%VariablePlayers"
@onready var n_variable_players_min := $"%VariablePlayersMin"
@onready var n_variable_players_max := $"%VariablePlayersMax"
@onready var n_favorite := $"%Favorite"
@onready var n_num_times_played := $"%NumTimesPlayed"

var game_data : RetroHubGameData: set = set_game_data

@export var disable_edits: bool := false

func _ready():
	#warning-ignore:return_value_discarded
	RetroHubConfig.connect("game_data_updated", Callable(self, "_on_game_data_updated"))
	RetroHubConfig.connect("config_ready", Callable(self, "_on_config_ready"))
	RetroHubConfig.connect("config_updated", Callable(self, "_on_config_updated"))

	n_age_rating.get_popup().max_height = RetroHubUI.max_popupmenu_height

func _on_config_ready(config: ConfigData):
	update_age_rating_options(config.rating_system)

func _on_config_updated(key: String, old, new):
	if key == ConfigData.KEY_RATING_SYSTEM:
		update_age_rating_options(new)
		if game_data:
			discard_changes()

func update_age_rating_options(type: String):
	n_age_rating.clear()
	match type:
		"pegi":
			n_age_rating.add_icon_item(load("res://assets/ratings/pegi/unknown.png"), "Unknown")
			n_age_rating.add_icon_item(load("res://assets/ratings/pegi/3.png"), "3+")
			n_age_rating.add_icon_item(load("res://assets/ratings/pegi/7.png"), "7+")
			n_age_rating.add_icon_item(load("res://assets/ratings/pegi/12.png"), "12+")
			n_age_rating.add_icon_item(load("res://assets/ratings/pegi/16.png"), "16+")
			n_age_rating.add_icon_item(load("res://assets/ratings/pegi/18.png"), "18+")
		"cero":
			n_age_rating.add_icon_item(load("res://assets/ratings/cero/unknown.png"), "Unknown")
			n_age_rating.add_icon_item(load("res://assets/ratings/cero/A.png"), "All Ages")
			n_age_rating.add_icon_item(load("res://assets/ratings/cero/B.png"), "12+")
			n_age_rating.add_icon_item(load("res://assets/ratings/cero/C.png"), "15+")
			n_age_rating.add_icon_item(load("res://assets/ratings/cero/D.png"), "17+")
			n_age_rating.add_icon_item(load("res://assets/ratings/cero/Z.png"), "Adults Only")
		"esrb", _:
			n_age_rating.add_icon_item(load("res://assets/ratings/esrb/unknown.png"), "Unknown")
			n_age_rating.add_icon_item(load("res://assets/ratings/esrb/E.png"), "Everyone")
			n_age_rating.add_icon_item(load("res://assets/ratings/esrb/E10.png"), "Everyone 10+")
			n_age_rating.add_icon_item(load("res://assets/ratings/esrb/T.png"), "Teen")
			n_age_rating.add_icon_item(load("res://assets/ratings/esrb/M.png"), "Mature")
			n_age_rating.add_icon_item(load("res://assets/ratings/esrb/AO.png"), "Adults Only")
		

func _on_game_data_updated(_game_data: RetroHubGameData):
	if game_data == _game_data:
		discard_changes()

func set_game_data(_game_data: RetroHubGameData) -> void:
	game_data = _game_data
	discard_changes()

func discard_changes():
	if game_data:
		set_edit_nodes_enabled(true)
		n_name.text = game_data.name
		n_description.text = game_data.description
		n_rating.value = int(game_data.rating * 100)
		n_release_date.text = RegionUtils.localize_date(game_data.release_date)
		n_developer.text = game_data.developer
		n_publisher.text = game_data.publisher
		n_age_rating.selected = int(game_data.age_rating.get_slice("/", RegionUtils.localize_age_rating_idx()))
		n_genres.text = game_data.genres[0] if game_data.genres.size() > 0 else ""
		var players_splits := game_data.num_players.split_floats("-")
		if players_splits.size() >= 2:
			if players_splits[0] == players_splits[1]:
				n_fixed_players.set_pressed_no_signal(true)
				n_variable_players.set_pressed_no_signal(false)
				if not disable_edits:
					_on_FixedPlayers_toggled(true)
				n_fixed_players_num.value = players_splits[0]
				n_variable_players_min.value = 1
				n_variable_players_max.value = 2
			else:
				n_variable_players.set_pressed_no_signal(true)
				n_fixed_players.set_pressed_no_signal(false)
				if not disable_edits:
					_on_VariablePlayers_toggled(true)
				n_variable_players_min.value = players_splits[0]
				n_variable_players_max.value = players_splits[1]
				n_fixed_players_num.value = 1
		else:
			n_fixed_players.set_pressed_no_signal(true)
			if not disable_edits:
				_on_FixedPlayers_toggled(true)
			n_fixed_players_num.value = 1
			n_variable_players.set_pressed_no_signal(false)
			n_variable_players_min.value = 1
			n_variable_players_max.value = 2
		n_favorite.set_pressed_no_signal(game_data.favorite)
		n_num_times_played.value = game_data.play_count
	else:
		set_edit_nodes_enabled(false)
		n_name.text = ""
		n_description.text = ""
		n_rating.value = 0
		n_release_date.text = ""
		n_developer.text = ""
		n_publisher.text = ""
		n_age_rating.selected = 0
		n_genres.text = ""
		n_fixed_players.set_pressed_no_signal(true)
		_on_FixedPlayers_toggled(true)
		n_fixed_players_num.value = 1
		n_variable_players.set_pressed_no_signal(false)
		n_variable_players_min.value = 1
		n_variable_players_max.value = 2
		n_favorite.set_pressed_no_signal(false)
		n_num_times_played.value = 0
	emit_signal("reset_state")

func set_edit_nodes_enabled(enabled: bool):
	if disable_edits:
		enabled = false
	n_name.editable = enabled
	n_description.readonly = !enabled
	n_rating.editable = enabled
	n_release_date.editable = enabled
	n_developer.editable = enabled
	n_publisher.editable = enabled
	n_age_rating.disabled = !enabled
	n_genres.editable = enabled
	n_fixed_players.disabled = !enabled
	n_fixed_players_num.editable = enabled
	n_variable_players.disabled = !enabled
	n_variable_players_min.editable = enabled
	n_variable_players_max.editable = enabled
	n_favorite.disabled = !enabled
	n_num_times_played.editable = enabled

func save_changes():
	if game_data:
		game_data.name = n_name.text
		game_data.description = n_description.text
		game_data.rating = n_rating.value / 100.0
		game_data.release_date = RegionUtils.globalize_date_str(n_release_date.text)
		game_data.developer = n_developer.text
		game_data.publisher = n_publisher.text
		var rating_idx := RegionUtils.localize_age_rating_idx()
		var rating_str = "%d/%d/%d" % [
			n_age_rating.selected if rating_idx == 0 else int(game_data.age_rating.get_slice("/", 0)),
			n_age_rating.selected if rating_idx == 1 else int(game_data.age_rating.get_slice("/", 1)),
			n_age_rating.selected if rating_idx == 2 else int(game_data.age_rating.get_slice("/", 2))
		]
		game_data.age_rating = rating_str
		if game_data.genres.size():
			game_data.genres[0] = n_genres.text
		else:
			game_data.genres.push_back(n_genres.text)
		if n_fixed_players.pressed:
			game_data.num_players = "%d-%d" % [n_fixed_players_num.value, n_fixed_players_num.value]
		else:
			game_data.num_players = "%d-%d" % [n_variable_players_min.value, n_variable_players_max.value]
		game_data.favorite = n_favorite.pressed
		game_data.play_count = n_num_times_played.value
		if RetroHubConfig.save_game_data(game_data):
			emit_signal("reset_state")

func grab_focus():
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_intro_lbl.grab_focus()
	else:
		n_name.grab_focus()

func _on_Rating_value_changed(value):
	n_rating_lbl.text = str(value) + "%"


func _on_FixedPlayers_toggled(_button_pressed):
	n_fixed_players_num.editable = true
	n_variable_players_max.editable = false
	n_variable_players_min.editable = false


func _on_VariablePlayers_toggled(_button_pressed):
	n_fixed_players_num.editable = false
	n_variable_players_max.editable = true
	n_variable_players_min.editable = true


func _on_FixedPlayersNum_value_changed(value):
	if value == 1:
		n_fixed_players_num.suffix = "player"
	else:
		n_fixed_players_num.suffix = "players"


func _on_VariablePlayersMin_value_changed(value):
	n_variable_players_max.min_value = value if value > 1 else 2

func _on_change_ocurred(_tmp = null):
	emit_signal("change_ocurred")
