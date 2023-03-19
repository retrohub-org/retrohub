extends VBoxContainer

onready var n_use_account := $"%UseAccount"
onready var n_username := $"%Username"
onready var n_password := $"%Password"
onready var n_thread_count_lbl := $"%ThreadCountLabel"
onready var n_thread_count := $"%ThreadCount"


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
	n_thread_count.set_value_no_signal(thread_count_to_range(config_data.scraper_ss_max_threads))
	update_thread_count_label(config_data.scraper_ss_max_threads)

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

func _on_ThreadCount_value_changed(value: float):
	var value_i := thread_count_from_range()
	update_thread_count_label(value_i)
	RetroHubConfig.config.scraper_ss_max_threads = value_i

func thread_count_to_range(value: int) -> int:
	if value == 0:
		return 11
	return value

func thread_count_from_range() -> int:
	if n_thread_count.value >= 11:
		return 0
	return int(n_thread_count.value)

func update_thread_count_label(value: int):
	if value == 0:
		n_thread_count_lbl.text = "Unlimited"
	else:
		n_thread_count_lbl.text = str(value)
