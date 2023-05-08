extends Popup

signal scrape_step(game_entry)

@export var system_entry_scene: PackedScene : PackedScene

@onready var n_scraper_done := $"%ScraperDone"
@onready var n_scraper_warning := $"%ScraperWarning"
@onready var n_scraper_error := $"%ScraperError"
@onready var n_scraper_pending := $"%ScraperPending"
@onready var n_scraper_details := $"%ScraperDetails"

@onready var n_game_entries := $"%GameEntries"
@onready var n_game_entry_editor := $"%GameEntryEditor"
@onready var n_pending_games := $"%PendingGames"
@onready var n_finish := $"%Finish"
@onready var n_warning := $"%Warning"

@onready var n_stop_scraper_dialog := $"%StopScraperDialog"

@onready var button_group := ButtonGroup.new()

class Request:
	enum Type {
		DATA_HASH,
		DATA_SEARCH,
		MEDIA,
		MEDIA_FROM_SEARCH
	}
	var type : int
	var game_entry : RetroHubScraperGameEntry
	var data

var game_list_arr : Array
var scrape_data : bool
var scrape_media : bool
var scrape_by_hash : bool
var scrape_by_name : bool
var media_bitmask : int
var scene_entry_list := {}
var game_entry_list := []

var num_games_success : int
var num_games_warning : int
var num_games_error : int
var num_games_pending : int

# Thread variables
var thread : Thread
var requests_semaphore : Semaphore
var processing_request_mutex := Mutex.new()
var requests_mutex := Mutex.new()
var requests_queue := []
var requests_curr := []

var pending_datas := {}
var pending_medias := {}

var scraper : RetroHubScraper

func _ready():
	n_scraper_done.modulate = RetroHubUI.color_success
	n_scraper_warning.modulate = RetroHubUI.color_warning
	n_scraper_error.modulate = RetroHubUI.color_error

func begin_scraping(_game_list_arr: Array, _scraper: RetroHubScraper, _scrape_data: bool, _scrape_media: bool, _scrape_by_hash: bool, _scrape_by_name: bool, _media_bitmask: int):
	game_list_arr = _game_list_arr
	scrape_data = _scrape_data
	scrape_media = _scrape_media
	scrape_by_hash = _scrape_by_hash
	scrape_by_name = _scrape_by_name
	media_bitmask = _media_bitmask

	scraper = _scraper
	add_child(scraper)
	n_warning.scraper = scraper
	clear_game_entries()
	populate_game_entries()
	fetch_game_entries_async()
	n_game_entries.grab_focus()


func fetch_game_entries_async():
	thread = Thread.new()
	requests_semaphore = Semaphore.new()
	requests_mutex.lock()
	requests_queue.clear()
	requests_curr.clear()
	for game_entry in game_entry_list:
		add_data_request(game_entry, Request.Type.DATA_HASH if scrape_by_hash else Request.Type.DATA_SEARCH)
	requests_mutex.unlock()

	if thread.start(Callable(self, "thread_fetch_game_entries")):
		push_error("Failed to start thread for scraper")

func add_data_request(game_entry: RetroHubScraperGameEntry, type: int, priority: bool = false) -> void:
	var req := Request.new()
	req.type = type
	if type == Request.Type.DATA_SEARCH and not game_entry.data:
		game_entry.data = game_entry.game_data.name.get_basename()
	req.game_entry = game_entry
	if priority:
		requests_queue.push_front(req)
	else:
		requests_queue.push_back(req)
	#warning-ignore:return_value_discarded
	requests_semaphore.post()

