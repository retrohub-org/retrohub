extends Control

onready var n_remove_system := $"%RemoveSystem"
onready var n_system_selection := $"%SystemSelection"
onready var n_system_editor := $"%SystemEditor"

func _ready():
	n_system_selection.get_popup().max_height = 350
	RetroHubConfig.connect("config_ready", self, "_on_config_ready")

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
	n_system_editor.curr_system = data


func _on_SystemSettings_visibility_changed():
	if n_system_selection and n_system_editor:
		if visible:
			_on_SystemSelection_item_selected(n_system_selection.selected)
		else:
			n_system_editor.clear_icons()
