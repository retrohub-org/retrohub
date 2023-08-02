extends Control

@onready var n_intro_lbl := %IntroLabel
@onready var n_service := %Service
@onready var n_games_selected := %GamesSelected
@onready var n_games_type := %GamesType
@onready var n_metadata := %Metadata
@onready var n_search_by_hash := %Hash
@onready var n_search_by_name := %Filename
@onready var n_hash_max_size_lbl := %HashMaxSizeLabel
@onready var n_hash_max_size := %HashMaxSize
@onready var n_media := %Media
@onready var n_media_select_all := %MediaSelectAll
@onready var n_media_deselect_all := %MediaDeselectAll
@onready var n_media_logo := %MediaLogo
@onready var n_media_title_screen := %MediaTitleScreen
@onready var n_media_screenshot := %MediaScreenshot
@onready var n_media_video := %MediaVideo
@onready var n_media_box_render := %MediaBoxRender
@onready var n_media_box_tex := %MediaBoxTex
@onready var n_media_support_render := %MediaSupportRender
@onready var n_media_support_tex := %MediaSupportTex
@onready var n_media_manual := %MediaManual
@onready var n_scrape := %Scrape

@onready var n_scraping_game_picker_popup := %ScrapingGamePickerPopup
@onready var n_scrape_popup := %ScraperPopup

@onready var n_ss_settings := %ScreenScrapperSettings

@onready var n_media_nodes := [
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

func _ready():
	RetroHubConfig.config_ready.connect(_on_config_ready)

func _on_config_ready(config_data: ConfigData):
	set_hash_max_size_text(config_data.scraper_hash_file_size)
	n_hash_max_size.set_value_no_signal(convert_hash_size_to_range(config_data.scraper_hash_file_size))

func grab_focus():
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_intro_lbl.grab_focus()
	else:
		n_service.grab_focus()

func toggle_scrape_button():
	n_scrape.disabled = selected_game_datas.is_empty() or \
		!(n_metadata.button_pressed or n_media.button_pressed) or \
		!(n_search_by_hash.button_pressed or n_search_by_name.button_pressed)

func _on_Metadata_toggled(_button_pressed):
	toggle_scrape_button()

func _on_Media_toggled(button_pressed):
	toggle_scrape_button()
	n_media_select_all.disabled = !button_pressed
	n_media_deselect_all.disabled = !button_pressed
	for node in n_media_nodes:
		node.disabled = !button_pressed


func _on_MediaSelectAll_pressed():
	for node in n_media_nodes:
		node.button_pressed = true


func _on_MediaDeselectAll_pressed():
	for node in n_media_nodes:
		node.button_pressed = false


func _on_GamesType_item_selected(_index):
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
				n_scraping_game_picker_popup.popup_centered()
				selected_game_datas = await n_scraping_game_picker_popup.games_selected
	match selected_game_datas.size():
		0:
			n_games_selected.text = "No games selected"
		1:
			n_games_selected.text = "1 game selected"
		var selected_size:
			n_games_selected.text = "%d games selected" % selected_size
	toggle_scrape_button()

func get_media_bitmask() -> int:
	var bitmask := 0
	var idx := 0
	for media in n_media_nodes:
		bitmask |= int(media.button_pressed) << (idx)
		idx += 1
	return bitmask

func _on_Scrape_pressed():
	n_ss_settings.save_credentials()
	n_scrape_popup.popup_centered()
	var media_bitmask := get_media_bitmask()
	# TODO: Make Scraper generation dynamic according to selection
	var scraper := RetroHubScreenScraperScraper.new()
	n_scrape_popup.begin_scraping(selected_game_datas, scraper, n_metadata.button_pressed, n_media.button_pressed,
		n_search_by_hash.button_pressed, n_search_by_name.button_pressed, media_bitmask)


func _on_ScraperSettings_visibility_changed():
	if visible:
		update_scrape_stats(true)
	elif n_ss_settings:
		n_ss_settings.save_credentials()
		RetroHubConfig.save_config()

func convert_hash_size_from_range(value: float) -> int:
	# Value is actually an int
	var value_i := int(value)
	if value == 129:
		# Unlimited
		return 0
	if value >= 96:
		# 2GB to 10GB
		return 2048 + (value_i - 96) * 256
	elif value >= 64:
		# 512MB to 2GB
		return 512 + (value_i - 64) * 48
	elif value >= 32:
		# 64MB to 512MB
		return 64 + (value_i - 32) * 14
	elif value > 1:
		# 2MB to 64MB
		return (value_i - 1) * 2
	# 1MB
	return 1

func convert_hash_size_to_range(value: int):
	if value == 0:
		# Unlimited
		return 129
	if value >= 2048:
		# 2GB to 10GB
		@warning_ignore("integer_division")
		return 96 + (value - 2048) / 256
	elif value >= 512:
		# 512MB to 2GB
		@warning_ignore("integer_division")
		return 64 + (value - 512) / 48
	elif value >= 64:
		# 64MB to 512MB
		@warning_ignore("integer_division")
		return 32 + (value - 64) / 14
	elif value > 0:
		# 1MB to 64MB
		return value
	return 1

func _on_HashMaxSize_value_changed(value: float):
	var mb_size = convert_hash_size_from_range(value)
	RetroHubConfig.config.scraper_hash_file_size = mb_size
	set_hash_max_size_text(mb_size)

func set_hash_max_size_text(value: int):
	if value == 0:
		n_hash_max_size_lbl.text = "Unlimited"
	elif value > 1024:
		n_hash_max_size_lbl.text = "%.2f GB" % (value / 1024.0)
	else:
		n_hash_max_size_lbl.text = "%d MB" % value

func _on_Hash_toggled(button_pressed):
	toggle_scrape_button()
	n_hash_max_size.editable = button_pressed


func _on_Filename_toggled(_button_pressed):
	toggle_scrape_button()

func tts_range_value_text(value: float, node: Node) -> String:
	if node == n_hash_max_size:
		var hash_size := convert_hash_size_from_range(value)
		if hash_size == 0:
			return "Unlimited"
		elif hash_size >= 1024:
			return "%.2f GB" % (value / 1024.0)
		else:
			return "%d MB" % value
	return ""


func _on_ScraperPopup_visibility_changed():
	if not n_scrape_popup.visible:
		update_scrape_stats(true)
