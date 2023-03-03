extends Node
class_name RetroHubScraper

# Signals that a game scrape has finished successfully, returning the
# modified game data.
#warning-ignore:unused_signal
signal game_scrape_finished(game_data)
# Signals that a game scrape is incomplete since there are multiple
# possible results. Returns the list of game datas of all results.
# A further scrape will be called under one of these datas to uniquely
# identify it and finish the scraping process properly.
#warning-ignore:unused_signal
signal game_scrape_multiple_available(game_data, results)
# Signals that a game scrape has failed because no results were found.
#warning-ignore:unused_signal
signal game_scrape_not_found(game_data)
# Signals that a game scrape resulted in an error, returning further
# details to show to the user.
#warning-ignore:unused_signal
signal game_scrape_error(game_data, details)

# Signals that a media scrape has completed, returning it's
# type (from RetroHubMedia), raw content and file extension.
#warning-ignore:unused_signal
signal media_scrape_finished(game_data, type, data, extension)
# Signals that a media scrape has failed because no results were found.
#warning-ignore:unused_signal
signal media_scrape_not_found(game_data, type)
# Signals that a media scrape resulted in an error, returning further
# details to show to the user.
#warning-ignore:unused_signal
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
# This allows a scrape to be uniquely identified regardless of the
# game filenames. If the game cannot be uniquely identified by this
# method, this should signal "game_scrape_not_found". RetroHub may
# then try doing a scrape by search if configured to do so.
func scrape_game_by_hash(_game_data: RetroHubGameData) -> int:
	return -1

# Start a metadata scrape by searching by the supplied search term.
# This may result in multiple scrape results, in which case this
# function must signal `game_scrape_multiple_available`. If no results
# are found, it should signal "game_scrape_not_found".
func scrape_game_by_search(_game_data: RetroHubGameData, _search_term: String) -> int:
	return -1

# Start a media scrape for a specific media type. This will
# download a media file and must return it's raw content. The main app
# will always call this ONLY after a successfull game data scrape.
# `media_type` is a value from the RetroHubMedia.Type enum.
# `game_data` may be either an original existing game data or one of the
# temporary datas returned in the `game_scrape_multiple_available` signal.
# This function can fail immediately, in which case the main app will
# skip this media file.
func scrape_media(_game_data: RetroHubGameData, _media_type: int) -> int:
	return -1

# Start a media scrape for a specific media type. This will
# download a media file and return it's raw content. The main app
# will call this function instead of the `scrape_media` if this data was
# manually picked by the user from search results, where `orig_game_data`
# is the original file to modify, and `search_game_data` the temporary data
# this scraper returned on the `game_scrape_multiple_available` signal.
# `media_type` is a value from the RetroHubMedia.Type enum.
# This function can fail immediately, in which case the main app will
# skip thimedia file.
func scrape_media_from_search(_orig_game_data: RetroHubGameData, _search_game_data: RetroHubGameData, _media_type: int) -> int:
	return -1

# Marks a given game data as fully scraped, meaning RetroHub won't require any more
# information from it, and so any data associated with it can be freed by
# the scraper. If the app needs to rescrape it for some reason, it will
# restart the scraping process of without prior assumptions
func scrape_completed(_game_data: RetroHubGameData) -> void:
	return

# Cancels a pending request associated with a game data. This function
# must return immediately. A given request might still finish even
# after cancelation depending on it's state, but will be ignored by
# RetroHub.
func cancel(_game_data: RetroHubGameData) -> void:
	return

# Cancels all pending requests. This function must return immediately.
# Some requests might still finish even after cancelation depending on
# it's state, but will be ignored by RetroHub.
func cancel_all() -> void:
	return
