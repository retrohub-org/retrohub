extends Control

signal advance_section

onready var n_next_button := $"%NextButton"

func grab_focus():
	n_next_button.grab_focus()

func _on_NextButton_pressed():
	emit_signal("advance_section")
