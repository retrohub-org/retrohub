extends EmulationStationImporter

class_name ESDEImporter

func _init():
	config_path = FileUtils.get_home_dir() + "/ES-DE"
	media_path = config_path + "/downloaded_media"
	gamelists_path = config_path + "/gamelists"
	config_file_path = config_path + "/settings/es_settings.xml"

# Returns this importer name
func get_importer_name() -> String:
	return "ES-DE"

# Return this importer icon
func get_icon() -> Texture2D:
	return preload("res://assets/frontends/es-de.png")

# Returns the compatibility level regarding existing game metadata.
# This one in particular must offer SUPPORTED or PARTIAL support.
# This is run after `is_available()`, so this method doesn't need to be
# static, and can change level depending on the existing configuration/version.
func get_metadata_compatibility_level() -> int:
	return CompatibilityLevel.SUPPORTED

# Returns the compatibility level regarding existing game media
func get_media_compatibility_level() -> int:
	return CompatibilityLevel.SUPPORTED

# Returns the compatibility level regarding existing themes
func get_theme_compatibility_level() -> int:
	return CompatibilityLevel.UNSUPPORTED

# Returns a description/note to give more information about the
# game metadata compatibility level
func get_metadata_compatibility_level_description() -> String:
	return "Age ratings will have to be scraped from RetroHub."

# Returns a description/note to give more information about the
# game media compatibility level
func get_media_compatibility_level_description() -> String:
	return "Game box and physical support textures, used in 3D models, will have to be scraped from RetroHub."

# Returns a description/note to give more information about the
# theme compatibility level
func get_theme_compatibility_level_description() -> String:
	return "ES-DE themes are not supported."
