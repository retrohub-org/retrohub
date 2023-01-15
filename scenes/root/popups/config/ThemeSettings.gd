extends Control

export(PackedScene) var no_theme_settings_scene : PackedScene

func _ready():
	RetroHub.connect("_theme_loaded", self, "_on_theme_loaded")

func grab_focus():
	get_child(0).grab_focus()

func _on_theme_loaded(theme_data: RetroHubTheme):
	for child in get_children():
		remove_child(child)
		child.queue_free()

	if theme_data.config_scene:
		add_config_scene(theme_data.config_scene)
	else:
		add_config_scene(no_theme_settings_scene.instance())

func add_config_scene(scene: Control):
	scene.size_flags_horizontal = SIZE_EXPAND_FILL
	scene.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(scene)
