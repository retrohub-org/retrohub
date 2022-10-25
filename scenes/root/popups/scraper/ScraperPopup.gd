extends Popup

signal scrape_step(game_entry)

export(int, 1, 100) var max_queued_scrapes : int
export(PackedScene) var system_entry_scene : PackedScene

onready var n_game_entries := $"%GameEntries"
onready var n_game_entry_editor := $"%GameEntryEditor"
onready var n_pending_games := $"%PendingGames"
onready var n_finish := $"%Finish"
onready var n_warning := $"%Warning"

onready var n_stop_scraper_dialog := $"%StopScraperDialog"

onready var button_group := ButtonGroup.new()

class Request:
	enum Type {
		DATA_HASH,
		DATA_SEARCH
		MEDIA
	}
	var type : int
	var game_entry : RetroHubScraperGameEntry
	var data

var game_list_arr : Array
var media_bitmask : int
var scene_entry_list := {}
var game_entry_list := []

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

func begin_scraping(_game_list_arr: Array, _scraper: RetroHubScraper, _media_bitmask : int):
	game_list_arr = _game_list_arr
	media_bitmask = _media_bitmask

	scraper = _scraper
	add_child(scraper)
	n_warning.scraper = scraper
	clear_game_entries()
	populate_game_entries()
	fetch_game_entries_async()
	n_game_entries.get_child(0).grab_focus()


func fetch_game_entries_async():
	thread = Thread.new()
	requests_semaphore = Semaphore.new()
	requests_mutex.lock()
	requests_queue.clear()
	requests_curr.clear()
	for game_entry in game_entry_list:
		# TODO: Allow changing default behavior, hash or search
		add_data_request(game_entry, Request.Type.DATA_HASH)
	requests_mutex.unlock()
	
	thread.start(self, "thread_fetch_game_entries")

func add_data_request(game_entry, type, priority: bool = false) -> void:
	var req := Request.new()
	req.type = type
	req.game_entry = game_entry
	if priority:
		requests_queue.push_front(req)
	else:
		requests_queue.push_back(req)
	requests_semaphore.post()

func add_media_request(game_entry, priority: bool = false) -> int:
	var medias = RetroHubMedia.convert_type_bitmask_to_list(media_bitmask)
	# Invert medias due to the way requests are placed in queue
	medias.invert()
	var idx := 0
	if not priority:
		for i in range(requests_queue.size()):
			if requests_queue[i].type == Request.Type.MEDIA:
				idx = i
	for media in medias:
		var req := Request.new()
		req.type = Request.Type.MEDIA
		req.game_entry = game_entry
		req.data = media
		if priority:
			requests_queue.push_front(req)
		else:
			requests_queue.insert(idx, req)
		requests_semaphore.post()
	return medias.size()


func thread_fetch_game_entries():
	scraper.connect("game_scrape_finished", self, "t_on_game_scrape_finished")
	scraper.connect("game_scrape_multiple_available", self, "t_on_game_scrape_multiple_available")
	scraper.connect("game_scrape_not_found", self, "t_on_game_scrape_not_found")
	scraper.connect("game_scrape_error", self, "t_on_game_scrape_error")
	scraper.connect("media_scrape_finished", self, "t_on_media_scrape_finished")
	scraper.connect("media_scrape_not_found", self, "t_on_media_scrape_not_found")
	scraper.connect("media_scrape_error", self, "t_on_media_scrape_error")

	while true:
		processing_request_mutex.lock()
		# Wait for a scrape request
		requests_semaphore.wait()

		# Get a game entry to fetch
		requests_mutex.lock()
		if requests_queue.empty():
			processing_request_mutex.unlock()
			requests_mutex.unlock()
			break
		var req : Request = requests_queue.pop_front()
		var game_entry : RetroHubScraperGameEntry = req.game_entry
		requests_curr.push_back(req)
		requests_mutex.unlock()
		processing_request_mutex.unlock()
		
		# Retrieve game data and begin scraping it
		var game_data = game_entry.game_data
		game_entry.set_deferred("state", RetroHubScraperGameEntry.State.WORKING)
		match req.type:
			Request.Type.DATA_HASH:
				game_entry.curr = 0
				game_entry.total = 1
				game_entry.description = "metadata (by hash)"
				emit_signal("scrape_step", game_entry)
				if not scraper.scrape_game_by_hash(game_data):
					pending_datas[game_data] = req
			Request.Type.DATA_SEARCH:
				game_entry.curr = 0
				game_entry.total = 1
				game_entry.description = "metadata (by search)"
				emit_signal("scrape_step", game_entry)
				if not scraper.scrape_game_by_search(game_data, game_entry.data):
					pending_datas[game_data] = req
			Request.Type.MEDIA:
				if scraper.scrape_media(game_data, req.data):
					# This requested media doesn't exist, so skip it
					requests_curr.erase(req)
					game_entry.curr += 1

	scraper.disconnect("game_scrape_finished", self, "t_on_game_scrape_finished")
	scraper.disconnect("game_scrape_multiple_available", self, "t_on_game_scrape_multiple_available")
	scraper.disconnect("game_scrape_not_found", self, "t_on_game_scrape_not_found")
	scraper.disconnect("game_scrape_error", self, "t_on_game_scrape_error")
	scraper.disconnect("media_scrape_finished", self, "t_on_media_scrape_finished")
	scraper.disconnect("media_scrape_not_found", self, "t_on_media_scrape_not_found")
	scraper.disconnect("media_scrape_error", self, "t_on_media_scrape_error")

