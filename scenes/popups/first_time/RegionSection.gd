extends Control

signal advance_section

onready var n_region := $"%RegionOptions"
onready var n_rating := $"%RatingContainer"
onready var n_date := $"%DateContainer"

func grab_focus():
	n_region.grab_focus()

func _on_RegionOptions_item_selected(index):
	match index:
		0:
			RetroHubConfig.config.region = "usa"
		1:
			RetroHubConfig.config.region = "eur"
		2:
			RetroHubConfig.config.region = "jpn"
	n_rating.select(index)
	n_date.select(index)


func _on_NextButton_pressed():
	emit_signal("advance_section")
