extends Viewport

onready var n_theme_node = $NoTheme

var _joypad_echo_delay := Timer.new()
var _joypad_echo_interval := Timer.new()
var _joypad_last_event = null

func _ready():
	_joypad_echo_delay.wait_time = 1.0
	_joypad_echo_interval.wait_time = 0.25
	_joypad_echo_delay.one_shot = true
	_joypad_echo_delay.connect("timeout", self, "_on_joypad_echo_delay_timeout")
	_joypad_echo_interval.connect("timeout", self, "_on_joypad_echo_interval_timeout")
	add_child(_joypad_echo_delay)
	add_child(_joypad_echo_interval)

func set_theme(node: Node):
	remove_child(n_theme_node)
	RetroHubMedia._clear_media_cache()
	if is_instance_valid(n_theme_node):
		n_theme_node.queue_free()
	n_theme_node = node
	add_child(n_theme_node)

func _on_joypad_echo_delay_timeout():
	_joypad_echo_interval.start()
	_on_joypad_echo_interval_timeout()

func _on_joypad_echo_interval_timeout():
	Input.parse_input_event(_joypad_last_event)

func _input(event):
	if event == _joypad_last_event:
		RetroHub.is_echo = true
		return
	RetroHub.is_echo = event.is_echo()
	if event is InputEventJoypadMotion or event is InputEventJoypadButton:
		if Input.is_action_just_released("ui_left") or Input.is_action_just_released("ui_up") \
			or Input.is_action_just_released("ui_right") or Input.is_action_just_released("ui_down"):
			_joypad_echo_delay.stop()
			_joypad_echo_interval.stop()

		if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_up") \
			or Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_down"):
			if _joypad_echo_delay.is_stopped():
				_joypad_last_event = event
				_joypad_echo_delay.start()
			#else:
				#get_tree().set_input_as_handled()
