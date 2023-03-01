extends Control

signal advance_section

onready var n_categories := $"%Categories"
onready var n_system_trees := $"%SystemTrees"
onready var n_system_info := $"%SystemInfo"

var categories := [
	"Consoles",
	"Arcades",
	"Computers",
	"Game Engines",
	"Modern Consoles"
]

func _ready():
	setup_categories()

func grab_focus():
	RetroHubConfig.load_systems()
	RetroHubConfig.load_game_data_files()
	n_system_trees.setup_systems(categories)
	n_categories.grab_focus()

func _on_NextButton_pressed():
	n_system_trees.save()
	emit_signal("advance_section")

func setup_categories():
	n_categories.set_column_title(0, "Category")
	var root = n_categories.create_item()

	# Tied to RetroHubSystemData.Category
	for idx in range(categories.size()):
		var child : TreeItem = n_categories.create_item(root)
		child.set_text(0, categories[idx])
		child.set_metadata(0, idx)


func _on_Categories_cell_selected():
	n_system_info.visible = false
	n_system_trees.set_systems_visible(n_categories.get_selected().get_metadata(0))


func _on_SystemTrees_system_selected(system: Dictionary):
	n_system_info.visible = system != null
	if system:
		n_system_info.set_system(system)


func _on_Categories_item_activated():
	n_system_trees.grab_focus()
