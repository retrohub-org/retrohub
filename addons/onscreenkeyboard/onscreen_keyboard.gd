extends Window

enum Direction {
	UP,
	DOWN
}

###########################
## SETTINGS
###########################

@export_file("*.json") var customLayoutFile : String = ""
@export var styleBackground : StyleBoxFlat = null
@export var styleHover : StyleBoxFlat = null
@export var stylePressed : StyleBoxFlat = null
@export var styleNormal : StyleBoxFlat = null
@export var styleSpecialKeys : StyleBoxFlat = null
@export var font : FontFile = null
@export var fontColor := Color(1,1,1)
@export var fontColorHover := Color(1,1,1)
@export var fontColorPressed := Color(1,1,1)

###########################
## SIGNALS
###########################

signal layoutChanged

###########################
## PANEL
###########################

func _enter_tree():
	get_tree().get_root().size_changed.connect(size_changed)
	focus_exited.connect(hide)
	visible = false
	transient = true
	exclusive = true
	borderless = true

func _ready():
	RetroHubConfig.config_ready.connect(on_config_ready)
	RetroHubConfig.config_updated.connect(on_config_updated)

	# Wait a frame for the config to load
	await get_tree().process_frame
	if RetroHubConfig.config.is_first_time:
		_initKeyboard("qwerty")

func on_config_ready(config_data: ConfigData):
	_initKeyboard(config_data.virtual_keyboard_layout)

func on_config_updated(key: String, old, new):
	match key:
		ConfigData.KEY_VIRTUAL_KEYBOARD_LAYOUT:
			_initKeyboard(new)

func _input(event):
	_handleKeyEvents(event)
	if sendingEvent and event is InputEventKey and event.keycode == KEY_ENTER and isKeyboardFocusObjectCompleteOnEnter():
		_hideKeyboard()

func size_changed():
	var root_vp := get_tree().get_root().get_viewport()
	size.x = root_vp.get_visible_rect().size.x
	bottomPos = root_vp.get_visible_rect().size.y
	if visible:
		if tweenOnTop:
			position = Vector2i(0, 0)
		else:
			position = Vector2i(0, bottomPos - size.y)

###########################
## INIT
###########################
var KeyboardButton
var KeyListHandler

var layouts = []
var keys = []
var layoutKeys = {}
var focusKeys = null
var capslockKeys = []
var uppercase = false

var focusedKeyX = 0
var focusedKeyY = 0
var sendingEvent = false

var tweenSpeed = .2
var tweenOnTop = false
@onready var bottomPos := get_tree().get_root().get_viewport().get_visible_rect().size.y

func _initKeyboard(config_value: String):
	match config_value:
		"qwertz":
			customLayoutFile = "res://addons/onscreenkeyboard/customize/keyboardLayouts/qwertz.json"
		"azerty":
			customLayoutFile = "res://addons/onscreenkeyboard/customize/keyboardLayouts/azerty.json"
		"qwerty", _:
			customLayoutFile = "res://addons/onscreenkeyboard/customize/keyboardLayouts/qwerty.json"

	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	layouts = []
	keys = []
	layoutKeys = {}
	focusKeys = null
	capslockKeys = []
	uppercase = false

	focusedKeyX = 0
	focusedKeyY = 0
	sendingEvent = false

	if customLayoutFile == null:
		var defaultLayout = preload("default_layout.gd").new()
		_createKeyboard(defaultLayout.data)
	else:
		_createKeyboard(_loadJSON(customLayoutFile))

	hide_keyboard()

###########################
## HIDE/SHOW
###########################

var focused_control : Control = null
var focused_window : Window = null

func show_keyboard(focused_control: Control):
	self.focused_control = focused_control
	visible = true
	
	# Set window transience
	focused_window = focused_control.get_viewport().get_window()
	_showKeyboard()
	# Skip current frame to avoid double input when opening the keyboard

func hide_keyboard():
	await _hideKeyboard()
	if focused_window:
		focused_window.grab_focus()
	focused_control = null
	focused_window = null

func _hideKeyboard(keyData=null,x=null,y=null,steal_focus=null):
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	if tweenOnTop:
		tween.tween_property(self,"position", Vector2i(0,-size.y), tweenSpeed)
	else:
		tween.tween_property(self,"position", Vector2i(0,bottomPos + 10), tweenSpeed)

	_setCapsLock(false)
	# Restore focus to the old viewport
	gui_release_focus()
	await tween.finished
	hide()


