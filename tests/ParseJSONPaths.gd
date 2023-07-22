extends Control

var filepath := "base_config/emulators.json"
@onready	var raw_json_node := $VBoxContainer/HBoxContainer2/VBoxContainer/RawJSON
@onready	var edited_json_node := $VBoxContainer/HBoxContainer2/VBoxContainer2/EditedJSON
@onready var system_select_node := $VBoxContainer/HBoxContainer/OptionButton

func _ready():
	var file := File.new()
	#warning-ignore:return_value_discarded
	file.open(filepath, File.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var res := test_json_conv.get_data()
	if(!res.error):
		raw_json_node.text = JSON.stringify(res.result, "\t")


func _on_Button_pressed():
	var test_json_conv = JSON.new()
	test_json_conv.parse(raw_json_node.text)
	var res := test_json_conv.get_data()
	var system : system_select_node.get_item_text(system_select_node.selected)
	var output := JSONUtils.make_system_specific(res.result, system)
	edited_json_node.text = JSON.stringify(output, "\t")

