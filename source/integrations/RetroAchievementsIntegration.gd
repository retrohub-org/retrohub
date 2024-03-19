extends RetroHubIntegration

class_name RetroAchievementsIntegration

const ConsoleMapping := {
	"genesis": 1,
	"n64": 2,
	"64dd": 2,
	"snes": 3,
	"satellaview": 3,
	"sufami": 3,
	"gb": 4,
	"gba": 5,
	"gbc": 6,
	"nes": 7,
	"fds": 7,
	"tg16": 8,
	"supergrafx": 8,
	"segacd": 9,
	"sega32x": 10,
	"mastersystem": 11,
	"psx": 12,
	"atarilynx": 13,
	"ngp": 14,
	"ngpc": 14,
	"gamegear": 15,
	"gc": 16,
	"atarijaguar": 17,
	"nds": 18,
	"wii": 19,
	"wiiu": 20,
	"ps2": 21,
	"xbox": 22,
	"odyssey2": 23,
	"pokemini": 24,
	"atari2600": 25,
	"dos": 26,
	"pc": 26,
	"arcade": 27,
	"atomiswave": 27,
	"naomi": 27,
	"naomigd": 27,
	"virtualboy": 28,
	"msx": 29,
	"c64": 30,
	"zx81": 31,
	"oric": 32,
	"sg-1000": 33,
	"multivision": 33,
	"vic20": 34,
	"amiga": 35,
	"amiga600": 35,
	"amiga1200": 35,
	"atarist": 36,
	"amstradcpc": 37,
	"gx4000": 37,
	"apple2": 38,
	"saturn": 39,
	"dreamcast": 40,
	"psp": 41,
	"cdimono1": 42,
	"3do": 43,
	"colecovision": 44,
	"intellivision": 45,
	"vectrex": 46,
	"pc88": 47,
	"pc98": 48,
	"pcfx": 49,
	"atari5200": 50,
	"atari7800": 51,
	"x68000": 52,
	"wonderswan": 53,
	"wonderswancolor": 53,
	"neogeocd": 56,
	"channelf": 57,
	"zxspectrum": 59,
	"gameandwatch": 60,
	"n3ds": 62,
	"x1": 64,
	"tic80": 65,
	"to8": 66,
	"tg-cd": 76,
	"atarijaguarcd": 77,
	"uzebox": 80,
}

class GameInfo:
	enum Error {
		OK, # All good
		ERR_INVALID_CRED, # Username/API key is invalid
		ERR_CONSOLE_NOT_SUPPORTED, # Console is not supported by RA
		ERR_GAME_NOT_FOUND, # Game not found
		ERR_NETWORK, # Generic network error
		ERR_INTERNAL # Generic internal error (RetroHub/Godot), should not happen: report it!
	}

	# Error code, if any.
	var err : GameInfo.Error = Error.OK

	# Game ID in RetroAchievements.
	var id : int

	# Available achievements in the game.
	var achievements : Array[Achievement]

	# How many players are registered to have played the game (in soft/hard mode).
	var player_count : int

	func parse_raw(data: Dictionary) -> void:
		if data.has("ID"):
			id = int(data["ID"])
		if data.has("Achievements") and data["Achievements"] is Dictionary:
			achievements = []
			for achievement_data in data["Achievements"].values():
				var achievement := Achievement.new()
				achievement.parse_raw(achievement_data)
				achievements.append(achievement)
		if data.has("NumDistinctPlayers"):
			player_count = int(data["NumDistinctPlayers"])

