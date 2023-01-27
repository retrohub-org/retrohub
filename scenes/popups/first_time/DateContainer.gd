extends VBoxContainer

onready var n_options := $"%DateOptions"
onready var n_example := $"%ExampleDate"

func select(idx: int):
	n_options.select(idx)
	_on_DateOptions_item_selected(idx)

# Called when the node enters the scene tree for the first time.
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
	var time = Time.get_datetime_dict_from_system()
	var raw_time = "%04d%02d%02dT%02d%02d%02d" % [
			time["year"], time["month"], time["day"],
			time["hour"], time["minute"], time["second"]
	]
	n_example.text = RegionUtils.localize_date(raw_time)
