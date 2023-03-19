tool
extends Node

signal swipe_left

signal swipe_right

signal swipe_up

signal swipe_down

var Accessible = preload("Accessible.gd")

export var enabled = true

export var control_lifetime = false

export var min_swipe_distance = 5

export var tap_execute_interval = 125

export var explore_by_touch_interval = 200

export var enable_focus_mode = false

var should_stop_on_focus = true


func _get_enabled():
	return enabled


func augment_node(node):
	if not enabled:
		return
	if node is Control:
		Accessible.new(node)


func augment_tree(node):
	if not enabled:
		return
	if node is Accessible:
		return
	augment_node(node)
	for child in node.get_children():
		augment_tree(child)


func find_focusable_control(node):
	if (
		node is Control
		and node.is_visible_in_tree()
		and (node.focus_mode == Control.FOCUS_CLICK or node.focus_mode == Control.FOCUS_ALL)
	):
		return node
	for child in node.get_children():
		var result = find_focusable_control(child)
		if result:
			return result
	return null


func _enter_tree():
	pause_mode = Node.PAUSE_MODE_PROCESS

func _ready():
	if control_lifetime:
		RetroHubConfig.connect("config_ready", self, "_on_config_ready")
	else:
		init()

func _on_config_ready(config: ConfigData):
	if config.accessibility_screen_reader_enabled:
		init()
	else:
		queue_free()

func init():
	if Engine.is_editor_hint() and not TTS.editor_accessibility_enabled:
		return
	if enabled:
		augment_tree(get_tree().root)
	#get_tree().connect("node_added", self, "augment_node")
	connect("swipe_right", self, "swipe_right")
	connect("swipe_left", self, "swipe_left")
	connect("swipe_up", self, "swipe_up")
	connect("swipe_down", self, "swipe_down")


func _press_and_release(action, fake_via_keyboard = false):
	if fake_via_keyboard:
		for event in InputMap.get_action_list(action):
			if event is InputEventKey:
				event.pressed = true
				Input.action_press(action)
				get_tree().input_event(event)
				event.pressed = false
				Input.action_release(action)
				get_tree().input_event(event)
				return
	var event = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.action_press(action)
	get_tree().input_event(event)
	event.pressed = false
	Input.action_release(action)
	get_tree().input_event(event)


func _ui_left(fake_via_keyboard = false):
	_press_and_release("ui_left", fake_via_keyboard)


func _ui_right(fake_via_keyboard = false):
	_press_and_release("ui_right", fake_via_keyboard)


func _ui_up(fake_via_keyboard = false):
	_press_and_release("ui_up", fake_via_keyboard)


func _ui_down(fake_via_keyboard = false):
	_press_and_release("ui_down", fake_via_keyboard)


func _ui_focus_next(fake_via_keyboard = false):
	_press_and_release("ui_focus_next", fake_via_keyboard)


func _ui_focus_prev(fake_via_keyboard = false):
	_press_and_release("ui_focus_prev", fake_via_keyboard)


func swipe_right():
	var fake_via_keyboard = false
	if OS.get_name() == "Android":
		fake_via_keyboard = true
	_ui_focus_next(fake_via_keyboard)


func swipe_left():
	var fake_via_keyboard = false
	if OS.get_name() == "Android":
		fake_via_keyboard = true
	_ui_focus_prev(fake_via_keyboard)


func swipe_up():
	var focus = find_focusable_control(get_tree().root)
	if focus:
		focus = focus.get_focus_owner()
		if focus:
			if focus is Range:
				_press_and_release("ui_right")


func swipe_down():
	var focus = find_focusable_control(get_tree().root)
	if focus:
		focus = focus.get_focus_owner()
		if focus:
			if focus is Range:
				_press_and_release("ui_left")


var touch_index = null

var touch_position = null

var touch_start_time = null

var touch_stop_time = null

var explore_by_touch = false

var tap_count = 0

var focus_mode = false
var in_focus_mode_handler = false


func _input(event):
	if Engine.is_editor_hint() and not TTS.editor_accessibility_enabled:
		return
	if not enabled or not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	var focus = find_focusable_control(get_tree().root)
	if focus:
		focus = focus.get_focus_owner()
		if focus is Tree and Input.is_action_just_pressed("ui_accept"):
			var accessible
			for n in focus.get_children():
				if n is Accessible:
					accessible = n
					break
			if accessible and accessible.button_index != null:
				accessible._tree_input(event)
				get_tree().set_input_as_handled()
	if enable_focus_mode:
		if (
			event is InputEventKey
			and Input.is_key_pressed(KEY_ESCAPE)
			and Input.is_key_pressed(KEY_SHIFT)
			and not event.echo
		):
			get_tree().set_input_as_handled()
			if focus_mode:
				focus_mode = false
				TTS.speak("UI mode", true)
				return
			else:
				focus_mode = true
				TTS.speak("Focus mode", true)
				return
		if focus_mode:
			if (
				Input.is_action_just_pressed("ui_left")
				or Input.is_action_just_pressed("ui_right")
				or Input.is_action_just_pressed("ui_up")
				or Input.is_action_just_pressed("ui_down")
				or Input.is_action_just_pressed("ui_focus_next")
				or Input.is_action_just_pressed("ui_focus_prev")
			):
				if in_focus_mode_handler:
					return
				in_focus_mode_handler = true
				if Input.is_action_just_pressed("ui_left"):
					_ui_left()
				elif Input.is_action_just_pressed("ui_right"):
					_ui_right()
				elif Input.is_action_just_pressed("ui_up"):
					_ui_up()
				elif Input.is_action_just_pressed("ui_down"):
					_ui_down()
				elif Input.is_action_just_pressed("ui_focus_prev"):
					_ui_focus_prev()
				elif Input.is_action_just_pressed("ui_focus_next"):
					_ui_focus_next()
				get_tree().set_input_as_handled()
				in_focus_mode_handler = false
				return
	if event is InputEventScreenTouch:
		get_tree().set_input_as_handled()
		if touch_index and event.index != touch_index:
			return
		if event.pressed:
			touch_index = event.index
			touch_position = event.position
			touch_start_time = OS.get_ticks_msec()
			touch_stop_time = null
		elif touch_position:
			touch_index = null
			var relative = event.position - touch_position
			if relative.length() < min_swipe_distance:
				tap_count += 1
			elif not explore_by_touch:
				if abs(relative.x) > abs(relative.y):
					if relative.x > 0:
						emit_signal("swipe_right")
					else:
						emit_signal("swipe_left")
				else:
					if relative.y > 0:
						emit_signal("swipe_down")
					else:
						emit_signal("swipe_up")
			touch_position = null
			touch_start_time = null
			touch_stop_time = OS.get_ticks_msec()
			explore_by_touch = false
	elif event is InputEventScreenDrag:
		if touch_index and event.index != touch_index:
			return
		if (
			not explore_by_touch
			and OS.get_ticks_msec() - touch_start_time >= explore_by_touch_interval
		):
			explore_by_touch = true
	if event is InputEventMouseButton:
		if event.device == -1 and not explore_by_touch:
			get_tree().set_input_as_handled()


func _process(delta):
	if Engine.is_editor_hint() and not TTS.editor_accessibility_enabled:
		return
	if not enabled or not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	if (
		touch_stop_time
		and OS.get_ticks_msec() - touch_stop_time >= tap_execute_interval
		and tap_count != 0
	):
		touch_stop_time = null
		if tap_count == 2:
			_press_and_release("ui_accept")
		tap_count = 0