func add_media_request(game_entry: RetroHubScraperGameEntry, priority: bool = false, is_search: bool = false) -> int:
	var medias := RetroHubMedia.convert_type_bitmask_to_list(media_bitmask)
	# Invert medias due to the way requests are placed in queue
	medias.invert()
	var idx := 0
	if not priority:
		for i in range(requests_queue.size()):
			if requests_queue[i].type == Request.Type.MEDIA:
				idx = i
	for media in medias:
		var req := Request.new()
		req.type = Request.Type.MEDIA_FROM_SEARCH if is_search else Request.Type.MEDIA
		req.game_entry = game_entry
		req.data = media
		if priority:
			requests_queue.push_front(req)
		else:
			requests_queue.insert(idx, req)
			#warning-ignore:return_value_discarded
		requests_semaphore.post()
	return medias.size()


func thread_fetch_game_entries():
	scraper.connect("scraper_details", Callable(self, "t_on_scraper_details"))
	#warning-ignore:return_value_discarded
	scraper.connect("game_scrape_finished", Callable(self, "t_on_game_scrape_finished"))
	#warning-ignore:return_value_discarded
	scraper.connect("game_scrape_multiple_available", Callable(self, "t_on_game_scrape_multiple_available"))
	#warning-ignore:return_value_discarded
	scraper.connect("game_scrape_not_found", Callable(self, "t_on_game_scrape_not_found"))
	#warning-ignore:return_value_discarded
	scraper.connect("game_scrape_error", Callable(self, "t_on_game_scrape_error"))
	#warning-ignore:return_value_discarded
	scraper.connect("media_scrape_finished", Callable(self, "t_on_media_scrape_finished"))
	#warning-ignore:return_value_discarded
	scraper.connect("media_scrape_not_found", Callable(self, "t_on_media_scrape_not_found"))
	#warning-ignore:return_value_discarded
	scraper.connect("media_scrape_error", Callable(self, "t_on_media_scrape_error"))

	while true:
		processing_request_mutex.lock()
		# Wait for a scrape request
		#warning-ignore:return_value_discarded
		requests_semaphore.wait()

		# Get a game entry to fetch
		requests_mutex.lock()
		if requests_queue.is_empty():
			processing_request_mutex.unlock()
			requests_mutex.unlock()
			break
		var req : Request = requests_queue.pop_front()
		var game_entry := req.game_entry
		requests_curr.push_back(req)
		requests_mutex.unlock()
		processing_request_mutex.unlock()

		# Retrieve game data and begin scraping it
		var game_data := game_entry.game_data
		game_entry.set_deferred("state", RetroHubScraperGameEntry.State.WORKING)
		match req.type:
			Request.Type.DATA_HASH:
				game_entry.curr = 0
				game_entry.total = 1
				if scrape_data:
					game_entry.description = "Downloading metadata (by hash)..."
				else:
					game_entry.description = "Fetching media (by hash)..."
				emit_signal("scrape_step", game_entry)
				if not scraper.scrape_game_by_hash(game_data):
					pending_datas[game_data] = req
			Request.Type.DATA_SEARCH:
				game_entry.curr = 0
				game_entry.total = 1
				if scrape_data:
					game_entry.description = "Downloading metadata (by search)"
				else:
					game_entry.description = "Fetching media (by search)..."
				emit_signal("scrape_step", game_entry)
				if not scraper.scrape_game_by_search(game_data, game_entry.data):
					pending_datas[game_data] = req
			Request.Type.MEDIA:
				if scraper.scrape_media(game_data, req.data):
					# This requested media doesn't exist, so skip it
					requests_curr.erase(req)
					game_entry.curr += 1
			Request.Type.MEDIA_FROM_SEARCH:
				if scraper.scrape_media_from_search(game_data, game_entry.data, req.data):
					# This requested media doesn't exist, so skip it
					requests_curr.erase(req)
					game_entry.curr += 1

	scraper.disconnect("scraper_details", Callable(self, "t_on_scraper_details"))
	scraper.disconnect("game_scrape_finished", Callable(self, "t_on_game_scrape_finished"))
	scraper.disconnect("game_scrape_multiple_available", Callable(self, "t_on_game_scrape_multiple_available"))
	scraper.disconnect("game_scrape_not_found", Callable(self, "t_on_game_scrape_not_found"))
	scraper.disconnect("game_scrape_error", Callable(self, "t_on_game_scrape_error"))
	scraper.disconnect("media_scrape_finished", Callable(self, "t_on_media_scrape_finished"))
	scraper.disconnect("media_scrape_not_found", Callable(self, "t_on_media_scrape_not_found"))
	scraper.disconnect("media_scrape_error", Callable(self, "t_on_media_scrape_error"))

