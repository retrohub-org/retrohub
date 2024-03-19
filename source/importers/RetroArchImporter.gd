extends RetroHubImporter

class_name RetroArchImporter

var config_path : String
var thumbnails_path : String
var playlists_path : String
var folder_size : int = -1

var game_datas := {}

const RA_MEDIA_NAMES := [
	"Named_Snaps", "Named_Titles"
]

const RH_MEDIA_NAMES := [
	"screenshot", "title-screen"
]

# Returns this importer name
func get_importer_name() -> String:
	return "RetroArch"

# Return this importer icon
func get_icon() -> Texture2D:
	return preload("res://assets/frontends/retroarch.png")

# Returns the compatibility level regarding existing game metadata.
# This one in particular must offer SUPPORTED or PARTIAL support.
# This is run after `is_available()`, so this method doesn't need to be
# static, and can change level depending on the existing configuration/version.
func get_metadata_compatibility_level() -> int:
	return CompatibilityLevel.PARTIAL

# Returns the compatibility level regarding existing game media
func get_media_compatibility_level() -> int:
	return CompatibilityLevel.SUPPORTED

# Returns the compatibility level regarding existing themes
func get_theme_compatibility_level() -> int:
	return CompatibilityLevel.UNSUPPORTED

# Returns a description/note to give more information about the
# game metadata compatibility level
func get_metadata_compatibility_level_description() -> String:
	return "Only game names. Remaining information will have to be scraped from RetroHub.\n\nWarning: RetroArch does not centralize game file locations, so no games will be copied. You will have to set the game folder location in the next step for RetroHub to find your games."

# Returns a description/note to give more information about the
# game media compatibility level
func get_media_compatibility_level_description() -> String:
	return "Only title screens and screenshots. Remaining media will have to be scraped from RetroHub."

# Returns a description/note to give more information about the
# theme compatibility level
func get_theme_compatibility_level_description() -> String:
	return "There's currently no wrapper for RetroArch themes."

# Returns the estimated size needed to copy the platform's data to RetroHub, in bytes.
# This will run in a thread, so avoid any unsafe-thread API
func get_estimated_size() -> int:
	if folder_size == -1:
		folder_size = 0
		var dir := DirAccess.open(thumbnails_path)
		if dir and not dir.list_dir_begin() :# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
			var next := dir.get_next()
			while not next.is_empty():
				if dir.current_is_dir() and guess_system_name(next) != "":
					folder_size += FileUtils.get_folder_size(thumbnails_path.path_join(next), RA_MEDIA_NAMES)
				next = dir.get_next()
	return folder_size

# Determines if this gaming library platform is available in the system
# As this may take some time to determine, this function will run in a
# thread. Therefore, you shouldn't use any unsafe-thread API, and limit
# to finding local files, reading content, and determining compatibility levels
func is_available() -> bool:
	var path := RetroHubRetroArchEmulator.get_config_path()
	if not path.is_empty():
		set_paths(path)
		return true
	return false

func set_paths(root: String):
	config_path = root
	thumbnails_path = config_path.path_join("thumbnails")
	playlists_path = config_path.path_join("playlists")

# Begins the import process. `copy` determines if the user wants
# to copy previous data and, therefore, not affect the other game library
# platform. This will be run in a thread, so avoid any unsafe-thread API
func begin_import(copy: bool):
	reset_major(3)
	progress_major("Importing game metadata")
	import_metadata()
	progress_major("Importing game media")
	import_media(copy)
	progress_major("Saving game data")
	save_game_data()
	progress_major("Finished")
	cleanup()

func import_metadata():
	reset_minor(0)
	var gamelists := {}
	var total_games := 0
	var dir := DirAccess.open(playlists_path)
	if dir and not dir.list_dir_begin() :# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := dir.get_next()
		while not next.is_empty():
			if not dir.current_is_dir() and next.to_lower().ends_with(".lpl"):
				var lpl_file := playlists_path.path_join(next)
				progress_minor("Reading gamedata from \"%s\"..." % next)
				var system_name := guess_system_name(next)
				if not system_name.is_empty():
					if gamelists.has(system_name):
						gamelists[system_name].append_array(process_lpl_file(lpl_file))
					else:
						gamelists[system_name] = process_lpl_file(lpl_file)
			next = dir.get_next()
	reset_minor(total_games)
	for system in gamelists.keys():
		var base_path := RetroHubConfig._get_gamelists_dir().path_join(system as String)
		FileUtils.ensure_path(base_path)
		for child in gamelists[system]:
			process_metadata(system, child)

