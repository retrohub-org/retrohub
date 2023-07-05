extends Control

signal advance_section

@onready var n_intro_lbl := %IntroLabel
@onready var n_buttons_prompt := %ButtonsPrompt
@onready var n_next_button := %NextButton

func grab_focus():
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_intro_lbl.grab_focus()
	else:
		n_next_button.grab_focus()

func _on_NextButton_pressed():
	emit_signal("advance_section")

func tts_text(focused: Control):
	if focused == n_buttons_prompt:
		return $VBoxContainer/HBoxContainer/ButtonsPrompt/Label.text \
			+ " " + $VBoxContainer/HBoxContainer/ButtonsPrompt/ControllerTextureRect.get_tts_string() + " "\
			+ $VBoxContainer/HBoxContainer/ButtonsPrompt/Label2.text \
			+ " " + $VBoxContainer/HBoxContainer/ButtonsPrompt/ControllerTextureRect2.get_tts_string() + " "\
			+ $VBoxContainer/HBoxContainer/ButtonsPrompt/Label3.text
	return ""
