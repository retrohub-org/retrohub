extends VBoxContainer

func set_name(name):
	$SystemLabel.text = name

func add_game(child):
	$GameContainer.add_child(child)

func get_games():
	return $GameContainer.get_children()
