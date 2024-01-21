extends Control

@onready var n_label := %Label
@onready var n_retro_achievements := %RetroAchievements

func grab_focus():
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_label.grab_focus()
	else:
		n_retro_achievements.grab_focus()

func _on_hidden():
	RetroHubConfig._save_config()
	n_retro_achievements.save_credentials()
