extends VBoxContainer

@onready var n_options := $"%DateOptions"
@onready var n_example := $"%ExampleDate"

func select(idx: int):
	n_options.select(idx)
	_on_DateOptions_item_selected(idx)

func _ready():
	_on_DateOptions_item_selected(n_options.selected)


func _on_DateOptions_item_selected(index):
	match index:
		0:
			RetroHubConfig.config.date_format = "mm/dd/yyyy"
		1:
			RetroHubConfig.config.date_format = "dd/mm/yyyy"
		2:
			RetroHubConfig.config.date_format = "yyyy/mm/dd"


func _on_Timer_timeout():
	var time := Time.get_datetime_dict_from_system()
	var raw_time := "%04d%02d%02dT%02d%02d%02d" % [
			time["year"], time["month"], time["day"],
			time["hour"], time["minute"], time["second"]
	]
	n_example.text = RegionUtils.localize_date(raw_time)

func tts_text(focused: Control) -> String:
	if focused == n_options:
		return tts_popup_menu_item_text(n_options.selected, n_options.get_popup()) + ". button"
	return ""

func tts_popup_menu_item_text(idx: int, menu: PopupMenu) -> String:
	if menu == n_options.get_popup():
		match idx:
			0:
				return "month/day/year"
			1:
				return "day/month/year"
			2:
				return "year/month/day"
	return ""
