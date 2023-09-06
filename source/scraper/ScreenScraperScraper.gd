extends RetroHubScraper
class_name RetroHubScreenScraperScraper

class RequestDetails:
	enum Type {
		DATA,
		MEDIA
	}
	var game_data : RetroHubGameData
	var url : String
	var type : int
	var data

	var _http := HTTPRequest.new()
	var _req_result : int
	var _req_response_code : int
	var _req_headers : PackedStringArray
	var _req_body : PackedByteArray

	func _init():
		#warning-ignore:return_value_discarded
		_http.request_completed.connect(_on_request_completed)
		_http.use_threads = true
		_http.timeout = 10

	func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		_req_result = result
		_req_response_code = response_code
		_req_headers = headers
		_req_body = body

	func is_ok():
		return not _req_result and _req_response_code == HTTPClient.RESPONSE_OK

	func perform_request(big: bool):
		_http.download_chunk_size = 1024 * 1024 # 1MB
		if big:
			_http.download_chunk_size *= 4 # 4MB
		if _http.request(url):
			push_error("Failed to perform request [ScreenScraper]")
			cancel()

	func is_content_on_body(content: String):
		return content in _req_body.get_string_from_utf8()

	func cancel():
		_http.cancel_request()
		_http.emit_signal("request_completed", -1, 0, PackedStringArray(), PackedByteArray())

var MAX_REQUESTS := 2
var _checked_user_threads := false

var _req_semaphore := Semaphore.new()

var _cached_requests_data := {}
var _cached_search_data := {}
var _pending_requests := {}
var _curr_requests := {}

var ss_system_map := {
	"megadrive": 1,
	"genesis": 1,
	"mastersystem": 2,
	"nes": 3,
	"famicom": 3,
	"snes": 4,
	"sfc": 4,
	"gb": 9,
	"gbc": 10,
	"virtualboy": 11,
	"gba": 12,
	"gc": 13,
	"n64": 14,
	"nds": 15,
	"wii": 16,
	"n3ds": 17,
	"wiiu": 18,
	"sega32x": 19,
	"segacd": 20,
	"gamegear": 21,
	"saturn": 22,
	"saturnjp": 22,
	"dreamcast": 23,
	"ngp": 25,
	"atari2600": 26,
	"atarijaguar": 27,
	"atarilynx": 28,
	"3do": 29,
	"tg16": 31,
	"pcengine": 31,
	"xbox": 32,
	"xbox360": 33,
	"bbcmicro": 37,
	"atari5200": 40,
	"atari7800": 41,
	"atarist": 42,
	"atari800": 43,
	"atarixe": 43,
	"astrocade": 44,
	"wonderswan": 45,
	"wonderswancolor": 46,
	"colecovision": 48,
	"daphne": 49,
	"gameandwatch": 52,
	"atomiswave": 53,
	"naomi": 56,
	"psx": 57,
	"ps2": 58,
	"ps3": 59,
	"psp": 61,
	"psvita": 62,
	"amiga": 64,
	"amiga600": 64,
	"amstradcpc": 65,
	"c64": 66,
	"neogeocd": 70,
	"neogeocdjp": 70,
	"pcfx": 72,
	"vic20": 73,
	"fba": 75,
	"fbneo": 75,
	"mame": 75,
	"arcade": 75,
	"zxspectrum": 76,
	"zx81": 77,
	"x68000": 79,
	"channelf": 80,
	"ngpc": 82,
	"apple2": 86,
	"gx4000": 87,
	"dragon32": 91,
	"tanodragon": 91,
	"vectrex": 102,
	"videopac": 104,
	"odyssey2": 104,
	"supergrafx": 105,
	"fds": 106,
	"satellaview": 107,
	"sufami": 108,
	"sg-1000": 109,
	"multivision": 109,
	"amiga1200": 111,
	"msx": 113,
	"tg-cd": 114,
	"pcenginecd": 114,
	"intellivision": 115,
	"msx2": 116,
	"msxturbor": 118,
	"64dd": 122,
	"scummvm": 123,
	"cdtv": 129,
	"amigacd32": 130,
	"oric": 131,
	"cdimono1": 133,
	"dos": 135,
	"pc": 135,
	"moto": 141,
	"to8": 141,
	"neogeo": 142,
	"trs-80": 144,
	"coco": 144,
	"macintosh": 146,
	"atarijaguarcd": 171,
	"ti99": 205,
	"lutro": 206,
	"pc98": 208,
	"pokemini": 211,
	"samcoupe": 213,
	"openbor": 214,
	"zmachine": 215,
	"uzebox": 216,
	"apple2gs": 217,
	"spectravideo": 218,
	"palm": 219,
	"x1": 220,
	"pc88": 221,
	"tic80": 222,
	"solarus": 223,
	"switch": 225,
	"naomigd": 227,
	"pico8": 234
}

