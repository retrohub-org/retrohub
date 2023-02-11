extends Button

var keyData

signal released
signal down

var iconTexRect

var focused = false setget set_focused
var pressing = false setget set_pressing
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

func _enter_tree():
	pass


func _draw():
	var style = get_stylebox("normal")
	if pressing or get_draw_mode() == DRAW_PRESSED or (toggle_mode and pressed):
		draw_style_box(get_stylebox("pressed"), Rect2(Vector2.ZERO, rect_size))
	else:
		draw_style_box(style, Rect2(Vector2.ZERO, rect_size))
	if focused:
		draw_style_box(get_stylebox("focus"), Rect2(Vector2.ZERO, rect_size))
	var font = get_font("font")
	var text_ofs = ((rect_size - style.get_minimum_size() - font.get_string_size(text)) / 2.0) + style.get_offset();
	text_ofs.y += font.get_ascent();
	font.draw(get_canvas_item(), text_ofs, text)

func item_rect_changed():
	if iconTexRect != null:
		iconTexRect.rect_size = rect_size

func _init(_keyData):
	keyData = _keyData
	connect("button_up",self,"button_up")
	connect("button_down",self,"button_down")
	connect("item_rect_changed",self,"item_rect_changed")
	
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	
	focus_mode = FOCUS_NONE
	
	if keyData.has("display"):
		text = keyData.get("display")

	if keyData.has("stretch-ratio"):
		size_flags_stretch_ratio = keyData.get("stretch-ratio")


func setIconColor(color):
	if iconTexRect != null:
		iconTexRect.modulate = color

func setIcon(texture):
	iconTexRect = TextureRect.new()
	iconTexRect.expand = true
	iconTexRect.stretch_mode = 6
	iconTexRect.texture = texture
	add_child(iconTexRect)


func changeUppercase(value):
	if value:
		if keyData.has("display-uppercase"):
			text = keyData.get("display-uppercase")
	else:
		if keyData.has("display"):
			text = keyData.get("display")


func button_up():
	emit_signal("released",keyData,id_x,id_y)
	
func button_down():
	emit_signal("down",keyData,id_x,id_y)
