extends VBoxContainer

onready var n_options := $"%RatingOptions"
onready var n_rating_icons := $"%RatingIcons"

func select(idx: int):
	n_options.select(idx)
	_on_RatingOptions_item_selected(idx)

func _ready():
	_on_RatingOptions_item_selected(n_options.selected)

func _on_RatingOptions_item_selected(index):
	match index:
		0:
			RetroHubConfig.config.rating_system = "esrb"
		1:
			RetroHubConfig.config.rating_system = "pegi"
		2:
			RetroHubConfig.config.rating_system = "cero"

	for i in range(n_rating_icons.get_child_count()):
		n_rating_icons.get_child(i).from_idx(i+1, index)
