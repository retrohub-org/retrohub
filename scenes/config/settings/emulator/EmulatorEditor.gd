extends Control

signal change_ocurred

var curr_emulator : Dictionary setget set_curr_emulator

onready var n_logo := $"%Logo"
onready var n_name := $"%Identifier"
onready var n_fullname := $"%Name"
onready var n_path := $"%Path"
onready var n_command := $"%Command"

func focus_node_from_top():
	n_logo.grab_focus()

func focus_node_from_bottom():
	$HFlowContainer/HBoxContainer/VarButton.grab_focus()

func set_curr_emulator(_curr_emulator: Dictionary):
	curr_emulator = _curr_emulator
	n_logo.icon = load("res://assets/emulators/%s.png" % curr_emulator["name"])
	n_logo.text = "<click to add>" if not n_logo.icon else ""
	n_name.text = curr_emulator["name"]
	n_fullname.text = curr_emulator["fullname"]
	n_path.text = RetroHubGenericEmulator.find_and_substitute_str(curr_emulator["binpath"], {})
	n_command.text = curr_emulator["command"]

func save() -> Dictionary:
	curr_emulator["fullname"] = n_fullname.text
	curr_emulator["binpath"] = n_path.text
	curr_emulator["command"] = n_command.text

	return curr_emulator

func reset():
	if curr_emulator:
		set_curr_emulator(curr_emulator)

func clear_icons():
	n_logo.icon = null

func _on_item_change(__):
	emit_signal("change_ocurred")

func _on_VarButton_pressed(variable: String):
	emit_signal("change_ocurred")
	var curr_pos : int = n_command.caret_position
	n_command.text = n_command.text.substr(0, curr_pos) + variable + n_command.text.substr(curr_pos)
	n_command.caret_position = curr_pos + variable.length()


func _on_LoadPath_pressed():
	match FileUtils.get_os_id():
		FileUtils.OS_ID.WINDOWS:
			RetroHubUI.filesystem_filters(["*.exe ; Executable Files"])
			RetroHubUI.request_file_load("C://")
		_:
			RetroHubUI.filesystem_filters([])
			RetroHubUI.request_file_load("/bin")
	var path : String = yield(RetroHubUI, "path_selected")
	if not path.empty():
		n_path.text = path
		emit_signal("change_ocurred")
