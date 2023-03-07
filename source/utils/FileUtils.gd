extends Node

enum OS_ID {
	WINDOWS,
	MACOS,
	LINUX,
	UNSUPPORTED
}

# Finds the first file/folder that exists from the array of paths.
func test_for_valid_path(paths) -> String:
	var dir := Directory.new()
	if paths is String:
		var expanded_path := expand_path(paths)
		if dir.dir_exists(expanded_path) or dir.file_exists(expanded_path):
			return expanded_path
	if paths is Array:
		for path in paths:
			var expanded_path := expand_path(path)
			if dir.dir_exists(expanded_path) or dir.file_exists(expanded_path):
				return expanded_path
	return ""

func ensure_path(path: String):
	var dir := Directory.new()
	if dir.make_dir_recursive(path.get_base_dir()):
		push_error("Failed to create directory %s" % path.get_base_dir())

func expand_path(path: String) -> String:
	# Replace ~ by home
	path = path.replace("~", get_home_dir())
	# If path is relative, add executable path
	if path.is_rel_path():
		path = OS.get_executable_path().get_base_dir().plus_file(path)
	return path

func get_space_left() -> int:
	var dir := Directory.new()
	if dir.open(get_home_dir()):
		push_error("Failed to open home directory")
		return 0
	return dir.get_space_left()

func get_folder_size(path: String, filter_folders: Array = []) -> int:
	var dir := Directory.new()
	if not dir.dir_exists(path):
		return -1
	var size := 0
	var file := File.new()
	if not dir.open(path) and not dir.list_dir_begin(true):
		var next := dir.get_next()
		while not next.empty():
			var fullpath := path + "/" + next
			if dir.current_is_dir():
				if filter_folders.empty() or next in filter_folders:
					size += get_folder_size(fullpath)
			else:
				if not file.open(fullpath, File.READ):
					size += file.get_len()
					file.close()
				else:
					push_error("Failed to open file %s" % fullpath)
			next = dir.get_next()
	return size

func get_file_count(path: String, filter_folders: Array = []):
	var dir := Directory.new()
	if not dir.dir_exists(path):
		return -1
	var count := 0
	if not dir.open(path) and not dir.list_dir_begin(true):
		var next := dir.get_next()
		while not next.empty():
			if dir.current_is_dir():
				if filter_folders.empty() or next in filter_folders:
					count += get_file_count(path + "/" + next)
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
		"OSX":
			return OS_ID.MACOS
		"X11":
			return OS_ID.LINUX
		_:
			return OS_ID.UNSUPPORTED

func get_os_string() -> String:
	match OS.get_name():
		"Windows", "UWP":
			return "windows"
		"OSX":
			return "macos"
		"X11":
			return "linux"
		_:
			return "null"
