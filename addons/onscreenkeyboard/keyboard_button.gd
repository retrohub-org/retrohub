extends Button

var keyData

signal released
signal down

var iconTexRect

func _enter_tree():
	pass

func _ready():
	pass # Replace with function body.

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
	emit_signal("released",keyData)
	
func button_down():
	emit_signal("down",keyData)
