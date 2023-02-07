extends Node

enum OS_ID {
	WINDOWS,
	MACOS,
	LINUX,
	UNSUPPORTED
}

# Finds the first file/folder that exists from the array of paths.
func test_for_valid_path(paths):
	var dir = Directory.new()
	if paths is String and (dir.dir_exists(paths) or dir.file_exists(paths)):
		return paths
	if paths is Array:
		for path in paths:
			if dir.dir_exists(path) or dir.file_exists(path):
				return path
	return ""

func ensure_path(path: String):
	var dir := Directory.new()
	dir.make_dir_recursive(path.get_base_dir())

func expand_path(path: String):
	path = path.replace("~", get_home_dir())
	return path

func get_space_left() -> int:
	var dir := Directory.new()
	dir.open(get_home_dir())
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
			var fullpath = path + "/" + next
			if dir.current_is_dir():
				if filter_folders.empty() or next in filter_folders:
					size += get_folder_size(fullpath)
			else:
				file.open(fullpath, File.READ)
				size += file.get_len()
				file.close()
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
			var path = homedrive + homepath
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
