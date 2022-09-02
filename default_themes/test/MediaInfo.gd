extends VBoxContainer

var game_data : RetroHubGameData setget set_game_data
var game_media_data : RetroHubGameMediaData setget set_game_media_data

func set_game_data(_game_data: RetroHubGameData):
	game_data = _game_data
	
	$Name.text = "Name: " + game_data.name + " (" + game_data.path + ")"
	$Description.text = "Description: " + game_data.description

func set_game_media_data(_game_media_data: RetroHubGameMediaData):
	game_media_data = _game_media_data
	
	$Logo.texture = game_media_data.logo
	$SS.texture = game_media_data.screenshot
	$TitleScreen.texture = game_media_data.title_screen
	$BoxRender.texture = game_media_data.box_render
	$BoxTex.texture = game_media_data.box_texture
	$Support.texture = game_media_data.support
	$Video.stream = game_media_data.video
	$Video.play()
