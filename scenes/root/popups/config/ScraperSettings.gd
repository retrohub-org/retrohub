extends Control

onready var n_service = $"%Service"
onready var n_games_selected = $"%GamesSelected"
onready var n_games_type = $"%GamesType"
onready var n_metadata = $"%Metadata"
onready var n_media = $"%Media"
onready var n_media_select_all = $"%MediaSelectAll"
onready var n_media_deselect_all = $"%MediaDeselectAll"
onready var n_media_logo = $"%MediaLogo"
onready var n_media_title_screen = $"%MediaTitleScreen"
onready var n_media_screenshot = $"%MediaScreenshot"
onready var n_media_video = $"%MediaVideo"
onready var n_media_box_render = $"%MediaBoxRender"
onready var n_media_box_tex = $"%MediaBoxTex"
onready var n_media_support_render = $"%MediaSupportRender"
onready var n_media_support_tex = $"%MediaSupportTex"
onready var n_media_manual = $"%MediaManual"
onready var n_scrape = $"%Scrape"

onready var n_scraping_game_picker_popup = $"%ScrapingGamePickerPopup"
onready var n_scrape_popup = $"%ScraperPopup"

onready var n_media_nodes = [
	n_media_logo,
	n_media_title_screen,
	n_media_screenshot,
	n_media_video,
	n_media_box_render,
	n_media_box_tex,
	n_media_support_render,
	n_media_support_tex,
	n_media_manual
]

var selected_game_datas : Array

func grab_focus():
	n_service.grab_focus()

func _on_Media_toggled(button_pressed):
	n_media_select_all.disabled = !button_pressed
	n_media_deselect_all.disabled = !button_pressed
	for node in n_media_nodes:
		node.disabled = !button_pressed


func _on_MediaSelectAll_pressed():
	for node in n_media_nodes:
		node.pressed = true


func _on_MediaDeselectAll_pressed():
	for node in n_media_nodes:
		node.pressed = false


func _on_GamesType_item_selected(index):
	update_scrape_stats(false)

func update_scrape_stats(passive: bool):
	selected_game_datas.clear()
	match n_games_type.selected:
		0:	# Selected only
			if RetroHub.curr_game_data:
				selected_game_datas.push_back(RetroHub.curr_game_data)
		1:	# Without metadata
			for game in RetroHubConfig.games:
				if not (game as RetroHubGameData).has_metadata:
					selected_game_datas.push_back(game)
		2:	# Without media
			for game in RetroHubConfig.games:
				if not (game as RetroHubGameData).has_media:
					selected_game_datas.push_back(game)
		3:	# All
			for game in RetroHubConfig.games:
				selected_game_datas.push_back(game)
		4:	# Custom
			if not passive:
				n_scraping_game_picker_popup.popup()
				selected_game_datas = yield(n_scraping_game_picker_popup, "games_selected")
	match selected_game_datas.size():
		0:
			n_games_selected.text = "No games selected"
		1:
			n_games_selected.text = "1 game selected"
		var size:
			n_games_selected.text = "%d games selected" % size
	n_scrape.disabled = selected_game_datas.empty()

func _on_Scrape_pressed():
	n_scrape_popup.popup()
	n_scrape_popup.begin_scraping(selected_game_datas)


func _on_ScraperSettings_visibility_changed():
	if visible:
		update_scrape_stats(true)


func _on_ScraperPopup_popup_hide():
	update_scrape_stats(true)
