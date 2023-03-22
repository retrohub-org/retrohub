extends Control

signal advance_section

onready var n_intro_lbl := $"%IntroLabel"
onready var n_region := $"%RegionOptions"
onready var n_rating := $"%RatingContainer"
onready var n_date := $"%DateContainer"
onready var n_systems := $"%SystemsContainer"


func grab_focus():
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_intro_lbl.grab_focus()
	else:
		n_region.grab_focus()
	n_systems.select(n_region.selected)

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
	n_systems.select(index)


func _on_NextButton_pressed():
	emit_signal("advance_section")