var ss_api_user := [54, 216, 224, 9, 206, 207, 228, 99, 31, 99, 210, 57, 90, 50, 134, 250, 114, 82, 96, 136, 218, 83, 226, 212, 175, 48, 253, 169, 64, 71, 72, 107]
var ss_api_pass := [71, 95, 154, 207, 11, 9, 22, 151, 98, 61, 166, 108, 167, 182, 2, 14, 85, 140, 162, 234, 59, 77, 43, 88, 56, 223, 107, 166, 4, 85, 80, 143]
var ss_api_key := [40, 206, 49, 126, 206, 20, 187, 83, 105, 247, 33, 92, 90, 52, 228, 239, 20, 99, 152, 152, 145, 15, 111, 98, 195, 92, 191, 67, 254, 178, 251, 215]
var ss_api_scr := [11, 8, 17, 25, 14, 24, 7, 3, 4, 6, 10, 23, 15, 30, 21, 16, 18, 12, 5, 19, 27, 20, 26, 9, 31, 1, 13, 2, 0, 29, 22, 28]

func ss_get_api_keys(buf: Array, flag: bool) -> String:
	var _r := ""
	for val in ss_api_scr:
		var v = buf[31 - val if flag else val] ^ ss_api_key[val]
		if v:
			_r += char(v)
		else:
			break
	return _r

func ss_add_user_account(header_data: Dictionary):
	if RetroHubConfig.config.scraper_ss_use_custom_account:
		header_data["ssid"] = RetroHubConfig._get_credential("scraper_ss_username")
		header_data["sspassword"] = RetroHubConfig._get_credential("scraper_ss_password")

func get_ss_system_mapping(system_name) -> int:
	if ss_system_map.has(system_name):
		return ss_system_map[system_name]
	return -1

func _send_user_threads(threads_owner: String):
	return "Using %d thread%s (%s quota)" % [
		MAX_REQUESTS,
		"s" if MAX_REQUESTS > 1 else "",
		threads_owner
	]

func _init():
	for __ in range(MAX_REQUESTS):
		#warning-ignore:return_value_discarded
		_req_semaphore.post()

