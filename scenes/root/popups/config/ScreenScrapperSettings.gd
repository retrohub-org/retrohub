extends VBoxContainer

onready var n_use_account = $"%UseAccount"
onready var n_username = $"%Username"
onready var n_password = $"%Password"

# Called when the node enters the scene tree for the first time.
func _ready():
	RetroHubConfig.connect("config_ready", self, "_on_config_ready")


func _on_config_ready(config_data: ConfigData):
	n_use_account.pressed = config_data.scraper_ss_use_custom_account
	n_username.text = config_data.scraper_ss_username
	n_password.text = config_data.scraper_ss_password


func _on_ShowPassword_toggled(button_pressed):
	n_password.secret = !button_pressed


func _on_Username_text_changed(new_text):
	RetroHubConfig.config.scraper_ss_username = new_text


func _on_Password_text_changed(new_text):
	RetroHubConfig.config.scraper_ss_password = new_text


func _on_UseAccount_toggled(button_pressed):
	RetroHubConfig.config.scraper_ss_use_custom_account = button_pressed
	n_username.editable = button_pressed
	n_password.editable = button_pressed
