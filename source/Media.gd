extends HTTPRequest

enum Status {
	SUCCESS,
	MULTIPLE_AVAILABLE,
	ERROR,
	CANCELED
}

signal game_scrape_finished(status)
signal game_scrape_step(curr, total, description)
signal game_media_scrape_finished(status)
signal game_media_scraped(game_data, req_body)

var status : int
var status_details

var cached_requests := {}

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
	"xboxone": 34,
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
	"ps4": 60,
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
	"mess": 75,
	"arcade": 75,
	"zxspectrum": 76,
	"zx81": 77,
	"x68000": 79,
	"channelf": 80,
	"ngpc": 82,
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

func _enter_tree():
	connect("request_completed", self, "_on_request_completed")
	use_threads = true
	timeout = 10

func _on_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	print("\t\tReceived request")
	_req_result = result
	_req_response_code = response_code
	_req_headers = headers
	_req_body = body

var _req_result: int
var _req_response_code: int
var _req_headers: PoolStringArray
var _req_body: PoolByteArray

func is_req_ok():
	return not _req_result and _req_response_code == HTTPClient.RESPONSE_OK

func scrape_game_by_hash(game_data: RetroHubGameData) -> void:
	print("\tCached:", cached_requests.size())
	if cached_requests.has(game_data):
		_process_raw_game_data(cached_requests[game_data], game_data)
		print("\tReturning cached result instead")
		emit_signal("game_scrape_finished", Status.SUCCESS)
		return

	var file = File.new()
	var system_id = get_ss_system_mapping(game_data.system_name)
	var rom_name = game_data.path.get_file()
	var md5 = file.get_md5(game_data.path)
	file.open(game_data.path, File.READ)
	var rom_size = file.get_len()
	file.close()

	var header_data = {
		"devid": ss_get_api_keys(ss_api_user, false),
		"devpassword": ss_get_api_keys(ss_api_pass, true),
		"softname": "RetroHub",
		"output": "json",
		"romtype": "rom",
		"md5": md5,
		"systemeid": str(system_id),
		"romnom": rom_name,
		"romtaille": str(rom_size)
	}
	
	var http_client := HTTPClient.new()

	var url = "https://www.screenscraper.fr/api2/jeuInfos.php?" + http_client.query_string_from_dict(header_data)
	download_file = ""
	download_chunk_size = 1024 * 1024 # 1MB
	# Wait for any pending requests to finish
	if get_http_client_status() == HTTPClient.STATUS_REQUESTING:
		yield(self, "request_completed")
	print(url)
	request(url)
	emit_signal("game_scrape_step", 0, 1, "metadata")
	print("\tRequest sent")
	yield(self, "request_completed")
	print("\tRequest complete")

	if is_req_ok():
		var json = JSON.parse(_req_body.get_string_from_utf8())
		if json.error:
			print("\tError when parsing JSON!")
			status_details = _req_body.get_string_from_utf8()
			emit_signal("game_scrape_finished", Status.ERROR)
			return
		else:
			var json_raw = json.result
			# Preprocess json a bit due to ScreenScraper structure
			json_raw = json_raw["response"]
			json_raw = json_raw["jeu"]
			# Even if ScreenScraper answered correctly, it might not have matched by hash but by name instead.
			# Ensure the hash is here
			if _is_hash_in_response(json_raw, md5):
				_process_raw_game_data(json_raw, game_data)
				cached_requests[game_data] = json_raw
				emit_signal("game_scrape_finished", Status.SUCCESS)
				return
			else:
				# Default to search term
				scrape_game_by_search(game_data, game_data.name.get_basename())
	elif _req_response_code == HTTPClient.RESPONSE_NOT_FOUND:
		# Error from system. Most likely because this ROM hash doesn't exist in the database.
		# Default to search term
		scrape_game_by_search(game_data, game_data.name.get_basename())
	else:
		handle_error()
		emit_signal("game_scrape_finished", Status.ERROR)

func handle_error():
	if _req_response_code:
		status_details = "HTTP Error: " + str(_req_response_code)
	elif _req_result:
		match _req_result:
			RESULT_CANT_CONNECT, RESULT_CANT_RESOLVE:
				# Couldn't connect to API. It might be down, or user have no internet
				status_details = "Can't connect to service. Check your internet connection, and check if the service is up at http://screenscraper.fr/"
			RESULT_TIMEOUT:
				# Timeout
				status_details = "The service took too much time to answer. This might be due to a slow/unreliable internet connection, or the service is too busy."