func _process(_delta):
	if not _pending_requests.is_empty():
		var game_data : RetroHubGameData = _pending_requests.keys()[0]
		var req : RequestDetails = _pending_requests[game_data].pop_front()
		if _pending_requests[game_data].is_empty():
			#warning-ignore:return_value_discarded
			_pending_requests.erase(game_data)
		if _curr_requests.has(game_data):
			_curr_requests[game_data].push_back(req)
		else:
			_curr_requests[game_data] = [req]

		if not req._http.is_inside_tree():
			await get_tree().process_frame
		req.perform_request(req.type == RequestDetails.Type.MEDIA)
		await req._http.request_completed
		#warning-ignore:return_value_discarded
		_req_semaphore.post()

		# If request got canceled, exit early
		if not _curr_requests.has(game_data):
			return
		_curr_requests[game_data].erase(req)
		if _curr_requests[game_data].is_empty():
			#warning-ignore:return_value_discarded
			_curr_requests.erase(game_data)

		if req.is_ok():
			match req.type:
				RequestDetails.Type.DATA:
					_process_req_meta(req)
					_process_req_data(req, game_data)
				RequestDetails.Type.MEDIA:
					_process_req_media(req, game_data)
		else:
			var details
			if req._req_response_code:
				# Game not found
				if req._req_response_code == HTTPClient.RESPONSE_NOT_FOUND:
					match req.type:
						RequestDetails.Type.DATA:
							call_thread_safe("emit_signal", "game_scrape_not_found", game_data)
						RequestDetails.Type.MEDIA:
							call_thread_safe("emit_signal", "media_scrape_not_found", game_data, req.data["type"])
					return
				# API limit reached
				elif req._req_response_code == 430 and req.is_content_on_body("Votre quota de scrape est dépassé"):
					details = "The ScreenScraper API quota limit was reached for today. You will need to use your own account to bypass this limit.\n\nIf the issue persists, please try another scraper service or wait until tomorrow to use ScreenScraper again."
				# Something else
				else:
					details = "HTTP Error: " + str(req._req_response_code) + "\nRaw Content:" + req._req_body.get_string_from_utf8()
			else:
				match req._req_result:
					HTTPRequest.RESULT_CANT_CONNECT, HTTPRequest.RESULT_CANT_RESOLVE:
						# Couldn't connect to API. It might be down, or the user has no internet
						details = "Can't connect to service. Check your internet connection, and check if the service is up at http://screenscraper.fr/"
					HTTPRequest.RESULT_TIMEOUT:
						# Timeout
						details = "The service took too much time to answer. This might be due to a slow/unreliable internet connection, or the service is too busy."
					-1:
						# Request was canceled
						details = "Canceled by user"
			match req.type:
				RequestDetails.Type.DATA:
					call_thread_safe("emit_signal", "game_scrape_error", game_data, details)
				RequestDetails.Type.MEDIA:
					call_thread_safe("emit_signal", "media_scrape_error", game_data, req.data["type"], details)

func _process_req_meta(req: RequestDetails):
	# Num of threads will not change during scraping, we only have to check this once
	if _checked_user_threads:
		return

	# If custom accounts are disabled, return
	if not RetroHubConfig.config.scraper_ss_use_custom_account:
		_checked_user_threads = true
		call_thread_safe("emit_signal", "scraper_details", _send_user_threads("RetroHub"))
		return

	# Handle growth/shrink in threads
	var json_raw = JSONUtils.load_json_buffer(req._req_body.get_string_from_utf8())
	if json_raw:
		# Preprocess json a bit due to ScreenScraper structure
		json_raw = json_raw["response"]
		if json_raw.has("ssuser") and json_raw["ssuser"].has("maxthreads"):
			_checked_user_threads = true
			# Ensure user is really logged in
			if json_raw["ssuser"].has("numid") and json_raw["ssuser"]["numid"] == "0":
				_checked_user_threads = true
				call_thread_safe("emit_signal", "scraper_details", _send_user_threads("Credentials failed; using RetroHub"))
				return
			var max_threads := int(json_raw["ssuser"]["maxthreads"])
			if RetroHubConfig.config.scraper_ss_max_threads > 0:
				max_threads = int(min(max_threads, RetroHubConfig.config.scraper_ss_max_threads))
			if max_threads <= 0:
				return
			if max_threads > MAX_REQUESTS:
				for __ in range(max_threads - MAX_REQUESTS):
					#warning-ignore:return_value_discarded
					_req_semaphore.post()
				MAX_REQUESTS = max_threads
			elif max_threads < MAX_REQUESTS:
				for __ in range(MAX_REQUESTS - max_threads):
					#warning-ignore:return_value_discarded
					_req_semaphore.wait()
				MAX_REQUESTS = max_threads
			call_thread_safe("emit_signal", "scraper_details", _send_user_threads("user"))

