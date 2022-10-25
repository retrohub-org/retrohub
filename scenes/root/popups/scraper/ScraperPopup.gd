extends Popup

export(int, 1, 100) var max_queued_scrapes : int
export(PackedScene) var system_entry_scene : PackedScene

onready var n_game_entries := $"%GameEntries"
onready var n_game_entry_editor := $"%GameEntryEditor"
onready var n_pending_games := $"%PendingGames"
onready var n_finish := $"%Finish"

onready var n_stop_scraper_dialog := $"%StopScraperDialog"

onready var button_group := ButtonGroup.new()

var game_list_arr : Array
var scene_entry_list := {}
var game_entry_list := []

var num_games_pending : int

# Thread variables
var thread : Thread
var games_semaphore : Semaphore
var games_mutex := Mutex.new()
var games_queue := []

var t_scrape_semaphore : Semaphore
var t_scrape_data_errcode : int
var t_scrape_media_errcode : int

func begin_scraping(_game_list_arr: Array):
	game_list_arr = _game_list_arr
	clear_game_entries()
	populate_game_entries()
	fetch_game_entries_async()
	n_game_entries.get_child(0).grab_focus()

func fetch_game_entries_async():
	thread = Thread.new()
	games_semaphore = Semaphore.new()
	games_mutex.lock()
	games_queue.clear()
	for game_entry in game_entry_list:
		games_queue.push_back(game_entry)
		games_semaphore.post()
	games_mutex.unlock()
	
	thread.start(self, "thread_fetch_game_entries")

func thread_fetch_game_entries():
	print("Thread starting")
	RetroHubMedia.connect("game_scrape_finished", self, "t_on_game_scrape_finished")
	RetroHubMedia.connect("game_media_scrape_finished", self, "t_on_game_media_scrape_finished")
	t_scrape_semaphore = Semaphore.new()

	while true:
		# Wait for a scrape request
		print("Waiting...")
		games_semaphore.wait()
		#print("Waited")

		# Get a game entry to fetch
		#print("Locking...")
		games_mutex.lock()
		#print("Locked")
		if games_queue.empty():
			games_mutex.unlock()
			break
		var game_entry : RetroHubScraperGameEntry = games_queue.pop_front()
		games_mutex.unlock()
		#print("Unlocked. Game entry is ", game_entry)
		
		# Retrieve game data and begin scraping it
		var game_data = game_entry.game_data
		t_scrape_data_errcode = -1
		t_scrape_media_errcode = -1
		#print("Scraping..., fetch mode: ", game_entry.fetch_mode)
		game_entry.set_deferred("state", RetroHubScraperGameEntry.State.WORKING)
		if game_entry.fetch_mode & RetroHubScraperGameEntry.FETCH_METADATA:
			match game_entry.check_mode:
				RetroHubScraperGameEntry.CHECK_HASH:
					print("Blocking for metadata (hash)...")
					RetroHubMedia.scrape_game_by_hash(game_data)
				RetroHubScraperGameEntry.CHECK_SEARCH:
					print("Blocking for metadata (search)...")
					RetroHubMedia.scrape_game_by_search(game_data, game_entry.data)
			t_scrape_semaphore.wait()
		if not t_scrape_data_errcode and game_entry.fetch_mode & RetroHubScraperGameEntry.FETCH_MEDIA:
			RetroHubMedia.scrape_game_media_data(game_data)
			print("Blocking for media...")
			t_scrape_semaphore.wait()
		print("Completed")

		match (t_scrape_media_errcode if t_scrape_media_errcode != -1 else t_scrape_data_errcode):
			RetroHubMedia.Status.SUCCESS:
				game_entry.set_deferred("state", RetroHubScraperGameEntry.State.SUCCESS)
				set_deferred("num_games_pending", num_games_pending - 1)
				call_deferred("update_games_pending")
				RetroHubConfig.call_deferred("save_game_data", game_entry.game_data)
			RetroHubMedia.Status.ERROR, RetroHubMedia.Status.CANCELED:
				game_entry.set_deferred("data", RetroHubMedia.get_status_details())
				game_entry.set_deferred("state", RetroHubScraperGameEntry.State.ERROR)
			RetroHubMedia.Status.MULTIPLE_AVAILABLE:
				game_entry.set_deferred("data", RetroHubMedia.get_status_details())
				game_entry.set_deferred("state", RetroHubScraperGameEntry.State.WARNING)
	
	RetroHubMedia.disconnect("game_scrape_finished", self, "t_on_game_scrape_finished")
	RetroHubMedia.disconnect("game_media_scrape_finished", self, "t_on_game_media_scrape_finished")
	print("Thread ending")

