extends Control

signal theme_reload()

onready var n_save := $"%Save"
onready var n_discard := $"%Discard"
onready var n_emulator_selection := $"%EmulatorSelection"
onready var n_emulator_editor := $"%EmulatorEditor"
onready var n_default_opt := $"%DefaultOptions"
onready var n_custom_opt := $"%CustomOptions"
onready var n_restore_emulator := $"%RestoreEmulator"

func _ready():
	n_emulator_selection.get_popup().max_height = 350
	RetroHubConfig.connect("config_ready", self, "_on_config_ready")
	n_save.disabled = true
	n_discard.disabled = true
	n_default_opt.visible = false
	n_custom_opt.visible = false

func grab_focus():
	n_emulator_selection.grab_focus()

func _on_config_ready(config_data: ConfigData):
	var idx = 0
	for emulator in RetroHubConfig.emulators_map.values():
		if not emulator.has("#custom"):
			n_emulator_selection.add_item("[%s] %s" % [emulator["name"], emulator["fullname"]], idx)
			n_emulator_selection.set_item_metadata(idx, emulator)
			idx += 1

func _on_EmulatorSelection_item_selected(index):
	var data : Dictionary = n_emulator_selection.get_item_metadata(index)
	discard_changes()
	var is_custom = data.has("#custom")
	n_default_opt.visible = !is_custom
	n_custom_opt.visible = is_custom
	n_restore_emulator.disabled = not data.has("#modified")
	n_emulator_editor.curr_emulator = data


func _on_EmulatorSettings_visibility_changed():
	if n_emulator_selection and n_emulator_editor:
		if visible:
			_on_EmulatorSelection_item_selected(n_emulator_selection.selected)
		else:
			n_emulator_editor.clear_icons()


func _on_EmulatorEditor_change_ocurred():
	n_save.disabled = false
	n_discard.disabled = false


func save_changes():
	var emulator_raw : Dictionary = n_emulator_editor.save()
	RetroHubConfig.save_emulator(emulator_raw)
	update_emulator_selection(emulator_raw)
	emit_signal("theme_reload")
	n_save.disabled = true
	n_discard.disabled = true
	n_restore_emulator.disabled = false

func discard_changes():
	n_emulator_editor.reset()
	n_save.disabled = true
	n_discard.disabled = true


func _on_RestoreEmulator_pressed():
	var default_emulator = RetroHubConfig.restore_emulator(n_emulator_editor.curr_emulator)
	n_emulator_editor.curr_emulator = default_emulator
	update_emulator_selection(default_emulator)
	emit_signal("theme_reload")
	n_save.disabled = true
	n_discard.disabled = true
	n_restore_emulator.disabled = true

func update_emulator_selection(emulator: Dictionary):
	for idx in range(n_emulator_selection.get_item_count()):
		if n_emulator_selection.get_item_metadata(idx)["name"] == emulator["name"]:
			n_emulator_selection.set_item_text(idx, "[%s] %s" % [emulator["name"], emulator["fullname"]])
			n_emulator_selection.set_item_metadata(idx, emulator)
			return
