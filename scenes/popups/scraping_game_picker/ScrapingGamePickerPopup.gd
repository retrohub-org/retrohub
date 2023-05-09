extends ConfirmationDialog

signal games_selected(game_data_array)

@onready var n_game_tree := $"%GameTree"

var root : TreeItem
var systems_items : Dictionary

func _ready():
	n_game_tree.set_column_title(0, "Games")
	n_game_tree.set_column_title(1, "Selected?")
	n_game_tree.set_column_expand(0, true)
	n_game_tree.set_column_expand(1, false)
	n_game_tree.set_column_custom_minimum_width(1, 100)

	# Set focus neighbors
	var ok := get_ok_button()
	var cancel := get_cancel_button()

	var path := "../../%s/%s" % [cancel.get_parent().name, cancel.name]
	n_game_tree.focus_neighbor_bottom = path
	n_game_tree.focus_neighbor_top = path

	path = "../../%s/%s" % [n_game_tree.get_parent().name, n_game_tree.name]
	ok.focus_neighbor_top = path
	ok.focus_neighbor_bottom = path
	cancel.focus_neighbor_top = path
	cancel.focus_neighbor_bottom = path

func _on_ScrapingGamePickerPopup_about_to_show():
	n_game_tree.clear()
	systems_items.clear()
	root = n_game_tree.create_item()
	set_item_settings(root, "Systems")

	# First, create all systems
	for system in RetroHubConfig.systems.values():
		var item : TreeItem = n_game_tree.create_item(root)
		set_item_settings(item, system.fullname)
		systems_items[system] = item
	# Then all games
	for game in RetroHubConfig.games:
		var item : TreeItem = n_game_tree.create_item(systems_items[game.system])
		set_item_settings(item, game.path.get_file())
		item.set_metadata(0, game)
	# Focus tree
	await get_tree().idle_frame
	n_game_tree.grab_focus()
	n_game_tree.scroll_to_item(root)
	root.select(0)

func set_item_settings(item: TreeItem, name: String):
	item.set_text(0, name)
	item.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
	item.set_editable(1, true)
	item.set_checked(1, true)

func set_item_checked_down(item: TreeItem, checked: bool):
	if item:
		item.set_checked(1, checked)
		for child in item.get_children():
			set_item_checked_down(child, checked)

func set_item_checked_up(item: TreeItem):
	if item:
		var all_checked := true
		for child in item.get_children():
			if not child.is_checked(1):
				all_checked = false
				break
		item.set_checked(1, all_checked)
		set_item_checked_up(item.get_parent())


func _on_GameTree_item_edited():
	handle_tree_edit(n_game_tree.get_edited())


func handle_tree_edit(edited: TreeItem):
	set_item_checked_down(edited, edited.is_checked(1))
	set_item_checked_up(edited.get_parent())


func _on_ScrapingGamePickerPopup_confirmed():
	emit_signal("games_selected", get_selected_items(root))
	hide()


func _on_ScrapingGamePickerPopup_popup_hide():
	emit_signal("games_selected", [])


func get_selected_items(_root: TreeItem):
	var selected_items := []
	if _root:
		var next := _root
		while next:
			if _root.get_children():
				selected_items.append_array(get_selected_items(next.get_child(0)))
			elif next.is_checked(1):
				selected_items.append(next.get_metadata(0))
			next = next.get_next()
	return selected_items


func _on_GameTree_item_activated():
	var item : TreeItem = n_game_tree.get_selected()
	if n_game_tree.get_selected_column() == 0:
		if item.get_children() != null:
			item.collapsed = not item.collapsed
		else:
			item.set_checked(1, not item.is_checked(1))
			handle_tree_edit(item)
