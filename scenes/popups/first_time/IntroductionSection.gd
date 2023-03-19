extends Control

signal advance_section

onready var n_label := $"%Label"
onready var n_screen_reader := $"%ScreenReader"
onready var n_next_button := $"%NextButton"

func grab_focus():
	TTS.speak("To enable the screen reader, press the Control key.")
	RetroHubConfig.config.accessibility_screen_reader_enabled = false
	n_next_button.grab_focus()

func _input(event):
	if event is InputEventKey and event.scancode == KEY_CONTROL:
		n_screen_reader.pressed = true
		n_label.grab_focus()

func _on_NextButton_pressed():
	emit_signal("advance_section")


func _on_ScreenReader_toggled(button_pressed):
	RetroHubConfig.config.accessibility_screen_reader_enabled = button_pressed


func _on_Label_focus_entered():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_screen_reader.grab_focus()