func _ensure_valid_req(game_data: RetroHubGameData):
	if not pending_datas.has(game_data):
		for req in requests_curr:
			if req.game_entry.game_data == game_data:
				return req
		return null
	else:
		return pending_datas[game_data]

func t_on_scraper_details(text: String):
	n_scraper_details.set_deferred("text", text)

func t_on_game_scrape_finished(game_data: RetroHubGameData):
	var req : Request = _ensure_valid_req(game_data)
	if not req:
		return
	var game_entry := req.game_entry
	requests_curr.erase(req)
	#warning-ignore:return_value_discarded
	pending_datas.erase(game_data)
	if not prepare_media_scrape(game_entry):
		_finish_scrape(game_entry)

func t_on_game_scrape_multiple_available(game_data: RetroHubGameData, results: Array):
	var req : Request = _ensure_valid_req(game_data)
	if not req:
		return
	var game_entry := req.game_entry
	requests_curr.erase(req)
	#warning-ignore:return_value_discarded
	pending_datas.erase(game_data)
	game_entry.set_deferred("data", results)
	game_entry.set_deferred("state", RetroHubScraperGameEntry.State.WARNING)
	call_deferred("incr_num_games_warning")
	call_deferred("decr_num_games_pending")

func t_on_game_scrape_not_found(game_data: RetroHubGameData):
	var req : Request = _ensure_valid_req(game_data)
	if not req:
		return
	var game_entry := req.game_entry
	requests_curr.erase(req)
	#warning-ignore:return_value_discarded
	pending_datas.erase(game_data)
	if req.type == Request.Type.DATA_HASH:
		if scrape_by_name:
			# Hash failed, try by filename
			game_entry.data = game_entry.game_data.name.get_basename()
			requests_mutex.lock()
			add_data_request(game_entry, Request.Type.DATA_SEARCH, true)
			requests_mutex.unlock()
		else:
			# Hash failed and user doesn't want to search by name
			game_entry.set_deferred("data", ["Identification by hash has failed, either because this game is bigger than the set hash file size limit, or the scraper does not have this hash in their database.\n\nSearching by file name is disabled. To try it instead, you must enable it on the scraper options.", req])
			game_entry.set_deferred("state", RetroHubScraperGameEntry.State.ERROR)
			call_deferred("decr_num_games_pending")
			call_deferred("incr_num_games_error")



func t_on_game_scrape_error(game_data: RetroHubGameData, details: String):
	var req : Request = _ensure_valid_req(game_data)
	if not req:
		return
	var game_entry := req.game_entry
	requests_curr.erase(req)
	#warning-ignore:return_value_discarded
	pending_datas.erase(game_data)
	# Request may already be in error state, e.g. user canceled it
	if game_entry.state == RetroHubScraperGameEntry.State.ERROR:
		return
	game_entry.set_deferred("data", [details, req])
	game_entry.set_deferred("state", RetroHubScraperGameEntry.State.ERROR)
	call_deferred("decr_num_games_pending")
	call_deferred("incr_num_games_error")

func prepare_media_scrape(game_entry: RetroHubScraperGameEntry):
	if scrape_media && media_bitmask > 0:
		requests_mutex.lock()
		game_entry.curr = 0
		game_entry.total = add_media_request(game_entry)
		requests_mutex.unlock()
		game_entry.description = "Downloading " + _convert_type_to_str(RetroHubMedia.convert_type_bitmask_to_list(media_bitmask)[0]) + "..."
		pending_medias[game_entry.game_data] = game_entry
		return true
	return false

