extends VBoxContainer

onready var n_use_account := $"%UseAccount"
onready var n_username := $"%Username"
onready var n_password := $"%Password"

var changed := false

func _ready():
	#warning-ignore:return_value_discarded
	RetroHubConfig.connect("config_ready", self, "_on_config_ready")


func _on_config_ready(config_data: ConfigData):
	n_use_account.set_pressed_no_signal(config_data.scraper_ss_use_custom_account)
	n_username.editable = config_data.scraper_ss_use_custom_account
	n_password.editable = config_data.scraper_ss_use_custom_account
	n_username.text = RetroHubConfig._get_credential("scraper_ss_username")
	n_password.text = RetroHubConfig._get_credential("scraper_ss_password")


func _on_text_changed(_new_text):
	changed = true


func _on_ShowPassword_toggled(button_pressed):
	n_password.secret = !button_pressed


func _on_UseAccount_toggled(button_pressed):
	RetroHubConfig.config.scraper_ss_use_custom_account = button_pressed
	n_username.editable = button_pressed
	n_password.editable = button_pressed


func save_credentials():
	if changed:
		RetroHubConfig._set_credential("scraper_ss_username", n_username.text)
		RetroHubConfig._set_credential("scraper_ss_password", n_password.text)
		changed = false
