extends CenterContainer

var game_data : RetroHubGameData setget set_game_data
var label_text : String

func _ready():
	label_text = $Label.text

func set_game_data(_game_data : RetroHubGameData):
	game_data = _game_data
	
	$Label.text = label_text % game_data.name
