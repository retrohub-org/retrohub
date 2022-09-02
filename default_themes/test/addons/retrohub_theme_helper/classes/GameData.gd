extends Resource
class_name RetroHubGameData

## Whether this game already has metadata; if it doesn't, you should
## present a much simpler view of it
var has_metadata : bool

## Whether this game has media to present; only check this if
## `has_metadata = true`
var has_media : bool

## From what system is this game from
var system_name : String

## Name; will default to `path` if no metadata is present yet
var name : String

## File's path
var path : String

### The following variables should only be considered if `has_metadata = true`
## Description/synopsis of the game.
var description : String

## Rating, in the range [0.0, 1.0]
var rating : float

## Release date, already pre-formatted to user's region.
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

## Age rating, already pre-formatted to user's region
var age_rating: ImageTexture

## Whether this game has been marked as favorite by the user
var favorite : bool

## How many times with game was launched/played
var play_count : int

## Last date this game was played, already pre-formatted to user's region.
## May be "null" if game hasn't been played yet
var last_played : String