func prepare_media_scrape_from_search(game_entry: RetroHubScraperGameEntry, search_game_data: RetroHubGameData):
	if scrape_media && media_bitmask > 0:
		requests_mutex.lock()
		game_entry.curr = 0
		game_entry.total = add_media_request(game_entry, false, true)
		game_entry.data = search_game_data
		requests_mutex.unlock()
		game_entry.description = "Downloading " + _convert_type_to_str(RetroHubMedia.convert_type_bitmask_to_list(media_bitmask)[0]) + "..."
		pending_medias[game_entry.game_data] = game_entry
		return true
	return false

func t_on_media_scrape_finished(game_data: RetroHubGameData, type: int, data: PackedByteArray, extension: String):
	if pending_medias.has(game_data):
		# Save media
		var path := RetroHubConfig.get_gamemedia_dir() + "/" + \
					game_data.system.name + "/" + \
					RetroHubMedia.convert_type_to_media_path(type) + "/" + \
					game_data.path.get_file().get_basename() + \
					"." + extension
		FileUtils.ensure_path(path)
		var file := File.new()
		if file.open(path, File.WRITE):
			push_error("\tError when saving file " + path)
			return
		else:
			game_data.has_media = true
			file.store_buffer(data)
			file.close()

		var game_entry : RetroHubScraperGameEntry = pending_medias[game_data]
		for req in requests_curr:
			if req.game_entry == game_entry:
				requests_curr.erase(req)
				break
		game_entry.description = "Downloading " + _convert_type_to_str(type) + "..."
		game_entry.curr += 1
		emit_signal("scrape_step", game_entry)
		if game_entry.curr >= game_entry.total:
			_finish_scrape(game_entry)

func t_on_media_scrape_not_found(game_data: RetroHubGameData, _type: int):
	if pending_medias.has(game_data):
		var game_entry : RetroHubScraperGameEntry = pending_medias[game_data]
		for req in requests_curr:
			if req.game_entry == game_entry:
				requests_curr.erase(req)
				break
		game_entry.curr += 1
		emit_signal("scrape_step", game_entry)
		if game_entry.curr >= game_entry.total:
			_finish_scrape(game_entry)

func t_on_media_scrape_error(game_data: RetroHubGameData, type: int, _details: String):
	t_on_media_scrape_not_found(game_data, type)

func _finish_scrape(game_entry: RetroHubScraperGameEntry):
	game_entry.set_deferred("data", scrape_data)
	game_entry.set_deferred("state", RetroHubScraperGameEntry.State.SUCCESS)
	call_deferred("incr_num_games_success")
	call_deferred("decr_num_games_pending")
	if scrape_data:
		RetroHubConfig.call_deferred("save_game_data", game_entry.game_data)

func _convert_type_to_str(type: int):
	match type:
		RetroHubMedia.Type.LOGO:
			return "logo"
		RetroHubMedia.Type.SCREENSHOT:
			return "screenshot"
		RetroHubMedia.Type.TITLE_SCREEN:
			return "title screen"
		RetroHubMedia.Type.VIDEO:
			return "video"
		RetroHubMedia.Type.BOX_RENDER:
			return "box-art (render)"
		RetroHubMedia.Type.BOX_TEXTURE:
			return "box-art (texture)"
		RetroHubMedia.Type.SUPPORT_RENDER:
			return "support (render)"
		RetroHubMedia.Type.SUPPORT_TEXTURE:
			return "support (texture)"
		RetroHubMedia.Type.MANUAL:
			return "manual"

func clear_game_entries():
	for scene_entry in scene_entry_list.values():
		n_game_entries.remove_child(scene_entry)
		scene_entry.queue_free()
	scene_entry_list.clear()
	game_entry_list.clear()

