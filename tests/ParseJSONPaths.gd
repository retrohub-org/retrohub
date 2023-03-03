extends Control

var filepath := "base_config/emulators.json"
onready	var raw_json_node := $VBoxContainer/HBoxContainer2/VBoxContainer/RawJSON
onready	var edited_json_node := $VBoxContainer/HBoxContainer2/VBoxContainer2/EditedJSON
onready var system_select_node := $VBoxContainer/HBoxContainer/OptionButton

func _ready():
	var file := File.new()
	#warning-ignore:return_value_discarded
	file.open(filepath, File.READ)
	var res := JSON.parse(file.get_as_text())
	if(!res.error):
		raw_json_node.text = JSON.print(res.result, "\t")


func _on_Button_pressed():
	var res := JSON.parse(raw_json_node.text)
	var system : system_select_node.get_item_text(system_select_node.selected)
	var output := JSONUtils.make_system_specific(res.result, system)
	edited_json_node.text = JSON.print(output, "\t")

