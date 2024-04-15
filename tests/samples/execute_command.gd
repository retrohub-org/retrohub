extends Control

var output := []

func _on_Button_pressed():
	$FileDialog.popup()

func _input(event):
	if event.is_action_pressed("ui_quit"):
		get_tree().quit()

func _on_FileDialog_file_selected(path):
	$VBoxContainer/HBoxContainer/FileSelectField.text = path


func _on_LaunchButton_pressed():
	$VBoxContainer/RichTextLabel.text = ""
	var arr : Array = $VBoxContainer/Command.text.split(" ")
	var command : String = arr[0]
	arr.remove_at(0)
	if($VBoxContainer/HBoxContainer/FileSelectField.text.length()):
		arr.push_back($VBoxContainer/HBoxContainer/FileSelectField.text)
	print("Executing command ", command, " with arg len ", arr.size())
	var _pid := OS.execute(command, arr, output, false)


func _on_Timer_timeout():
	$VBoxContainer/RichTextLabel.text = ""
	for line in output:
		$VBoxContainer/RichTextLabel.text += line + '\n'
