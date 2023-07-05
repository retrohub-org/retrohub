extends Window

signal identifier_picked(id)

@onready var n_intro_lbl := %IntroLabel

@onready var n_options := %Options
@onready var n_ok := %OK

@onready var base_text_intro : String = n_intro_lbl.text

func _ready():
	n_options.get_popup().max_size.y = RetroHubUI.max_popupmenu_height

func start(data: Dictionary, existing: Array, asset_format: String, data_name: String):
	n_intro_lbl.text = base_text_intro % data_name
	populate_options(data.values(), existing, asset_format)
	popup_centered()
	await get_tree().process_frame
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_intro_lbl.grab_focus()
	else:
		n_options.grab_focus()

func populate_options(datas: Array, existing_keys: Array, asset_format: String):
	for data in datas:
		var shortname : String = data["name"]
		if shortname in existing_keys or check_complex(shortname, existing_keys):
			continue
		var fullname : String = data["fullname"]
		var asset_name := asset_format % shortname
		n_options.add_icon_item(load(asset_name), fullname)
		n_options.set_item_metadata(n_options.get_item_count()-1, shortname)
	if n_options.get_item_count() == 0:
		n_options.add_item("No emulators left to add")
		n_options.set_item_disabled(0, true)
		n_options.set_item_metadata(0, "")

func check_complex(shortname: String, data: Array):
	for child in data:
		if child is Dictionary and child.has(shortname):
			return true
	return false

func _on_OK_pressed():
	var metadata : String = n_options.get_selected_metadata()
	if not metadata.is_empty():
		emit_signal("identifier_picked", n_options.get_selected_metadata())
	hide()


func _on_AddExistingInfoPopup_popup_hide():
	n_options.clear()
