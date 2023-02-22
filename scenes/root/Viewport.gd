extends Viewport

onready var n_theme_node = $NoTheme

func set_theme(node: Node):
	remove_child(n_theme_node)
	RetroHubMedia._clear_media_cache()
	if is_instance_valid(n_theme_node):
		n_theme_node.queue_free()
	n_theme_node = node
	add_child(n_theme_node)
