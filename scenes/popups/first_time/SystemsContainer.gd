extends VBoxContainer

onready var n_genesis_opt := $"%GenesisOpt"
onready var n_nes_opt := $"%NESOpt"
onready var n_snes_opt := $"%SNESOpt"
onready var n_tg_16_opt := $"%TG16Opt"
onready var n_tg_cd_opt := $"%TGCDOpt"
onready var n_odyssey2_opt := $"%Odyssey2Opt"

onready var n_genesis_icon := $"%GenesisIcon"
onready var n_nes_icon := $"%NESIcon"
onready var n_snes_icon := $"%SNESIcon"
onready var n_tg_16_icon := $"%TG16Icon"
onready var n_tgcd_icon := $"%TGCDIcon"
onready var n_odyssey2_icon := $"%Odyssey2Icon"

func select(idx: int):
	set_system_regions(idx)

func set_system_regions(index: int):
	# 0 = USA, 1 = Europe, 2 = Japan
	set_genesis_region(0 if index == 0 else 1)
	set_nes_region(1 if index == 2 else 0)
	set_snes_region(1 if index == 2 else 0)
	set_tg16_region(1 if index == 2 else 0)
	set_tgcd_region(1 if index == 2 else 0)
	set_odyssey2_region(0 if index == 1 else 1)

func set_genesis_region(index: int):
	n_genesis_opt.selected = index
	RetroHubConfig.config.system_names["genesis"] = "genesis" if index == 0 else "megadrive"
	n_genesis_icon.texture = load("res://assets/systems/%s-photo.png" % RetroHubConfig.config.system_names["genesis"])

func set_nes_region(index: int):
	n_nes_opt.selected = index
	RetroHubConfig.config.system_names["nes"] = "nes" if index == 0 else "famicom"
	n_nes_icon.texture = load("res://assets/systems/%s-photo.png" % RetroHubConfig.config.system_names["nes"])

func set_snes_region(index: int):
	n_snes_opt.selected = index
	RetroHubConfig.config.system_names["snes"] = "snes" if index == 0 else "sfc"
	n_snes_icon.texture = load("res://assets/systems/%s-photo.png" % RetroHubConfig.config.system_names["snes"])

func set_tg16_region(index: int):
	n_tg_16_opt.selected = index
	RetroHubConfig.config.system_names["tg16"] = "tg16" if index == 0 else "pcengine"
	n_tg_16_icon.texture = load("res://assets/systems/%s-photo.png" % RetroHubConfig.config.system_names["tg16"])

func set_tgcd_region(index: int):
	n_tg_cd_opt.selected = index
	RetroHubConfig.config.system_names["tg-cd"] = "tg-cd" if index == 0 else "pcenginecd"
	n_tgcd_icon.texture = load("res://assets/systems/%s-photo.png" % RetroHubConfig.config.system_names["tg-cd"])

func set_odyssey2_region(index: int):
	n_odyssey2_opt.selected = index
	RetroHubConfig.config.system_names["odyssey2"] = "odyssey2" if index == 0 else "videopac"
	n_odyssey2_icon.texture = load("res://assets/systems/%s-photo.png" % RetroHubConfig.config.system_names["odyssey2"])
