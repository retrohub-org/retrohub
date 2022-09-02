extends RetroHubGenericEmulator
class_name RetroHubRetroArchEmulator

func _init(emulator_raw : Dictionary, game_data : RetroHubGameData, system_cores : Array).(emulator_raw, game_data):
	var corepath := find_and_substitute_str(emulator_raw["corepath"])
	var corefile : String
	_substitutes["corepath"] = corepath
	var dir = Directory.new()
	for core_name in system_cores:
		for core_info in emulator_raw["cores"]:
			if core_info["name"] == core_name:
				var core_file_path : String = corepath + "/" + core_info["file"]
				if dir.file_exists(core_file_path):
					corefile = core_info["file"]
					_substitutes["corefile"] = corefile
					break
		if not corefile.empty():
			break
	
	if not corefile.empty():
		command = substitute_str(command)
	else:
		print("Could not find valid core file for emulator \"%s\"" % game_data.system_name)