func _ensure_valid_req(game_data):
	if not pending_datas.has(game_data):
		for req in requests_curr:
			if req.game_entry.game_data == game_data:
				return req
		return null
	else:
		return pending_datas[game_data]

func t_on_game_scrape_finished(game_data: RetroHubGameData):
	var req : Request = _ensure_valid_req(game_data)
	if not req:
		return
	var game_entry := req.game_entry
	requests_curr.erase(req)
	pending_datas.erase(game_data)
	if not prepare_media_scrape(game_entry):
		_finish_scrape(game_entry)

func t_on_game_scrape_multiple_available(game_data: RetroHubGameData, results: Array):
	var req : Request = _ensure_valid_req(game_data)
	if not req:
		return
	var game_entry := req.game_entry
	requests_curr.erase(req)
	pending_datas.erase(game_data)
	game_entry.set_deferred("data", results)
	game_entry.set_deferred("state", RetroHubScraperGameEntry.State.WARNING)

func t_on_game_scrape_not_found(game_data: RetroHubGameData):
	var req : Request = _ensure_valid_req(game_data)
	if not req:
		return
	var game_entry := req.game_entry
	requests_curr.erase(req)
	pending_datas.erase(game_data)
	if req.type == Request.Type.DATA_HASH:
		game_entry.data = game_entry.game_data.name
		requests_mutex.lock()
		add_data_request(game_entry, Request.Type.DATA_SEARCH, true);
		requests_mutex.unlock()

func t_on_game_scrape_error(game_data: RetroHubGameData, details: String):
	var req : Request = _ensure_valid_req(game_data)
	if not req:
		return
	var game_entry := req.game_entry
	requests_curr.erase(req)
	pending_datas.erase(game_data)
	game_entry.set_deferred("data", details)
	game_entry.set_deferred("state", RetroHubScraperGameEntry.State.ERROR)

func prepare_media_scrape(game_entry: RetroHubScraperGameEntry):
	if media_bitmask > 0:
		requests_mutex.lock()
		game_entry.curr = 0
		game_entry.total = add_media_request(game_entry)
		requests_mutex.unlock()
		game_entry.description = _convert_type_to_str(RetroHubMedia.convert_type_bitmask_to_list(media_bitmask)[0])
		pending_medias[game_entry.game_data] = game_entry
		return true
	return false

func t_on_media_scrape_finished(game_data: RetroHubGameData, type: int, data: PoolByteArray, extension: String):
	if pending_medias.has(game_data):
		# Save media
		var path = RetroHubConfig.get_gamemedia_dir() + "/" + \
					game_data.system.name + "/" + \
					RetroHubMedia.convert_type_to_media_path(type) + "/" + \
					game_data.path.get_file().get_basename() + \
					"." + extension
		FileUtils.ensure_path(path)
		var file := File.new()
		if file.open(path, File.WRITE):
			print("\tError when saving file ", path)
			return
		else:
			game_data.has_media = true
			file.store_buffer(data)
			file.close()

		var game_entry = pending_medias[game_data]
		for req in requests_curr:
			if req.game_entry == game_entry:
				requests_curr.erase(req)
				break
		game_entry.description = _convert_type_to_str(type)
		game_entry.curr += 1
		emit_signal("scrape_step", game_entry)
		if game_entry.curr >= game_entry.total:
			_finish_scrape(game_entry)

func t_on_media_scrape_not_found(game_data: RetroHubGameData, type: int):
	if pending_medias.has(game_data):
		var game_entry = pending_medias[game_data]
		for req in requests_curr:
			if req.game_entry == game_entry:
				requests_curr.erase(req)
				break
		game_entry.curr += 1
		emit_signal("scrape_step", game_entry)
		if game_entry.curr >= game_entry.total:
			_finish_scrape(game_entry)

func t_on_media_scrape_error(game_data: RetroHubGameData, type: int, details: String):
	t_on_media_scrape_not_found(game_data, type)

