@tool
extends EditorPlugin

var ScreenReader := preload("ScreenReader.gd")

var screen_reader = null

func set_initial_screen_focus(screen):
	if not screen_reader.enabled:
		return
	TTS.speak("%s: screen" % screen, false)
	var control = screen_reader.find_focusable_control(get_tree().root)
	if control.get_viewport().gui_get_focus_owner() != null:
		return
	screen_reader.augment_tree(get_tree().root)
	var focus = screen_reader.find_focusable_control(get_tree().root)
	if not focus:
		return
	focus.grab_click_focus()
	focus.grab_focus()


func _enter_tree():
	add_autoload_singleton("TTS", "res://addons/godot-tts/TTS.gd")
	add_custom_type("ScreenReader", "Node", ScreenReader, null)
	var rate = TTS.normal_rate
	var config = ConfigFile.new()
	var err = config.load("res://.godot-accessibility-editor-settings.ini")
	if not err:
		TTS.editor_accessibility_enabled = config.get_value(
			"global", "editor_accessibility_enabled", true
		)
		rate = config.get_value("speech", "rate", 50)
	if TTS.editor_accessibility_enabled and Engine.is_editor_hint():
		TTS.call_deferred("_set_rate", rate)
		screen_reader = ScreenReader.new()
		screen_reader.enable_focus_mode = true
		get_tree().root.call_deferred("add_child", screen_reader)


func _exit_tree():
	remove_custom_type("ScreenReader")


var _focus_loss_interval = 0


func _process(delta):
	if not screen_reader or not screen_reader.enabled:
		return
	var focus = screen_reader.find_focusable_control(get_tree().root)
	focus = focus.get_viewport().gui_get_focus_owner()
	if focus:
		_focus_loss_interval = 0
	else:
		_focus_loss_interval += delta
		if _focus_loss_interval >= 0.2:
			_focus_loss_interval = 0
			focus = screen_reader.find_focusable_control(get_tree().root)
			focus.grab_focus()
			focus.grab_click_focus()
