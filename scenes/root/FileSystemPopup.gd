extends FileDialog

var ok_button : Button
var cancel_button : Button
var upwards_button : Button
var refresh_button : Button
var hide_button : Button

func _ready():
	## Normal nodes
	var tree : Tree = get_vbox().get_child(2).get_child(0)
	ok_button = get_ok()
	cancel_button = get_cancel()
	upwards_button = get_vbox().get_child(0).get_child(0)
	refresh_button = get_vbox().get_child(0).get_child(4)
	hide_button = get_vbox().get_child(0).get_child(5)
	var path : String
	var controller_icon_rect := preload("res://addons/controller_icons/objects/TextureRect.gd")

	# Attach ControllerIcons to buttons
	var box : HBoxContainer = ok_button.get_parent()
	var back_icon := create_icon(controller_icon_rect, "rh_back")
	box.add_child_below_node(box.get_child(0), back_icon)
	var select_icon := create_icon(controller_icon_rect, "rh_major_option")
	box.add_child_below_node(box.get_child(3), select_icon)

	box = upwards_button.get_parent()
	var upwards_icon := create_icon(controller_icon_rect, "rh_minor_option")
	box.add_child(upwards_icon)
	box.move_child(upwards_icon, 0)
	var refresh_icon := create_icon(controller_icon_rect, "rh_theme_menu")
	box.add_child_below_node(box.get_child(4), refresh_icon)
	var hide_icon := create_icon(controller_icon_rect, "rh_menu")
	box.add_child_below_node(box.get_child(6), hide_icon)

	# Tree should focus cancel button on down
	path = "../../../%s/%s" % [
		cancel_button.get_parent().name,
		cancel_button.name
	]
	tree.focus_neighbour_bottom = path
	# Ok and Cancel buttons should focus tree on up
	path = "../../%s/%s/%s" % [
		tree.get_parent().get_parent().name,
		tree.get_parent().name,
		tree.name
	]
	ok_button.focus_neighbour_top = path
	cancel_button.focus_neighbour_top = path

	## Create Folder nodes
	var create_folder_popup : ConfirmationDialog = get_child(5)
	var create_folder_line_edit : LineEdit = create_folder_popup.get_child(3).get_child(1).get_child(0)
	var create_folder_ok_button := create_folder_popup.get_ok()
	var create_folder_cancel_button := create_folder_popup.get_cancel()

	# Set focus neighbors
	# Line edit should focus cancel button on down
	path = "../../../%s/%s" % [
		create_folder_cancel_button.get_parent().name,
		create_folder_cancel_button.name
	]
	create_folder_line_edit.focus_neighbour_bottom = path

	# Ok and Cancel buttons should focus line edit on up
	path = "../../%s/%s/%s" % [
		create_folder_line_edit.get_parent().get_parent().name,
		create_folder_line_edit.get_parent().name,
		create_folder_line_edit.name
	]
	create_folder_ok_button.focus_neighbour_top = path
	create_folder_cancel_button.focus_neighbour_top = path

func _unhandled_input(event):
	if RetroHub.is_input_echo() or not visible:
		return
	if event is InputEventJoypadButton:
		if event.is_action_released("rh_major_option"):
			get_tree().set_input_as_handled()
			ok_button.emit_signal("pressed")
		elif event.is_action_released("rh_minor_option"):
			get_tree().set_input_as_handled()
			upwards_button.emit_signal("pressed")
		elif event.is_action_released("rh_theme_menu"):
			get_tree().set_input_as_handled()
			refresh_button.emit_signal("pressed")
		elif event.is_action_released("rh_menu"):
			get_tree().set_input_as_handled()
			hide_button.pressed = not hide_button.pressed

func create_icon(base: GDScript, path: String) -> Control:
	var icon : Control = base.new()
	icon.path = path
	icon.max_width = 32
	icon.show_only = 2

	return icon
