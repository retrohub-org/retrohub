extends Node

signal app_initializing
signal app_closing
signal app_received_focus
signal app_lost_focus
signal app_returning(system_data, game_data)

signal system_received(system_data)
signal game_received(game_data)

var _num_games_to_generate := 10

onready var JSONUtils = preload("res://addons/retrohub_theme_helper/utils/JSONUtils.gd").new()
onready var GameRandomData = preload("res://addons/retrohub_theme_helper/utils/GameRandomData.gd").new()

# Called when the node enters the scene tree for the first time.
func _ready():
	emit_signal("app_initializing", true)
	randomize()
	load_titles()

func _on_app_closing():
	emit_signal("app_closing")

func _on_app_received_focus():
		emit_signal("app_received_focus")

func _on_app_lost_focus():
	emit_signal("app_lost_focus")

func load_titles():
	yield(get_tree(), "idle_frame")
	var systems = JSONUtils.load_json_file("res://addons/retrohub_theme_helper/data/systems.json")["systems_list"]

	for system in systems:
		var system_data := RetroHubSystemData.new()
		system_data.name = system["name"]
		system_data.fullname = system["fullname"]
		system_data.platform = system["platform"]
		system_data.num_games = _num_games_to_generate
		emit_signal("system_received", system_data)
	
	for system in systems:
		for i in range(_num_games_to_generate):
			emit_signal("game_received", gen_random_game(system["name"]))

func gen_random_game(system_name):
	var game_data := RetroHubGameData.new()
	game_data.has_metadata = true
	game_data.has_media = false # TODO: Implement random media
	game_data.system_name = system_name
	game_data.name = GameRandomData.random_title()
	game_data.path = game_data.name.to_lower() + GameRandomData.random_extension()
	game_data.description = GameRandomData.random_description()
	game_data.rating = randf()
	game_data.release_date = GameRandomData.random_date()
	game_data.developer = GameRandomData.random_company()
	game_data.publisher = GameRandomData.random_company()
	game_data.genre = GameRandomData.random_genre()
	
	# 50/50 chance of being single or multiplayer
	if randf() > 0.5:
		game_data.num_players = "1-1"
	else:
		game_data.num_players = "%d-%d" % [1 + randi() % 4, 2 + randi() % 7]
	game_data.age_rating = GameRandomData.random_age_rating()
	game_data.favorite = randf() > 0.7
	game_data.play_count = randi() % 1000
	game_data.last_played = GameRandomData.random_date()
	
	return game_data

func request_game_media(game_data: RetroHubGameData) -> RetroHubGameMediaData:
	print("Data requested")
	return RetroHubGameMediaData.new()

func launch_game(game_data: RetroHubGameData):
	print("Launching game ", game_data.name)

func stop_game():
	print("Stopping game")
	load_titles()
