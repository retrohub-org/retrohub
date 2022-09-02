extends Node

# _ready function, called everytime the theme is loaded
func _ready():
	# App related signals
	RetroHub.connect("app_initialized", self, "_on_app_initialized")
	RetroHub.connect("app_closed", self, "_on_app_closed")
	RetroHub.connect("app_received_focus", self, "_on_app_received_focus")
	RetroHub.connect("app_lost_focus", self, "_on_app_lost_focus")
	RetroHub.connect("app_returning", self, "_on_app_returning")

	# Content related signals
	RetroHub.connect("system_receive_start", self, "_on_system_receive_start")
	RetroHub.connect("system_received", self, "_on_system_received")
	RetroHub.connect("system_receive_end", self, "_on_system_receive_end")

	RetroHub.connect("game_receive_start", self, "_on_game_receive_start")
	RetroHub.connect("game_received", self, "_on_game_received")
	RetroHub.connect("game_receive_end", self, "_on_game_receive_end")

#_process function, called at every frame
func _process(delta):
	pass

#_unhandled_input, called at every input event
# use this function for input (not _input/_process) for proper behavior
func _unhandled_input(event):
	pass

## Called when RetroHub is initializing your theme.
## This can either happen when RetroHub is launching, or
## the theme was changed to this one.
func _on_app_initialized(cold_boot : bool):
	pass

## Called when RetroHub is unitializing your theme.
## This can either happen when RetroHub is closing, or
## the theme was changed to another one.
##
## While this function can block for the duration needed
## (if, for example, you want a custom "exiting" animation),
## do not do anything that takes too long.
func _on_app_closed():
	pass

## Called when RetroHub window receives focus without any current game launched.
## Use this for any behavior desired (for example, re-enabling audio streams)
func _on_app_received_focus():
	pass

## Called when RetroHub window loses focus without any current game launched.
## Use this for any behavior desired (for example, muting audio streams)
func _on_app_lost_focus():
	pass

## Called when RetroHub is returning from a launched game back into focus.
## The way RetroHub works, signals "app_initialized", "app_received_focus",
## and all "system_received" and "game_received" signals are sent before this
## signal is fired, as themes are unloaded during games to reduce memory footprint.
##
## Use this signal to recreate the UI state as it was before launching the game.
func _on_app_returning(system_data: RetroHubSystemData, game_data: RetroHubGameData):
	pass

## Called when RetroHub is about to send all system data.
func _on_system_receive_start():
	pass

## Called when RetroHub has information of a game system available.
## It's your job to display the system information in the UI. All the information
## given to you is only of currently detected systems, and not all systems that
## RetroHub supports.
##
## System information always arrives before game information.
func _on_system_received(data: RetroHubSystemData):
	pass

## Called when RetroHub has finished sending all system data.
## Game data will follow immediately after that.
func _on_system_receive_end():
	pass

## Called when RetroHub is about to send all game data.
## At this point, all system data has been sent to the theme.
func _on_game_receive_start():
	pass

## Called when RetroHub has information of a game available.
## It's your job to display the game information, as well as a game list per system,
## in the UI. All the information given to you is only of currently available games.
##
## Game information always arrives after system information.
func _on_game_received(data: RetroHubGameData):
	pass

## Called when RetroHub has finished sending all game data.
func _on_game_receive_end():
	pass
