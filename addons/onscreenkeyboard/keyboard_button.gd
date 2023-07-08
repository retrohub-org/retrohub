extends ControllerButton

var keyData

signal released
signal down

var iconTex : Texture2D

var id_x = 0
var id_y = 0

func _input(event):
	if not RetroHubUI.is_event_from_virtual_keyboard() and is_visible_in_tree() \
		and not path.is_empty() and event.is_action(path):
		get_viewport().set_input_as_handled()
		if event.is_pressed():
			button_down(false)
		else:
			button_up(false)


func _draw():
	#super._draw()
	if iconTex:
		var iconSize := iconTex.get_size()
		var origY = iconSize.y
		iconSize.y = min(iconSize.y, size.y)
		iconSize.x = iconSize.y * iconSize.x / origY

		var iconRect := Rect2(Vector2((size.x / 2.0) - (iconSize.x / 2.0), 0), iconSize)
		if icon:
			if icon_alignment == HORIZONTAL_ALIGNMENT_LEFT:
				iconRect.position.x += icon.get_width() / 4.0
			else:
				iconRect.position.x -= icon.get_width() / 4.0
		draw_texture_rect(iconTex, iconRect, false)

func _init(_keyData):
	keyData = _keyData
	connect("button_up", Callable(self, "button_up"))
	connect("button_down", Callable(self, "button_down"))

	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL

	if keyData.has("display"):
		text = keyData.get("display")

	if keyData.has("stretch-ratio"):
		size_flags_stretch_ratio = keyData.get("stretch-ratio")

func setIcon(texture):
	iconTex = texture

func changeUppercase(value):
	if value:
		if keyData.has("display-uppercase"):
			text = keyData.get("display-uppercase")
	else:
		if keyData.has("display"):
			text = keyData.get("display")


func button_up(steal_focus: bool = true):
	emit_signal("released",keyData,id_x,id_y,steal_focus)
	
func button_down(steal_focus: bool = true):
	emit_signal("down",keyData,id_x,id_y,steal_focus)
