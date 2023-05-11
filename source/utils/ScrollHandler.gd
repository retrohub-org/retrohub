extends Control
class_name ScrollHandler

## Handles sliding through controller secondary input. Add as a child of a scrollable node.
## Supports nodes with scroll bars:
## - ScrollContainer
## - Tree
## - OptionButton
## - PopupMenu

var scroll_h : HScrollBar = null
var scroll_v : VScrollBar = null
var scroll_h_speed := 0.0
var scroll_v_speed := 0.0

@export var scroll_multiplier := 500.0

func _ready():
	# This _ready is called before parent, we need to wait a frame for parent to initialize
	mouse_filter = MOUSE_FILTER_IGNORE
	await get_tree().process_frame
	var parent := get_parent()
	if parent is ScrollContainer:
		_handle_scroll_container(parent)
	elif parent is Tree:
		_handle_internal_children(parent)
	elif parent is OptionButton:
		_handle_popup_menu(parent.get_popup())
	elif parent is PopupMenu:
		_handle_popup_menu(parent)

	if not scroll_h and not scroll_v:
		push_error("ScrollHandler added to a non-scrollable node! Queueing free...")
		queue_free()

func _handle_scroll_container(node: ScrollContainer):
	if node.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		scroll_h = node.get_h_scroll_bar()
	if node.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		scroll_v = node.get_v_scroll_bar()

func _handle_internal_children(node):
	for child in node.get_children():
		if child == self:
			continue
		if child is HScrollBar:
			scroll_h = child
		if child is VScrollBar:
			scroll_v = child

func _handle_popup_menu(node: PopupMenu):
	if node.get_child_count() < 0:
		return

	for child in node.get_child(0).get_children():
		if child is ScrollContainer:
			_handle_scroll_container(child)
			return

func _process(delta):
	if scroll_h:
		scroll_h.value += scroll_h_speed * delta * scroll_multiplier
	if scroll_v:
		scroll_v.value += scroll_v_speed * delta * scroll_multiplier

func _unhandled_input(event):
	if RetroHub.is_input_echo():
		return

	if (scroll_h and scroll_h.is_visible_in_tree()) or (scroll_v and scroll_v.is_visible_in_tree()):
		if scroll_h and (event.is_action("rh_rstick_left") or event.is_action("rh_rstick_right")):
			scroll_h_speed = Input.get_axis("rh_rstick_left", "rh_rstick_right")
			get_viewport().set_input_as_handled()
		if scroll_v and (event.is_action("rh_rstick_up") or event.is_action("rh_rstick_down")):
			scroll_v_speed = Input.get_axis("rh_rstick_up", "rh_rstick_down")
			get_viewport().set_input_as_handled()
