extends Popup

export(int, 1, 100) var max_queued_scrapes : int
export(PackedScene) var system_entry_scene : PackedScene

onready var n_game_entries := $"%GameEntries"
onready var n_game_entry_editor := $"%GameEntryEditor"
onready var n_pending_games := $"%PendingGames"
onready var n_finish := $"%Finish"

onready var button_group := ButtonGroup.new()

var game_list_arr : Array
var scene_entry_list := {}
var game_entry_list := []

var num_games_pending : int

# Thread variables
var thread := Thread.new()
var games_semaphore := Semaphore.new()
var games_mutex := Mutex.new()
var games_queue := []

var t_scrape_semaphore := Semaphore.new()
var t_scrape_data_errcode : int
var t_scrape_media_errcode : int

func begin_scraping(_game_list_arr: Array):
	game_list_arr = _game_list_arr
	populate_game_entries()
	fetch_game_entries_async()
	n_game_entries.get_child(0).grab_focus()

func fetch_game_entries_async():
	games_mutex.lock()
	games_queue.clear()
	for game_entry in game_entry_list:
		games_queue.push_back(game_entry)
		games_semaphore.post()
	games_mutex.unlock()
	
	thread.start(self, "thread_fetch_game_entries")

func thread_fetch_game_entries():
	RetroHubMediaHelper.connect("game_scrape_finished", self, "t_on_game_scrape_finished")
	RetroHubMediaHelper.connect("game_media_scrape_finished", self, "t_on_game_media_scrape_finished")

	while true:
		# Wait for a scrape request
		print("Waiting...")
		games_semaphore.wait()
		print("Waited")

		# Get a game entry to fetch
		print("Locking...")
		games_mutex.lock()
		print("Locked")
		if games_queue.empty():
			break
		var game_entry : RetroHubScraperGameEntry = games_queue.pop_front()
		games_mutex.unlock()
		print("Unlocked. Game entry is ", game_entry)
		
		# Retrieve game data and begin scraping it
		var game_data = game_entry.game_data
		t_scrape_data_errcode = -1
		t_scrape_media_errcode = -1
		print("Scraping..., fetch mode: ", game_entry.fetch_mode)
		if game_entry.fetch_mode & RetroHubScraperGameEntry.FETCH_METADATA:
			match game_entry.check_mode:
				RetroHubScraperGameEntry.CHECK_HASH:
					RetroHubMediaHelper.scrape_game_by_hash(game_data)
				RetroHubScraperGameEntry.CHECK_SEARCH:
					RetroHubMediaHelper.scrape_game_by_search(game_data, game_entry.data)
			t_scrape_semaphore.wait()
		if game_entry.fetch_mode & RetroHubScraperGameEntry.FETCH_MEDIA:
			RetroHubMediaHelper.scrape_game_media_data(game_data)
			t_scrape_semaphore.wait()
		print("Completed")

		match (t_scrape_media_errcode if t_scrape_media_errcode != -1 else t_scrape_data_errcode):
			RetroHubMediaHelper.Status.SUCCESS:
				game_entry.set_deferred("state", RetroHubScraperGameEntry.State.SUCCESS)
				set_deferred("num_games_pending", num_games_pending - 1)
				call_deferred("update_games_pending")
				RetroHubConfig.call_deferred("save_game_data", game_entry.game_data)
			RetroHubMediaHelper.Status.ERROR:
				game_entry.set_deferred("data", RetroHubMediaHelper.get_status_details())
				game_entry.set_deferred("state", RetroHubScraperGameEntry.State.ERROR)
			RetroHubMediaHelper.Status.MULTIPLE_AVAILABLE:
				game_entry.set_deferred("data", RetroHubMediaHelper.get_status_details())
				game_entry.set_deferred("state", RetroHubScraperGameEntry.State.WARNING)

func t_on_game_scrape_finished(errcode: int):
	t_scrape_data_errcode = errcode
	t_scrape_semaphore.post()

func t_on_game_media_scrape_finished(errcode: int):
	t_scrape_media_errcode = errcode
	t_scrape_semaphore.post()

func populate_game_entries():
	for game_data in game_list_arr:
		if not scene_entry_list.has(game_data.system_name):
			var scene_entry = system_entry_scene.instance()
			n_game_entries.add_child(scene_entry)
			scene_entry.system_name = RetroHubConfig.systems[game_data.system_name].fullname
			scene_entry_list[game_data.system_name] = scene_entry
		var game_entry = scene_entry_list[game_data.system_name].add_game_entry(game_data, button_group)
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
			game_entry.state = RetroHubScraperGameEntry.State.WORKING
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
			game_entry.state = RetroHubScraperGameEntry.State.WORKING
			game_entry.fetch_mode = RetroHubScraperGameEntry.FETCH_MEDIA
			games_mutex.lock()
			games_queue.push_back(game_entry)
			games_semaphore.post()
			games_mutex.unlock()
			break

func _on_Finish_pressed():
	RetroHubMediaHelper.clear_cache()
	games_semaphore.post()
	thread.wait_to_finish()
	hide()