func _showKeyboard(keyData=null,x=null,y=null):
	var control_rect := focused_control.get_global_rect()
	tweenOnTop = control_rect.position.y + control_rect.size.y > bottomPos - size.y - 30

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	if tweenOnTop:
		position = Vector2i(0, -size.y)
		tween.tween_property(self,"position", Vector2i(0,0), tweenSpeed)
	else:
		position = Vector2i(0, bottomPos)
		tween.tween_property(self,"position", Vector2i(0,bottomPos-size.y), tweenSpeed)
	focusKey(0,0)


func _handleKeyEvents(event):
	# Manually trigger ControllerIcons to consume event
	ControllerIcons._input(event)
	# Selection
	if event.is_action_pressed("ui_left", true):
		set_input_as_handled()
		focusKey(focusedKeyX - 1, focusedKeyY)
	elif event.is_action_pressed("ui_right", true):
		set_input_as_handled()
		focusKey(focusedKeyX + 1, focusedKeyY)
	elif event.is_action_pressed("ui_up", true) or event.is_action_pressed("ui_focus_prev", true):
		set_input_as_handled()
		focusKeyDir(Direction.UP)
	elif event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_focus_next", true):
		set_input_as_handled()
		focusKeyDir(Direction.DOWN)

###########################
##  KEY LAYOUT
###########################

var prevPrevLayout = null
var previousLayout = null
var currentLayout = null

func setActiveLayoutByName(name):
	for layout in layouts:
		if layout.tooltip_text == str(name):
			_showLayout(layout)
		else:
			_hideLayout(layout)

func _showLayout(layout):
	layout.show()
	currentLayout = layout
	# Old key, unfocus
	var key = focusKeys[focusedKeyY][focusedKeyX]
	focusKeys = layoutKeys[layout]
	# Focus new key on different layout
	focusedKeyX = 0
	focusedKeyY = 0
	focusKeys[focusedKeyY][focusedKeyX].grab_focus()
	tts_speak_key(focusKeys[focusedKeyY][focusedKeyX])

func tts_speak_key(key):
	match key.keyData["type"]:
		"switch-layout":
			if key.keyData["layout-name"] == "special-characters":
				TTS.speak("Change to special characters")
			else:
				TTS.speak("Change to normal characters")
		"special-shift":
			TTS.speak("Shift")
		"special-hide-keyboard":
			TTS.speak("Hide keyboard")
		"special", "char":
			if key.keyData.has("display"):
				TTS.speak(key.keyData["display"])
			else:
				TTS.speak(key.keyData["output"])


func _hideLayout(layout):
	layout.hide()


func _switchLayout(keyData,x,y,steal_focus):
	await get_tree().process_frame
	prevPrevLayout = previousLayout
	previousLayout = currentLayout
	emit_signal("layoutChanged", keyData.get("layout-name"))
	
	for layout in layouts:
		_hideLayout(layout)
	
	if keyData.get("layout-name") == "PREVIOUS-LAYOUT":
		if prevPrevLayout != null:
			_showLayout(prevPrevLayout)
			return
	
	for layout in layouts:
		if layout.tooltip_text == keyData.get("layout-name"):
			_showLayout(layout)
			return
	
	_setCapsLock(false)

###########################
## KEY EVENTS
###########################

func _setCapsLock(value):
	uppercase = value
	for key in capslockKeys:
		if value:
			if key.get_draw_mode() != BaseButton.DRAW_PRESSED:
				key.button_pressed = !key.pressed
		else:
			if key.get_draw_mode() == BaseButton.DRAW_PRESSED:
				key.button_pressed = !key.pressed
				
	for key in keys:
		key.changeUppercase(value)


func _triggerUppercase(keyData,x,y,steal_focus):
	uppercase = !uppercase
	_setCapsLock(uppercase)


func _keyDown(keyData,x,y,steal_focus):
	if steal_focus:
		focusKey(x,y)

