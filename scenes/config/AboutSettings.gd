extends Control

const WEBSITE_URL := "https://github.com/retrohub-org/retrohub"
const ISSUES_URL := "https://github.com/retrohub-org/retrohub/issues"

onready var n_version := $"%Version"
onready var n_engine_version := $"%EngineVersion"

onready var n_open_website_button = $"%OpenWebsiteButton"



# Called when the node enters the scene tree for the first time.
func _ready():
	n_version.text = n_version.text % RetroHub.version_str
	n_engine_version.text = n_engine_version.text % Engine.get_version_info()["string"]

func grab_focus():
	n_open_website_button.grab_focus()

func _on_RichTextLabel_meta_clicked(meta):
	if "http" in meta:
		OS.shell_open(meta)
		return
	# License text
	# TODO

func _on_OpenWebsiteButton_pressed():
	OS.shell_open(WEBSITE_URL)


func _on_OpenIssuesButton_pressed():
	OS.shell_open(ISSUES_URL)
