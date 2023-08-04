extends Control

signal advance_section

@onready var n_intro_lbl := %IntroLabel
@onready var n_import_options := %ImportOptions
@onready var n_compatibility_details := %CompatibilityDetails
@onready var n_next_btn := %NextButton


@onready var n_copy_move_popup := %CopyMovePopup

@onready var importers := [
	EmulationStationImporter.new(),
	RetroArchImporter.new()
]

var thread := Thread.new()
var importer_support := []

func _ready():
	n_import_options.get_popup().max_size.y = RetroHubUI.max_popupmenu_height

func grab_focus():
	# Importers need emulator info already
	RetroHubConfig.load_emulators()
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_intro_lbl.grab_focus()
	else:
		n_import_options.grab_focus()
	query_importers()

func query_importers():
	n_import_options.clear()
	n_import_options.add_item("Searching for available platforms...")
	n_import_options.disabled = true
	n_compatibility_details.visible = false

	if thread.start(Callable(self, "t_query_importers")):
		push_error("Thread start failed [t_query_importers]")

func t_query_importers():
	for importer in importers:
		importer_support.push_back(importer.is_available())
	call_deferred("thread_finished")

func thread_finished():
	thread.wait_to_finish()
	set_importer_buttons()

func set_importer_buttons():
	n_import_options.clear()
	var not_found := true
	var idx := 0
	for support in importer_support:
		if support:
			not_found = false
			var importer : RetroHubImporter = importers[idx]
			n_import_options.add_icon_item(importer.get_icon(), importer.get_importer_name(), idx)
		idx += 1

	n_import_options.disabled = not_found
	if not_found:
		n_import_options.add_item("No systems found")
	else:
		n_import_options.add_item("Don't import settings", idx + 1)
		n_import_options.emit_signal("item_selected", n_import_options.selected)

func _on_ImportOptions_item_selected(_index):
	var importer := get_importer_selected()
	if importer:
		n_compatibility_details.visible = true
		n_compatibility_details.set_importer_status(importer)
	else:
		n_compatibility_details.visible = false

func get_importer_selected() -> RetroHubImporter:
	if true in importer_support and n_import_options.get_selected_id() < importer_support.size():
		return importers[n_import_options.get_selected_id()]
	else:
		return null

func _on_NextButton_pressed():
	var importer := get_importer_selected()
	if importer:
		n_copy_move_popup.set_importer(importer)
		n_copy_move_popup.popup_centered()
	else:
		emit_signal("advance_section")

func _on_ImportProgressPopup_import_finished():
	emit_signal("advance_section")


func _on_CopyMovePopup_popup_hide():
	n_next_btn.grab_focus()
