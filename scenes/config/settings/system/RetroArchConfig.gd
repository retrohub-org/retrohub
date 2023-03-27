extends WindowDialog

signal cores_picked(cores)

onready var n_intro_lbl := $"%IntroLabel"
onready var n_core_options := $"%CoreOptions"
onready var n_add_core := $"%AddCore"
onready var n_cores := $"%Cores"

onready var n_ok := $"%OK"

var root : TreeItem

func _ready():
	n_core_options.get_popup().max_height = RetroHubUI.max_popupmenu_height
	n_cores.set_column_expand(0, true)
	n_cores.set_column_expand(1, false)
	n_cores.set_column_min_width(1, 48)

func start(cores: Array, existing: Array):
	reset()

	# Add new cores to list
	for core in cores:
		if not core in existing:
			add_core_option(core)

	# Setup tree
	root = n_cores.create_item()
	for core in existing:
		add_core(core)

	# Popup
	popup_centered()
	yield(get_tree(), "idle_frame")
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_intro_lbl.grab_focus()
	else:
		n_core_options.grab_focus()
	n_add_core.disabled = n_core_options.get_child_count() == 0

func reset():
	n_core_options.clear()
	n_cores.clear()
	root = null

func add_core_option(core: Dictionary):
	var text : String = "<%s>" % core["name"] if core["fullname"].empty() else core["fullname"]
	n_core_options.add_item(text)
	n_core_options.set_item_metadata(n_core_options.get_item_count()-1, core)

func add_core(core: Dictionary):
	var child : TreeItem = n_cores.create_item(root)
	child.set_metadata(0, core)
	var text : String = "<%s>" % core["name"] if core["fullname"].empty() else core["fullname"]
	child.set_text(0, text)
	child.set_icon(1, preload("res://assets/icons/failure.svg"))

func _on_OK_pressed():
	hide()
	var cores := []
	var item : TreeItem = root.get_children()
	while item != null:
		cores.push_back(item.get_metadata(0))
		item = item.get_next()

	emit_signal("cores_picked", cores)


func _on_Cores_item_activated():
	if n_cores.get_selected_column() == 1:
		# Remove
		var core : Dictionary = n_cores.get_selected().get_metadata(0)
		add_core_option(core)
		n_add_core.disabled = false
		n_cores.get_selected().free()


func _on_AddCore_pressed():
	var core : Dictionary = n_core_options.get_selected_metadata()
	add_core(core)
	var idx : int = n_core_options.get_item_index(n_core_options.get_selected_id())
	n_core_options.remove_item(idx)
	idx -= 1
	if idx < 0 and n_core_options.get_item_count() > 0:
		idx = 0
	n_core_options.selected = idx
	n_add_core.disabled = n_core_options.get_item_count() == 0

func tts_tree_item_text(item: TreeItem, tree: Tree) -> String:
	if tree == n_cores:
		if item:
			if item.is_selected(1):
				return "Remove emulator"
	return ""
