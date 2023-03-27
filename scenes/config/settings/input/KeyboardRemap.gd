extends WindowDialog

signal key_remapped(key, old_code, new_code)

onready var n_key_icon := $"%KeyIcon"
onready var n_key_label := $"%KeyLabel"
onready var n_timer := $"%Timer"

onready var base_text : String = n_key_label.text

var key := ""
var oldcode := 0
var scancode := 0

func start(_key: String):
	key = _key
	self.scancode = 0
	self.oldcode = find_old_keycode(key)
	n_key_icon.texture = null
	n_key_label.text = base_text
	popup_centered()
	TTS.speak($"%Label".text)

func _input(event):
	if visible and event is InputEventKey:
		get_tree().set_input_as_handled()
		if not event.is_pressed():
			n_timer.stop()
			scancode = 0
		elif event.physical_scancode != scancode and not event.is_echo():
			scancode = (event as InputEventKey).physical_scancode
			n_key_icon.texture = ControllerIcons.parse_event(event)
			n_key_label.text = OS.get_scancode_string(scancode)
			TTS.speak(n_key_label.text)
			n_timer.start()

func find_old_keycode(raw_key: String):
	for ev in InputMap.get_action_list(raw_key):
		if ev is InputEventKey:
			return ev.physical_scancode if ev.scancode == 0 else ev.scancode
	return 0


func _on_Timer_timeout():
	hide()
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		yield(get_tree(), "idle_frame")
		TTS.speak("Key was remapped to " + n_key_label.text)
	emit_signal("key_remapped", key, oldcode, scancode)
