extends Node
class_name RetroHubScraper

# Signals that a game scrape has finished successfully, returning the
# altered game data
signal game_scrape_finished(game_data)
# Signals that a game scrape is incomplete since there are multiple
# possible results. Returns the list of game datas of all results.
# A further scrape must be done under one of these datas to uniquely
# identify it and finish the scraping process properly
signal game_scrape_multiple_available(game_data, results)
# Signals that a game scrape has failed because no results were found.
signal game_scrape_not_found(game_data)
# Signals that a game scrape resulted in an error, returning further
# details to show to the user
signal game_scrape_error(game_data, details)

# Signals that a media scrape has completed, returning it's
# type (from RetroHubMedia), raw content and file extension
signal media_scrape_finished(game_data, type, data, extension)
# Signals that a media scrape has failed because no results were found.
signal media_scrape_not_found(game_data, type)
# Signals that a media scrape resulted in an error, returning further
# details to show to the user
signal media_scrape_error(game_data, type, details)


## All of these functions will be run in a thread, and can run
## multiple times. To properly support simultaneous requests, the
## supplied game data is used to uniquely identifying a request.
## The main app will be constantly calling these scraping methods
## without limit, so it's up to each scraper to control how many
## simultaneous requests to allow. When the limit is reached the
## function must block until it can be processed. The best way to
## implement this behavior is through a semaphore so the scraper
## doesn't do busy waits.

# Start a metadata scrape by the game file's hash.
# This allows a scrape to be unique regardless
# of the game's local filenames. If the game
# cannot be uniquely identified by this
# method, this should signal "game_scrape_not_found"
func scrape_game_by_hash(game_data: RetroHubGameData) -> int:
	return -1

# Start a metadata scrape by searching with a given search them.
# This allows possibly multiple scrape results, in
# which case this function must signal "game_scrape_multiple_available", and
# "game_scrape_not_found" if there are no results.
func scrape_game_by_search(game_data: RetroHubGameData, search_term: String) -> int:
	return -1

# Start a media scrape for a specific media type. This will
# download a media file and return it's raw content. The main app
# will always call this ONLY after a successfull game data scrape.
# media_type should be a value from RetroHubMedia.Type enum.
# This function can fail immediately, in which case the main app will "skip" this
# media file.
func scrape_media(game_data: RetroHubGameData, media_type: int) -> int:
	return -1

# Marks a given game data as fully scraped. The app won't require any more
# information from it, so any data associated with it can be freed by
# the scraper. If the app eventually needs to rescrape it for some reason
# it will restart the whole process of scraping without prior assumptions
func scrape_completed(game_data: RetroHubGameData) -> void:
	return

# Cancels a pending request associated with a game data. This function
# must return immediately. A given request might still finish even
# after cancelation depending on it's state, in which case it will
# be ignored by the app but may still be cached by the scraper.
func cancel(game_data: RetroHubGameData) -> void:
	return

# Cancels all pending requests. This function must return immediately.
func cancel_all() -> void:
	return