func t_on_game_scrape_finished(errcode: int):
	t_scrape_data_errcode = errcode
	#print("Scrape finished with code ", errcode)
	t_scrape_semaphore.post()

func t_on_game_media_scrape_finished(errcode: int):
	t_scrape_media_errcode = errcode
	#print("Media scrape finished with code ", errcode)
	t_scrape_semaphore.post()

func clear_game_entries():
	for scene_entry in scene_entry_list.values():
		n_game_entries.remove_child(scene_entry)
		scene_entry.queue_free()
	scene_entry_list.clear()
	game_entry_list.clear()

func populate_game_entries():
	for game_data in game_list_arr:
		if not scene_entry_list.has(game_data.system.name):
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


func _on_Warning_request_search(search, game_data):
	for game_entry in game_entry_list:
		if game_entry.game_data == game_data:
			game_entry.data = search
			game_entry.state = RetroHubScraperGameEntry.State.WAITING
			game_entry.fetch_mode = RetroHubScraperGameEntry.FETCH_METADATA
			game_entry.check_mode = RetroHubScraperGameEntry.CHECK_SEARCH
			games_mutex.lock()
			games_queue.push_back(game_entry)
			games_semaphore.post()
			games_mutex.unlock()
			break


func _on_Warning_search_completed(orig_game_data, new_game_data):
	orig_game_data.has_metadata = true
	orig_game_data.name = new_game_data.name
	orig_game_data.description = new_game_data.description
	orig_game_data.rating = new_game_data.rating
	orig_game_data.release_date = new_game_data.release_date
	orig_game_data.developer = new_game_data.developer
	orig_game_data.publisher = new_game_data.name
	orig_game_data.genres = new_game_data.genres
	orig_game_data.num_players = new_game_data.num_players
	orig_game_data.age_rating = new_game_data.age_rating

	for game_entry in game_entry_list:
		if game_entry.game_data == orig_game_data:
			game_entry.state = RetroHubScraperGameEntry.State.WAITING
			game_entry.fetch_mode = RetroHubScraperGameEntry.FETCH_MEDIA
			games_mutex.lock()
			games_queue.push_back(game_entry)
			games_semaphore.post()
			games_mutex.unlock()
			break

func cancel_current_scrape():
	RetroHubMedia.cancel()

func cancel_entry(game_entry):
	games_mutex.lock()
	games_queue.remove(games_queue.find(game_entry))
	games_mutex.unlock()
	games_semaphore.wait()
	game_entry.data = "Canceled"
	game_entry.state = RetroHubScraperGameEntry.State.ERROR

func finish_scraping():
	games_mutex.lock()
	games_queue.clear()
	games_mutex.unlock()
	RetroHubMedia.cancel()
	games_semaphore.post()
	thread.wait_to_finish()
	RetroHubMedia.clear_cache()
	
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
	games_mutex.lock()
	games_queue.push_back(game_entry)
	games_mutex.unlock()
	games_semaphore.post()
	game_entry.state = RetroHubScraperGameEntry.State.WAITING


func _on_Waiting_cancel_entry(game_entry: Control):
	cancel_entry(game_entry)


func _on_Working_cancel_entry(game_entry):
	cancel_current_scrape()
