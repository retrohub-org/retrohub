extends Resource
class_name RetroHubGameData

enum BoxTextureRegions {
	BACK,
	SPINE,
	FRONT,
}

# Sorter function
static func sort(a: RetroHubGameData, b: RetroHubGameData):
	return a.name.naturalnocasecmp_to(b.name) == -1

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
	emulator = other.emulator
	box_texture_regions = other.box_texture_regions.duplicate()

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

## Custom emulator to run this game on, overriding default values.
## If non-empty, specifies a valid emulator name
var emulator : String

## Information about box texture regions. This is a dictionary of
## Rect2 dimensions, with range [0.0 , 1.0] delimiting the regions of the box texture.
## (use `RetroHubMedia.get_box_texture_region` to fetch the region's sub-Texture)
var box_texture_regions : Dictionary = {}
