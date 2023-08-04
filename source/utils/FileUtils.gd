extends Node

enum OS_ID {
	WINDOWS,
	MACOS,
	LINUX,
	UNSUPPORTED
}

# Finds the first file/folder that exists from the array of paths.
func test_for_valid_path(paths) -> String:
	if paths is String:
		var expanded_path := expand_path(paths)
		if DirAccess.dir_exists_absolute(expanded_path) or FileAccess.file_exists(expanded_path):
			return expanded_path
	if paths is Array:
		for path in paths:
			var expanded_path := expand_path(path)
			if DirAccess.dir_exists_absolute(expanded_path) or FileAccess.file_exists(expanded_path):
				return expanded_path
	return ""

func ensure_path(path: String):
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()):
		push_error("Failed to create directory %s" % path.get_base_dir())

func expand_path(path: String) -> String:
	# Replace ~ by home
	path = path.replace("~", get_home_dir())
	# If path is relative, add executable path
	if path.is_relative_path():
		path = OS.get_executable_path().get_base_dir().path_join(path)
	return path

func get_space_left() -> int:
	var dir := DirAccess.open(get_home_dir())
	if not dir:
		push_error("Failed to open home directory")
		return 0
	return dir.get_space_left()

func get_folder_size(path: String, filter_folders: Array = []) -> int:
	if not DirAccess.dir_exists_absolute(path):
		return -1
	var size := 0
	var dir := DirAccess.open(path)
	if dir and not dir.list_dir_begin() :# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := dir.get_next()
		while not next.is_empty():
			var fullpath := path.path_join(next)
			if dir.current_is_dir():
				if filter_folders.is_empty() or next in filter_folders:
					size += get_folder_size(fullpath)
			else:
				var file := FileAccess.open(fullpath, FileAccess.READ)
				if file:
					size += file.get_length()
					file.close()
				else:
					push_error("Failed to open file %s" % fullpath)
			next = dir.get_next()
	return size

func get_file_count(path: String, filter_folders: Array = []):
	if not DirAccess.dir_exists_absolute(path):
		return -1
	var count := 0
	var dir := DirAccess.open(path)
	if dir and not dir.list_dir_begin() :# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := dir.get_next()
		while not next.is_empty():
			if dir.current_is_dir():
				if filter_folders.is_empty() or next in filter_folders:
					count += get_file_count(path.path_join(next))
			else:
				count += 1
			next = dir.get_next()
	return count

func get_home_dir() -> String:
	match get_os_id():
		OS_ID.WINDOWS:
			# C:/Users/xxx/RetroHub
			var homedrive := OS.get_environment("HOMEDRIVE")
			var homepath := OS.get_environment("HOMEPATH")
			var path := homedrive + homepath
			# Replace \ with /
			path = path.replace('\\', '/')
			return path
		OS_ID.MACOS, OS_ID.LINUX:
			# ~/.retrohub
			return OS.get_environment("HOME")
		_:
			return ""

func get_os_id() -> int:
	match OS.get_name():
		"Windows", "UWP":
			return OS_ID.WINDOWS
		"macOS":
			return OS_ID.MACOS
		"Linux":
			return OS_ID.LINUX
		_:
			return OS_ID.UNSUPPORTED

func get_os_string() -> String:
	match OS.get_name():
		"Windows", "UWP":
			return "windows"
		"macOS":
			return "macos"
		"Linux":
			return "linux"
		_:
			return "null"

func is_steam_deck():
	return get_os_id() == OS_ID.LINUX and not OS.get_environment("SteamDeck").is_empty()
