extends Node

@export var theme_viewport : NodePath

func _enter_tree():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node):
	if node is Window:
		connect_signals(node)
	if node is Viewport:
		(node as Viewport).gui_focus_changed.connect(gui_focus_changed)

func _accept_dialog_about_to_popup():
	await get_tree().process_frame
	RetroHubUI.play_sound(RetroHubUI.AudioKeys.MENU_IN)

func _window_about_to_popup():
	await get_tree().process_frame
	RetroHubUI.play_sound(RetroHubUI.AudioKeys.MENU_ENTER)

func _window_visibility_changed(node: Window):
	if not node.visible:
		await  get_tree().process_frame
		RetroHubUI.play_sound(RetroHubUI.AudioKeys.MENU_OUT)

func _basebutton_pressed():
	RetroHubUI.play_sound(RetroHubUI.AudioKeys.ACTIVATED)


func _checkbox_or_checkbutton_toggled(checked: bool, node: Button):
	if node.has_focus():
		RetroHubUI.play_sound(RetroHubUI.AudioKeys.CHECK_BUTTON_ON if checked else RetroHubUI.AudioKeys.CHECK_BUTTON_OFF)

func popup_menu_item_id_focused(_index: int, _node: PopupMenu):
	RetroHubUI.play_sound(RetroHubUI.AudioKeys.NAVIGATION)

func popup_menu_item_id_pressed(index: int, node: PopupMenu):
	if node.is_item_checkable(index) and not node.is_item_radio_checkable(index):
		if node.is_item_checked(index):
			RetroHubUI.play_sound(RetroHubUI.AudioKeys.CHECK_BUTTON_ON)
		else:
			RetroHubUI.play_sound(RetroHubUI.AudioKeys.CHECK_BUTTON_OFF)
	else:
		RetroHubUI.play_sound(RetroHubUI.AudioKeys.ACTIVATED)

func range_value_changed(_value, _node):
	RetroHubUI.play_sound(RetroHubUI.AudioKeys.SLIDER_TICK)

func _tree_item_or_cell_selected(_node):
	RetroHubUI.play_sound(RetroHubUI.AudioKeys.ACTIVATED)

func tab_container_tab_changed(_tab, _node):
	await get_tree().process_frame
	RetroHubUI.play_sound(RetroHubUI.AudioKeys.SLIDE)

func tab_container_handler_changed(_tab, enter_tab, _node):
	if not enter_tab:
		await get_tree().process_frame
		RetroHubUI.play_sound(RetroHubUI.AudioKeys.SLIDE)

func gui_focus_changed(node: Control):
	connect_signals(node)
	if not node.is_in_group("rh_no_sound"):
		RetroHubUI.play_sound(RetroHubUI.AudioKeys.NAVIGATION, false)

func connect_signals(node: Node):
	if node.is_in_group("rh_no_sound") or node.is_in_group("rh_sound_connected"):
		return
	# Re-use group to mark nodes with connected signals already
	node.add_to_group("rh_sound_connected")
	if node is CheckBox or node is CheckButton:
		node.toggled.connect(_checkbox_or_checkbutton_toggled.bind(node))
	elif node is BaseButton:
		node.pressed.connect(_basebutton_pressed)
	elif node is PopupMenu:
		var callable = func(n):
			popup_menu_item_id_focused(n.get_focused_item(), n)

		node.about_to_popup.connect(callable.bind(node))
		node.id_focused.connect(popup_menu_item_id_focused.bind(node))
		node.id_pressed.connect(popup_menu_item_id_pressed.bind(node))
	elif node is AcceptDialog or node is Popup:
		node.about_to_popup.connect(_accept_dialog_about_to_popup)
		node.visibility_changed.connect(_window_visibility_changed.bind(node))
	elif node is Window:
		node.about_to_popup.connect(_window_about_to_popup)
		node.visibility_changed.connect(_window_visibility_changed.bind(node))
	elif node is Range:
		node.value_changed.connect(range_value_changed.bind(node))
	elif node is TabBar:
		node.tab_changed.connect(tab_container_tab_changed.bind(node))
	elif node is Tree:
		node.item_selected.connect(_tree_item_or_cell_selected.bind(node))
		node.item_edited.connect(_tree_item_or_cell_selected.bind(node))
		node.item_activated.connect(_tree_item_or_cell_selected.bind(node))
