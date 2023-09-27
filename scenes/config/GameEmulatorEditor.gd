extends Control

signal change_ocurred

@onready var n_intro_lbl := %IntroLabel
@onready var n_override_emulator := %OverrideEmulator
@onready var n_emulator_options := %EmulatorOptions

var game_data : RetroHubGameData: set = set_game_data

@export var disable_edits := false

func _ready():
	#warning-ignore:return_value_discarded
	RetroHubConfig.game_data_updated.connect(_on_game_data_updated)

	n_emulator_options.get_popup().max_size.y = RetroHubUI.max_popupmenu_height

func _on_game_data_updated(_game_data: RetroHubGameData):
	if game_data == _game_data:
		discard_changes()

func set_game_data(_game_data: RetroHubGameData) -> void:
	game_data = _game_data
	discard_changes()
	if not game_data: return

	update_emulator_options()
	for idx in n_emulator_options.item_count:
		if n_emulator_options.get_item_metadata(idx) == game_data.emulator:
			n_emulator_options.selected = idx
			break

func update_emulator_options() -> void:
	n_emulator_options.clear()

	var system_emulators : Array = RetroHubConfig._systems_raw[game_data.system.name]["emulator"]
	for system_emulator in system_emulators:
		var emu_short_name : String
		if system_emulator is Dictionary:
			emu_short_name = system_emulator.keys()[0]
		else:
			emu_short_name = system_emulator
		if RetroHubConfig.emulators_map.has(emu_short_name):
			var emu_logo := RetroHubGenericEmulator.load_icon(emu_short_name)
			n_emulator_options.add_icon_item(emu_logo, RetroHubConfig.emulators_map[emu_short_name]["fullname"])
		else:
			n_emulator_options.add_item(emu_short_name)
		n_emulator_options.set_item_metadata(n_emulator_options.item_count-1, emu_short_name)

func discard_changes():
	if game_data:
		n_override_emulator.button_pressed = !game_data.emulator.is_empty()
		n_override_emulator.disabled = false
	else:
		n_override_emulator.button_pressed = false
		n_override_emulator.disabled = true
		n_emulator_options.disabled = true
		n_emulator_options.clear()


func save_changes():
	if game_data:
		if n_override_emulator.button_pressed:
			game_data.emulator = n_emulator_options.get_selected_metadata()
		else:
			game_data.emulator = ""

func grab_focus():
	if not game_data: return

	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_intro_lbl.grab_focus()
	else:
		n_override_emulator.grab_focus()
	_on_override_emulator_toggled(n_override_emulator.button_pressed)
	if n_emulator_options.item_count == 0:
		update_emulator_options()

func _on_change_ocurred(_tmp = null):
	emit_signal("change_ocurred")


func _on_override_emulator_toggled(button_pressed):
	n_emulator_options.disabled = !button_pressed
