extends HBoxContainer

onready var n_logo := $"%Logo"
onready var n_name := $"%Name"
onready var n_path_section := $"%PathSection"
onready var n_core_section := $"%CoreSection"

func set_path_found(found: bool, details: String):
	n_path_section.set_found(found, details)
	modulate.a = 1.0 if found else 0.5
	n_core_section.visible = found

func set_core_found(found: bool, details: String):
	n_core_section.set_found(found, details)
	modulate.a = 1.0 if found else 0.5
