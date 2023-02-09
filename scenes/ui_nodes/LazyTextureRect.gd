extends TextureRect
class_name LazyTextureRect

var resource_path = null

func _ready():
	if texture:
		resource_path = texture.resource_path
	
	var node = self
	while node:
		if node.has_signal("visibility_changed"):
			node.connect("visibility_changed", self, "_on_visibility_changed")
		node = node.get_parent()

func _on_visibility_changed():
	if is_visible_in_tree():
		if not texture and resource_path:
			texture = load(resource_path)
	elif texture:
		texture = null

func set_texture(texture: Texture):
	resource_path = texture.resource_path
	if is_visible_in_tree():
		.set_texture(texture)