func guess_system_name(file_name: String) -> String:
	# RetroArch saves system information in the file name as full name.
	# We have to try and match it to known entries
	# Entries sourced from https://github.com/libretro/libretro-database/blob/master/rdb
	match file_name.get_basename():
		"Amstrad - CPC":
			return "amstradcpc"
		"Amstrad - GX4000":
			return "gx4000"
		"Atari - 2600":
			return "atari2600"
		"Atari - 5200":
			return "atari5200"
		"Atari - 7800":
			return "atari7800"
		"Atari - 8-bit":
			return "atari800"
		"Atari - Jaguar":
			return "atarijaguar"
		"Atari - Lynx":
			return "atarilynx"
		"Atari - ST":
			return "atarist"
		"Atomiswave":
			return "atomiswave"
		"Bandai - WonderSwan Color":
			return "wonderswancolor"
		"Bandai - WonderSwan":
			return "wonderswan"
		"Cave Story":
			return "cavestory"
		"ChaiLove":
			return "chailove"
		"Coleco - ColecoVision":
			return "colecovision"
		"Commodore - 64":
			return "c64"
		"Commodore - Amiga":
			return "amiga"
		"Commodore - CD32":
			return "amigacd32"
		"Commodore - CDTV":
			return "cdtv"
		"Commodore - VIC-20":
			return "vic20"
		"DOOM":
			return "doom"
		"DOS":
			return "dos"
		"FBNeo - Arcade Games", "MAME 2000", "MAME 2003-Plus", "MAME 2003", \
		"MAME 2010", "MAME 2015", "MAME 2016", "MAME":
			return "arcade"
		"Fairchild - Channel F":
			return "channelf"
		"GCE - Vectrex":
			return "vectrex"
		"Infocom - Z-Machine":
			return "zmachine"
		"Lutro":
			return "lutro"
		"Magnavox - Odyssey2":
			return "odyssey2"
		"Mattel - Intellivision":
			return "intellivision"
		"Microsoft - MSX":
			return "msx"
		"Microsoft - MSX2":
			return "msx2"
		"Microsoft - Xbox":
			return "xbox"
		"NEC - PC Engine - TurboGrafx 16":
			return "tg16"
		"NEC - PC Engine CD - TurboGrafx-CD":
			return "tg-cd"
		"NEC - PC Engine SuperGrafx":
			return "supergrafx"
		"NEC - PC-98":
			return "pc98"
		"NEC - PC-FX":
			return "pcfx"
		"Nintendo - Family Computer Disk System":
			return "fds"
		"Nintendo - Game Boy Advance":
			return "gba"
		"Nintendo - Game Boy Color":
			return "gbc"
		"Nintendo - Game Boy":
			return "gb"
		"Nintendo - GameCube":
			return "gc"
		"Nintendo - Nintendo 3DS":
			return "n3ds"
		"Nintendo - Nintendo 64":
			return "n64"
		"Nintendo - Nintendo 64DD":
			return "n64dd"
		"Nintendo - Nintendo DS", "Nintendo - Nintendo DSi":
			return "ds"
		"Nintendo - Nintendo Entertainment System":
			return "nes"
		"Nintendo - Pokemon Mini":
			return "pokemini"
		"Nintendo - Satellaview":
			return "satellaview"
		"Nintendo - Sufami Turbo":
			return "sufami"
		"Nintendo - Super Nintendo Entertainment System":
			return "snes"
		"Nintendo - Virtual Boy":
			return "virtualboy"
		"Nintendo - Wii (Digital)", "Nintendo - Wii":
			return "wii"
		"Philips - CD-i":
			return "cdimono1"
		"Philips - Videopac+":
			return "videopac"
		"SNK - Neo Geo CD":
			return "neogeocd"
		"SNK - Neo Geo Pocket Color":
			return "ngpc"
		"SNK - Neo Geo Pocket":
			return "ngp"
		"ScummVM":
			return "scummvm"
		"Sega - 32X":
			return "sega32x"
		"Sega - Dreamcast":
			return "dreamcast"
		"Sega - Game Gear":
			return "gamegear"
		"Sega - Master System - Mark III":
			return "mastersystem"
		"Sega - Mega Drive - Genesis":
			return "genesis"
		"Sega - Mega-CD - Sega CD":
			return "segacd"
		"Sega - Naomi", "Sega - Naomi 2":
			return "naomi"
		"Sega - SG-1000":
			return "sg-1000"
		"Sega - Saturn":
			return "saturn"
		"Sharp - X1":
			return "x1"
		"Sharp - X68000":
			return "x68000"
		"Sinclair - ZX 81":
			return "zx81"
		"Sinclair - ZX Spectrum", "Sinclair - ZX Spectrum +3":
			return "zxspectrum"
		"Sony - PlayStation 2":
			return "ps2"
		"Sony - PlayStation 3", "Sony - PlayStation 3 (PSN)":
			return "ps3"
		"Sony - PlayStation Portable", "Sony - PlayStation Portable (PSN)":
			return "psp"
		"Sony - PlayStation Vita":
			return "psvita"
		"Sony - PlayStation":
			return "psx"
		"TIC-80":
			return "tic80"
		"The 3DO Company - 3DO":
			return "3do"
		"Thomson - MOTO":
			return "moto"
		"Uzebox":
			return "uzebox"
		_:
			return ""

