extends Control

signal change_ocurred
signal request_extensions(system_name, curr_extensions)
signal request_add_emulator
signal request_retroarch_config(existing_cores)

var curr_system : Dictionary setget set_curr_system
var emulators : Array
var extensions := []
var emulator_tree_root : TreeItem

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
	emulators = curr_system["emulator"].duplicate(true)
	set_extension_label()

	n_emulators.clear()
	emulator_tree_root = n_emulators.create_item()
	for emulator in emulators:
		add_emulator(emulator)

func add_emulator(emulator):
	var child : TreeItem = n_emulators.create_item(emulator_tree_root)
	child.set_metadata(0, emulator)
	if emulator is Dictionary:
		# RetroArch
		var text : String = get_emulator_name(emulator.keys()[0])
		if emulator.keys()[0] == "retroarch":
			text += " " + get_retroarch_pretty_name(emulator.values()[0])
		child.set_text(0, text)
		child.set_icon(1, preload("res://assets/icons/settings.svg"))
	else:
		child.set_text(0, get_emulator_name(emulator))
		child.set_selectable(1, false)
	child.set_icon(2, preload("res://assets/icons/failure.svg"))

func get_retroarch_pretty_name(cores: Array):
	var text := "["
	for core in cores:
		text += core + ","
	if text.rfind(",") != -1:
		text[text.rfind(",")] = "]"
	else:
		text += "]"
	return text

func get_emulator_name(name: String):
	if RetroHubConfig.emulators_map.has(name):
		return RetroHubConfig.emulators_map[name]["fullname"]
	return name

func save() -> Dictionary:
	curr_system["fullname"] = n_fullname.text
	curr_system["category"] = RetroHubSystemData.idx_to_category(n_category.selected)
	curr_system["extension"] = extensions.duplicate()
	curr_system["emulator"] = emulators.duplicate(true)

	return curr_system

func reset():
	if curr_system:
		set_curr_system(curr_system)

func clear_icons():
	n_photo.icon = null
	n_logo.icon = null

func extensions_picked(_extensions: Array):
	extensions = _extensions
	set_extension_label()
	emit_signal("change_ocurred")

func set_retroarch_cores(cores: Array):
	var core_names := []
	for core in cores:
		core_names.push_back(core["name"])
	var item : TreeItem = emulator_tree_root.get_children()
	while item != null:
		var core_def = item.get_metadata(0)
		if core_def is Dictionary and core_def.keys()[0] == "retroarch":
			emit_signal("change_ocurred")
			core_def["retroarch"] = core_names
			item.set_text(0, get_emulator_name("retroarch") + " " + get_retroarch_pretty_name(core_names))
			return
		item = item.get_next()

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


func _on_Emulators_item_activated():
	var selected : TreeItem = n_emulators.get_selected()
	var emulator = selected.get_metadata(0)
	match n_emulators.get_selected_column():
		1: # Emulator config
			match emulator.keys()[0]:
				"retroarch":
					emit_signal("request_retroarch_config", emulator.values()[0])
		2: # Delete
			emulators.erase(emulator)
			selected.free()
			emit_signal("change_ocurred")


func _on_AddEmulator_pressed():
	emit_signal("request_add_emulator")