func populate_game_entries():
	for game_data in game_list_arr:
		if not scene_entry_list.has(game_data.system):
			var scene_entry := system_entry_scene.instantiate()
			n_game_entries.add_child(scene_entry)
			scene_entry.system_name = game_data.system.fullname
			scene_entry_list[game_data.system] = scene_entry
		var data : RetroHubGameData = game_data.duplicate() if not scrape_data else game_data
		var game_entry : RetroHubScraperGameEntry = scene_entry_list[game_data.system].add_game_entry(data, button_group)
		#warning-ignore:return_value_discarded
		game_entry.connect("game_selected", Callable(self, "_on_game_entry_selected"))
		#warning-ignore:return_value_discarded
		game_entry.connect("focus_exited", Callable(n_game_entries, "_on_game_entry_focus_exited"))
		#warning-ignore:return_value_discarded
		game_entry.connect("game_selected", Callable(n_game_entries, "_on_game_entry_selected"))
		game_entry_list.push_back(game_entry)
	num_games_success = 0
	num_games_warning = 0
	num_games_error = 0
	num_games_pending = game_list_arr.size()
	update_games_stats()

func update_games_stats():
	n_scraper_done.text = str(num_games_success)
	n_scraper_warning.text = str(num_games_warning)
	n_scraper_error.text = str(num_games_error)
	n_scraper_pending.text = str(num_games_pending)

	var remaining := num_games_warning + num_games_error + num_games_pending
	match remaining:
		0:
			n_pending_games.text = "All games have been successfully scrapped"
		1:
			n_pending_games.text = "There is 1 game yet to be sucessfully scrapped"
		_:
			n_pending_games.text = "There are %d games yet to be successfully scrapped" % remaining

func _on_game_entry_selected(game_entry: RetroHubScraperGameEntry, by_app: bool):
	n_game_entry_editor.current_tab = game_entry.state
	n_game_entry_editor.get_current_tab_control().set_entry(game_entry)
	if not by_app or not n_game_entries.focused:
		n_game_entry_editor.get_current_tab_control().grab_focus()


func _on_Warning_request_search(search: String, game_data: RetroHubGameData):
	for game_entry in game_entry_list:
		if game_entry.game_data == game_data:
			game_entry.data = search
			game_entry.state = RetroHubScraperGameEntry.State.WAITING
			num_games_warning -= 1
			num_games_pending += 1
			update_games_stats()
			requests_mutex.lock()
			add_data_request(game_entry, Request.Type.DATA_SEARCH, true)
			requests_mutex.unlock()
			break

func _on_Warning_search_completed(orig_game_data: RetroHubGameData, new_game_data: RetroHubGameData):
	orig_game_data.copy_from(new_game_data)
	for game_entry in game_entry_list:
		if game_entry.game_data == orig_game_data:
			game_entry.state = RetroHubScraperGameEntry.State.WAITING
			num_games_warning -= 1
			num_games_pending += 1
			update_games_stats()
			if not prepare_media_scrape_from_search(game_entry, new_game_data):
				_finish_scrape(game_entry)
			break

func cancel_scrape(game_entry: RetroHubScraperGameEntry):
	game_entry.data = ["Canceled", null]
	game_entry.state = RetroHubScraperGameEntry.State.ERROR
	num_games_pending = num_games_pending - 1
	num_games_error = num_games_error + 1
	update_games_stats()

	# Cancel in data
	for game_data in pending_datas:
		if pending_datas[game_data].game_entry == game_entry:
			scraper.cancel(game_data)

	# Cancel in media (current)
	for req in requests_curr:
		if req.type == Request.Type.MEDIA and req.game_entry == game_entry:
			scraper.cancel(game_entry.game_data)
			break

	# Cancel in media (pending)
	# Don't lock if thread is waiting for job, otherwise a deadlock happens
	if requests_queue.is_empty():
		return
	# Only enter when the thread is not handling a request currently
	processing_request_mutex.lock()
	var to_erase := []
	requests_mutex.lock()
	for req in requests_queue:
		if req.type == Request.Type.MEDIA and req.game_entry == game_entry:
			to_erase.push_back(req)
	for req in to_erase:
		requests_queue.erase(req)
		#warning-ignore:return_value_discarded
		requests_semaphore.wait()
	requests_mutex.unlock()
	#warning-ignore:return_value_discarded
	pending_medias.erase(game_entry.game_data)
	processing_request_mutex.unlock()


