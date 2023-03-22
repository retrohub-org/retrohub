extends Node
class_name AccessibilityFocus

export var neighbour_left : NodePath
export var neighbour_top : NodePath
export var neighbour_right : NodePath
export var neighbour_bottom : NodePath
export var next : NodePath
export var previous : NodePath
export(int, "None", "Click", "All") var mode : int = 0

var _old_neighbour_left : NodePath
var _old_neighbour_top : NodePath
var _old_neighbour_right : NodePath
var _old_neighbour_bottom : NodePath
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
	_old_neighbour_left = parent.focus_neighbour_left
	_old_neighbour_top = parent.focus_neighbour_top
	_old_neighbour_right = parent.focus_neighbour_right
	_old_neighbour_bottom = parent.focus_neighbour_bottom
	_old_next = parent.focus_next
	_old_previous = parent.focus_previous
	_old_mode = parent.focus_mode

	# Change existing ones, as they're a layer deep
	for neighbour_str in [
		"neighbour_left",
		"neighbour_top",
		"neighbour_right",
		"neighbour_bottom",
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

func _on_config_ready(config: ConfigData):
	toggle_info(config.accessibility_screen_reader_enabled)

func _on_config_updated(key: String, old, new):
	if key == ConfigData.KEY_ACCESSIBILITY_SCREEN_READER_ENABLED:
		toggle_info(new)

func toggle_info(flag: bool):
	parent.focus_neighbour_left = neighbour_left if flag else _old_neighbour_left
	parent.focus_neighbour_top = neighbour_top if flag else _old_neighbour_top
	parent.focus_neighbour_right = neighbour_right if flag else _old_neighbour_right
	parent.focus_neighbour_bottom = neighbour_bottom if flag else _old_neighbour_bottom
	parent.focus_next = next if flag else _old_next
	parent.focus_previous = previous if flag else _old_previous
	parent.focus_mode = mode if flag else _old_mode
