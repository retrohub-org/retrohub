extends Control

onready var n_metadata_icon := $"%MetadataIcon"
onready var n_metadata_status := $"%MetadataStatus"
onready var n_metadata_details := $"%MetadataDetails"

onready var n_media_icon := $"%MediaIcon"
onready var n_media_status := $"%MediaStatus"
onready var n_media_details := $"%MediaDetails"

onready var n_theme_icon := $"%ThemeIcon"
onready var n_theme_status := $"%ThemeStatus"
onready var n_theme_details := $"%ThemeDetails"

func set_importer_status(importer: RetroHubImporter):
	# Labels
	set_label(n_metadata_status, importer.get_metadata_compatibility_level())
	set_label(n_media_status, importer.get_media_compatibility_level())
	set_label(n_theme_status, importer.get_theme_compatibility_level())

	# Icons
	set_icon(n_metadata_icon, importer.get_metadata_compatibility_level())
	set_icon(n_media_icon, importer.get_media_compatibility_level())
	set_icon(n_theme_icon, importer.get_theme_compatibility_level())

	# Details
	n_metadata_details.text = importer.get_metadata_compatibility_level_description()
	n_media_details.text = importer.get_media_compatibility_level_description()
	n_theme_details.text = importer.get_theme_compatibility_level_description()

func set_label(node: Label, level: int):
	match level:
		RetroHubImporter.CompatibilityLevel.UNSUPPORTED:
			node.text = "Unsupported"
			node.add_color_override("font_color", RetroHubUI.color_error)
		RetroHubImporter.CompatibilityLevel.PARTIAL:
			node.text = "Partially supported"
			node.add_color_override("font_color", RetroHubUI.color_warning)
		RetroHubImporter.CompatibilityLevel.SUPPORTED:
			node.text = "Supported"
			node.add_color_override("font_color", RetroHubUI.color_success)

func set_icon(node: TextureRect, level: int):
	match level:
		RetroHubImporter.CompatibilityLevel.UNSUPPORTED:
			node.texture = preload("res://assets/icons/error.svg")
		RetroHubImporter.CompatibilityLevel.PARTIAL:
			node.texture = preload("res://assets/icons/warning.svg")
		RetroHubImporter.CompatibilityLevel.SUPPORTED:
			node.texture = preload("res://assets/icons/success.svg")

func tts_text(focused: Control) -> String:
	var text := ""
	# Game Metadata
	text += "Game Metadata: "
	text += n_metadata_status.text + ". "
	text += n_metadata_details.text + ". "
	# Game Media
	text += "Game Media: "
	text += n_media_status.text + ". "
	text += n_media_details.text + ". "
	# Game Theme
	text += "Existing themes: "
	text += n_theme_status.text + ". "
	text += n_theme_details.text + ". "
	
	return text
