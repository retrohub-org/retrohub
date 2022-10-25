extends ConfirmationDialog

onready var n_stop_description := $"%StopDescription"

onready var base_text : String = n_stop_description.text

func _ready():
	# The size is reset by the parent popup, so this prevents this one
	# from getting the same size as parent, covering the whole screen
	rect_size = rect_min_size

func set_num_games_pending(num_games_pending: int):
	n_stop_description.text = base_text % num_games_pending
