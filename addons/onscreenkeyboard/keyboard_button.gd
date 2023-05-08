extends ControllerButton

var keyData

signal released
signal down

var iconTex : Texture2D

var focused = false: set = set_focused
var pressing = false: set = set_pressing
var id_x = 0
var id_y = 0

func set_focused(_focused):
	focused = _focused
	update()

func set_pressing(_pressing):
	if pressing != _pressing:
		if _pressing:
			emit_signal("button_down")
		else:
			emit_signal("button_up")
	pressing = _pressing
	update()

func _input(event):
	if not RetroHubUI.is_event_from_virtual_keyboard() and is_visible_in_tree() \
		and path and event.is_action(path):
		get_viewport().set_input_as_handled()
		if event.is_pressed():
			button_down(false)
		else:
			button_up(false)


func _draw():
	var style = get_stylebox("normal")
	if pressing or get_draw_mode() == DRAW_PRESSED or (toggle_mode and pressed):
		draw_style_box(get_stylebox("pressed"), Rect2(Vector2.ZERO, size))
	else:
		draw_style_box(style, Rect2(Vector2.ZERO, size))
	if focused:
		draw_style_box(get_stylebox("focus"), Rect2(Vector2.ZERO, size))
	var font = get_font("font")
	var icon_region := Rect2()
	if icon:
		var valign = size.y - style.get_minimum_size().y
		var icon_ofs_region = 0
		var style_offset := Vector2()
		var icon_size = icon.get_size()
		if icon_alignment == ALIGN_LEFT:
			style_offset.x = style.get_margin(MARGIN_LEFT)
		elif icon_alignment == ALIGN_RIGHT:
			style_offset.x = -style.get_margin(MARGIN_RIGHT)
		style_offset.y = style.get_margin(MARGIN_TOP)

		if expand_icon:
			var _size = size - style.get_offset() * 2
			var icon_text_separation = 0 if text.is_empty() else get_constant("h_separation")
			_size.x -= icon_text_separation + icon_ofs_region
			var icon_width = icon.get_width() * _size.y / icon.get_height()
			var icon_height = _size.y

			if icon_width > _size.x:
				icon_width = _size.x
				icon_height = icon.get_height() * icon_width / icon.get_width()

			icon_size = Vector2(icon_width, icon_height)

		if icon_alignment == ALIGN_LEFT:
			icon_region = Rect2(style_offset + Vector2(icon_ofs_region, floor((valign - icon_size.y) * 0.5)), icon_size)
		else:
			icon_region = Rect2(style_offset + Vector2(icon_ofs_region + size.x - icon_size.x, floor((valign - icon_size.y) * 0.5)), icon_size)

		if icon_region.size.x > 0:
			draw_texture_rect_region(icon, icon_region, Rect2(Vector2(), icon.get_size()))
	var icon_ofs = Vector2(icon_region.size.x + get_constant("h_separation"), 0) if icon else Vector2()
	var text_ofs = ((size - style.get_minimum_size() + icon_ofs - font.get_string_size(text)) / 2.0) + style.get_offset()
	text_ofs.y += font.get_ascent()
	font.draw(get_canvas_item(), text_ofs, text)
	if iconTex:
		var iconSize := iconTex.get_size()
		var origY = iconSize.y
		iconSize.y = min(iconSize.y, size.y)
		iconSize.x = iconSize.y * iconSize.x / origY

		var iconRect := Rect2(Vector2((size.x / 2.0) - (iconSize.x / 2.0), 0), iconSize)
		if icon:
			if icon_alignment == ALIGN_LEFT:
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
	
	focus_mode = FOCUS_NONE
	
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
