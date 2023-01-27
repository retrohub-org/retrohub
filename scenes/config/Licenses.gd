extends Control

const LICENSE_PATH := "res://assets/copyright/licenses/"

onready var n_names = $"%Names"
onready var n_content = $"%Content"



# Called when the node enters the scene tree for the first time.
func _ready():
	# Load licenses
	var license_files = [
		"gpl3retrohub.txt",
		"gpl3.txt",
		"mit.txt",
		"cc0.txt",
		"cc40by.txt"
	]
	var licenses := {}
	var file := File.new()
	for license in license_files:
		if not file.open(LICENSE_PATH + license, File.READ):
			licenses[license.get_file().get_basename()] = file.get_as_text()
			file.close()
		else:
			print("Error reading license file %s!" % LICENSE_PATH + license)
	
	# Populate tree
	var root : TreeItem = n_names.create_item()
	for key in licenses:
		var child : TreeItem = n_names.create_item(root)
		child.set_text(0, key)
		child.set_metadata(0, licenses[key])

func _on_Names_item_selected():
	var item : TreeItem = n_names.get_selected()
	n_content.text = item.get_metadata(0)
