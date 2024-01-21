extends VBoxContainer

const WEB_PAGE := "https://retroachievements.org/"
const SETUP_PAGE := "https://retrohub.readthedocs.io/en/latest/user_guide/integrations/retroachievements/index.html"

@onready var n_integration_name := %IntegrationName
@onready var n_integration_description := %IntegrationDescription
@onready var n_integration_enabled := %IntegrationEnabled
@onready var n_open_website := %OpenWebsite
@onready var n_setup_guide := %SetupGuide
@onready var n_username := %Username
@onready var n_show_password := %ShowPassword
@onready var n_web_api := %WebAPI

var changed := false

# Called when the node enters the scene tree for the first time.
func _ready():
	RetroHubConfig.config_ready.connect(_on_config_ready)

func _on_config_ready(data: ConfigData):
	n_integration_enabled.set_pressed_no_signal(data.integration_rcheevos_enabled)
	n_username.editable = n_integration_enabled.button_pressed
	n_web_api.editable = n_integration_enabled.button_pressed
	n_username.text = RetroHubConfig._get_credential("rcheevos_username")
	n_web_api.text = RetroHubConfig._get_credential("rcheevos_api_key")

func grab_focus():
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_integration_name.grab_focus()
	else:
		n_integration_enabled.grab_focus()

func tts_text(focused: Control):
	if focused == n_integration_name:
		return n_integration_name.text + ". " + n_integration_description.text
	return ""

func _on_integration_enabled_toggled(toggled_on: bool):
	RetroHubConfig.config.integration_rcheevos_enabled = toggled_on
	n_username.editable = toggled_on
	n_web_api.editable = toggled_on


func _on_open_website_pressed():
	OS.shell_open(WEB_PAGE)


func _on_setup_guide_pressed():
	OS.shell_open(SETUP_PAGE)


func _on_text_changed(new_text):
	changed = true


func save_credentials():
	if changed:
		RetroHubConfig._set_credential("rcheevos_username", n_username.text)
		RetroHubConfig._set_credential("rcheevos_api_key", n_web_api.text)
		changed = false


func _on_show_password_toggled(toggled_on: bool):
	n_web_api.secret = not toggled_on