func _keyReleased(keyData,x,y,steal_focus):
	if keyData.has("output"):
		var keyValue = keyData.get("output")
		
		###########################
		## DISPATCH InputEvent
		###########################
		
		var inputEventKey := InputEventKey.new()
		inputEventKey.shift_pressed = uppercase
		inputEventKey.alt_pressed = false
		inputEventKey.meta_pressed = false
		inputEventKey.ctrl_pressed = false
		inputEventKey.pressed = true
		
		var keyUnicode = KeyListHandler.getUnicodeFromString(keyValue)
		if keyUnicode != KEY_UNKNOWN and not uppercase and KeyListHandler.hasLowercase(keyValue):
			keyUnicode +=32
		if !(keyUnicode & KEY_SPECIAL):
			inputEventKey.unicode = keyUnicode
		inputEventKey.keycode = KeyListHandler.getScancodeFromString(keyValue)

		sendingEvent = true
		# Manually disable ControllerIcons for this event
		ControllerIcons.set_process_input(false)
		focused_control.get_viewport().push_input(inputEventKey)
		RetroHubUI.play_sound(RetroHubUI.AudioKeys.KEYBOARD_TYPE)
		await get_tree().process_frame
		ControllerIcons.set_process_input(true)
		sendingEvent = false
		
		###########################
		## DISABLE CAPSLOCK AFTER
		###########################
		_setCapsLock(false)


###########################
## CONSTRUCT KEYBOARD
###########################

func _setKeyStyle(styleName, key, style):
	if style != null:
		key.set('custom_styles/'+styleName, style)

func _createKeyboard(layoutData):
	if layoutData == null:
		print("ERROR. No layout file found")
		return
	
	KeyListHandler = preload("keylist.gd").new()
	KeyboardButton = preload("keyboard_button.gd")
	
	var ICON_DELETE = preload("icons/delete.png")
	var ICON_SHIFT = preload("icons/shift.png")
	var ICON_LEFT = preload("icons/left.png")
	var ICON_RIGHT = preload("icons/right.png")
	var ICON_HIDE = preload("icons/hide.png")
	var ICON_ENTER = preload("icons/enter.png")
	
	var data = layoutData
	
	if styleBackground != null:
		set('theme_override_styles/panel', styleBackground)
	
	var index = 0
	for layout in data.get("layouts"):

		var layoutContainer = PanelContainer.new()
		
		if styleBackground != null:
			layoutContainer.set('theme_override_styles/panel', styleBackground)
		
		# SHOW FIRST LAYOUT ON DEFAULT
		if index > 0:
			layoutContainer.hide()
		else:
			currentLayout = layoutContainer
		
		layoutContainer.tooltip_text = layout.get("name")
		layouts.push_back(layoutContainer)
		add_child(layoutContainer)
		layoutContainer.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		layoutContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		layoutContainer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		var baseVbox = VBoxContainer.new()
		baseVbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		baseVbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		var loopLayoutKeys = []
		layoutKeys[layoutContainer] = loopLayoutKeys
		if focusKeys == null:
			focusKeys = layoutKeys[layoutContainer]

		for row in layout.get("rows"):
			var firstShift = true
			var focusRowKeys = []
			loopLayoutKeys.push_back(focusRowKeys)

			var keyRow = HBoxContainer.new()
			keyRow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			keyRow.size_flags_vertical = Control.SIZE_EXPAND_FILL
			
			for key in row.get("keys"):
				var newKey = KeyboardButton.new(key)
				newKey.add_to_group("rh_no_sound")
				newKey.expand_icon = true
				newKey.show_only = 2
				newKey.force_type = 2
				newKey.id_x = focusRowKeys.size()
				newKey.id_y = loopLayoutKeys.size()-1
				focusRowKeys.push_back(newKey)
				
				_setKeyStyle("normal",newKey, styleNormal)
				_setKeyStyle("hover",newKey, styleHover)
				_setKeyStyle("pressed",newKey, stylePressed)
					
				if font != null:
					newKey.set('theme_override_fonts/font', font)
				if fontColor != null:
					newKey.set('theme_override_colors/font_color', fontColor)
					newKey.set('theme_override_colors/font_hover_color', fontColorHover)
					newKey.set('theme_override_colors/font_pressed_color', fontColorPressed)
					newKey.set('theme_override_colors/font_disabled_color', fontColor)

				newKey.down.connect(_keyDown)
				newKey.released.connect(_keyReleased)
				
				if key.has("type"):
					if key.get("type") == "char" and key.get("output") == "Space":
						newKey.path = "rh_minor_option"
					if key.get("type") == "switch-layout":
						newKey.path = "rh_major_option"
						newKey.released.connect(_switchLayout)
						_setKeyStyle("normal",newKey, styleSpecialKeys)
					elif key.get("type") == "special":
						match key.get("output"):
							"Backspace":
								newKey.path = "rh_back"
								newKey.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
							"Return":
								newKey.path = "rh_right_trigger"
								newKey.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
							"LeftArrow":
								newKey.path = "rh_left_shoulder"
							"RightArrow":
								newKey.path = "rh_right_shoulder"
						_setKeyStyle("normal",newKey, styleSpecialKeys)
					elif key.get("type") == "special-shift":
						newKey.path = "rh_left_trigger"
						newKey.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT if firstShift else HORIZONTAL_ALIGNMENT_RIGHT
						firstShift = false
						newKey.released.connect(_triggerUppercase)
						newKey.toggle_mode = true
						capslockKeys.push_back(newKey)
						_setKeyStyle("normal",newKey, styleSpecialKeys)
					elif key.get("type") == "special-hide-keyboard":
						newKey.path = "rh_menu"
						newKey.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
						newKey.released.connect(func(_1, _2, _3, _4):
							hide_keyboard()
						)
						_setKeyStyle("normal",newKey, styleSpecialKeys)
				
				# SET ICONS
				if key.has("display-icon"):
					var iconData = str(key.get("display-icon")).split(":")
					# PREDEFINED
					if str(iconData[0])=="PREDEFINED":
						if str(iconData[1])=="DELETE":
							newKey.setIcon(ICON_DELETE)
						elif str(iconData[1])=="SHIFT":
							newKey.setIcon(ICON_SHIFT)
						elif str(iconData[1])=="LEFT":
							newKey.setIcon(ICON_LEFT)
						elif str(iconData[1])=="RIGHT":
							newKey.setIcon(ICON_RIGHT)
						elif str(iconData[1])=="HIDE":
							newKey.setIcon(ICON_HIDE)
						elif str(iconData[1])=="ENTER":
							newKey.setIcon(ICON_ENTER)
					# CUSTOM
					if str(iconData[0])=="res":
						print(key.get("display-icon"))
						var texture = load(key.get("display-icon"))
						newKey.setIcon(texture)
				
				keyRow.add_child(newKey)
				keys.push_back(newKey)
				
			baseVbox.add_child(keyRow)
		
		layoutContainer.add_child(baseVbox)
		index+=1


