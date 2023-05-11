extends Control

signal change_ocurred
signal request_add_core

var curr_emulator : Dictionary: set = set_curr_emulator
var cores : Array

@onready var n_logo := $"%Logo"
@onready var n_name := $"%Identifier"
@onready var n_fullname := $"%Name"
@onready var n_path := $"%Path3D"
@onready var n_core_path := $"%CorePath"
@onready var n_command := $"%Command"

@onready var n_core_option := $"%CoreOption"
@onready var n_remove_core := $"%RemoveCore"
@onready var n_add_core := $"%AddCore"
@onready var n_core_identifier := $"%CoreIdentifier"
@onready var n_core_name := $"%CoreName"
@onready var n_core_file_name := $"%CoreFileName"

func focus_node_from_top():
	n_logo.grab_focus()

func focus_node_from_bottom():
	n_core_file_name.grab_focus()

func _ready():
	n_core_option.get_popup().max_size.y = RetroHubUI.max_popupmenu_height

func set_curr_emulator(_curr_emulator: Dictionary):
	curr_emulator = _curr_emulator
	n_logo.icon = load("res://assets/emulators/%s.png" % curr_emulator["name"])
	n_logo.text = "<click to add>" if not n_logo.icon else ""
	n_name.text = curr_emulator["name"]
	n_fullname.text = curr_emulator["fullname"]
	n_path.text = RetroHubGenericEmulator.find_and_substitute_str(curr_emulator["binpath"], {})
	n_core_path.text = RetroHubRetroArchEmulator.get_custom_core_path()
	if n_core_path.text.is_empty():
		n_core_path.text = RetroHubGenericEmulator.find_and_substitute_str(
				curr_emulator["corepath"],
				{"binpath": n_path.text}
		)
	n_command.text = curr_emulator["command"]

	n_core_option.clear()
	cores = curr_emulator["cores"].duplicate(true)
	for core in cores:
		var text : String = "<%s>" % core["name"] if core["fullname"].is_empty() else core["fullname"]
		n_core_option.add_item(text)
		n_core_option.set_item_metadata(n_core_option.get_item_count()-1, core)
	n_remove_core.disabled = n_core_option.get_item_count() == 0
	if n_core_option.get_item_count() > 0:
		_on_CoreOption_item_selected(n_core_option.selected)

func save() -> Dictionary:
	curr_emulator["fullname"] = n_fullname.text
	curr_emulator["binpath"] = n_path.text
	curr_emulator["corepath"] = n_core_path.text
	curr_emulator["command"] = n_command.text

	var core : Dictionary = n_core_option.get_selected_metadata()
	if core:
		core["fullname"] = n_core_name.text
		core["file"] = n_core_file_name.text
		var text : String = "<%s>" % n_core_identifier.text if n_core_name.text.is_empty() else n_core_name.text
		n_core_option.set_item_text(n_core_option.selected, text)

	curr_emulator["cores"] = cores.duplicate(true)

	return curr_emulator

func reset():
	if curr_emulator:
		set_curr_emulator(curr_emulator)

func clear_icons():
	n_logo.icon = null

func add_core(core: Dictionary):
	cores.push_back(core)
	n_core_option.add_item("<%s>" % core["name"])
	n_core_option.set_item_metadata(n_core_option.get_item_count()-1, core)
	n_core_option.selected = n_core_option.get_item_count()-1
	_on_CoreOption_item_selected(n_core_option.selected)

func _on_item_change(__):
	emit_signal("change_ocurred")

func _on_VarButton_pressed(variable: String):
	emit_signal("change_ocurred")
	var curr_pos : int = n_command.caret_column
	n_command.text = n_command.text.substr(0, curr_pos) + variable + n_command.text.substr(curr_pos)
	n_command.caret_column = curr_pos + variable.length()


func _on_LoadPath_pressed():
	match FileUtils.get_os_id():
		FileUtils.OS_ID.WINDOWS:
			RetroHubUI.filesystem_filters(["*.exe ; Executable Files"])
			RetroHubUI.request_file_load("C://")
		_:
			RetroHubUI.filesystem_filters([])
			RetroHubUI.request_file_load("/bin")
	var path : String = await RetroHubUI.path_selected
	if not path.is_empty():
		n_path.text = path
		emit_signal("change_ocurred")


func _on_LoadCorePath_pressed():
	RetroHubUI.filesystem_filters([])
	RetroHubUI.request_folder_load(n_path.text)
	var path : String = await RetroHubUI.path_selected
	if not path.is_empty():
		n_core_path.text = path
		emit_signal("change_ocurred")


func _on_CoreOption_item_selected(index):
	var core : Dictionary = n_core_option.get_item_metadata(index)
	n_core_identifier.text = core["name"]
	n_core_name.text = core["fullname"]
	n_core_file_name.text = core["file"]


func _on_LoadCoreFileName_pressed():
	match FileUtils.get_os_id():
		FileUtils.OS_ID.WINDOWS:
			RetroHubUI.filesystem_filters(["*.dll ; DLL libretro Cores"])
		FileUtils.OS_ID.MACOS:
			RetroHubUI.filesystem_filters(["*.dylib ; DYLIB libretro Cores"])
		FileUtils.OS_ID.LINUX:
			RetroHubUI.filesystem_filters(["*.so ; SO libretro Cores"])
	RetroHubUI.request_file_load(n_core_path.text)
	var path : String = await RetroHubUI.path_selected
	if not path.is_empty():
		n_core_file_name.text = path.get_file()
		emit_signal("change_ocurred")


func _on_RemoveCore_pressed():
	emit_signal("change_ocurred")
	var core : Dictionary = n_core_option.get_selected_metadata()
	cores.erase(core)
	var idx : int = n_core_option.selected
	n_core_option.remove_item(idx)
	idx -= 1
	if idx < 0 and n_core_option.get_item_count() > 0:
		idx = 0
	n_core_option.selected = idx
	n_remove_core.disabled = n_core_option.get_item_count() == 0
	if idx >= 0:
		_on_CoreOption_item_selected(idx)
	else:
		n_core_identifier.text = ""
		n_core_name.text = ""
		n_core_file_name.text = ""


func _on_AddCore_pressed():
	emit_signal("request_add_core")
