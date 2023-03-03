extends Control
class_name SpinBoxHandler

## Hack for tackling focus issues with spinboxes
## Must be added as a child component of a spin box, aka
## get_parent() returns the spin box

enum Dir {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	NEXT,
	PREVIOUS
}

func _ready():
	# This _ready is called before parent, we need to wait a frame for parent to initialize
	mouse_filter = MOUSE_FILTER_IGNORE
	yield(get_tree(), "idle_frame")
	var spin_box : SpinBox = get_parent()
	if not spin_box:
		return
	spin_box.focus_mode = FOCUS_ALL
	#warning-ignore:return_value_discarded
	spin_box.connect("focus_entered", self, "_on_focus_entered")
	for dir in [
		Dir.TOP,
		Dir.BOTTOM,
		Dir.LEFT,
		Dir.RIGHT,
		Dir.NEXT,
		Dir.PREVIOUS
	]:
		handle_neighbors(dir)


func handle_neighbors(dir: int):
	var neighbor : NodePath
	match dir:
		Dir.TOP:
			neighbor = get_parent().focus_neighbour_top
		Dir.BOTTOM:
			neighbor = get_parent().focus_neighbour_bottom
		Dir.LEFT:
			neighbor = get_parent().focus_neighbour_left
		Dir.RIGHT:
			neighbor = get_parent().focus_neighbour_right
		Dir.NEXT:
			neighbor = get_parent().focus_next
		Dir.PREVIOUS:
			neighbor = get_parent().focus_previous

	if not neighbor:
		return

	var neighbor_obj := get_node("../" + neighbor)

	var raw_path := ".."
	for i in range(neighbor.get_name_count()):
		raw_path += "/" + neighbor.get_name(i)
	if neighbor_obj is SpinBox:
		raw_path += "/" + neighbor_obj.get_line_edit().get_name()

	match dir:
		Dir.TOP:
			get_parent().get_line_edit().focus_neighbour_top = NodePath(raw_path)
		Dir.BOTTOM:
			get_parent().get_line_edit().focus_neighbour_bottom = NodePath(raw_path)
		Dir.LEFT:
			get_parent().get_line_edit().focus_neighbour_left = NodePath(raw_path)
		Dir.RIGHT:
			get_parent().get_line_edit().focus_neighbour_right = NodePath(raw_path)
		Dir.NEXT:
			get_parent().get_line_edit().focus_next = NodePath(raw_path)
		Dir.PREVIOUS:
			get_parent().get_line_edit().focus_previous = NodePath(raw_path)

func _on_focus_entered():
	get_parent().get_line_edit().grab_focus()
