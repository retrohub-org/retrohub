extends TextureRect
class_name LazyTextureRect

var resource_path := ""

func _ready():
	if texture:
		resource_path = texture.resource_path

	var node = self
	while node:
		if node.has_signal("visibility_changed"):
			#warning-ignore:return_value_discarded
			node.visibility_changed.connect(_on_visibility_changed)
		node = node.get_parent()

func _on_visibility_changed():
	if is_visible_in_tree():
		if not texture and not resource_path.is_empty():
			texture = load(resource_path)
	elif texture:
		texture = null

func set_texture(_texture: Texture2D):
	resource_path = _texture.resource_path
	if is_visible_in_tree():
		super.set_texture(_texture)
