extends Control

signal theme_reload

@onready var n_save := $"%Save"
@onready var n_discard := $"%Discard"
@onready var n_system_selection := $"%SystemSelection"
@onready var n_system_editor := $"%SystemEditor"
@onready var n_default_opt := $"%DefaultOptions"
@onready var n_custom_opt := $"%CustomOptions"
@onready var n_restore_system := $"%RestoreSystem"

@onready var n_select_extensions_popup := $"%SelectExtensionsPopup"
@onready var n_add_custom_info_popup := $"%AddCustomInfoPopup"
@onready var n_add_existing_info_popup := $"%AddExistingInfoPopup"
@onready var n_retro_arch_config := $"%RetroArchConfig"

var sep_idx := -1

func _ready():
	n_system_selection.get_popup().max_height = RetroHubUI.max_popupmenu_height + 50
	#warning-ignore:return_value_discarded
	RetroHubConfig.connect("config_ready", Callable(self, "_on_config_ready"))
	n_save.disabled = true
	n_discard.disabled = true
	n_default_opt.visible = false
	n_custom_opt.visible = false

func grab_focus():
	n_system_selection.grab_focus()

func _on_config_ready(_config_data: ConfigData):
	var idx := 0
	var found_custom := false
	for system in RetroHubConfig._systems_raw.values():
		if not found_custom and system.has("#custom"):
			found_custom = true
			n_system_selection.add_separator()
			sep_idx = idx
			idx += 1
		n_system_selection.add_item("[%s] %s" % [system["name"], system["fullname"]], idx)
		n_system_selection.set_item_metadata(idx, system)
		idx += 1
	if sep_idx == -1:
		sep_idx = n_system_selection.get_item_count()
		n_system_selection.add_separator()

func _on_SystemSelection_item_selected(index):
	if index == -1:
		return
	var data : Dictionary = n_system_selection.get_item_metadata(index)
	discard_changes()
	var is_custom := data.has("#custom")
	n_default_opt.visible = !is_custom
	n_custom_opt.visible = is_custom
	n_restore_system.disabled = not data.has("#modified")
	n_system_editor.curr_system = data


func _on_SystemSettings_visibility_changed():
	if n_system_selection and n_system_editor:
		if is_visible_in_tree():
			_on_SystemSelection_item_selected(n_system_selection.selected)
		else:
			n_system_editor.clear_icons()


func _on_SystemEditor_change_ocurred():
	n_save.disabled = false
	n_discard.disabled = false


func save_changes():
	var system_raw : Dictionary = n_system_editor.save()
	system_raw["#modified"] = true
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
	n_select_extensions_popup.start(Callable(system_name, curr_extensions))


func _on_RestoreSystem_pressed():
	var default_system : Dictionary = RetroHubConfig.restore_system(n_system_editor.curr_system)
	n_system_editor.curr_system = default_system
	update_system_selection(default_system)
	emit_signal("theme_reload")
	n_save.disabled = true
	n_discard.disabled = true
	n_restore_system.disabled = true

func update_system_selection(system: Dictionary):
	for idx in range(n_system_selection.get_item_count()):
		if idx == sep_idx:
			continue
		if n_system_selection.get_item_metadata(idx)["name"] == system["name"]:
			n_system_selection.set_item_text(idx, "[%s] %s" % [system["name"], system["fullname"]])
			n_system_selection.set_item_metadata(idx, system)
			return


func _on_AddCustomInfoPopup_identifier_picked(id):
	var system := {
		"name": id,
		"platform": id,
		"fullname": "",
		"extension": [],
		"emulator": [],
		"category": RetroHubSystemData.idx_to_category(0),
		"#custom": true,
	}

	RetroHubConfig._systems_raw[id] = system
	RetroHubConfig.save_system(system)

	var idx : int = n_system_selection.get_item_count()
	n_system_selection.add_item("[%s] %s" % [system["name"], system["fullname"]], idx)
	n_system_selection.set_item_metadata(idx, system)
	n_system_selection.select(idx)
	_on_SystemSelection_item_selected(idx)


func _on_AddSystem_pressed():
	n_add_custom_info_popup.start(RetroHubConfig._systems_raw.keys(), "system")


func _on_RemoveSystem_pressed():
	var system_raw : Dictionary = n_system_editor.curr_system
	RetroHubConfig.remove_custom_system(system_raw)

	for idx in n_system_selection.get_item_count():
		if idx == sep_idx:
			continue
		if n_system_selection.get_item_metadata(idx) == system_raw:
			n_system_selection.remove_item(idx)
			idx -= 1
			if idx == sep_idx:
				idx -= 1
			n_system_selection.select(idx)
			_on_SystemSelection_item_selected(idx)
	if not n_restore_system.visible:
		n_restore_system.grab_focus()


func _on_SystemEditor_request_add_emulator():
	n_add_existing_info_popup.start(RetroHubConfig.emulators_map, n_system_editor.curr_system["emulator"], "res://assets/emulators/%s.png","emulator")


func _on_AddExistingInfoPopup_identifier_picked(emulator_name: String):
	var added_info
	if emulator_name == "retroarch":
		added_info = {"retroarch": []}
	else:
		added_info = emulator_name
	n_system_editor.emulators.append(added_info)
	n_system_editor.add_emulator(added_info)
	_on_SystemEditor_change_ocurred()


func _on_SystemEditor_request_retroarch_config(existing_cores: Array):
	var retroarch_config : Dictionary = RetroHubConfig.emulators_map["retroarch"]
	var cores := []
	for name in existing_cores:
		for core in retroarch_config["cores"]:
			if core["name"] == name:
				cores.push_back(core)
				break
	n_retro_arch_config.start(retroarch_config["cores"], cores)


func _on_RetroArchConfig_cores_picked(cores):
	n_system_editor.set_retroarch_cores(cores)
