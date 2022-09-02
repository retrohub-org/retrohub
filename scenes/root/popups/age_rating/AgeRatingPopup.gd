extends ConfirmationDialog

signal rating_defined(rating_str)

onready var n_min_age = $"%MinAge"

onready var n_rating_nodes := [
	$"%ESRB", $"%PEGI", $"%CERO"
]

func set_rating_str(rating_str: String):
	var splits = rating_str.split_floats("/")
	for i in range(splits.size()):
		# FIXME: idx is offset by -1 unitl unknown textures are created
		n_rating_nodes[i].set_idx(splits[i]-1)

func _on_MinAge_value_changed(value):
	for rating in n_rating_nodes:
		rating.raw_age = value


func _on_AgeRatingPopup_confirmed():
	var rating_str := ""
	for rating in n_rating_nodes:
		if not rating_str.empty():
			rating_str += "/"
		rating_str += str(rating.get_age_index() + 1)
	emit_signal("rating_defined", rating_str)


func _on_AgeRatingPopup_about_to_show():
	n_min_age.grab_focus()


func _on_AgeRatingPopup_focus_entered():
	n_min_age.grab_focus()
