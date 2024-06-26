extends Control

signal advance_section

@onready var n_intro_lbl := %IntroLabel
@onready var n_systems := %Systems
@onready var n_emulator_info_tab := %EmulatorInfoTab

var icon_cache := {}

func _ready():
	n_systems.get_popup().max_size.y = RetroHubUI.max_popupmenu_height + 50

func grab_focus():
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_intro_lbl.grab_focus()
	else:
		n_systems.grab_focus()
	set_systems()

var sorted_systems := []

func _sort_by_fullname(a: Dictionary, b: Dictionary):
	return a["fullname"].naturalnocasecmp_to(b["fullname"]) == -1

func set_systems():
	n_systems.clear()
	clear_emulator_info()
	
	sorted_systems = RetroHubConfig._systems_raw.values().duplicate()
	sorted_systems.sort_custom(Callable(self, "_sort_by_fullname"))

	for system in sorted_systems:
		var found := handle_emulator_info(system)
		if found:
			n_systems.add_icon_item(preload("res://assets/icons/success.svg"), system["fullname"])
			n_systems.set_item_metadata(n_systems.get_item_count()-1, true)
		else:
			n_systems.add_icon_item(preload("res://assets/icons/failure.svg"), system["fullname"])
			n_systems.set_item_metadata(n_systems.get_item_count()-1, false)

func handle_emulator_info(system_raw: Dictionary) -> bool:
	var system_emulators : Array = system_raw["emulator"]
	var emulators := RetroHubConfig.emulators_map
	var found := false
	var parent := create_emulator_info_node()
	for system_emulator in system_emulators:
		if system_emulator is Dictionary and system_emulator.has("retroarch"):
			var retroarch_info := preload("res://scenes/popups/first_time/RetroArchEmulatorInfo.tscn").instantiate()
			var emulator : Dictionary = emulators["retroarch"]
			parent.add_child(retroarch_info)

			# Test for binpath first
			var binpath := RetroHubRetroArchEmulator.find_path(emulator, "binpath", {})
			if not binpath.is_empty():
				retroarch_info.set_path_found(true, binpath)
				# Then test for cores
				var required_cores : Array = system_emulator["retroarch"]
				var corespath := RetroHubRetroArchEmulator.get_custom_core_path()
				if corespath.is_empty():
					corespath = JSONUtils.format_string_with_substitutes(FileUtils.test_for_valid_path(emulator["corepath"]) , {"binpath": binpath})
				if corespath.is_empty():
					retroarch_info.set_core_found(false, "Could not find any cores inside:\n" + convert_list_to_string(emulator["corepath"]))
					continue
				var cores : Array = emulator["cores"]
				var avail_cores := []
				for req_core in required_cores:
					for core in cores:
						if core["name"] == req_core:
							avail_cores.push_back(core)
				if avail_cores.is_empty():
					retroarch_info.set_core_found(false, "No default config for cores:\n" + convert_list_to_string(required_cores))
					continue
				var corepaths := []
				var corepath := ""
				for core in avail_cores:
					corepath = RetroHubRetroArchEmulator.find_core_path(core["name"], emulator, corespath)
					if not corepath.is_empty():
						break
					corepaths.push_back(corespath.path_join(core["file"]))
				if not corepath.is_empty():
					for core in avail_cores:
						if core["file"] == corepath.get_file():
							retroarch_info.set_core_found(true, "%s (%s)" % [core["fullname"] ,corepath])
					found = true
				else:
					retroarch_info.set_core_found(false, convert_list_to_string(corepaths))
					continue
			else:
				retroarch_info.set_path_found(false, convert_list_to_string(emulator["binpath"]))
				continue

		elif emulators.has(system_emulator):
			# Generic emulator
			var generic_info := preload("res://scenes/popups/first_time/GenericEmulatorInfo.tscn").instantiate()
			var emulator : Dictionary = emulators[system_emulator]
			parent.add_child(generic_info)

			generic_info.set_emu_name(emulator["fullname"])
			if not icon_cache.has(system_emulator):
				icon_cache[system_emulator] = RetroHubGenericEmulator.load_icon(system_emulator)
			generic_info.set_logo(icon_cache[system_emulator])

			# Test for binpath first
			var binpath := RetroHubGenericEmulator.find_path(emulator, "binpath", {})
			if not binpath.is_empty():
				found = true
				generic_info.set_found(true, binpath)
				continue
			else:
				generic_info.set_found(false, convert_list_to_string(emulator["binpath"]))
				continue
	return found

func convert_list_to_string(values: Array):
	var text := ""
	for value in values:
		if text.is_empty():
			text = "- %s" % value
		else:
			text += "\n- %s" % value
	return text

func create_emulator_info_node() -> VBoxContainer:
	var node := VBoxContainer.new()
	node.size_flags_vertical = SIZE_EXPAND_FILL
	node.size_flags_horizontal = SIZE_EXPAND_FILL
	n_emulator_info_tab.add_child(node)
	return node

func clear_emulator_info():
	for child in n_emulator_info_tab.get_children():
		child.queue_free()
		n_emulator_info_tab.remove_child(child)


func _on_NextButton_pressed():
	icon_cache.clear()
	clear_emulator_info()
	emit_signal("advance_section")


func _on_Systems_item_selected(index):
	n_emulator_info_tab.current_tab = index

func tts_text(focused: Control) -> String:
	if focused == n_systems:
		return tts_popup_menu_item_text(n_systems.get_item_index(n_systems.get_selected_id()), n_systems.get_popup()) + ". button"
	return ""

func tts_popup_menu_item_text(idx: int, menu: PopupMenu) -> String:
	return menu.get_item_text(idx) + ". " + ("supported" if menu.get_item_metadata(idx) else "not supported")
