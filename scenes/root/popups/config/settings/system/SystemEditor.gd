extends Control

var curr_system : Dictionary setget set_curr_system

onready var n_photo := $"%Photo"
onready var n_logo := $"%Logo"
onready var n_name := $"%Identifier"
onready var n_fullname := $"%Name"
onready var n_category := $"%Category"
onready var n_emulators := $"%Emulators"

onready var n_add_emulator := $"%AddEmulator"
onready var n_edit_emulator := $"%EditEmulator"
onready var n_remove_emulator := $"%RemoveEmulator"

func set_curr_system(_curr_system: Dictionary):
	curr_system = _curr_system
	n_photo.icon = load("res://assets/systems/%s-photo.png" % curr_system["name"])
	n_logo.icon = load("res://assets/systems/%s-logo.png" % curr_system["name"])
	n_photo.text = "<click to add>" if not n_photo.icon else ""
	n_logo.text = "<click to add>" if not n_logo.icon else ""
	n_name.text = curr_system["name"]
	n_fullname.text = curr_system["fullname"]
	n_category.selected = RetroHubConfig.convert_system_category(curr_system["category"])
	
	n_emulators.clear()
	var root = n_emulators.create_item()
	for emulator in curr_system["emulator"]:
		var child = n_emulators.create_item(root)
		if emulator is Dictionary:
			# RetroArch
			var text : String = emulator.keys()[0] + " ["
			for core in emulator.values()[0]:
				text += core + ","
			text[text.rfind(",")] = "]"
			child.set_text(0, text)
		else:
			child.set_text(0, emulator)

func clear_icons():
	n_photo.icon = null
	n_logo.icon = null