class Achievement:
	# Achievement ID in RetroAchievements.
	var id : int

	# Title of the achievement.
	var title : String

	# Description of the achievement.
	var description : String

	# Achievement type
	enum Type {
		NORMAL, # Regular achievement
		PROGRESSION, # Represents in-game progression
		WIN, # Is a win condition
		MISSABLE # Can be missed during gameplay
	}
	var type : Type

	# Whether the achievement is unlocked (in soft/hard mode).
	var unlocked : bool
	var unlocked_hard_mode : bool

	# How many players have unlocked the achievement in soft mode.
	var unlocked_count : int
	var unlocked_hard_mode_count : int

	var _icon_url : String

	func load_icon() -> Texture:
		var icon_path := RetroAchievementsIntegration.get_cheevos_dir().path_join("%s.png" % id)
		if FileAccess.file_exists(icon_path):
			var image := Image.load_from_file(icon_path)
			return ImageTexture.create_from_image(image)

		# Download icons
		var icon_url : String = _icon_url + ".png"
		var img := Image.new()
		img.load_png_from_buffer(await RetroAchievementsIntegration.Raw._make_asset_req(icon_url))
		if not img.is_empty():
			img.save_png(icon_path)
		return ImageTexture.create_from_image(img)

	func parse_raw(data: Dictionary) -> void:
		if data.has("ID"):
			id = int(data["ID"])
		if data.has("Title"):
			title = data["Title"]
		if data.has("Description"):
			description = data["Description"]
		if data.has("type"):
			match data["type"]:
				"progression":
					type = Type.PROGRESSION
				"win_condition":
					type = Type.WIN
				"missable":
					type = Type.MISSABLE
				_:
					type = Type.NORMAL
		unlocked = data.has("DateEarned")
		unlocked_hard_mode = data.has("DateEarnedHardcore")
		if data.has("NumAwarded"):
			unlocked_count = int(data["NumAwarded"])
		if data.has("NumAwardedHardcore"):
			unlocked_hard_mode_count = int(data["NumAwardedHardcore"])
		if data.has("BadgeName"):
			_icon_url = "Badge/%s" % data["BadgeName"]

