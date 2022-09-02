extends VBoxContainer

onready var n_fullname := $"%Fullname"
onready var n_name := $"%Name"
onready var n_platform := $"%Platform"

func set_system(system_raw: Dictionary):
	n_fullname.text = system_raw["fullname"]
	n_name.text = system_raw["name"]
	n_platform.text = system_raw["platform"]
