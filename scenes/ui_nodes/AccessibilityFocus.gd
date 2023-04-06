extends Node
class_name AccessibilityFocus

export var previous : NodePath
export var next : NodePath
export(int, "None", "Click", "All") var mode : int = 2

var _old_next : NodePath
var _old_previous : NodePath
var _old_mode : int

var parent : Control

# Called when the node enters the scene tree for the first time.
func _ready():
	parent = get_parent()
	if not parent or not parent is Control:
		push_error("AccessibilityFocus added to non-control node!")
		queue_free()
		return

	# Copy old settings
	_old_next = parent.focus_next
	_old_previous = parent.focus_previous
	_old_mode = parent.focus_mode

	# Change existing ones, as they're a layer deep
	for neighbour_str in [
		"next",
		"previous"
	]:
		var neighbour : NodePath = get(neighbour_str)
		if not neighbour or neighbour.get_name_count() < 1:
			continue
		var node_path_str = ""
		for i in range(1, neighbour.get_name_count()-1):
			node_path_str += neighbour.get_name(i) + "/"
		node_path_str += neighbour.get_name(neighbour.get_name_count()-1)

		set(neighbour_str, NodePath(node_path_str))

	RetroHubConfig.connect("config_ready", self, "_on_config_ready")
	RetroHubConfig.connect("config_updated", self, "_on_config_updated")

	if RetroHub.is_main_app():
		_on_config_ready(RetroHubConfig.config)

func _on_config_ready(config: ConfigData):
	toggle_info(config.accessibility_screen_reader_enabled)

func _on_config_updated(key: String, old, new):
	if key == ConfigData.KEY_ACCESSIBILITY_SCREEN_READER_ENABLED:
		toggle_info(new)

func toggle_info(flag: bool):
	parent.focus_next = next if flag else _old_next
	parent.focus_previous = previous if flag else _old_previous
	parent.focus_mode = mode if flag else _old_mode
