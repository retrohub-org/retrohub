extends SubViewport

@onready var n_theme_node : Node = $NoTheme

func set_theme(node: Node):
	RetroHubMedia._clear_media_cache()
	if is_instance_valid(n_theme_node):
		remove_child(n_theme_node)
		n_theme_node.queue_free()
	n_theme_node = node
	add_child(n_theme_node)
