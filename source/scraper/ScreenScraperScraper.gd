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
	var _req_headers : PoolStringArray
	var _req_body : PoolByteArray

	func _init():
		_http.connect("request_completed", self, "_on_request_completed")
		_http.use_threads = true
		_http.timeout = 10

	func _on_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
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
		_http.request(url)
	
	func cancel():
		_http.cancel_request()
		_http.emit_signal("request_completed", FAILED, 400, PoolStringArray(), PoolByteArray())

const MAX_REQUESTS := 3

var _req_semaphore := Semaphore.new()

var _cached_requests_data := {}
var _pending_requests := {}
var _curr_requests := {}

var ss_system_map = {
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

func get_ss_system_mapping(system_name) -> int:
	if ss_system_map.has(system_name):
		return ss_system_map[system_name]
	return -1

func _init():
	for __ in range(MAX_REQUESTS):
		_req_semaphore.post()


func _process(_delta):
	if not _pending_requests.empty():
		var game_data = _pending_requests.keys()[0]
		var req = _pending_requests[game_data].pop_front()
		if _pending_requests[game_data].empty():
			_pending_requests.erase(game_data)
		if _curr_requests.has(game_data):
			_curr_requests[game_data].push_back(req)
		else:
			_curr_requests[game_data] = [req]

		req.perform_request(req.type == RequestDetails.Type.MEDIA)
		yield(req._http, "request_completed")
		_req_semaphore.post()

		# If request got canceled, exit early
		if not _curr_requests.has(game_data):
			return
		_curr_requests[game_data].erase(req)
		if _curr_requests[game_data].empty():
			_curr_requests.erase(game_data)

		if req.is_ok():
			match req.type:
				RequestDetails.Type.DATA:
					_process_req_data(req, game_data)
				RequestDetails.Type.MEDIA:
					_process_req_media(req, game_data)
		else:
			if req._req_response_code == HTTPClient.RESPONSE_NOT_FOUND:
				match req.type:
					RequestDetails.Type.DATA:
						emit_signal("game_scrape_not_found", game_data)
					RequestDetails.Type.MEDIA:
						emit_signal("media_scrape_not_found", game_data, req.data["type"])
				return
			var details
			if req._req_response_code:
				details = "HTTP Error: " + str(req._req_response_code)
			else:
				match req._req_result:
					HTTPRequest.RESULT_CANT_CONNECT, HTTPRequest.RESULT_CANT_RESOLVE:
						# Couldn't connect to API. It might be down, or the user has no internet
						details = "Can't connect to service. Check your internet connection, and check if the service is up at http://screenscraper.fr/"
					HTTPRequest.RESULT_TIMEOUT:
						# Timeout
						details = "The service took too much time to answer. This might be due to a slow/unreliable internet connection, or the service is too busy."
			match req.type:
				RequestDetails.Type.DATA:
					emit_signal("game_scrape_error", game_data, details)
				RequestDetails.Type.MEDIA:
					emit_signal("media_scrape_error", game_data, req.data["type"], details)
			

func _process_req_data(req: RequestDetails, game_data: RetroHubGameData):
	var json = JSON.parse(req._req_body.get_string_from_utf8())
	if json.error:
		var details = req._req_body.get_string_from_utf8()
		emit_signal("game_scrape_error", game_data, details)
	else:
		var json_raw = json.result
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
				emit_signal("game_scrape_finished", game_data)
			else:
				emit_signal("game_scrape_not_found", game_data)
		else:
			json_raw = json_raw["jeux"]
			var details = []
			for child in json_raw:
				if not child.empty():
					var game_data_tmp := RetroHubGameData.new()
					_process_raw_game_data(child, game_data_tmp)
					_cached_requests_data[game_data_tmp] = child
					details.push_back(game_data_tmp)

			emit_signal("game_scrape_multiple_available", game_data, details)

func _process_req_media(req: RequestDetails, game_data):
	var extension = req.data["format"]
	var type = req.data["type"]
	emit_signal("media_scrape_finished", game_data, type, req._req_body, extension)

func _new_request_details(game_data: RetroHubGameData) -> RequestDetails:
	var req := RequestDetails.new()
	add_child(req._http)
	if _pending_requests.has(game_data):
		_pending_requests[game_data].push_back(req)
	else:
		_pending_requests[game_data] = [req]
	return req

func scrape_game_by_hash(game_data: RetroHubGameData, type: int = RequestDetails.Type.DATA) -> int:
	if _cached_requests_data.has(game_data):
		var json : Dictionary = _cached_requests_data[game_data]
		_process_raw_game_data(json, game_data)
		emit_signal("game_scrape_finished", game_data)
		return OK

	_req_semaphore.wait()

	# Compute game's hash
	var file = File.new()
	file.open(game_data.path, File.READ)
	var md5 : String = file.get_md5(game_data.path)
	var header_data = {
		"devid": ss_get_api_keys(ss_api_user, false),
		"devpassword": ss_get_api_keys(ss_api_pass, true),
		"softname": "RetroHub",
		"output": "json",
		"romtype": "rom",
		"md5": md5,
		"systemeid": str(get_ss_system_mapping(game_data.system.name)),
		"romnom": game_data.path.get_file(),
		"romtaille": str(file.get_len())
	}
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
		emit_signal("game_scrape_finished", game_data)
		return OK

	_req_semaphore.wait()

	var header_data = {
		"devid": ss_get_api_keys(ss_api_user, false),
		"devpassword": ss_get_api_keys(ss_api_pass, true),
		"softname": "RetroHub",
		"output": "json",
		"systemeid": str(get_ss_system_mapping(game_data.system.name)),
		"recherche": search_term
	}

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

	if not _cached_requests_data.has(game_data):
		# App is guaranteed to scrape data before media, so something is wrong
		print("\t Internal error: need to scrape metadata first!")
		return FAILED

	var json : Dictionary = _cached_requests_data[game_data]
	var medias_raw : Array = json["medias"]
	var scrape = JSONUtils.find_all_by_key(medias_raw, "type", scraper_names)
	if scrape.empty():
		return FAILED
	var res = extract_json_region(scrape)
	
	_req_semaphore.wait()

	var req := _new_request_details(game_data)
	req.type = RequestDetails.Type.MEDIA
	req.url = res["url"]
	req.data = {"format": res["format"], "type": media_type}
	return OK

func scrape_completed(game_data: RetroHubGameData) -> void:
	if _cached_requests_data.has(game_data):
		_cached_requests_data.erase(game_data)

func cancel(game_data: RetroHubGameData) -> void:
	# Cancel current requests
	if _curr_requests.has(game_data):
		for req in _curr_requests[game_data]:
			req.cancel()
		_curr_requests.erase(game_data)

	# Cancel pending requests
	if _pending_requests.has(game_data):
		for __ in range(_pending_requests[game_data].size()):
			_req_semaphore.post()
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
		game_data.release_date = RegionUtils.localize_date(extract_json_date(extract_json_region(json["dates"])["text"]))
	if json.has("classifications"):
		game_data.age_rating = extract_json_age_rating(json["classifications"])

	# Handle tricker cases
	if json.has("genres"):
		var genres = json["genres"]
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
	var regions = ["wor", "ss", "us", "eu", "jp"]
	var curr_region = RetroHubConfig.config.region
	regions.erase(curr_region)
	regions.push_front(curr_region)

	var result = JSONUtils.find_by_key(json_arr, "region", regions)
	
	return json_arr[0] if result.empty() else result

func extract_json_language(json_arr: Array) -> Dictionary:
	var languages = ["en"]
	var curr_language = RetroHubConfig.config.lang
	languages.erase(curr_language)
	languages.push_front(curr_language)

	var result = JSONUtils.find_by_key(json_arr, "langue", languages)

	return json_arr[0] if result.empty() else result

func extract_json_age_rating(classifications: Array):
	var rating_usa = JSONUtils.find_by_key(classifications, "type", ["ESRB"])
	var rating_eur = JSONUtils.find_by_key(classifications, "type", ["PEGI"])
	var rating_jpn = JSONUtils.find_by_key(classifications, "type", ["CERO"])
	var rating_final : String
	if not rating_usa.empty():
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
	if not rating_eur.empty():
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
	if not rating_jpn.empty():
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
