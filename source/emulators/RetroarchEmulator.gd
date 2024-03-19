extends RetroHubGenericEmulator
class_name RetroHubRetroArchEmulator

static func get_custom_core_path() -> String:
	var corepath := RetroHubConfig._get_emulator_path("retroarch", "corepath")
	if not corepath.is_empty():
		return corepath

	var config_file := get_config_path()
	if config_file:
		var file := FileAccess.open(config_file.path_join("retroarch.cfg"), FileAccess.READ)
		if file:
			while file.get_position() < file.get_length():
				var line := file.get_line()
				if "libretro_directory" in line:
					var path := line.get_slice("=", 1).replace("\"", "").replace("'", "").strip_edges()
					path = FileUtils.expand_path(path)
					RetroHubConfig._set_emulator_path("retroarch", "corepath", path)
					return path
		return ""
	return ""

static func get_config_path() -> String:
	match FileUtils.get_os_id():
		FileUtils.OS_ID.WINDOWS:
			# RetroArch on Windows works as a "portable" installation. Config is located beside main files.
			# Try to find a valid binpath.
			var emulator : Dictionary = RetroHubConfig.emulators_map["retroarch"]
			var binpath := RetroHubRetroArchEmulator.find_path(emulator, "binpath", {})
			return binpath
		FileUtils.OS_ID.LINUX:
			# RetroArch uses either XDG_CONFIG_HOME or HOME.
			var xdg := OS.get_environment("XDG_CONFIG_HOME")
			if not xdg.is_empty():
				var path := xdg.path_join("retroarch")
				if DirAccess.dir_exists_absolute(path):
					return path
			else:
				# Default to HOME
				var path := FileUtils.get_home_dir().path_join(".config/retroarch")
				if DirAccess.dir_exists_absolute(path):
					return path
			return ""
		_:
			return ""

static func find_core_path(core_key: String, emulator_def: Dictionary, corepath: String) -> String:
	var path_key := "core_" + core_key
	var path := RetroHubConfig._get_emulator_path("retroarch", path_key)
	if not path.is_empty() and FileAccess.file_exists(corepath.path_join(path)):
		return path
	for core_info in emulator_def["cores"]:
		if core_info["name"] == core_key:
			var core_file : String = core_info["file"]
			var core_file_path : String = corepath.path_join(core_file)
			RetroHubConfig._set_emulator_path("retroarch", path_key, core_file)
			if FileAccess.file_exists(core_file_path):
				return core_file
	return ""

func _init(emulator_raw : Dictionary, game_data : RetroHubGameData, system_cores : Array):
	super(emulator_raw, game_data)
	var corepath := RetroHubRetroArchEmulator.get_custom_core_path()
	if corepath.is_empty():
		corepath = RetroHubRetroArchEmulator.find_path(emulator_raw, "corepath", _substitutes)
	var corefile : String
	_substitutes["corepath"] = corepath
	for core_name in system_cores:
		corefile = RetroHubRetroArchEmulator.find_core_path(core_name, emulator_raw, corepath)
		if not corefile.is_empty():
			break

	if not corefile.is_empty():
		_substitutes["corefile"] = corefile
		command = RetroHubRetroArchEmulator.substitute_str(command, _substitutes)
	else:
		print("Could not find valid core file for emulator \"%s\"" % game_data.system.name)
		command = ""