func process_lpl_file(path: String) -> Array:
	# RetroArch 1.7.5 onwards saves data in JSON format.
	var json : Dictionary = JSONUtils.load_json_file(path)
	var names := []
	if not json.is_empty():
		if json.has("items"):
			for child in json["items"]:
				names.append({"name": child["label"], "path": child["path"]})
	else:
		# Deprecated format. File consists of 6-line chunks of information
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			while not file.eof_reached():
				var file_path := file.get_line()
				var file_name := file.get_line()
				names.push_back({"name": file_name, "path": file_path})
				for _i in range(4):
					file.get_line()
			file.close()
	return names

func process_metadata(system: String, dict: Dictionary):
	var game_data := RetroHubGameData.new()
	var root_path := RetroHubConfig.config.games_dir.path_join(system)
	game_data.has_metadata = true
	game_data.path = root_path.path_join(dict["path"].substr(2))
	progress_minor("Converting \"%s\" (\"%s\")" % [game_data.path.get_file(), system])
	if dict.has("name"):
		game_data.name = dict["name"]
	var short_path := system.path_join(game_data.path.get_file().get_basename())
	game_data.system_path = system
	game_datas[short_path] = game_data


func import_media(copy: bool):
	var count := 0
	var dir := DirAccess.open(thumbnails_path)
	if dir and not dir.list_dir_begin() :# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := dir.get_next()
		while not next.is_empty():
			if dir.current_is_dir() and guess_system_name(next) != "":
				count += FileUtils.get_file_count(thumbnails_path.path_join(next), RA_MEDIA_NAMES)
			next = dir.get_next()
	reset_minor(count)
	if not dir.list_dir_begin() :# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := dir.get_next()
		while not next.is_empty():
			if dir.current_is_dir():
				var system_name := guess_system_name(next)
				if not system_name.is_empty():
					var base_path := RetroHubConfig._get_gamemedia_dir().path_join(system_name)
					FileUtils.ensure_path(base_path)
					process_media_subfolder(thumbnails_path.path_join(next), system_name, copy)
			next = dir.get_next()

func process_media_subfolder(path: String, system: String, copy: bool):
	var dir := DirAccess.open(path)
	if dir and not dir.list_dir_begin() :# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := dir.get_next()
		while not next.is_empty():
			if dir.current_is_dir() and next in RA_MEDIA_NAMES:
				process_media(path.path_join(next), system, RH_MEDIA_NAMES[RA_MEDIA_NAMES.find(next)], copy)
			next = dir.get_next()

func process_media(path: String, system: String, media_name: String, copy: bool):
	var dir := DirAccess.open(path)
	if dir and not dir.list_dir_begin() :# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := dir.get_next()
		var base_path := RetroHubConfig._get_gamemedia_dir().path_join(system).path_join(media_name)
		while not next.is_empty():
			if not dir.current_is_dir():
				var from_path := path.path_join(next)
				# RetroHub uses game name for media names.
				var game_data := find_game_data_with_label(next.get_basename())
				if game_data:
					var to_path := base_path.path_join(game_data.path.get_file().get_basename() + "." + next.get_extension())
					FileUtils.ensure_path(to_path)
					if copy:
						progress_minor("Copying \"%s\" (\"%s\")" % [from_path.get_file(), system])
						if dir.copy(from_path, to_path):
							push_error("Failed to copy \"%s\" to \"%s\"" % [from_path, to_path])
					else:
						progress_minor("Moving \"%s\" (\"%s\")" % [from_path.get_file(), system])
						if dir.rename(from_path, to_path):
							push_error("Failed to move \"%s\" to \"%s\"" % [from_path, to_path])
					game_data.has_media = true
				next = dir.get_next()

func find_game_data_with_label(label: String) -> RetroHubGameData:
	for game_data in game_datas.values():
		if game_data.name == label:
			return game_data
	return null

func save_game_data():
	reset_minor(game_datas.size())
	for game_data in game_datas.values():
		progress_minor("Saving \"%s\" metadata" % game_data.name)
		if not RetroHubConfig._save_game_data(game_data, game_data.system_path, false):
			push_error("Failed to save game data for \"%s\"" % game_data.name)


func cleanup():
	game_datas.clear()
