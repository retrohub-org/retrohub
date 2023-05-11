extends FileDialog

var ok_button : Button
var cancel_button : Button
var upwards_button : Button
var refresh_button : Button
var hide_button : Button

func _ready():
	## Normal nodes
	var tree : Tree = get_vbox().get_child(2, true).get_child(0, true)
	ok_button = get_ok_button()
	cancel_button = get_cancel_button()
	upwards_button = get_vbox().get_child(0, true).get_child(2, true)
	refresh_button = get_vbox().get_child(0, true).get_child(6, true)
	hide_button = get_vbox().get_child(0, true).get_child(7, true)
	var path : String
	var controller_icon_rect := preload("res://addons/controller_icons/objects/TextureRect.gd")

	# Attach ControllerIcons to buttons
	var box : HBoxContainer = ok_button.get_parent()
	var back_icon := create_icon(controller_icon_rect, "rh_back")
	box.get_child(0).add_sibling(back_icon)
	var select_icon := create_icon(controller_icon_rect, "rh_major_option")
	box.get_child(3).add_sibling(select_icon)

	box = upwards_button.get_parent()
	var upwards_icon := create_icon(controller_icon_rect, "rh_minor_option")
	box.add_child(upwards_icon)
	box.move_child(upwards_icon, 0)
	var refresh_icon := create_icon(controller_icon_rect, "rh_theme_menu")
	box.get_child(4).add_sibling(refresh_icon)
	var hide_icon := create_icon(controller_icon_rect, "rh_menu")
	box.get_child(6).add_sibling(hide_icon)

	# Tree should focus cancel button on down
	path = "../../../%s/%s" % [
		cancel_button.get_parent().name,
		cancel_button.name
	]
	tree.focus_neighbor_bottom = path
	tree.focus_next = path
	# Ok and Cancel buttons should focus tree on up
	path = "../../%s/%s/%s" % [
		tree.get_parent().get_parent().name,
		tree.get_parent().name,
		tree.name
	]
	ok_button.focus_neighbor_top = path
	ok_button.focus_previous = path
	cancel_button.focus_neighbor_top = path
	cancel_button.focus_previous = path

	## Create Folder nodes
	var create_folder_popup : ConfirmationDialog = get_child(5, true)
	var create_folder_line_edit : LineEdit = create_folder_popup.get_child(3, true).get_child(1, true).get_child(0, true)
	var create_folder_ok_button := create_folder_popup.get_ok_button()
	var create_folder_cancel_button := create_folder_popup.get_cancel_button()

	# Set focus neighbors
	# Line edit should focus cancel button on down
	path = "../../../%s/%s" % [
		create_folder_cancel_button.get_parent().name,
		create_folder_cancel_button.name
	]
	create_folder_line_edit.focus_neighbor_bottom = path

	# Ok and Cancel buttons should focus line edit on up
	path = "../../%s/%s/%s" % [
		create_folder_line_edit.get_parent().get_parent().name,
		create_folder_line_edit.get_parent().name,
		create_folder_line_edit.name
	]
	create_folder_ok_button.focus_neighbor_top = path
	create_folder_cancel_button.focus_neighbor_top = path

func _unhandled_input(event):
	if RetroHub.is_input_echo() or not visible:
		return
	if event is InputEventJoypadButton:
		if event.is_action_released("rh_major_option"):
			get_viewport().set_input_as_handled()
			ok_button.emit_signal("pressed")
		elif event.is_action_released("rh_minor_option"):
			get_viewport().set_input_as_handled()
			upwards_button.emit_signal("pressed")
		elif event.is_action_released("rh_theme_menu"):
			get_viewport().set_input_as_handled()
			refresh_button.emit_signal("pressed")
		elif event.is_action_released("rh_menu"):
			get_viewport().set_input_as_handled()
			hide_button.button_pressed = not hide_button.button_pressed

func create_icon(base: GDScript, path: String) -> Control:
	var icon : Control = base.new()
	icon.path = path
	icon.max_width = 32
	icon.show_only = 2

	return icon
