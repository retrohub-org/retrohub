extends WindowDialog

signal rating_defined(rating_str)

onready var n_min_age = $"%MinAge"

onready var n_rating_nodes := [
	$"%ESRB", $"%PEGI", $"%CERO"
]

func set_rating_str(rating_str: String):
	var splits = rating_str.split_floats("/")
	for i in range(splits.size()):
		n_rating_nodes[i].set_idx(splits[i])

func _on_MinAge_value_changed(value):
	for rating in n_rating_nodes:
		rating.raw_age = value


func _on_AgeRatingPopup_confirmed():
	var rating_str := ""
	for rating in n_rating_nodes:
		if not rating_str.empty():
			rating_str += "/"
		rating_str += str(rating.get_age_index())
	emit_signal("rating_defined", rating_str)


func _on_AgeRatingPopup_about_to_show():
	yield(get_tree(), "idle_frame")
	n_min_age.get_line_edit().grab_focus()

func _on_Cancel_pressed():
	hide()

func _on_Ok_pressed():
	hide()
	_on_AgeRatingPopup_confirmed()
