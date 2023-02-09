extends Resource
class_name RetroHubGameData

# Sorter function
static func sort(a: RetroHubGameData, b: RetroHubGameData):
	return a.name.naturalnocasecmp_to(b.name) == -1

func duplicate(_subresources: bool = false) -> Resource:
	var other = .duplicate(_subresources)
	other.copy_from(self)

	return other

func copy_from(other: RetroHubGameData) -> void:
	has_metadata = other.has_metadata
	has_media = other.has_media
	system = other.system
	system_path = other.system_path
	name = other.name
	path = other.path
	description = other.description
	rating = other.rating
	release_date = other.release_date
	developer = other.developer
	publisher = other.publisher
	genres = other.genres.duplicate()
	num_players = other.num_players
	age_rating = other.age_rating
	favorite = other.favorite
	play_count = other.play_count
	last_played = other.last_played

## Whether this game already has metadata; if it doesn't, you should
## present a much simpler view of it
var has_metadata : bool

## Whether this game has media to present; only check this if
## `has_metadata = true`
var has_media : bool

## From what system is this game from
var system : RetroHubSystemData

## From what "loaded" system path this game is from
var system_path : String

## Name; will default to `path` if no metadata is present yet
var name : String

## File's path
var path : String

### The following variables should only be considered if `has_metadata = true`
## Description/synopsis of the game.
var description : String

## Rating, in the range [0.0, 1.0]
var rating : float

## Release date in ISO8601 format. Use RegionUtils.localize_date(...) to show this
## information correctly according to the user's preferences.
var release_date : String

## Developer name
var developer : String

## Publisher name
var publisher : String

## Game genres, as Strings
var genres : Array

## No. of players; it's a string because it can depend, such as 1-2 or 2-4.
## You can however still parse this as you see fit, as it will always be of the format
## "{min_players}-{max_players}", even if in singleplayer (1-1)
var num_players : String

## Age rating in a "raw" format, with ratings for all systems available.
## To present the appropriate rating label, use RegionUtils.localize_age_rating(...)
var age_rating: String

## Whether this game has been marked as favorite by the user
var favorite : bool

## How many times with game was launched/played
var play_count : int

## Last date this game was played, in ISO8601 format. Use RegionUtils.localize_date(...)
## to show this information correctly according to the user's preferences.
## May be equal to "null" if game hasn't been played yet
var last_played : String
