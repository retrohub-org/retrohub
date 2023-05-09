extends Popup

signal extensions_picked(extensions)

@onready var n_intro_lbl = $"%IntroLabel"
@onready var n_new_extensions := $"%NewExtensions"
@onready var n_ext_line_edit := $"%ExtLineEdit"
@onready var n_add_extension := $"%AddExtension"
@onready var n_curr_extensions := $"%CurrExtensions"

@onready var n_ok := $"%OK"

var extensions := []

func start(system_name: String, _extensions: Array):
	reset()
	extensions = _extensions

	# Add current extensions
	for ext in _extensions:
		create_curr_extension_button(ext)

	# Add new extensions
	var game_path : String = RetroHubConfig.config.games_dir + "/" + system_name
	var dir := DirAccess.open(game_path)
	if dir:
		#warning-ignore:return_value_discarded
		dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var curr_extensions := []
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var ext : String = "." + file_name.get_extension()
				if not ext in curr_extensions:
					curr_extensions.push_back(ext)
					var btn := create_new_extension_button(ext)
					btn.disabled = ext in extensions
			file_name = dir.get_next()

	popup_centered()
	await get_tree().process_frame
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_intro_lbl.grab_focus()
	else:
		if n_new_extensions.get_child_count():
			n_new_extensions.get_child(0).grab_focus()
		else:
			n_ext_line_edit.grab_focus()

func reset():
	for child in n_new_extensions.get_children():
		n_new_extensions.remove_child(child)
		child.queue_free()

	for child in n_curr_extensions.get_children():
		n_curr_extensions.remove_child(child)
		child.queue_free()

	n_ext_line_edit.text = ""
	n_add_extension.disabled = true

func create_curr_extension_button(name: String):
	var btn := Button.new()
	btn.text = name
	#warning-ignore:return_value_discarded
	btn.connect("pressed", Callable(self, "_on_curr_button_pressed").bind(btn, n_curr_extensions.get_child_count()))
	n_curr_extensions.add_child(btn)

	for child in n_new_extensions.get_children():
		if child.text == name:
			child.disabled = true

func create_new_extension_button(name: String) -> Button:
	var btn := Button.new()
	btn.text = name
	#warning-ignore:return_value_discarded
	btn.connect("pressed", Callable(self, "_on_new_button_pressed").bind(btn))
	n_new_extensions.add_child(btn)
	return btn

func _on_ExtLineEdit_text_changed(new_text: String):
	n_add_extension.disabled = new_text.is_empty()

func _on_curr_button_pressed(btn: Button, idx: int):
	var ext := btn.text
	extensions.erase(ext)
	n_curr_extensions.remove_child(btn)
	if n_curr_extensions.get_child_count() > idx:
		n_curr_extensions.get_child(idx).grab_focus()
	elif n_curr_extensions.get_child_count() > 0:
		n_curr_extensions.get_child(n_curr_extensions.get_child_count()-1).grab_focus()
	else:
		n_add_extension.grab_focus()

	btn.queue_free()
	for child in n_new_extensions.get_children():
		if child.text == ext:
			child.disabled = false

func _on_new_button_pressed(btn: Button):
	var ext := btn.text
	extensions.push_back(ext)
	create_curr_extension_button(ext)


func _on_AddExtension_pressed(__ = null):
	var ext : String = "." + n_ext_line_edit.text.to_lower().lstrip(".")
	n_ext_line_edit.text = ""
	if not ext in extensions:
		extensions.push_back(ext)
		create_curr_extension_button(ext)
	n_add_extension.disabled = true

func _on_OK_pressed():
	hide()
	emit_signal("extensions_picked", extensions.duplicate())
	extensions.clear()