func cancel():
	cancel_request()
	emit_signal("request_completed", ERR_UNAVAILABLE, HTTPClient.RESPONSE_REQUEST_TIMEOUT, PoolStringArray(), PoolByteArray())
	status_details = "The request was canceled by the user."

func remap_cache(game_data_old: RetroHubGameData, game_data_new: RetroHubGameData) -> void:
	if cached_requests.has(game_data_old):
		cached_requests[game_data_new] = cached_requests[game_data_old]
		cached_requests.erase(game_data_old)

func clear_cache():
	cached_requests.clear()
	_req_body = PoolByteArray()

func scrape_game_by_search(game_data: RetroHubGameData, search_term: String) -> void:
	var system_id = get_ss_system_mapping(game_data.system_name)

	var header_data = {
		"devid": ss_get_api_keys(ss_api_user, false),
		"devpassword": ss_get_api_keys(ss_api_pass, true),
		"softname": "RetroHub",
		"output": "json",
		"systemeid": str(system_id),
		"recherche": search_term
	}
	
	var http_client := HTTPClient.new()

	var url = "https://www.screenscraper.fr/api2/jeuRecherche.php?" + http_client.query_string_from_dict(header_data)
	download_file = ""
	# Wait for any pending requests to finish
	if get_http_client_status() == HTTPClient.STATUS_REQUESTING:
		yield(self, "request_completed")
	print(url)
	request(url)
	emit_signal("game_scrape_step", 0, 1, "metadata")
	yield(self, "request_completed")

	if is_req_ok():
		var json = JSON.parse(_req_body.get_string_from_utf8())
		if json.error:
			status_details = _req_body.get_string_from_utf8()
			emit_signal("game_scrape_finished", Status.ERROR)
			return
		else:
			var json_raw = json.result
			json_raw = json_raw["response"]
			json_raw = json_raw["jeux"]
			status_details = []
			for child in json_raw:
				if not child.empty():
					var game_data_tmp := RetroHubGameData.new()
					_process_raw_game_data(child, game_data_tmp)
					status_details.push_back(game_data_tmp)
					cached_requests[game_data_tmp] = child

			emit_signal("game_scrape_finished", Status.MULTIPLE_AVAILABLE)
			return
	else:
		handle_error()
		emit_signal("game_scrape_finished", Status.ERROR)

func get_status_details():
	return status_details

func scrape_game_media_data(game_data):
	if cached_requests.has(game_data):
		var medias := [
			"logo",
			"screenshot",
			"title-screen",
			"video",
			"box-render",
			"box-texture",
			"manual",
			"support-render",
			"support-texture"
		]
		var idx = 0
		for media in medias:
			emit_signal("game_scrape_step", idx, medias.size(), media)
			print("\tStarting request of media")
			yield(_process_raw_game_media_data(cached_requests[game_data], game_data, media, true), "completed")
			if not is_req_ok():
				handle_error()
				print("\tError requesting media")
				emit_signal("game_media_scrape_finished", Status.ERROR)
				return
			idx += 1
		emit_signal("game_media_scrape_finished", Status.SUCCESS)
	else:
		emit_signal("game_media_scrape_finished", -1)

func scrape_game_media_data_type(game_data: RetroHubGameData, media_type: String):
	if not cached_requests.has(game_data):
		scrape_game_by_hash(game_data)
	yield(_process_raw_game_media_data(cached_requests[game_data], game_data, media_type, false), "completed")
	if not is_req_ok():
		handle_error()
		emit_signal("game_media_scrape_finished", Status.ERROR)
		return
	emit_signal("game_media_scraped", game_data, _req_body)

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