func _process_req_data(req: RequestDetails, game_data: RetroHubGameData):
	var json_raw = JSONUtils.load_json_buffer(req._req_body.get_string_from_utf8())
	if json_raw.is_empty():
		var details := req._req_body.get_string_from_utf8()
		call_thread_safe("emit_signal", "game_scrape_error", game_data, details)
	else:
		# Preprocess json a bit due to ScreenScraper structure
		json_raw = json_raw["response"]
		# If game has only one game, it has key "jeu", otherwise has key "jeux"
		if json_raw.has("jeu"):
			json_raw = json_raw["jeu"]
			# Even if ScreenScraper answered correctly, it might not have matched by hash but by name instead.
			# Ensure the hash is here
			if _is_hash_in_response(json_raw, req.data):
				_process_raw_game_data(json_raw, game_data)
				_cached_requests_data[game_data] = json_raw
				call_thread_safe("emit_signal", "game_scrape_finished", game_data)
			else:
				call_thread_safe("emit_signal", "game_scrape_not_found", game_data)
		else:
			json_raw = json_raw["jeux"]
			var details := []
			_cached_search_data[game_data] = {}
			for child in json_raw:
				if not child.is_empty():
					var game_data_tmp := RetroHubGameData.new()
					game_data_tmp.system = game_data.system
					game_data_tmp.path = game_data.path
					game_data_tmp.system_path = game_data.system_path
					_process_raw_game_data(child, game_data_tmp)
					_cached_search_data[game_data][game_data_tmp] = child
					details.push_back(game_data_tmp)

			call_thread_safe("emit_signal", "game_scrape_multiple_available", game_data, details)

func _process_req_media(req: RequestDetails, game_data):
	var extension : String = req.data["format"]
	var type : int = req.data["type"]
	call_thread_safe("emit_signal", "media_scrape_finished", game_data, type, req._req_body, extension)

func _new_request_details(game_data: RetroHubGameData) -> RequestDetails:
	var req := RequestDetails.new()
	call_thread_safe("add_child", req._http)
	if _pending_requests.has(game_data):
		_pending_requests[game_data].push_back(req)
	else:
		_pending_requests[game_data] = [req]
	return req

func scrape_game_by_hash(game_data: RetroHubGameData, type: int = RequestDetails.Type.DATA) -> int:
	if _cached_requests_data.has(game_data):
		var json : Dictionary = _cached_requests_data[game_data]
		_process_raw_game_data(json, game_data)
		call_thread_safe("emit_signal", "game_scrape_finished", game_data)
		return OK
	
	if not _checked_user_threads:
		call_thread_safe("emit_signal", "scraper_details", "Querying threads...")

	# If file is too big, we must fail
	var file := FileAccess.open(game_data.path, FileAccess.READ)
	if not file:
		push_error("Couldn't open file " + game_data.path)
		call_thread_safe("emit_signal", "game_scrape_not_found", game_data)
		return ERR_CANT_OPEN
	
	var max_size := RetroHubConfig.config.scraper_hash_file_size
	if max_size > 0 and file.get_length() > max_size * 1024 * 1024:
		call_thread_safe("emit_signal", "game_scrape_not_found", game_data)
		return FAILED

	#warning-ignore:return_value_discarded
	_req_semaphore.wait()

	# Compute game's hash
	var md5 := FileAccess.get_md5(game_data.path)

	var header_data := {
		"devid": ss_get_api_keys(ss_api_user, false),
		"devpassword": ss_get_api_keys(ss_api_pass, true),
		"softname": "RetroHub",
		"output": "json",
		"romtype": "rom",
		"md5": md5,
		"systemeid": str(get_ss_system_mapping(game_data.system.name)),
		"romnom": game_data.path.get_file(),
		"romtaille": str(file.get_length())
	}

	ss_add_user_account(header_data)
	file.close()

	var http_client := HTTPClient.new()

	var req := _new_request_details(game_data)
	req.type = type
	req.url = "https://www.screenscraper.fr/api2/jeuInfos.php?" + http_client.query_string_from_dict(header_data)
	req.data = md5
	return OK


func scrape_game_by_search(game_data: RetroHubGameData, search_term: String, type: int = RequestDetails.Type.DATA) -> int:
	if _cached_requests_data.has(game_data):
		var json : Dictionary = _cached_requests_data[game_data]
		_process_raw_game_data(json, game_data)
		call_thread_safe("emit_signal", "game_scrape_finished", game_data)
		return OK

	#warning-ignore:return_value_discarded
	_req_semaphore.wait()

	var header_data := {
		"devid": ss_get_api_keys(ss_api_user, false),
		"devpassword": ss_get_api_keys(ss_api_pass, true),
		"softname": "RetroHub",
		"output": "json",
		"systemeid": str(get_ss_system_mapping(game_data.system.name)),
		"recherche": search_term
	}
	ss_add_user_account(header_data)

	var http_client := HTTPClient.new()

	var req := _new_request_details(game_data)
	req.type = type
	req.url = "https://www.screenscraper.fr/api2/jeuRecherche.php?" + http_client.query_string_from_dict(header_data)
	return OK

