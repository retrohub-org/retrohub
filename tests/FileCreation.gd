extends Control

func _on_Create_pressed():
	var file := File.new()
	#warning-ignore:return_value_discarded
	file.open("/home/ricardo/test", File.WRITE)
	file.close()

func _on_Destroy_pressed():
	var file := File.new()
	if(file.file_exists("/home/ricardo/test")):
		var dir := Directory.new()
		#warning-ignore:return_value_discarded
		dir.remove("/home/ricardo/test")