func _finish_scrape(game_entry: RetroHubScraperGameEntry):
	game_entry.set_deferred("state", RetroHubScraperGameEntry.State.SUCCESS)
	set_deferred("num_games_pending", num_games_pending - 1)
	call_deferred("update_games_pending")
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
			var scene_entry = system_entry_scene.instance()
			n_game_entries.add_child(scene_entry)
			scene_entry.system_name = game_data.system.fullname
			scene_entry_list[game_data.system] = scene_entry
		var game_entry = scene_entry_list[game_data.system].add_game_entry(game_data, button_group)
		game_entry.connect("game_selected", self, "_on_game_entry_selected")
		game_entry_list.push_back(game_entry)
	num_games_pending = game_list_arr.size()
	update_games_pending()

func update_games_pending():
	match num_games_pending:
		0:
			n_pending_games.text = "All games have been successfully scrapped"
		1:
			n_pending_games.text = "There is 1 game yet to be sucessfully scrapped"
		_:
			n_pending_games.text = "There are %d games yet to be successfully scrapped" % num_games_pending

func _on_game_entry_selected(game_entry: Control):
	n_game_entry_editor.current_tab = game_entry.state
	n_game_entry_editor.get_current_tab_control().set_entry(game_entry)


func _on_Warning_request_search(search: String, game_data: RetroHubGameData):
	for game_entry in game_entry_list:
		if game_entry.game_data == game_data:
			game_entry.data = search
			game_entry.state = RetroHubScraperGameEntry.State.WAITING
			requests_mutex.lock()
			add_data_request(game_entry, Request.Type.DATA_SEARCH, true)
			requests_mutex.unlock()
			break

func _on_Warning_search_completed(orig_game_data, new_game_data):
	for game_entry in game_entry_list:
		if game_entry.game_data == orig_game_data:
			game_entry.game_data = new_game_data
			game_entry.game_data.path = orig_game_data.path
			game_entry.game_data.system = orig_game_data.system
			game_entry.state = RetroHubScraperGameEntry.State.WAITING
			prepare_media_scrape(game_entry)
			break

func cancel_scrape(game_entry):
	# Cancel in data
	for game_data in pending_datas:
		if pending_datas[game_data].game_entry == game_entry:
			scraper.cancel(game_data)
			game_entry.set_deferred("data", "Canceled")
			game_entry.set_deferred("state", RetroHubScraperGameEntry.State.ERROR)

	# Cancel in media (current)
	for req in requests_curr:
		if req.type == Request.Type.MEDIA and req.game_entry == game_entry:
			scraper.cancel(game_entry.game_data)
			game_entry.set_deferred("data", "Canceled")
			game_entry.set_deferred("state", RetroHubScraperGameEntry.State.ERROR)
			break

	# Cancel in media (pending)
	# Don't lock if thread is waiting for job, otherwise a deadlock happens
	if requests_queue.empty():
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
		requests_semaphore.wait()
	requests_mutex.unlock()
	if pending_medias.has(game_entry.game_data):
		pending_medias.erase(game_entry.game_data)
	game_entry.set_deferred("data", "Canceled")
	game_entry.set_deferred("state", RetroHubScraperGameEntry.State.ERROR)
	processing_request_mutex.unlock()


func cancel_entry(game_entry):
	# Don't lock if thread is waiting for job, otherwise a deadlock happens
	if requests_curr.empty() and pending_datas.empty():
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
	requests_semaphore.wait()
	requests_mutex.unlock()
	game_entry.data = "Canceled"
	game_entry.state = RetroHubScraperGameEntry.State.ERROR
	processing_request_mutex.unlock()

func finish_scraping():
	scraper.cancel_all()

	requests_mutex.lock()
	requests_queue.clear()
	requests_semaphore.post()
	requests_mutex.unlock()
	thread.wait_to_finish()
	n_warning.stop_thread()
	
	remove_child(scraper)
	scraper.queue_free()
	# Save pending metadata
	for game_entry in game_entry_list:
		if game_entry.state != RetroHubScraperGameEntry.State.SUCCESS and game_entry.game_data.has_metadata:
			RetroHubConfig.save_game_data(game_entry.game_data)
	hide()

func _on_Finish_pressed():
	if num_games_pending > 0:
		n_stop_scraper_dialog.set_num_games_pending(num_games_pending)
		n_stop_scraper_dialog.popup_centered()
	else:
		finish_scraping()

func _on_StopScraperDialog_confirmed():
	finish_scraping()


func _on_Error_retry_entry(game_entry):
	requests_mutex.lock()
	# TODO: Hash or search?
	add_data_request(game_entry, Request.Type.DATA_HASH, true)
	requests_mutex.unlock()
	game_entry.state = RetroHubScraperGameEntry.State.WAITING


func _on_Waiting_cancel_entry(game_entry: Control):
	cancel_entry(game_entry)

func _on_Working_cancel_entry(game_entry):
	cancel_scrape(game_entry)
