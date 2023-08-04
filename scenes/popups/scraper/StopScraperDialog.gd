extends ConfirmationDialog

@onready var n_stop_description := %StopDescription

@onready var base_text : String = n_stop_description.text

func set_num_games_pending(num_games_pending: int):
	n_stop_description.text = base_text % num_games_pending
