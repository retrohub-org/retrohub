extends HBoxContainer

onready var n_logo := $"%Logo"
onready var n_name := $"%Name"
onready var n_path_section := $"%PathSection"

func set_name(name: String):
	n_name.text = name

func set_logo(texture: Texture):
	n_logo.texture = texture

func set_found(found: bool, details: String):
	n_path_section.set_found(found, details)
	modulate.a = 1.0 if found else 0.5

