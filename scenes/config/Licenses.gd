extends Control

const LICENSE_PATH := "res://assets/copyright/licenses/"

@onready var n_names := %Names
@onready var n_content := %Content

var licenses := {}
var root : TreeItem

func _ready():
	# Load licenses
	var license_files := [
		["LGPLv3", "lgpl3.txt"],
		["MIT (RetroHub)", "mit_retrohub.txt"],
		["MIT (Godot Engine)", "mit_godot.txt"],
		["MIT (EIRTeam.FFmpeg)", "mit_eirteam_ffmpeg.txt"],
		["MIT (Controller Icons)", "mit_controllericons.txt"],
		["MIT (Onscreenkeyboard)", "mit_onscreenkeyboard.txt"],
		["MIT (Godot Accessibility Plugin)", "mit_godot-accessibility.txt"],
		["MIT (Godot-BlurHash)", "mit_godot-blurhash.txt"],
		["MIT (Games Icon)", "mit_games_icon.txt"],
		["CC0", "cc0.txt"],
		["CC BY 4.0", "ccby40.txt"],
		["CC BY NC SA 4.0", "ccbyncsa40.txt"],
		["Apache 2.0", "apache.txt"]
	]
	for license in license_files:
		var file := FileAccess.open(LICENSE_PATH + license[1], FileAccess.READ)
		if file:
			licenses[license[0]] = file.get_as_text()
			file.close()
		else:
			push_error("Error reading license file %s!" % LICENSE_PATH + license[1])

	# Populate tree
	root = n_names.create_item()
	for key in licenses:
		var child : TreeItem = n_names.create_item(root)
		child.set_text(0, key)
		child.set_autowrap_mode(0, TextServer.AUTOWRAP_WORD_SMART)

	if not root.get_children().is_empty():
		root.get_child(0).select(0)
		_on_Names_item_selected()

func _on_Names_item_selected():
	# FIXME: Text will be very slow until
	# https://github.com/godotengine/godot/pull/77280/ is merged
	var item : TreeItem = n_names.get_selected()
	n_content.text = licenses[item.get_text(0)]
	(n_content.get_parent() as ScrollContainer).scroll_vertical = 0

func select_license(license_key: String) -> bool:
	var license := convert_license_key(license_key)
	if license.is_empty():
		return false
	for child in root.get_children():
		if child.get_text(0) == license:
			child.select(0)
			_on_Names_item_selected()
			return true
	return false

func convert_license_key(key: String) -> String:
	match key:
		"lgpl3":
			return "LGPLv3"
		"mit_retrohub":
			return "MIT (RetroHub)"
		"mit_godot":
			return "MIT (Godot Engine)"
		"mit_eirteam_ffmpeg":
			return "MIT (EIRTeam.FFmpeg)"
		"mit_controllericons":
			return "MIT (Controller Icons)"
		"mit_onscreenkeyboard":
			return "MIT (Onscreenkeyboard)"
		"mit_godot-accessibility":
			return "MIT (Godot Accessibility Plugin)"
		"mit_godot-tts":
			return "MIT (Godot TTS)"
		"mit_godot-blurhash":
			return "MIT (Godot-BlurHash)"
		"mit_games_icon":
			return "MIT (Games Icon)"
		"cc0":
			return "CC0"
		"ccby40":
			return "CC BY 4.0"
		"ccbyncsa40":
			return "CC BY NC SA 4.0"
		"apache":
			return "Apache 2.0"
		_:
			return ""


func _on_Names_item_activated():
	if n_content.focus_mode == FOCUS_ALL:
		n_content.grab_focus()
