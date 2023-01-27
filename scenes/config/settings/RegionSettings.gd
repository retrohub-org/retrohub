extends Control

onready var n_region = $"%Region"
onready var n_rating_system = $"%RatingSystem"
onready var n_date_format = $"%DateFormat"


# Called when the node enters the scene tree for the first time.
func _ready():
	RetroHubConfig.connect("config_ready", self, "_on_config_ready")
	RetroHubConfig.connect("config_updated", self, "_on_config_updated")

func grab_focus():
	n_region.grab_focus()

func set_region(region: String):
	match region:
		"usa":
			n_region.selected = 0
		"eur":
			n_region.selected = 1
		"jpn":
			n_region.selected = 2

func set_rating_system(rating_system: String):
	match rating_system:
		"esrb":
			n_rating_system.selected = 0
		"pegi":
			n_rating_system.selected = 1
		"cero":
			n_rating_system.selected = 2

func set_date_format(date_format: String):
	match date_format:
		"mm/dd/yyyy":
			n_date_format.selected = 0
		"dd/mm/yyyy":
			n_date_format.selected = 1
		"yyyy/mm/dd":
			n_date_format.selected = 2

func _on_config_ready(config_data: ConfigData):
	set_region(config_data.region)
	set_rating_system(config_data.rating_system)
	set_date_format(config_data.date_format)

func _on_config_updated(key: String, _old_value, new_value):
	match key:
		ConfigData.KEY_REGION:
			set_region(new_value)
		ConfigData.KEY_RATING_SYSTEM:
			set_rating_system(new_value)
		ConfigData.KEY_DATE_FORMAT:
			set_date_format(new_value)

func _on_Region_item_selected(index):
	match index:
		0:	# USA
			RetroHubConfig.config.region = "usa"
		1:	# Europe
			RetroHubConfig.config.region = "eur"
		2:	# Japan
			RetroHubConfig.config.region = "jpn"


func _on_RatingSystem_item_selected(index):
	match index:
		0:	# ESRB
			RetroHubConfig.config.rating_system = "esrb"
		1:	# PEGI
			RetroHubConfig.config.rating_system = "pegi"
		2:	# CERO
			RetroHubConfig.config.rating_system = "cero"


func _on_DateFormat_item_selected(index):
	match index:
		0:	# mm/dd/yyyy
			RetroHubConfig.config.date_format  = "mm/dd/yyyy"
		1:	# dd/mm/yyyy
			RetroHubConfig.config.date_format = "dd/mm/yyyy"
		2:	# yyyy/mm/dd
			RetroHubConfig.config.date_format = "yyyy/mm/dd"

func _on_AppSettings_hide():
	RetroHubConfig.save_config()
