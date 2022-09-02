extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Create_pressed():
	var file = File.new()
	file.open("/home/ricardo/test", File.WRITE)
	file.close()

func _on_Destroy_pressed():
	var file = File.new()
	if(file.file_exists("/home/ricardo/test")):
		var dir = Directory.new()
		dir.remove("/home/ricardo/test")
