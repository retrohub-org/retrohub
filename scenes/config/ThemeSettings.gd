extends ScrollContainer

@export var no_theme_settings_scene : PackedScene

func _ready():
	#warning-ignore:return_value_discarded
	RetroHub._theme_load.connect(_on_theme_load)

func grab_focus():
	if(get_child_count() > 0):
		get_child(0).grab_focus()

func _on_theme_load(theme_data: RetroHubTheme):
	for child in get_children():
		# Don't remove the scroll handler node
		if child.name == "ScrollHandler":
			continue
		remove_child(child)
		child.queue_free()

	if theme_data.config_scene:
		add_config_scene(theme_data.config_scene)
	else:
		add_config_scene(no_theme_settings_scene)

func add_config_scene(scene: PackedScene):
	var child : Control = scene.instantiate()
	child.size_flags_horizontal = SIZE_EXPAND_FILL
	child.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(child)
