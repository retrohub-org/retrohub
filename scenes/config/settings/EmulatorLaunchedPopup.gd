extends Window

var pid := 0

func _process(delta):
	if not visible: return
	if pid > 0 and not OS.is_process_running(pid):
		# Request focus, as we might not have it
		get_tree().root.move_to_foreground()
		_on_close_requested()

func _on_about_to_popup():
	RetroHub._prevent_controller_input = true

func _on_close_requested():
	hide()
	# 0 or -1 will kill ALL processes, at least on Linux.
	# We definitely do not want that.
	if pid > 0:
		OS.kill(pid)
	pid = 0
	RetroHub._prevent_controller_input = false
