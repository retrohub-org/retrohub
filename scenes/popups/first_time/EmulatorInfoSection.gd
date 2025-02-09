@tool
extends VBoxContainer

@export var label : String:
	set(value):
		label = value
		if n_label:
			n_label.text = label

@onready var n_label := %Label
@onready var n_found_icon := %FoundIcon
@onready var n_found_label := %FoundLabel
@onready var n_found_details := %FoundDetails

@onready var icon_found := preload("res://assets/icons/success.svg")
@onready var icon_not_found := preload("res://assets/icons/failure.svg")

func _ready():
	label = label

func set_found(found: bool, details: String):
	n_found_icon.texture = icon_found if found else icon_not_found
	n_found_label.add_theme_color_override("font_color", RetroHubUI.color_success if found else RetroHubUI.color_error)
	n_found_label.text = "Found" if found else "Not found"
	n_found_details.add_theme_color_override("font_color", RetroHubUI.color_success if found else RetroHubUI.color_unavailable)
	n_found_details.text = details

func tts_prompt() -> String:
	var text : String = n_label.text + ": " + n_found_label.text
	if n_found_label.text == "Found":
		text += " at " + n_found_details.text
	else:
		text += ". Searched paths: " + n_found_details.text
	return text
