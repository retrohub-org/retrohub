extends Control

signal change_ocurred()
signal request_extensions(system_name, curr_extensions)
signal request_add_emulator()
signal request_edit_emulator()

var curr_system : Dictionary setget set_curr_system
var extensions := []

onready var n_photo := $"%Photo"
onready var n_logo := $"%Logo"
onready var n_name := $"%Identifier"
onready var n_fullname := $"%Name"
onready var n_category := $"%Category"
onready var n_emulators := $"%Emulators"
onready var n_extensions := $"%Extensions"

onready var n_change_extensions := $"%ChangeExtensions"
onready var n_add_emulator := $"%AddEmulator"

func _ready():
	n_emulators.set_column_expand(0, true)
	n_emulators.set_column_expand(1, false)
	n_emulators.set_column_expand(2, false)
	n_emulators.set_column_min_width(1, 48)
	n_emulators.set_column_min_width(2, 48)

func set_curr_system(_curr_system: Dictionary):
	curr_system = _curr_system
	n_photo.icon = load("res://assets/systems/%s-photo.png" % curr_system["name"])
	n_logo.icon = load("res://assets/systems/%s-logo.png" % curr_system["name"])
	n_photo.text = "<click to add>" if not n_photo.icon else ""
	n_logo.text = "<click to add>" if not n_logo.icon else ""
	n_name.text = curr_system["name"]
	n_fullname.text = curr_system["fullname"]
	n_category.selected = RetroHubSystemData.category_to_idx(curr_system["category"])
	extensions = curr_system["extension"].duplicate()
	set_extension_label()
	
	n_emulators.clear()
	var root = n_emulators.create_item()
	for emulator in curr_system["emulator"]:
		var child = n_emulators.create_item(root)
		if emulator is Dictionary:
			# RetroArch
			var text : String = get_emulator_name(emulator.keys()[0]) + " ["
			for core in emulator.values()[0]:
				text += core + ","
			text[text.rfind(",")] = "]"
			child.set_text(0, text)
			child.add_button(1, preload("res://assets/icons/load.svg"))
		else:
			child.set_text(0, get_emulator_name(emulator))
		child.add_button(2, preload("res://assets/icons/failure.svg"))

func get_emulator_name(name: String):
	if RetroHubConfig.emulators_map.has(name):
		return RetroHubConfig.emulators_map[name]["fullname"]
	return name

func save() -> Dictionary:
	curr_system["fullname"] = n_fullname.text
	curr_system["category"] = RetroHubSystemData.idx_to_category(n_category.selected)
	curr_system["extension"] = extensions.duplicate()

	return curr_system

func reset():
	if curr_system:
		set_curr_system(curr_system)

func clear_icons():
	n_photo.icon = null
	n_logo.icon = null

func extensions_picked(extensions: Array):
	self.extensions = extensions
	set_extension_label()
	emit_signal("change_ocurred")

func _on_item_change(__):
	emit_signal("change_ocurred")

func set_extension_label():
	n_extensions.text = str(extensions.size())
	if extensions.size() > 0:
		n_extensions.text += " (" + extensions[0]
		for i in range(1, extensions.size()):
			n_extensions.text += " " + extensions[i]
		n_extensions.text += ")"

func _on_ChangeExtensions_pressed():
	emit_signal("request_extensions", curr_system["name"], extensions)


func _on_Emulators_button_pressed(item: TreeItem, column, id):
	pass
