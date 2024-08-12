extends Control

@onready var n_quit := %Quit
@onready var n_shutdown := %Shutdown
@onready var n_restart := %Restart

@onready var n_shutdown_confirm : ConfirmationDialog = n_shutdown.get_node("Confirmation")
@onready var n_restart_confirm : ConfirmationDialog = n_restart.get_node("Confirmation")

@onready var n_extra_system_nodes := [
	%Separator, %SystemButtons
]

func _ready() -> void:
	# macOS does not allow apps to issue arbitrary shutdown/reboot
	# commands; it requires root privileges, and the programmatic
	# method would require native code (https://developer.apple.com/library/archive/qa/qa1134/_index.html)
	# So, just disable it.
	if FileUtils.get_os_id() == FileUtils.OS_ID.MACOS:
		for node: Node in n_extra_system_nodes:
			node.queue_free()

func grab_focus():
	n_quit.grab_focus()


func _on_Quit_pressed():
	RetroHub.quit()


func _on_shutdown_pressed() -> void:
	n_shutdown_confirm.popup_centered()


func _on_restart_pressed() -> void:
	n_restart_confirm.popup_centered()


func _on_shutdown_confirmed() -> void:
	match FileUtils.get_os_id():
		FileUtils.OS_ID.WINDOWS:
			OS.execute("shutdown", ["/s", "/t", "0"])
		FileUtils.OS_ID.LINUX:
			OS.execute("shutdown", ["-P", "now"])
		_:
			push_error("Unimplemented shutdown functionality!")
	_on_Quit_pressed()


func _on_restart_confirmed() -> void:
	match FileUtils.get_os_id():
		FileUtils.OS_ID.WINDOWS:
			OS.execute("shutdown", ["/r", "/t", "0"])
		FileUtils.OS_ID.LINUX:
			OS.execute("shutdown", ["-r", "now"])
		_:
			push_error("Unimplemented shutdown functionality!")
	_on_Quit_pressed()
