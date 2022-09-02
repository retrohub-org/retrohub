tool
extends EditorPlugin

var dock
var singleton

func _enter_tree():
	add_dock_elements()

func add_dock_elements():
	dock = preload("res://addons/retrohub_theme_helper/dock/ThemeDock.tscn").instance()
	
	add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()