func _process_raw_game_media_data(json: Dictionary, game_data: RetroHubGameData, media_type: String, download_locally: bool):
	var medias_raw : Array = json["medias"]
	var scraper_names: Array
	match media_type:
		"logo":
			scraper_names = ["wheel-hd", "wheel"]
		"screenshot":
			scraper_names = ["ss"]
		"title-screen":
			scraper_names = ["sstitle"]
		"video":
			scraper_names = ["video"]
		"box-render":
			scraper_names = ["box-3D"]
		"box-texture":
			scraper_names = ["box-texture"]
		"manual":
			scraper_names = ["manuel"]
		"support-render":
			scraper_names = ["support-2D"]
		"support-texture":
			scraper_names = ["support-texture"]
		_:
			return null

	var scrape = JSONUtils.find_all_by_key(medias_raw, "type", scraper_names)
	if scrape.empty():
		yield(get_tree().create_timer(0.001), "timeout")
		return
	var res = extract_json_region(scrape)
	if not res.empty():
		if download_locally:
			var local_filename = RetroHubConfig.get_gamemedia_dir() + "/" + \
								game_data.system_name + "/" + media_type + \
								"/" + game_data.path.get_file().get_basename()
			FileUtils.ensure_path(local_filename)
			download_file = local_filename + "." + res["format"]
		download_chunk_size = 1024 * 1024 * 4 # 4MB
		# Wait for any pending requests to finish
		if get_http_client_status() == HTTPClient.STATUS_REQUESTING:
			yield(self, "request_completed")
		print("\tRequesting media ", res["url"])
		request(res["url"])
		print("\tDone requesting media")
		yield(self, "request_completed")
		print("\tRequest over")
		if is_req_ok():
			game_data.has_media = true
			print("\tSuccess in requesting %s, at %s" % [media_type, download_file])
		else:
			print("\tError in requesting %s" % media_type)

func retrieve_media_data(game_data: RetroHubGameData) -> RetroHubGameMediaData:
	if not game_data.has_media:
		print("Error: game %s has no media" % game_data.name)
		return null
	var game_media_data := RetroHubGameMediaData.new()

	var media_path = RetroHubConfig.get_gamemedia_dir() + "/" + game_data.system_name
	var game_path = game_data.path.get_file().get_basename()

	var image := Image.new()
	var file := File.new()
	var path : String

	# Logo
	path = media_path + "/logo/" + game_path + ".png"
	if image.load(path):
		print("Error when loading logo image for game %s!" % game_data.name)
	else:
		var image_texture = ImageTexture.new()
		image_texture.create_from_image(image, 6)
		game_media_data.logo = image_texture

	# Screenshot
	path = media_path + "/screenshot/" + game_path + ".png"
	if image.load(path):
		print("Error when loading screenshot image for game %s!" % game_data.name)
	else:
		var image_texture = ImageTexture.new()
		image_texture.create_from_image(image, 6)
		game_media_data.screenshot = image_texture

	# Title screen
	path = media_path + "/title-screen/" + game_path + ".png"
	if image.load(path):
		print("Error when loading title screen image for game %s!" % game_data.name)
	else:
		var image_texture = ImageTexture.new()
		image_texture.create_from_image(image, 6)
		game_media_data.title_screen = image_texture

	# Box render
	path = media_path + "/box-render/" + game_path + ".png"
	if image.load(path):
		print("Error when loading box render image for game %s!" % game_data.name)
	else:
		var image_texture = ImageTexture.new()
		image_texture.create_from_image(image, 6)
		game_media_data.box_render = image_texture

	# Box texture
	path = media_path + "/box-texture/" + game_path + ".png"
	if image.load(path):
		print("Error when loading box texture image for game %s!" % game_data.name)
	else:
		var image_texture = ImageTexture.new()
		image_texture.create_from_image(image, 6)
		game_media_data.box_texture = image_texture

	# Support render
	path = media_path + "/support-render/" + game_path + ".png"
	if image.load(path):
		print("Error when loading support render image for game %s!" % game_data.name)
	else:
		var image_texture = ImageTexture.new()
		image_texture.create_from_image(image, 6)
		game_media_data.support_render = image_texture

	# Support texture
	path = media_path + "/support-texture/" + game_path + ".png"
	if image.load(path):
		print("Error when loading support texture image for game %s!" % game_data.name)
	else:
		var image_texture = ImageTexture.new()
		image_texture.create_from_image(image, 6)
		game_media_data.support_texture = image_texture

	# Video
	path = media_path + "/video/" + game_path + ".mp4"
	if not file.file_exists(path):
		print("Error when loading video for game %s!" % game_data.name)
	else:
		var video_stream := VideoStreamGDNative.new()
		video_stream.set_file(path)
		game_media_data.video = video_stream
	
	# Manual
	## FIXME: Very likely we won't be able to support PDF reading.

	return game_media_data

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

	return rating_final
