extends WindowDialog

signal identifier_picked(id)

var keys : Array

onready var n_intro_label = $"%IntroLabel"
onready var n_existing_label = $"%ExistingLabel"

onready var n_line_edit = $"%LineEdit"
onready var n_check_lower = $"%CheckLower"
onready var n_check_special = $"%CheckSpecial"
onready var n_check_existing = $"%CheckExisting"
onready var n_ok = $"%OK"

onready var base_text_intro : String = n_intro_label.text
onready var base_text_existing : String = n_existing_label.text

func start(_keys: Array, data_name: String):
	keys = _keys
	n_intro_label.text = base_text_intro % data_name
	n_existing_label.text = base_text_existing % data_name
	n_line_edit.text = ""
	check_text()
	popup_centered()
	yield(get_tree(), "idle_frame")
	n_line_edit.grab_focus()

func check_text(text: String = n_line_edit.text):
	# If text is empty, exit early
	if text.empty():
		set_check_enabled(n_check_lower, false)
		set_check_enabled(n_check_special, false)
		set_check_enabled(n_check_existing, false)
		n_ok.disabled = true
		return

	var enable_ok := true
	var check : bool
	
	# Lowercase
	check = text.to_lower() == text
	set_check_enabled(n_check_lower, check)
	enable_ok = enable_ok and check
	# Special chars
	var regex := RegEx.new()
	regex.compile("[^a-zA-Z_0-9]+")
	var results = regex.search(text)
	if results:
		check = results.strings.empty()
	else:
		check = true
	set_check_enabled(n_check_special, check)
	enable_ok = enable_ok and check
	# Non existing
	check = not text in keys
	set_check_enabled(n_check_existing, check)
	enable_ok = enable_ok and check

	n_ok.disabled = not enable_ok

func set_check_enabled(node: Control, enabled: bool):
	node.get_child(0).visible = enabled
	node.get_child(1).modulate = Color.white if enabled else Color.gray


func _on_OK_pressed():
	emit_signal("identifier_picked", n_line_edit.text)
	hide()