func scrape_media(game_data: RetroHubGameData, media_type: int) -> int:
	var scraper_names : Array
	match media_type:
		RetroHubMedia.Type.LOGO:
			scraper_names = ["wheel-hd", "wheel"]
		RetroHubMedia.Type.SCREENSHOT:
			scraper_names = ["ss"]
		RetroHubMedia.Type.TITLE_SCREEN:
			scraper_names = ["sstitle"]
		RetroHubMedia.Type.VIDEO:
			scraper_names = ["video"]
		RetroHubMedia.Type.BOX_RENDER:
			scraper_names = ["box-3D"]
		RetroHubMedia.Type.BOX_TEXTURE:
			scraper_names = ["box-texture"]
		RetroHubMedia.Type.SUPPORT_RENDER:
			scraper_names = ["support-2D"]
		RetroHubMedia.Type.SUPPORT_TEXTURE:
			scraper_names = ["support-texture"]
		RetroHubMedia.Type.MANUAL:
			scraper_names = ["manuel"]
		_:
			return FAILED

	var json : Dictionary = {}
	if _cached_requests_data.has(game_data):
		json = _cached_requests_data[game_data]
	else:
		for data in _cached_search_data:
			if _cached_search_data[data].has(game_data):
				json = _cached_search_data[data][game_data]
				break
		if json.is_empty():
			# App is guaranteed to scrape data before media, so something is wrong
			push_error("\t Internal error: need to scrape metadata first!")
			return FAILED

	var medias_raw : Array = json["medias"]
	var scrape := find_all_by_key(medias_raw, "type", scraper_names)
	if scrape.is_empty():
		return FAILED
	var res := extract_json_region(scrape)

	#warning-ignore:return_value_discarded
	_req_semaphore.wait()

	var req := _new_request_details(game_data)
	req.type = RequestDetails.Type.MEDIA
	req.url = res["url"]
	req.data = {"format": res["format"], "type": media_type}
	return OK

func scrape_media_from_search(orig_game_data: RetroHubGameData, search_game_data: RetroHubGameData, media_type: int):
	if _cached_search_data.has(orig_game_data):
		_cached_requests_data[orig_game_data] = _cached_search_data[orig_game_data][search_game_data]
		#warning-ignore:return_value_discarded
		_cached_search_data.erase(orig_game_data)

	return scrape_media(orig_game_data, media_type)

func scrape_completed(game_data: RetroHubGameData) -> void:
	#warning-ignore:return_value_discarded
	_cached_requests_data.erase(game_data)
	#warning-ignore:return_value_discarded
	_cached_search_data.erase(game_data)

func cancel(game_data: RetroHubGameData) -> void:
	# Cancel current requests
	if _curr_requests.has(game_data):
		for req in _curr_requests[game_data]:
			req.cancel()
		#warning-ignore:return_value_discarded
		_curr_requests.erase(game_data)

	# Cancel pending requests
	if _pending_requests.has(game_data):
		for __ in range(_pending_requests[game_data].size()):
			#warning-ignore:return_value_discarded
			_req_semaphore.post()
		#warning-ignore:return_value_discarded
		_pending_requests.erase(game_data)

func cancel_all() -> void:
	# Cancel current requests
	for game_data in _curr_requests:
		for req in _curr_requests[game_data]:
			req.cancel()
	_curr_requests.clear()

	# Cancel pending requests
	_pending_requests.clear()
	_req_semaphore = Semaphore.new()
	for __ in range(MAX_REQUESTS):
		#warning-ignore:return_value_discarded
		_req_semaphore.post()

func _is_hash_in_response(json: Dictionary, md5: String):
	if json.has("roms"):
		for rom in json["roms"]:
			if rom.has("rommd5") and rom["rommd5"].to_lower() == md5:
				return true
	return false