class Raw extends Object:
	class Response:
		# Godot error. If not OK, some internal error ocurred when trying to make the request.
		var godot_error : int
		# HTTP response code. If not 200 (OK), the request failed.
		var response_code : int
		# Response; can be Dictionary or Array
		var body

	static var http : HTTPRequest
	static var curr_requests := 0
	
	static func _make_raw_req(url: String) -> Response:
		while curr_requests > 0:
			await http.request_completed
		var err := http.request(url, ["User-Agent: " + FileUtils.get_user_agent()])
		var response := Response.new()
		if err != OK:
			response.godot_error = err
			return response

		curr_requests += 1
		var req_data = await http.request_completed
		curr_requests -= 1

		# req_data = [result, response_code, headers, body]
		response.godot_error = req_data[0]
		response.response_code = req_data[1]

		# If we have an internal body, there is no response body at all
		if response.godot_error != OK:
			return response

		response.body = JSONUtils.load_json_buffer(req_data[3].get_string_from_utf8())

		return response
	
	static func _make_req(url: String, auth: Dictionary, data: Dictionary = {}) -> Response:
		var http_client := HTTPClient.new()
		data.merge(auth)
		var final_url = API_URL + url + "?" + http_client.query_string_from_dict(data)

		return await _make_raw_req(final_url)
	
	static func _make_asset_req(url: String) -> PackedByteArray:
		var final_url = MEDIA_API_URL + url

		while curr_requests > 0:
			await http.request_completed
		var err := http.request(final_url)
		if err != OK:
			return PackedByteArray()

		curr_requests += 1
		var req_data = await http.request_completed
		curr_requests -= 1

		# req_data = [result, response_code, headers, body]
		if req_data[0] == OK and req_data[1] == 200:
			return req_data[3]

		return PackedByteArray()

	static func _make_response_failed_params() -> Response:
		var response := Response.new()
		response.godot_error = ERR_INVALID_PARAMETER
		return response

	static func get_achievement_of_the_week(auth: Dictionary) -> Response:
		var url = "API_GetAchievementOfTheWeek.php"
		return await _make_req(url, auth)

	static func get_claims(auth: Dictionary, kind: String) -> Response:
		var url = "API_GetClaims.php"
		var data := {}
		match kind:
			"completed":
				data["k"] = 1
			"dropped":
				data["k"] = 2
			"expired":
				data["k"] = 3
			_:
				push_error("[RetroAchievements:get_claims] Invalid kind: " + kind)
				return _make_response_failed_params()
		return await _make_req(url, auth, data)

	static func get_active_claims(auth: Dictionary) -> Response:
		var url = "API_GetActiveClaims.php"
		return await _make_req(url, auth)

	static func get_top_ten_users(auth: Dictionary) -> Response:
		var url = "API_GetTopTenUsers.php"
		return await _make_req(url, auth)

	static func get_user_recent_achievements(auth: Dictionary, username: String, recent_minutes: int = 60) -> Response:
		var url = "API_GetUserRecentAchievements.php"
		var data = {
			"u": username,
			"m": recent_minutes
		}
		return await _make_req(url, auth, data)

	static func get_achievements_earned_between(auth: Dictionary, username: String, from_date: int, to_date: int) -> Response:
		var url = "API_GetAchievementsEarnedBetween.php"
		var data = {
			"u": username,
			"f": from_date,
			"t": to_date
		}
		return await _make_req(url, auth, data)

	static func get_achievements_earned_on_day(auth: Dictionary, username: String, on_date: String) -> Response:
		var url = "API_GetAchievementsEarnedOnDay.php"
		var data = {
			"u": username,
			"d": on_date
		}
		return await _make_req(url, auth, data)

	static func get_game_info_and_user_progress(auth: Dictionary, username: String, game_id: int) -> Response:
		var url = "API_GetGameInfoAndUserProgress.php"
		var data = {
			"g": game_id,
			"u": username
		}
		return await _make_req(url, auth, data)

	static func get_user_awards(auth: Dictionary, username: String) -> Response:
		var url = "API_GetUserAwards.php"
		var data = {
			"u": username
		}
		return await _make_req(url, auth, data)

	static func get_user_claims(auth: Dictionary, username: String) -> Response:
		var url = "API_GetUserClaims.php"
		var data = {
			"u": username
		}
		return await _make_req(url, auth, data)

	static func get_user_completed_games(auth: Dictionary, username: String) -> Response:
		var url = "API_GetUserCompletedGames.php"
		var data = {
			"u": username
		}
		return await _make_req(url, auth, data)

	static func get_user_game_rank_and_score(auth: Dictionary, username: String, game_id: int) -> Response:
		var url = "API_GetUserGameRankAndScore.php"
		var data = {
			"g": game_id,
			"u": username
		}
		return await _make_req(url, auth, data)

	static func get_user_points(auth: Dictionary, username: String) -> Response:
		var url = "API_GetUserPoints.php"
		var data = {
			"u": username
		}
		return await _make_req(url, auth, data)

	static func get_user_progress(auth: Dictionary, username: String, game_ids: Array[int]) -> Response:
		var url = "API_GetUserProgress.php"
		var data = {
			"u": username,
			"i": ",".join(game_ids)
		}
		return await _make_req(url, auth, data)

	static func get_user_recently_played_games(auth: Dictionary, username: String, count: int = 10, offset: int = 0) -> Response:
		var url = "API_GetUserRecentlyPlayedGames.php"
		var data = {
			"u": username,
			"c": count,
			"o": offset
		}
		return await _make_req(url, auth, data)

	static func get_user_summary(auth: Dictionary, username: String, recent_games_count: int = 0, recent_achievements_count: int = 5) -> Response:
		var url = "API_GetUserSummary.php"
		var data = {
			"u": username,
			"g": recent_games_count,
			"a": recent_achievements_count
		}
		return await _make_req(url, auth, data)

	static func get_achievement_count(auth: Dictionary, game_id: int) -> Response:
		var url = "API_GetAchievementCount.php"
		var data = {
			"i": game_id
		}
		return await _make_req(url, auth, data)

	static func get_achievement_distribution(auth: Dictionary, game_id: int) -> Response:
		var url = "API_GetAchievementDistribution.php"
		var data = {
			"i": game_id
		}
		return await _make_req(url, auth, data)

	static func get_game(auth: Dictionary, game_id: int) -> Response:
		var url = "API_GetGame.php"
		var data = {
			"i": game_id
		}
		return await _make_req(url, auth, data)

	static func get_game_extended(auth: Dictionary, game_id: int) -> Response:
		var url = "API_GetGameExtended.php"
		var data = {
			"i": game_id
		}
		return await _make_req(url, auth, data)

	static func get_game_rank_and_score(auth: Dictionary, game_id: int, type: String) -> Response:
		var url = "API_GetGameRankAndScore.php"
		var data = {
			"g": game_id,
		}
		match type:
			"latest-masters":
				data["t"] = 1
			"high-scores":
				data["t"] = 0
			_:
				push_error("[RetroAchievements:get_game_rank_and_score] Invalid type: " + type)
				return _make_response_failed_params()
		return await _make_req(url, auth, data)

	static func get_console_ids(auth: Dictionary) -> Response:
		var url = "API_GetConsoleIDs.php"
		return await _make_req(url, auth)

	static func get_game_list(auth: Dictionary, console_id: int, should_only_retrieve_games_with_achievements: bool = false, should_retrieve_game_hashes: bool = false) -> Response:
		var url = "API_GetGameList.php"
		var data = {
			"i": console_id,
			"f": 1 if should_only_retrieve_games_with_achievements else 0,
			"h": 1 if should_retrieve_game_hashes else 0
		}
		return await _make_req(url, auth, data)

	static func get_achievement_unlocks(auth: Dictionary, achievement_id: int, count: int = 50, offset: int = 0) -> Response:
		var url = "API_GetAchievementUnlocks.php"
		var data = {
			"a": achievement_id,
			"c": count,
			"o": offset
		}
		return await _make_req(url, auth, data)

