extends AcceptDialog

signal key_remapped(key, old_code, new_code)

onready var n_key_icon := $"%KeyIcon"
onready var n_key_label := $"%KeyLabel"

onready var base_text : String = n_key_label.text

var key := ""
var oldcode := 0
var scancode := 0

func start(key: String):
	self.key = key
	self.scancode = 0
	self.oldcode = find_old_keycode(key)
	n_key_label.text = base_text
	popup_centered()

func _input(event):
	if visible and event is InputEventKey:
		get_tree().set_input_as_handled()
		scancode = (event as InputEventKey).physical_scancode
		# TODO: change controller icons to support key_icon
		n_key_label.text = OS.get_scancode_string(scancode)

func find_old_keycode(key: String):
	for ev in InputMap.get_action_list(key):
		if ev is InputEventKey:
			return ev.physical_scancode if ev.scancode == 0 else ev.scancode
	return 0

func _on_KeyboardRemap_confirmed():
	if scancode != 0:
		emit_signal("key_remapped", key, oldcode, scancode)

