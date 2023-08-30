extends SubViewport

@onready var n_theme_node : Node = $NoTheme

func set_theme(scene: PackedScene):
	RetroHubMedia.clear_all_media_cache()
	n_theme_node = scene.instantiate()
	add_child(n_theme_node)

func clear_theme():
	remove_child(n_theme_node)
	n_theme_node.queue_free()
	#while is_instance_valid(n_theme_node):
	#	await get_tree().process_frame