const API_URL = "https://retroachievements.org/API/"
const MEDIA_API_URL = "https://media.retroachievements.org/"

var _api_username : String
var _api_key : String
var _api_needs_refetch := true

var _recent_hash_cache := false
var _game_info_cache := {}
var _achievement_cache := {}

static func is_available() -> bool:
	return RetroHubConfig.config.integration_rcheevos_enabled

static func get_cheevos_dir() -> String:
	return RetroHubConfig._get_config_dir().path_join("achievements")

static func get_cheevos_hash_cache_path() -> String:
	return get_cheevos_dir().path_join("_hash_cache.json")

func _ready() -> void:
	if not is_available():
		push_error("RetroAchievements integration is disabled. Use is_available() before instantiating.")
		queue_free()
		return

	if is_instance_valid(Raw.http):
		Raw.http.queue_free()
	Raw.http = HTTPRequest.new()
	Raw.http.accept_gzip = true
	Raw.http.timeout = 10
	add_child(Raw.http)

	FileUtils.ensure_dir(get_cheevos_dir())

func _download_hash_cache() -> int:
	var path := get_cheevos_hash_cache_path()
	var data : Dictionary = JSONUtils.load_json_file(path)
	var new_changes := false
	
	var response := await Raw._make_raw_req("https://retroachievements.org/dorequest.php?r=hashlibrary")
	if not _is_response_ok(response):
		if response.godot_error != 0:
			push_error("[RetroAchievements:_download_hash_cache] Internal Godot error: %d" % response.godot_error)
			return -GameInfo.Error.ERR_INTERNAL
		match response.response_code:
			401:
				return GameInfo.Error.ERR_INVALID_CRED
				_api_needs_refetch = true
			404:
				return GameInfo.Error.ERR_GAME_NOT_FOUND
			_:
				return GameInfo.Error.ERR_NETWORK

	var raw_data : Dictionary = response.body
	if raw_data.has("Success") and raw_data["Success"] and raw_data.has("MD5List"):
		for hash: String in raw_data["MD5List"].keys():
			var hash_key = hash[0].to_lower()
			if not data.has(hash_key):
				data[hash_key] = {}
			data[hash_key][hash.to_lower()] = int(raw_data["MD5List"][hash]) 
			new_changes = true
	
	if new_changes:
		JSONUtils.save_json_file(data, path)
	return GameInfo.Error.OK

