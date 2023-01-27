extends Control

onready var n_quit := $"%Quit"
onready var n_shutdown := $"%Shutdown"
onready var n_restart := $"%Restart"

func grab_focus():
	n_quit.grab_focus()


func _on_Quit_pressed():
	RetroHub.quit()
