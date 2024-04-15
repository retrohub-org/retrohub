# GdUnit generated TestSuite
extends GdUnitTestSuite
class_name UI_GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

var root_path : String
var runner : GdUnitSceneRunner

func setup():
	assert_not_yet_implemented()

func get_unique_named_nodes(_root : Node = self.runner.scene()) -> Array:
	var results := []
	for child in _root.get_children():
		results.append_array(get_unique_named_nodes(child))
		if child.is_unique_name_in_owner():
			results.append(child)
	return results

func get_node_from_scene(node: NodePath) -> Node:
	var ret = runner.scene().get_node(node)
	assert_object(ret).is_not_null()
	return ret

func focus_sequence(children : Array, action : String) -> void:
	if children.is_empty():
		fail("children is empty")

	var children_nodes : Array[Control]
	for path in children:
		var child = get_node_from_scene(path)
		assert_object(child).is_instanceof(Control)
		children_nodes.push_back(child)

	var first : Control = children_nodes[0]
	first.grab_focus()
	assert_bool(first.has_focus()).is_true().override_failure_message( 
		"Expected %s focus on %s, got %s instead" %
		[action, first, get_viewport().gui_get_focus_owner()]
	)
	await await_idle_frame()

	# This initial input action is required for some god-forsaken reason
	for idx in range(1, children_nodes.size()):
		runner.simulate_action_pressed(action)
		await await_idle_frame()
		assert_bool(children_nodes[idx].has_focus()).override_failure_message(
			"Expected %s focus change from %s to %s, got %s instead" %
			[action, children_nodes[idx-1], children_nodes[idx], get_viewport().gui_get_focus_owner()]
		).is_true()

	runner.simulate_action_pressed(action)
	await await_idle_frame()
	assert_bool(first.has_focus()).override_failure_message( 
		"Expected %s wraparound from %s to %s, got %s instead" %
		[action, children_nodes.back(), first, get_viewport().gui_get_focus_owner()]
	).is_true()

func focus_up(children : Array) -> void:
	await focus_sequence(children, "ui_up")

func focus_down(children : Array) -> void:
	await focus_sequence(children, "ui_down")

func focus_left(children : Array) -> void:
	await focus_sequence(children, "ui_left")

func focus_right(children : Array) -> void:
	await focus_sequence(children, "ui_right")

func focus_vertical(children : Array) -> void:
	await focus_down(children)
	#children.reverse()
	#await focus_up(children)

func focus_horizontal(children : Array) -> void:
	await focus_right(children)
	children.reverse()
	await focus_left(children)

func before():
	setup()

func before_test():
	runner = scene_runner(root_path)

