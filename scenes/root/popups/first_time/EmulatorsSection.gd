extends Control

signal advance_section

onready var n_systems := $"%Systems"
onready var n_emulator_info_tab := $"%EmulatorInfoTab"

var icon_cache := {}

func grab_focus():
	n_systems.grab_focus()
	set_systems()

func set_systems():
	n_systems.clear()
	clear_emulator_info()

	for system in RetroHubConfig._systems_raw.values():
		var found = handle_emulator_info(system)
		if found:
			n_systems.add_icon_item(preload("res://assets/icons/editor/success.svg"), system["fullname"])
		else:
			n_systems.add_icon_item(preload("res://assets/icons/editor/failure.svg"), system["fullname"])

func handle_emulator_info(system_raw: Dictionary) -> bool:
	var system_emulators = system_raw["emulator"]
	var emulators = RetroHubConfig.emulators_map
	var found := false
	var parent := create_emulator_info_node()
	for system_emulator in system_emulators:
		if system_emulator is Dictionary and system_emulator.has("retroarch"):
			var retroarch_info := preload("res://scenes/root/popups/first_time/RetroArchEmulatorInfo.tscn").instance()
			var emulator = emulators["retroarch"]
			parent.add_child(retroarch_info)
			
			# Test for binpath first
			var binpaths = emulator["binpath"]
			var binpath = FileUtils.test_for_valid_path(binpaths)
			if not binpath.empty():
				retroarch_info.set_path_found(true, binpath)
				# Then test for cores
				var required_cores : Array = system_emulator["retroarch"]
				var corespath = JSONUtils.format_string_with_substitutes(FileUtils.test_for_valid_path(emulator["corepath"]) , {"binpath": binpath})
				if corespath.empty():
					retroarch_info.set_core_found(false, "Could not find any cores inside:\n" + convert_list_to_string(emulator["corepath"]))
					continue
				var cores : Array = emulator["cores"]
				var avail_cores := []
				for req_core in required_cores:
					for core in cores:
						if core["name"] == req_core:
							avail_cores.push_back(core)
				if avail_cores.empty():
					retroarch_info.set_core_found(false, "No default config for cores:\n" + convert_list_to_string(required_cores))
					continue
				var corepaths := []
				for core in avail_cores:
					corepaths.push_back(corespath + "/" + core["file"])
				var corepath = FileUtils.test_for_valid_path(corepaths)
				if not corepath.empty():
					for core in avail_cores:
						if core["file"] == corepath.get_file():
							retroarch_info.set_core_found(true, "%s (%s)" % [core["fullname"] ,corepath])
					found = true
				else:
					retroarch_info.set_core_found(false, convert_list_to_string(corepaths))
					continue
			else:
				retroarch_info.set_path_found(false, convert_list_to_string(binpaths))
				continue
			
		elif emulators.has(system_emulator):
			# Generic emulator
			var generic_info := preload("res://scenes/root/popups/first_time/GenericEmulatorInfo.tscn").instance()
			var emulator = emulators[system_emulator]
			parent.add_child(generic_info)
			
			generic_info.set_name(emulator["fullname"])
			if not icon_cache.has(system_emulator):
				icon_cache[system_emulator] = load("res://assets/emulators/%s.png" % system_emulator)
			generic_info.set_logo(icon_cache[system_emulator])

			# Test for binpath first
			var binpaths = emulator["binpath"]
			var binpath = FileUtils.test_for_valid_path(binpaths)
			if not binpath.empty():
				found = true
				generic_info.set_found(true, binpath)
				continue
			else:
				generic_info.set_found(false, convert_list_to_string(binpaths))
				continue
	return found

func convert_list_to_string(values: Array):
	var text = ""
	for value in values:
		if text.empty():
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
