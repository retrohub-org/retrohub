extends Resource
class_name RetroHubSystemData

enum Category {
	Console,		# Retro console
	Arcade,			# Arcade machines
	Computer,		# Old computer
	GameEngine,		# General game engines
	ModernConsole	# Modern consoles (7th generation upwards)
}

## Short identifier name for this system. You can use this to uniquely identify this system
var name : String

## Full descriptive system name. Use this to present the system's name for the user
var fullname : String

## Platform of this system. Multiple systems might belong to the same platform
## (for example, n64 and 64dd are different consoles but on same platform: n64)
var platform : String

## System category, from Category enum
var category : int

## Num of games detected for this system
var num_games : int