###########################
## LOAD SETTINGS
###########################

func _loadJSON(filePath):
	var json = JSON.new()

	if json.parse(_loadFile(filePath)):
		print("!JSON PARSE ERROR!")
		return null
	else:
		return json.get_data()


func _loadFile(filePath):
	var file = FileAccess.open(filePath, FileAccess.READ)
	
	if !file:
		print("Error loading File. Error: "+str(FileAccess.get_open_error()))
	
	var content = file.get_as_text()
	file.close()
	return content


###########################
## HELPER
###########################

func isKeyboardFocusObjectCompleteOnEnter():
	if focused_control is LineEdit:
		return true
	return false

func isKeyboardFocusObject():
	if focused_control is LineEdit or focused_control is TextEdit:
		return true
	return false

func focusKey(x, y):
	if y < 0:
		y = focusKeys.size() - 1
	elif y >= focusKeys.size():
		y = 0
	if x < 0:
		x = focusKeys[y].size() - 1
	elif x >= focusKeys[y].size():
		x = 0

	# Focus new key
	focusedKeyX = x
	focusedKeyY = y
	focusKeys[focusedKeyY][focusedKeyX].grab_focus()
	tts_speak_key(focusKeys[focusedKeyY][focusedKeyX])
	

func focusKeyDir(dir):
	var currKey = focusKeys[focusedKeyY][focusedKeyX]
	var center = currKey.global_position + currKey.size / 2

	var idx = focusedKeyY + 1 if dir == Direction.DOWN else focusedKeyY - 1
	if idx == -1:
		idx = focusKeys.size()-1
	elif idx == focusKeys.size():
		idx = 0
	for key in focusKeys[idx]:
		var left_pos = key.global_position.x
		var right_pos = left_pos + key.size.x
		if (dir == Direction.UP and right_pos > center.x) or \
			(dir == Direction.DOWN and left_pos > center.x) or \
			(left_pos <= center.x and center.x <= right_pos):
			focusKey(key.id_x, key.id_y)
			return
