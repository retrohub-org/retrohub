extends ConfirmationDialog

signal games_selected(game_data_array)

onready var n_game_tree = $"%GameTree"

var root : TreeItem
var systems_items : Dictionary

func _ready():
	n_game_tree.set_column_title(0, "Games")
	n_game_tree.set_column_title(1, "Selected?")
	n_game_tree.set_column_expand(0, true)
	n_game_tree.set_column_expand(1, false)
	n_game_tree.set_column_min_width(1, 100)


func _on_ScrapingGamePickerPopup_about_to_show():
	n_game_tree.clear()
	systems_items.clear()
	root = n_game_tree.create_item()
	set_item_settings(root, "Systems")

	# First, create all systems
	for system in RetroHubConfig.systems.values():
		var item = n_game_tree.create_item(root)
		set_item_settings(item, system.fullname)
		systems_items[system] = item
	for game in RetroHubConfig.games:
		var item = n_game_tree.create_item(systems_items[game.system])
		set_item_settings(item, game.path.get_file())
		item.set_metadata(0, game)

func set_item_settings(item: TreeItem, name: String):
	item.set_text(0, name)
	item.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
	item.set_editable(1, true)
	item.set_checked(1, true)

func set_item_checked_down(item: TreeItem, checked: bool):
	if item:
		item.set_checked(1, checked)
		set_item_checked_down(item.get_children(), checked)
		var next := item.get_next()
		while next:
			set_item_checked_down(next.get_children(), checked)
			next.set_checked(1, checked)
			next = next.get_next()

func set_item_checked_up(item: TreeItem):
	if item:
		var all_checked = true
		var next = item.get_children()
		while next:
			if not next.is_checked(1):
				all_checked = false
				break
			next = next.get_next()
		item.set_checked(1, all_checked)
		set_item_checked_up(item.get_parent())


func _on_GameTree_item_edited():
	var edited = n_game_tree.get_edited()
	set_item_checked_down(edited.get_children(), edited.is_checked(1))
	set_item_checked_up(edited.get_parent())


func _on_ScrapingGamePickerPopup_confirmed():
	emit_signal("games_selected", get_selected_items(root))
	hide()


func _on_ScrapingGamePickerPopup_popup_hide():
	emit_signal("games_selected", [])


func get_selected_items(root: TreeItem):
	var selected_items := []
	if root:
		if root.get_children():
			var next = root
			while next:
				selected_items.append_array(get_selected_items(next.get_children()))
				next = next.get_next()
		else:
			var next = root
			while next:
				if next.is_checked(1):
					selected_items.append(next.get_metadata(0))
				next = next.get_next()
	return selected_items
