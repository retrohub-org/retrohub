extends Control

var last_path := ""

func _enter_tree():
	load("res://scenes/ui_nodes/AccessibilityFocus.gd").take_over_path("res://addons/retrohub_theme_helper/ui/AccessibilityFocus.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	var dir := DirAccess.open(RetroHubConfig.get_themes_dir())
	if dir and not dir.list_dir_begin(): # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := dir.get_next()
		while not next.is_empty():
			if not dir.current_is_dir() and next.ends_with(".pck"):
				make_theme_btn(next)
			next = dir.get_next()

func make_theme_btn(path: String):
	var button := Button.new()
	button.text = path.get_file()
	button.pressed.connect(load_theme.bind(path))
	$HFlowContainer.add_child(button)

func load_theme(path: String):
	var vp := $SubViewportContainer/SubViewport
	if vp.get_child_count() > 0:
		var child = vp.get_child(0)
		vp.remove_child(child)
		child.queue_free()
		while is_instance_valid(child):
			await get_tree().process_frame
	
	RetroHub._disconnect_theme_signals()
	RetroHubMedia._stop_thread()
	if $Unload.button_pressed:
		print(last_path)
		if not last_path.is_empty():
			print("Unload result: ", ProjectSettings.unload_resource_pack(last_path))

	if $Load.button_pressed:
		last_path = RetroHubConfig.get_themes_dir() + "/" + path
		print(last_path)
		print("Load result: ", ProjectSettings.load_resource_pack(last_path, false))

	var theme_json = JSONUtils.load_json_file("res://theme.json")
	if theme_json.is_empty():
		printerr("Theme json empty")
		return
	var entry_scene = theme_json["entry_scene"]
	var inst = ResourceLoader.load(entry_scene)
	if !inst:
		printerr("Entry scnee null")
		return
	vp.add_child(inst.instantiate())
	
	RetroHubConfig.theme_data = RetroHubTheme.new()
	RetroHubConfig.theme_data.id = theme_json["id"]
	RetroHubConfig.load_theme_config()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_send_data_pressed():
	var systems : Dictionary = RetroHubConfig.systems
	var games : Array = RetroHubConfig.games
	
	RetroHubMedia._start_thread()
	if not systems.is_empty():
		RetroHub.emit_signal("system_receive_start")
		for system in systems.values():
			RetroHub.emit_signal("system_received", system)
		RetroHub.emit_signal("system_receive_end")

		RetroHub.emit_signal("game_receive_start")
		for game in games:
			RetroHub.emit_signal("game_received", game)
		RetroHub.emit_signal("game_receive_end")
