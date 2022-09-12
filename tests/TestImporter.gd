extends Control

func _ready():
	var importer = RetroArchImporter.new()
	print("Availability: ", importer.is_available())
	print("Size: ", importer.get_estimated_size())
	print("Avail size: ", FileUtils.get_space_left())
	#importer.begin_import(false)