func _process_raw_game_data(json: Dictionary, game_data: RetroHubGameData):
		# Save simple metadata
	game_data.has_metadata = true
	if json.has("noms"):
		game_data.name = extract_json_region(json["noms"])["text"]
	if json.has("synopsis"):
		game_data.description = extract_json_language(json["synopsis"])["text"]
	if json.has("developpeur"):
		game_data.developer = json["developpeur"]["text"].replace("\n", "\\n")
	if json.has("editeur"):
		game_data.publisher = json["editeur"]["text"]
	if json.has("note"):
		game_data.rating = float(json["note"]["text"]) / 20.0
	if json.has("dates"):
		game_data.release_date = extract_json_date(extract_json_region(json["dates"])["text"])
	if json.has("classifications"):
		game_data.age_rating = extract_json_age_rating(json["classifications"])

	# Handle tricker cases
	if json.has("genres"):
		var genres : Array = json["genres"]
		game_data.genres = []
		for genre in genres:
			game_data.genres.push_back(extract_json_language(genre["noms"])["text"])

	if json.has("joueurs"):
		var players : String = json["joueurs"]["text"]
		if not "-" in players:
			players = players + "-" + players
		game_data.num_players = players

func extract_json_date(date: String) -> String:
	var splits := date.split("-")
	if splits.size() >= 3:		# yyyy-dd-mm
		return "%s%s%sT000000" % [splits[0], splits[2], splits[1]]
	elif splits.size() == 2:	#yyyy-mm # FIXME: Confirm this happens on screenscraper
		return "%s%s01T000000" % [splits[0], splits[1]]
	else:						# yyyy
		return "%s0101T000000" % splits[0]

func extract_json_region(json_arr: Array) -> Dictionary:
	var regions := ["wor", "ss", "us", "eu", "jp"]
	var curr_region := convert_region_to_ss(RetroHubConfig.config.region)
	regions.erase(curr_region)
	regions.push_front(curr_region)

	var result := find_by_key(json_arr, "region", regions)

	return json_arr[0] if result.is_empty() else result

func extract_json_language(json_arr: Array) -> Dictionary:
	var languages := ["en"]
	var curr_language := RetroHubConfig.config.lang
	languages.erase(curr_language)
	languages.push_front(curr_language)

	var result := find_by_key(json_arr, "langue", languages)

	return json_arr[0] if result.is_empty() else result

func extract_json_age_rating(classifications: Array):
	var rating_usa := find_by_key(classifications, "type", ["ESRB"])
	var rating_eur := find_by_key(classifications, "type", ["PEGI"])
	var rating_jpn := find_by_key(classifications, "type", ["CERO"])
	var rating_final : String
	if not rating_usa.is_empty():
		match rating_usa["text"]:
			"E":
				rating_final = "1"
			"E10":
				rating_final = "2"
			"T":
				rating_final = "3"
			"M":
				rating_final = "4"
			"AO":
				rating_final = "5"
			_:
				rating_final = "0"
	else:
		rating_final = "0"
	if not rating_eur.is_empty():
		match rating_eur["text"]:
			"3":
				rating_final += "/1"
			"7":
				rating_final += "/2"
			"12":
				rating_final += "/3"
			"16":
				rating_final += "/4"
			"18":
				rating_final += "/5"
			_:
				rating_final += "/0"
	else:
		rating_final += "/0"
	if not rating_jpn.is_empty():
		match rating_jpn["text"]:
			"A":
				rating_final += "/1"
			"B":
				rating_final += "/2"
			"C":
				rating_final += "/3"
			"D":
				rating_final += "/4"
			"Z":
				rating_final += "/5"
			_:
				rating_final += "/0"
	else:
		rating_final += "/0"

	return rating_final

func find_by_key(input_arr: Array, key: String, values: Array) -> Dictionary:
	for val in values:
		for input in input_arr:
			if input.has(key) and input[key] == val:
				return input
	return {}

func find_all_by_key(input_arr: Array, key: String, values: Array) -> Array:
	var output := []
	for val in values:
		for input in input_arr:
			if input.has(key) and input[key] == val:
				output.push_back(input)
	return output

func convert_region_to_ss(region: String) -> String:
	match region:
		"usa":
			return "us"
		"eur":
			return "eu"
		"jpn":
			return "jp"
		_:
			return "region"
