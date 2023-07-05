extends Window

signal identifier_picked(id)

var keys : Array

@onready var n_intro_lbl := %IntroLabel
@onready var n_existing_label := %ExistingLabel

@onready var n_line_edit := %LineEdit
@onready var n_check_lower := %CheckLower
@onready var n_check_special := %CheckSpecial
@onready var n_check_existing := %CheckExisting
@onready var n_ok := %OK

@onready var base_text_intro : String = n_intro_lbl.text
@onready var base_text_existing : String = n_existing_label.text

func start(_keys: Array, data_name: String):
	keys = _keys
	n_intro_lbl.text = base_text_intro % data_name
	n_existing_label.text = base_text_existing % data_name
	n_line_edit.text = ""
	check_text()
	popup_centered()
	await get_tree().process_frame
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_intro_lbl.grab_focus()
	else:
		n_line_edit.grab_focus()

func check_text(text: String = n_line_edit.text):
	# If text is empty, exit early
	if text.is_empty():
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
	if regex.compile("[^a-zA-Z_0-9]+"):
		push_error("Internal error compiling regex")
	var results := regex.search(text)
	if results:
		check = results.strings.is_empty()
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
	node.get_child(1).modulate = Color.WHITE if enabled else Color.GRAY


func _on_OK_pressed():
	emit_signal("identifier_picked", n_line_edit.text)
	hide()


func _on_LineEdit_text_entered(new_text):
	if not n_ok.disabled:
		_on_OK_pressed()

func tts_text(focused: Control):
	if focused == n_ok:
		if n_ok.disabled:
			var text = "The chosen identifier is not valid. The following checks have failed: "
			for node in [n_check_lower, n_check_special, n_check_existing]:
				if not node.get_child(0).visible:
					text += node.get_child(1).text + ". "
			return text
	return ""
