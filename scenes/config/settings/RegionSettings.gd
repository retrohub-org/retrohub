extends Control

signal theme_reload

onready var n_region = $"%Region"
onready var n_rating_system = $"%RatingSystem"
onready var n_date_format = $"%DateFormat"

onready var n_genesis := $"%Genesis"
onready var n_nes := $"%NES"
onready var n_snes := $"%SNES"
onready var n_tg_16 := $"%TG16"
onready var n_tg_cd := $"%TGCD"
onready var n_odyssey2 := $"%Odyssey2"

onready var n_genesis_icon := $"%GenesisIcon"
onready var n_nes_icon := $"%NESIcon"
onready var n_snes_icon := $"%SNESIcon"
onready var n_tg_16_icon := $"%TG16Icon"
onready var n_tgcd_icon := $"%TGCDIcon"
onready var n_odyssey2_icon := $"%Odyssey2Icon"


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

func set_system_names(system_names: Dictionary):
	n_genesis.selected = 0 if system_names["genesis"] == "genesis" else 1
	n_nes.selected = 0 if system_names["nes"] == "nes" else 1
	n_snes.selected = 0 if system_names["snes"] == "snes" else 1
	n_tg_16.selected = 0 if system_names["tg16"] == "tg16" else 1
	n_tg_cd.selected = 0 if system_names["tg-cd"] == "tg-cd" else 1
	n_odyssey2.selected = 0 if system_names["odyssey2"] == "odyssey2" else 1
	n_genesis_icon.set_texture(load("res://assets/systems/%s-photo.png" % system_names["genesis"]))
	n_nes_icon.set_texture(load("res://assets/systems/%s-photo.png" % system_names["nes"]))
	n_snes_icon.set_texture(load("res://assets/systems/%s-photo.png" % system_names["snes"]))
	n_tg_16_icon.set_texture(load("res://assets/systems/%s-photo.png" % system_names["tg16"]))
	n_tgcd_icon.set_texture(load("res://assets/systems/%s-photo.png" % system_names["tg-cd"]))
	n_odyssey2_icon.set_texture(load("res://assets/systems/%s-photo.png" % system_names["odyssey2"]))

func _on_config_ready(config_data: ConfigData):
	set_region(config_data.region)
	set_rating_system(config_data.rating_system)
	set_date_format(config_data.date_format)
	set_system_names(config_data.system_names)

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


func _on_ResetRegion_pressed():
	n_rating_system.selected = n_region.selected
	n_date_format.selected = n_region.selected
	n_genesis.selected = 0 if n_region.selected == 0 else 1
	n_nes.selected = 1 if n_region.selected == 2 else 0
	n_snes.selected = 1 if n_region.selected == 2 else 0
	n_tg_16.selected = 1 if n_region.selected == 2 else 0
	n_tg_cd.selected = 1 if n_region.selected == 2 else 0
	n_odyssey2.selected = 0 if n_region.selected == 1 else 1
	# Manually call signals
	_on_RatingSystem_item_selected(n_rating_system.selected)
	_on_DateFormat_item_selected(n_date_format.selected)
	_on_Genesis_item_selected(n_genesis.selected)
	_on_NES_item_selected(n_nes.selected)
	_on_SNES_item_selected(n_snes.selected)
	_on_TG16_item_selected(n_tg_16.selected)
	_on_TGCD_item_selected(n_tg_cd.selected)
	_on_Odyssey2_item_selected(n_odyssey2.selected)

func _on_Genesis_item_selected(index):
	RetroHubConfig.config.system_names["genesis"] = "megadrive" if index == 1 else "genesis"
	n_genesis_icon.set_texture(load("res://assets/systems/%s-photo.png" % RetroHubConfig.config.system_names["genesis"]))
	emit_signal("theme_reload")


func _on_NES_item_selected(index):
	RetroHubConfig.config.system_names["nes"] = "famicom" if index == 1 else "nes"
	n_nes_icon.set_texture(load("res://assets/systems/%s-photo.png" % RetroHubConfig.config.system_names["nes"]))
	emit_signal("theme_reload")


func _on_SNES_item_selected(index):
	RetroHubConfig.config.system_names["snes"] = "sfc" if index == 1 else "snes"
	n_snes_icon.set_texture(load("res://assets/systems/%s-photo.png" % RetroHubConfig.config.system_names["snes"]))
	emit_signal("theme_reload")


func _on_TG16_item_selected(index):
	RetroHubConfig.config.system_names["tg16"] = "pcengine" if index == 1 else "tg16"
	n_tg_16_icon.set_texture(load("res://assets/systems/%s-photo.png" % RetroHubConfig.config.system_names["tg16"]))
	emit_signal("theme_reload")


func _on_TGCD_item_selected(index):
	RetroHubConfig.config.system_names["tg-cd"] = "pcenginecd" if index == 1 else "tg-cd"
	n_tgcd_icon.set_texture(load("res://assets/systems/%s-photo.png" % RetroHubConfig.config.system_names["tg-cd"]))
	emit_signal("theme_reload")


func _on_Odyssey2_item_selected(index):
	RetroHubConfig.config.system_names["odyssey2"] = "videopac" if index == 1 else "odyssey2"
	n_odyssey2_icon.set_texture(load("res://assets/systems/%s-photo.png" % RetroHubConfig.config.system_names["odyssey2"]))
	emit_signal("theme_reload")
