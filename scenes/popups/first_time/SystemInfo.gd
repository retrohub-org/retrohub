extends VBoxContainer

@onready var n_photo := $"%Photo"
@onready var n_logo := $"%Logo"
@onready var n_fullname := $"%Fullname"
@onready var n_name := $"%Name"
@onready var n_platform := $"%Platform"

func set_system(system_raw: Dictionary):
	n_photo.texture = load("res://assets/systems/%s-photo.png" % system_raw["name"])
	n_logo.texture = load("res://assets/systems/%s-logo.png" % system_raw["name"])
	n_fullname.text = system_raw["fullname"]
	n_name.text = system_raw["name"]
	n_platform.text = system_raw["platform"]
