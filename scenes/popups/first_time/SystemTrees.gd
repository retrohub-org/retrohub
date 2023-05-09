extends Control

signal system_selected(system)

@onready var n_consoles := $"%Consoles"
@onready var n_arcades := $"%Arcades"
@onready var n_computers := $"%Computers"
@onready var n_engines := $"%Engines"
@onready var n_modern_consoles := $"%ModernConsoles"

@onready var n_system_warning := $"%SystemWarning"

@onready var n_systems := [
	n_consoles, n_arcades, n_computers,
	n_engines, n_modern_consoles
]

var _tts_last_item : TreeItem

func _ready():
	for system in n_systems:
		system.connect("focus_entered", Callable(self, "_on_tree_focus_entered").bind(system))

func _on_tree_focus_entered(tree: Tree):
	if not tree.get_selected():
		tree.get_root().select(1)
	_on_item_selected(tree)

func grab_focus():
	for tree in n_systems:
		if tree.visible:
			tree.grab_focus()
			return

func _sort_fullname(a: Dictionary, b: Dictionary):
	return a["fullname"].naturalnocasecmp_to(b["fullname"]) == -1

func setup_systems(categories: Array):
	for idx in range(n_systems.size()):
		n_systems[idx].set_column_title(1, categories[idx])
		n_systems[idx].set_column_expand(0, false)
		n_systems[idx].set_column_custom_minimum_width(0, 32)
		var root : TreeItem = n_systems[idx].create_item()
		root.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		root.set_checked(0, true)
		root.set_selectable(0, false)
		root.set_editable(0, true)
		root.set_text(1, "<all>")

	var systems := RetroHubConfig._systems_raw.values()
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		# Sort by fullname instead
		systems = systems.duplicate()
		systems.sort_custom(Callable(self, "_sort_fullname"))

	for system in systems:
		var idx := RetroHubSystemData.category_to_idx(system["category"])
		var child : TreeItem = n_systems[idx].create_item(n_systems[idx].get_root())
		child.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		child.set_checked(0, system["name"] in RetroHubConfig.systems)
		set_item_checked_up(child.get_parent())
		child.set_editable(0, true)
		child.set_selectable(0, false)
		child.set_metadata(0, system)
		child.set_text(1, system["name"])

	set_systems_visible(0)

func set_systems_visible(idx: int):
	n_consoles.visible = idx == 0
	n_arcades.visible = idx == 1
	n_computers.visible = idx == 2
	n_engines.visible = idx == 3
	n_modern_consoles.visible = idx == 4

func set_item_checked_down(item: TreeItem, checked: bool):
	if item:
		if is_edit_valid(item):
			item.set_checked(0, checked)
		for child in item.get_children():
			set_item_checked_down(child, checked)

func set_item_checked_up(item: TreeItem):
	if item:
		var all_checked := true
		for child in item.get_children():
			if not child.is_checked(0):
				all_checked = false
				break
		item.set_checked(0, all_checked)
		set_item_checked_up(item.get_parent())

func _on_item_edited(edited: TreeItem):
	if is_edit_valid(edited):
		if edited.get_child_count() > 0:
			set_item_checked_down(edited, edited.is_checked(0))
		set_item_checked_up(edited.get_parent())
	else:
		n_system_warning.popup()
		edited.set_checked(0, true)

func is_edit_valid(item: TreeItem):
	if item.get_metadata(0):
		var system : Dictionary = item.get_metadata(0)
		var name : String = system["name"]
		if RetroHubConfig.systems.has(name):
			return RetroHubConfig.systems[name].num_games == 0
	return true

func save():
	for tree in n_systems:
		var next : TreeItem = tree.get_root().get_children()
		while next:
			if next.is_checked(0):
				var system : Dictionary = next.get_metadata(0)
				RetroHubConfig.make_system_folder(system)
			next = next.get_next()

func _on_item_selected(tree: Tree):
	if tree.get_selected().get_metadata(0):
		var system : Dictionary = tree.get_selected().get_metadata(0)
		emit_signal("system_selected", system)

func _on_Consoles_item_edited():
	_on_item_edited(n_consoles.get_edited())

func _on_Arcades_item_edited():
	_on_item_edited(n_arcades.get_edited())

func _on_Computers_item_edited():
	_on_item_edited(n_computers.get_edited())

func _on_Engines_item_edited():
	_on_item_edited(n_engines.get_edited())

func _on_ModernConsoles_item_edited():
	_on_item_edited(n_modern_consoles.get_edited())

func _on_Consoles_item_selected():
	_on_item_selected(n_consoles)

func _on_Arcades_item_selected():
	_on_item_selected(n_arcades)

func _on_Computers_item_selected():
	_on_item_selected(n_computers)

func _on_Engines_item_selected():
	_on_item_selected(n_engines)

func _on_ModernConsoles_item_selected():
	_on_item_selected(n_modern_consoles)

func _on_Consoles_item_activated():
	var item : TreeItem = n_consoles.get_selected()
	item.set_checked(0, not item.is_checked(0))
	_on_item_edited(item)

func _on_Arcades_item_activated():
	var item : TreeItem = n_arcades.get_selected()
	item.set_checked(0, not item.is_checked(0))
	_on_item_edited(item)

func _on_Computers_item_activated():
	var item : TreeItem = n_computers.get_selected()
	item.set_checked(0, not item.is_checked(0))
	_on_item_edited(item)

func _on_Engines_item_activated():
	var item : TreeItem = n_engines.get_selected()
	item.set_checked(0, not item.is_checked(0))
	_on_item_edited(item)

func _on_ModernConsoles_item_activated():
	var item : TreeItem = n_modern_consoles.get_selected()
	item.set_checked(0, not item.is_checked(0))
	_on_item_edited(item)

func tts_tree_item_text(item: TreeItem, tree: Tree):
	var text : String
	if item != _tts_last_item:
		_tts_last_item = item
		if item.get_text(1) == "<all>":
			text = "All " + tree.get_column_title(1)
		else:
			text = item.get_metadata(0)["fullname"]
	text += ". " + ("checked" if item.is_checked(0) else "unchecked")
	return text
