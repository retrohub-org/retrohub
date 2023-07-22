extends Window

signal key_remapped(key, old_code, new_code)

@onready var n_key_icon := %KeyIcon
@onready var n_key_label := %KeyLabel
@onready var n_timer := %Timer

@onready var base_text : String = n_key_label.text

var key := ""
var oldcode := 0
var keycode := 0

func start(_key: String):
	key = _key
	self.keycode = 0
	self.oldcode = find_old_keycode(key)
	n_key_icon.texture = null
	n_key_label.text = base_text
	popup_centered()
	TTS.speak(%Label.text)

func _input(event):
	if visible and event is InputEventKey:
		get_viewport().set_input_as_handled()
		if not event.is_pressed():
			n_timer.stop()
			keycode = 0
		elif event.physical_keycode != keycode and not event.is_echo():
			keycode = (event as InputEventKey).physical_keycode
			n_key_icon.texture = ControllerIcons.parse_event(event)
			n_key_label.text = OS.get_keycode_string(keycode)
			TTS.speak(n_key_label.text)
			n_timer.start()

func find_old_keycode(raw_key: String):
	for ev in InputMap.action_get_events(raw_key):
		if ev is InputEventKey:
			return ev.physical_keycode if ev.keycode == 0 else ev.keycode
	return 0


func _on_Timer_timeout():
	hide()
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		await get_tree().process_frame
		TTS.speak("Key was remapped to " + n_key_label.text)
	emit_signal("key_remapped", key, oldcode, keycode)
