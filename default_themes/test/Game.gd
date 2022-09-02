extends Button

signal game_pressed(data)
signal game_focused(data)

export(Resource) var game_data setget set_game_data

func set_game_data(_game_data):
	game_data = _game_data
	self.text = game_data.name

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_GameButton_pressed():
	emit_signal("game_pressed", game_data)


func _on_GameButton_focus_entered():
	emit_signal("game_focused", game_data)
