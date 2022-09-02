extends Control

var filepath := "base_config/emulators.json"
onready	var raw_json_node := $VBoxContainer/HBoxContainer2/VBoxContainer/RawJSON
onready	var edited_json_node := $VBoxContainer/HBoxContainer2/VBoxContainer2/EditedJSON
onready var system_select_node := $VBoxContainer/HBoxContainer/OptionButton

# Called when the node enters the scene tree for the first time.
func _ready():
	var file = File.new()
	file.open(filepath, File.READ)
	var res := JSON.parse(file.get_as_text())
	if(!res.error):
		raw_json_node.text = JSON.print(res.result, "\t")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button_pressed():
	var res = JSON.parse(raw_json_node.text)
	var system = system_select_node.get_item_text(system_select_node.selected)
	var output = JSONUtils.make_system_specific(res.result, system)
	edited_json_node.text = JSON.print(output, "\t")
	
