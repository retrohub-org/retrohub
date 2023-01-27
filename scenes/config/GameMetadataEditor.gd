extends Control

signal change_ocurred
signal reset_state

onready var n_name = $"%Name"
onready var n_description = $"%Description"
onready var n_rating_lbl = $"%RatingLabel"
onready var n_rating = $"%Rating"
onready var n_release_date = $"%ReleaseDate"
onready var n_developer = $"%Developer"
onready var n_publisher = $"%Publisher"
onready var n_esrb = $"%ESRB"
onready var n_pegi = $"%PEGI"
onready var n_cero = $"%CERO"
onready var n_change_age_rating = $"%ChangeAgeRating"
onready var n_genres = $"%Genres"
onready var n_fixed_players = $"%FixedPlayers"
onready var n_fixed_players_num = $"%FixedPlayersNum"
onready var n_variable_players = $"%VariablePlayers"
onready var n_variable_players_min = $"%VariablePlayersMin"
onready var n_variable_players_max = $"%VariablePlayersMax"
onready var n_favorite = $"%Favorite"
onready var n_num_times_played = $"%NumTimesPlayed"

onready var n_age_rating_popup = $"%AgeRatingPopup"

var game_data : RetroHubGameData setget set_game_data
var rating_str : String

func _ready():
	RetroHubConfig.connect("game_data_updated", self, "_on_game_data_updated")

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
		rating_str = game_data.age_rating
		set_rating_icons()
		n_esrb.from_rating_str(game_data.age_rating, 0)
		n_pegi.from_rating_str(game_data.age_rating, 1)
		n_cero.from_rating_str(game_data.age_rating, 2)
		n_genres.text = game_data.genres[0] if game_data.genres.size() > 0 else ""
		var players_splits = game_data.num_players.split_floats("-")
		if players_splits.size() >= 2:
			if players_splits[0] == players_splits[1]:
				n_fixed_players.pressed = true
				n_fixed_players_num.value = players_splits[0]
				n_variable_players_min.value = 1
				n_variable_players_max.value = 2
			else:
				n_variable_players.pressed = true
				n_variable_players_min.value = players_splits[0]
				n_variable_players_max.value = players_splits[1]
				n_fixed_players_num.value = 1
		else:
			n_fixed_players.pressed = true
			n_fixed_players_num.value = 1
			n_variable_players.pressed = false
			n_variable_players_min.value = 1
			n_variable_players_max.value = 2
		n_favorite.pressed = game_data.favorite
		n_num_times_played.value = game_data.play_count
	else:
		set_edit_nodes_enabled(false)
		n_name.text = ""
		n_description.text = ""
		n_rating.value = 0
		n_release_date.text = ""
		n_developer.text = ""
		n_publisher.text = ""
		rating_str = "0/0/0"
		set_rating_icons()
		n_genres.text = ""
		n_fixed_players.pressed = true
		n_fixed_players_num.value = 1
		n_variable_players.pressed = false
		n_variable_players_min.value = 1
		n_variable_players_max.value = 2
		n_favorite.pressed = false
		n_num_times_played.value = 0
	emit_signal("reset_state")

func set_edit_nodes_enabled(enabled: bool):
	n_name.editable = enabled
	n_description.readonly = !enabled
	n_rating.editable = enabled
	n_release_date.editable = enabled
	n_developer.editable = enabled
	n_publisher.editable = enabled
	n_change_age_rating.disabled = !enabled
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
		RetroHubConfig.save_game_data(game_data)
		emit_signal("reset_state")

func grab_focus():
	n_name.grab_focus()

func _on_Rating_value_changed(value):
	n_rating_lbl.text = str(value) + "%"

func _on_AgeRatingPopup_rating_defined(_rating_str):
	rating_str = _rating_str
	set_rating_icons()

func _on_AgeRatingPopup_popup_hide():
	n_change_age_rating.grab_focus()

func set_rating_icons():
	n_esrb.from_rating_str(rating_str, 0)
	n_pegi.from_rating_str(rating_str, 1)
	n_cero.from_rating_str(rating_str, 2)

func _on_ChangeAgeRating_pressed():
	n_age_rating_popup.set_rating_str(rating_str)
	n_age_rating_popup.popup()


func _on_FixedPlayers_toggled(button_pressed):
	n_fixed_players_num.editable = true
	n_variable_players_max.editable = false
	n_variable_players_min.editable = false


func _on_VariablePlayers_toggled(button_pressed):
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
