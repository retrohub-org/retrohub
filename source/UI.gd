extends Node

var _n_filesystem_popup : FileDialog setget _set_filesystem_popup
var _n_virtual_keyboard_popup

var color_success := Color("41eb83")
var color_warning := Color("ffd24a")
var color_error := Color("ff5d5d")
var color_unavailable := Color("999999")

signal path_selected(file)

func _set_filesystem_popup(popup: FileDialog):
	_n_filesystem_popup = popup
	_n_filesystem_popup.connect("file_selected", self, "_on_popup_selected")
	_n_filesystem_popup.connect("dir_selected", self, "_on_popup_selected")
	_n_filesystem_popup.connect("popup_hide", self, "_on_popup_hide")

func _on_popup_selected(file: String):
	emit_signal("path_selected", file)

func _on_popup_hide():
	emit_signal("path_selected", "")

func filesystem_filters(filters: Array = []):
	_n_filesystem_popup.filters = filters

func request_file_load(base_path: String) -> void:
	_n_filesystem_popup.mode = FileDialog.MODE_OPEN_FILE
	_n_filesystem_popup.current_dir = base_path
	_n_filesystem_popup.popup()

func request_folder_load(base_path: String) -> void:
	_n_filesystem_popup.mode = FileDialog.MODE_OPEN_DIR
	_n_filesystem_popup.current_dir = base_path
	_n_filesystem_popup.popup()