func _get_id_from_hash(hash: String, system: String) -> int:
	if hash.is_empty(): return -GameInfo.Error.ERR_GAME_NOT_FOUND
	var path := get_cheevos_hash_cache_path()
	var data : Dictionary = JSONUtils.load_json_file(path)
	var hash_key = hash[0]
	if data.is_empty() or not data.has(hash_key):
		return -GameInfo.Error.ERR_GAME_NOT_FOUND
	var keys : Dictionary = data[hash_key]
	for key in keys.keys():
		if key == hash:
			return keys[key]
	return -GameInfo.Error.ERR_GAME_NOT_FOUND 

# Returns negative errcodes of GameInfo.Error values; positive values are valid game IDs
func _find_game_id(data: RetroHubGameData) -> int:
	var system_name = data.system.name
	if not ConsoleMapping.has(system_name):
		# Not supported by RetroAchievements
		return -GameInfo.Error.ERR_CONSOLE_NOT_SUPPORTED

	# Get file hash
	var game_hash := get_game_hash(data)
	print_verbose("[RetroAchievements:_find_game_id] Hash for %s: %s" % [data.path, game_hash])
	
	# Fetch from hash cache
	var game_id := _get_id_from_hash(game_hash, system_name)
	if game_id >= 0: return game_id
	
	# ID not found; cache may be outdated/unpopulated
	# If downloaded recently, then skip it. Extremely unlikely the game
	# appears now, and data is refetched on every reset.
	if _recent_hash_cache: return -GameInfo.Error.ERR_GAME_NOT_FOUND

	var errcode := await _download_hash_cache()
	if errcode != GameInfo.Error.OK:
		return -errcode
	_recent_hash_cache = true
	return _get_id_from_hash(game_hash, system_name)

func _download_game_info(data: RetroHubGameData) -> GameInfo:
	var game_info := GameInfo.new()
	var game_id := await _find_game_id(data)
	if game_id < 0:
		# Err codes are inverted because positive values represent valid IDs
		game_info.err = -game_id as GameInfo.Error
		return game_info

	var response : Raw.Response = await Raw.get_game_info_and_user_progress(build_auth(), _api_username, game_id)
	if not _is_response_ok(response):
		if response.godot_error != 0:
			push_error("[RetroAchievements:_download_game_info] Internal Godot error: %d" % response.godot_error)
			game_info.err = GameInfo.Error.ERR_INTERNAL
			return game_info
		match response.response_code:
			401:
				game_info.err = GameInfo.Error.ERR_INVALID_CRED
				_api_needs_refetch = true
			404:
				game_info.err = GameInfo.Error.ERR_GAME_NOT_FOUND
			_:
				game_info.err = GameInfo.Error.ERR_NETWORK
		return game_info

	game_info.parse_raw(response.body)
	_game_info_cache[data] = game_info
	return game_info

func _is_response_ok(response: Raw.Response) -> bool:
	return response.godot_error == OK and response.response_code == 200

func build_auth(reload_credentials: bool = false) -> Dictionary:
	if reload_credentials or _api_needs_refetch:
		_api_username = RetroHubConfig._get_credential("rcheevos_username")
		_api_key = RetroHubConfig._get_credential("rcheevos_api_key")
		_api_needs_refetch = false

	return {
		"z": _api_username,
		"y": _api_key
	}

func get_game_info(data: RetroHubGameData) -> GameInfo:
	if not _game_info_cache.has(data):
		return await _download_game_info(data)

	return _game_info_cache[data]

func get_game_hash(data: RetroHubGameData) -> String:
	if not ConsoleMapping.has(data.system.name):
		return ""
	return RCheevosHash.get_file_hash(data.path, ConsoleMapping[data.system.name])
