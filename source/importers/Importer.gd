extends Node

class_name RetroHubImporter

# Signals a major step in the import process (for example, metadata; media; themes; etc...)
#warning-ignore:unused_signal
signal import_major_step(curr, total, description)
# Signals a minor step in the import process (for example, individual files)
#warning-ignore:unused_signal
signal import_minor_step(curr, total, description)

var progress_major_curr := 0
var progress_major_total := 0
var progress_minor_curr := 0
var progress_minor_total := 0

enum CompatibilityLevel {
	UNSUPPORTED,
	PARTIAL,
	SUPPORTED
}

# Returns this importer name
func get_name() -> String:
	return "null"

# Return this importer icon
func get_icon() -> Texture:
	return null

# Returns the compatibility level regarding existing game metadata.
# This one in particular must offer SUPPORTED or PARTIAL support.
# This is run after `is_available()`, so this method doesn't need to be
# static, and can change level depending on the existing configuration/version.
func get_metadata_compatibility_level() -> int:
	return CompatibilityLevel.SUPPORTED

# Returns the compatibility level regarding existing game media.
# This is run after `is_available()`, so this method doesn't need to be
# static, and can change level depending on the existing configuration/version.
func get_media_compatibility_level() -> int:
	return CompatibilityLevel.UNSUPPORTED

# Returns the compatibility level regarding existing themes.
# This is run after `is_available()`, so this method doesn't need to be
# static, and can change level depending on the existing configuration/version.
func get_theme_compatibility_level() -> int:
	return CompatibilityLevel.UNSUPPORTED

# Returns a description/note to give more information about the
# game metadata compatibility level
func get_metadata_compatibility_level_description() -> String:
	match get_metadata_compatibility_level():
		CompatibilityLevel.SUPPORTED:
			return "All game metadata information can be re-used."
		CompatibilityLevel.PARTIAL, _:
			return "Some game metadata information can be re-used."

# Returns a description/note to give more information about the
# game media compatibility level
func get_media_compatibility_level_description() -> String:
	match get_media_compatibility_level():
		CompatibilityLevel.PARTIAL:
			return "Some game media files can be re-used."
		CompatibilityLevel.SUPPORTED:
			return "All game media files can be re-used."
		CompatibilityLevel.UNSUPPORTED, _:
			return "No game media files can be re-used."

# Returns a description/note to give more information about the
# theme compatibility level
func get_theme_compatibility_level_description() -> String:
	match get_theme_compatibility_level():
		CompatibilityLevel.PARTIAL:
			return "Themes under this platform can be partially used under a wrapper."
		CompatibilityLevel.SUPPORTED:
			return "Themes under this platform can be totally used under a wrapper."
		CompatibilityLevel.UNSUPPORTED, _:
			return "Themes under this platform cannot be used as there's no wrapper for it."

# Returns the estimated size needed to copy the platform's data to RetroHub, in bytes.
# This will run in a thread, so avoid any unsafe-thread API
func get_estimated_size() -> int:
	return 0


# Determines if this gaming library platform is available in the system
# As this may take some time to determine, this function will run in a
# thread. Therefore, you shouldn't use any unsafe-thread API, and limit
# to finding local files, reading content, and determining compatibility levels
func is_available() -> bool:
	return false


# Resets progress indicators
func reset_major(total: int):
	progress_major_curr = 0
	progress_major_total = total

func reset_minor(total: int):
	progress_minor_curr = 0
	progress_minor_total = total

# Increases progress on major task, emitting a signal
func progress_major(description: String):
	call_deferred("emit_signal","import_major_step", progress_major_curr, progress_major_total, description)
	progress_major_curr += 1

# Increases progress on minor task, emitting a signal
func progress_minor(description: String):
	call_deferred("emit_signal", "import_minor_step", progress_minor_curr, progress_minor_total, description)
	progress_minor_curr += 1


# Begins the import process. `copy` determines if the user wants
# to copy previous data and, therefore, not affect the other game library
# platform. This will be run in a thread, so avoid any unsafe-thread API
func begin_import(_copy: bool):
	pass
