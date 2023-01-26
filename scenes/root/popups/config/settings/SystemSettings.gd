extends Control

signal theme_reload()

onready var n_save := $"%Save"
onready var n_discard := $"%Discard"
onready var n_system_selection := $"%SystemSelection"
onready var n_system_editor := $"%SystemEditor"
onready var n_default_opt := $"%DefaultOptions"
onready var n_custom_opt := $"%CustomOptions"
onready var n_restore_system := $"%RestoreSystem"

onready var n_select_extensions_popup := $"%SelectExtensionsPopup"

func _ready():
	n_system_selection.get_popup().max_height = 350
	RetroHubConfig.connect("config_ready", self, "_on_config_ready")
	n_save.disabled = true
	n_discard.disabled = true
	n_default_opt.visible = false
	n_custom_opt.visible = false

func grab_focus():
	n_system_selection.grab_focus()

func _on_config_ready(config_data: ConfigData):
	var idx = 0
	for system in RetroHubConfig._systems_raw.values():
		if not system.has("#custom"):
			n_system_selection.add_item("[%s] %s" % [system["name"], system["fullname"]], idx)
			n_system_selection.set_item_metadata(idx, system)
			idx += 1

func _on_SystemSelection_item_selected(index):
	var data : Dictionary = n_system_selection.get_item_metadata(index)
	discard_changes()
	var is_custom = data.has("#custom")
	n_default_opt.visible = !is_custom
	n_custom_opt.visible = is_custom
	n_restore_system.disabled = not data.has("#modified")
	n_system_editor.curr_system = data


func _on_SystemSettings_visibility_changed():
	if n_system_selection and n_system_editor:
		if visible:
			_on_SystemSelection_item_selected(n_system_selection.selected)
		else:
			n_system_editor.clear_icons()


func _on_SystemEditor_change_ocurred():
	n_save.disabled = false
	n_discard.disabled = false


func save_changes():
	var system_raw : Dictionary = n_system_editor.save()
	RetroHubConfig.save_system(system_raw)
	update_system_selection(system_raw)
	emit_signal("theme_reload")
	n_save.disabled = true
	n_discard.disabled = true
	n_restore_system.disabled = false

func discard_changes():
	n_system_editor.reset()
	n_save.disabled = true
	n_discard.disabled = true


func _on_SelectExtensionsPopup_extensions_picked(extensions):
	n_system_editor.extensions_picked(extensions)


func _on_SystemEditor_request_extensions(system_name, curr_extensions):
	n_select_extensions_popup.start(system_name, curr_extensions)


func _on_RestoreSystem_pressed():
	var default_system = RetroHubConfig.restore_system(n_system_editor.curr_system)
	n_system_editor.curr_system = default_system
	update_system_selection(default_system)
	emit_signal("theme_reload")
	n_save.disabled = true
	n_discard.disabled = true
	n_restore_system.disabled = true

func update_system_selection(system: Dictionary):
	for idx in range(n_system_selection.get_item_count()):
		if n_system_selection.get_item_metadata(idx)["name"] == system["name"]:
			n_system_selection.set_item_text(idx, "[%s] %s" % [system["name"], system["fullname"]])
			n_system_selection.set_item_metadata(idx, system)
			return