func cancel_entry(game_entry: RetroHubScraperGameEntry):
	# Don't lock if thread is waiting for job, otherwise a deadlock happens
	if requests_curr.is_empty() and pending_datas.is_empty():
		return
	# Only enter when the thread is not handling a request currently
	processing_request_mutex.lock()
	# This is only called on entries waiting to be scraped, so
	# there's no need to check pending_datas/medias
	var to_delete := []
	requests_mutex.lock()
	for req in requests_queue:
		if req.game_entry == game_entry:
			to_delete.push_back(req)
	for req in to_delete:
		requests_queue.erase(req)
	to_delete.clear()
	#warning-ignore:return_value_discarded
	requests_semaphore.wait()
	requests_mutex.unlock()
	game_entry.data = ["Canceled", null]
	game_entry.state = RetroHubScraperGameEntry.State.ERROR
	num_games_pending -= 1
	num_games_error += 1
	update_games_stats()
	processing_request_mutex.unlock()

func finish_scraping():
	scraper.cancel_all()

	requests_mutex.lock()
	requests_queue.clear()
	#warning-ignore:return_value_discarded
	requests_semaphore.post()
	requests_mutex.unlock()
	thread.wait_to_finish()
	n_warning.stop_thread()

	remove_child(scraper)
	scraper.queue_free()
	# Save pending metadata
	for game_entry in game_entry_list:
		if game_entry.state != RetroHubScraperGameEntry.State.SUCCESS and game_entry.game_data.has_metadata:
			if not RetroHubConfig.save_game_data(game_entry.game_data):
				push_error("Error saving game data: " + game_entry.game_data.title)
	hide()

func _on_Finish_pressed():
	var remaining:= num_games_error + num_games_warning + num_games_pending
	if remaining > 0:
		n_stop_scraper_dialog.set_num_games_pending(remaining)
		n_stop_scraper_dialog.popup_centered()
	else:
		finish_scraping()

func _on_StopScraperDialog_confirmed():
	finish_scraping()


func _on_Error_retry_entry(game_entry: RetroHubScraperGameEntry, req: Request):
	requests_mutex.lock()
	if req == null:
		# No request, so start by scratch
		add_data_request(game_entry, Request.Type.DATA_HASH if scrape_by_hash else Request.Type.DATA_SEARCH, true)
	else:
		requests_queue.push_front(req)
		#warning-ignore:return_value_discarded
		requests_semaphore.post()
	requests_mutex.unlock()
	game_entry.state = RetroHubScraperGameEntry.State.WAITING
	num_games_error -= 1
	num_games_pending += 1
	update_games_stats()


func _on_Waiting_cancel_entry(game_entry: RetroHubScraperGameEntry):
	cancel_entry(game_entry)

func _on_Working_cancel_entry(game_entry: RetroHubScraperGameEntry):
	cancel_scrape(game_entry)

func incr_num_games_pending():
	num_games_pending += 1
	update_games_stats()

func incr_num_games_error():
	num_games_error += 1
	update_games_stats()

func incr_num_games_warning():
	num_games_warning += 1
	update_games_stats()

func incr_num_games_success():
	num_games_success += 1
	update_games_stats()

func decr_num_games_pending():
	num_games_pending -= 1
	update_games_stats()

func decr_num_games_error():
	num_games_error -= 1
	update_games_stats()

func decr_num_games_warning():
	num_games_warning -= 1
	update_games_stats()

func decr_num_games_success():
	num_games_success -= 1
	update_games_stats()
