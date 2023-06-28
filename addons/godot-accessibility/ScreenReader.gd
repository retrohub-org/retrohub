@tool
extends Node

@export var enabled = true

@export var theme_viewport : NodePath

var node : Control

func _enter_tree():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready():
	if Engine.is_editor_hint() and not TTS.editor_accessibility_enabled:
		return
	get_viewport().connect("gui_focus_changed", Callable(self, "gui_focus_changed"))
	if theme_viewport:
		get_node(theme_viewport).connect("gui_focus_changed", Callable(self, "gui_focus_changed"))


func click(item := node, button_index = MOUSE_BUTTON_LEFT):
	print_debug("Click")
	var click = InputEventMouseButton.new()
	click.button_index = button_index
	click.button_pressed = true
	if item is Node:
		click.position = item.global_position
	else:
		click.position = node.get_tree().root.get_mouse_position()
	node.get_tree().input_event(click)
	click.button_pressed = false
	node.get_tree().input_event(click)


func _accept_dialog_speak(node):
	var text
	if node.dialog_text != "":
		text = node.dialog_text
	else:
		for c in node.get_children():
			if c is Label:
				text = c.text
	if text:
		TTS.speak("Dialog: %s" % text)
	else:
		TTS.speak("Dialog")


func _accept_dialog_focused(node):
	_accept_dialog_speak(node)
	if node.get_parent() and node.get_parent().is_class("ProjectSettingsEditor"):
		await node.get_tree().create_timer(5).timeout
		node.get_ok_button().emit_signal("pressed")


func _accept_dialog_about_to_show(node):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	_accept_dialog_speak(node)
	#ScreenReader.should_stop_on_focus = false


func _basebutton_button_down():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	TTS.stop()


func checkbox_focused():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	var tokens = PackedStringArray([])
	if node.text:
		tokens.append(node.text)
	if node.button_pressed:
		tokens.append("checked")
	else:
		tokens.append("unchecked")
	tokens.append(" checkbox")
	TTS." ".join(speak(tokens))


func _checkbox_or_checkbutton_toggled(checked, node):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	if node.has_focus():
		if checked:
			TTS.speak("checked", true)
		else:
			TTS.speak("unchecked", true)


func _checkbutton_focused():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	var tokens = PackedStringArray([])
	if node.text:
		tokens.append(node.text)
	if node.button_pressed:
		tokens.append("checked")
	else:
		tokens.append("unchecked")
	tokens.append(" check button")
	TTS." ".join(speak(tokens))


var spoke_hint_tooltip


func _button_focused():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	var tokens = PackedStringArray([])
	if node.text:
		tokens.append(node.text)
	elif node.tooltip_text:
		spoke_hint_tooltip = true
		tokens.append(node.tooltip_text)
	else:
		tokens.append(_get_graphical_button_text(node.icon))
	tokens.append("button")
	if node.disabled:
		tokens.append("disabled")
	TTS.": ".join(speak(tokens))


func try_to_get_text_in_theme(theme, texture):
	if theme == null:
		return ""

	for type in theme.get_type_list(""):
		for icon in theme.get_icon_list(type):
			var icon_texture = theme.get_icon(icon, type)
			if icon_texture == texture:
				return icon

	return ""


func _get_graphical_button_text(texture):
	var default_theme_copy = Theme.new()
	default_theme_copy.copy_default_theme()
	var current = node
	while current != null:
		var text = try_to_get_text_in_theme(current.theme, texture)
		if text != "":
			return text
		current = current.get_parent_control()
	return try_to_get_text_in_theme(default_theme_copy, texture)


func _texturebutton_focused():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	var tokens = PackedStringArray([])
	tokens.append(_get_graphical_button_text(node.texture_normal))
	tokens.append("button")
	TTS.": ".join(speak(tokens))


func item_list_item_focused(idx, node):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	var tokens = PackedStringArray([])
	var text = node.get_item_text(idx)
	if text:
		tokens.append(text)
	text = node.get_item_tooltip(idx)
	if text:
		tokens.append(text)
	tokens.append("%s of %s" % [idx + 1, node.get_item_count()])
	TTS.": ".join(speak(tokens))


func item_list_focused():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	var count = node.get_item_count()
	var selected = node.get_selected_items()
	print_debug(selected)
	if len(selected) == 0:
		if node.get_item_count() == 0:
			return TTS.speak("list, 0 items")
		selected = 0
		node.select(selected)
		node.emit_signal("item_list_item_selected", selected)
	else:
		selected = selected[0]
	item_list_item_focused(selected, node)


func item_list_item_selected(index, node):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	item_list_item_focused(index, node)


func item_list_multi_selected(index, selected):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	TTS.speak("Multiselect")


func item_list_nothing_selected():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	TTS.speak("Nothing selected")


func item_list_input(event):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_left"):
		return node.accept_event()
	var old_count = node.get_item_count()
	if event.is_action_pressed("ui_up"):
		node.accept_event()
	elif event.is_action_pressed("ui_down"):
		node.accept_event()
	elif event.is_action_pressed("ui_home"):
		node.accept_event()
	elif event.is_action_pressed("ui_end"):
		node.accept_event()


func _label_focused():
	var tokens = PackedStringArray([])
	if node.get_parent() is Window:
		tokens.append("Dialog")
	var text = node.text
	if text == "":
		text = "blank"
	tokens.append(text)
	TTS.": ".join(speak(tokens))


func line_edit_focused():
	var text = "blank"
	if node.secret:
		text = "password"
	elif node.text != "":
		text = node.text
	elif node.placeholder_text != "":
		text = node.placeholder_text
	var type = "editable text"
	if not node.editable:
		type = "text"
	TTS.speak("%s: %s" % [text, type])

func menu_button_focused():
	var tokens = PackedStringArray([])
	if node.text:
		tokens.append(node.text)
	if node.tooltip_text:
		tokens.append(node.tooltip_text)
		spoke_hint_tooltip = true
	tokens.append("menu")
	TTS.": ".join(speak(tokens))


func popup_menu_focused():
	popup_menu_item_id_focused(node.get_current_index(), node)


func popup_menu_item_id_focused(index, node):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	print_debug("item id focus %s" % index)
	var n : Node = node
	var spoken_custom := false
	while n and not spoken_custom:
		if n.has_method("tts_popup_menu_item_text"):
			await get_tree().process_frame
			var text : String = n.tts_popup_menu_item_text(index, node)
			if not text.is_empty():
				TTS.speak(text)
				spoken_custom = true
		n = n.get_parent()
	var tokens = PackedStringArray([])
	var shortcut = node.get_item_shortcut(index)
	var name
	if shortcut:
		name = shortcut.resource_name
		if name:
			tokens.append(name)
		var text = shortcut.get_as_text()
		if text != "None":
			tokens.append(text)
	var item = node.get_item_text(index)
	if item and not spoken_custom and item != name:
		tokens.append(item)
	var submenu = node.get_item_submenu(index)
	if submenu:
		tokens.append(submenu)
		tokens.append("menu")
	if node.is_item_checkable(index):
		if node.is_item_checked(index):
			tokens.append("checked")
		else:
			tokens.append("unchecked")
	var tooltip = node.get_item_tooltip(index)
	if tooltip:
		tokens.append(tooltip)
	var disabled = node.is_item_disabled(index)
	if disabled:
		tokens.append("disabled")
	tokens.append(str(index + 1) + " of " + str(node.get_item_count()))
	TTS.": ".join(speak(tokens), not spoken_custom)


func popup_menu_item_id_pressed(index, node):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	if node.is_item_checkable(index):
		if node.is_item_checked(index):
			TTS.speak("checked")
		else:
			TTS.speak("unchecked")


func range_focused():
	var tokens = PackedStringArray([])
	var n = node
	while n:
		if n.has_method("tts_range_value_text"):
			break
		n = n.get_parent()
	if n:
		var text : String = n.tts_range_value_text(node.value, node)
		if not text.is_empty():
			tokens.append(text)
		else:
			tokens.append(str(node.value))
	else:
		tokens.append(str(node.value))
	if node is HSlider:
		tokens.append("horizontal slider")
	elif node is VSlider:
		tokens.append("vertical slider")
	elif node is SpinBox:
		tokens.append("spin box")
	else:
		tokens.append("range")
	if n:
		var min_text : String = n.tts_range_value_text(node.min_value, node)
		var max_text : String = n.tts_range_value_text(node.max_value, node)
		if not min_text.is_empty():
			tokens.append("minimum %s" % min_text)
		else:
			tokens.append("minimum %s" % node.min_value)
		if not max_text.is_empty():
			tokens.append("maximum %s" % max_text)
		else:
			tokens.append("maximum %s" % node.max_value)
	else:
		tokens.append("minimum %s" % node.min_value)
		tokens.append("maximum %s" % node.max_value)
	if OS.has_touchscreen_ui_hint():
		tokens.append("Swipe up and down to change.")
	TTS.": ".join(speak(tokens))


func spinbox_value_changed(value, node):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	if node.has_focus():
		var text := ""
		if node.prefix:
			text += node.prefix
		text += str(value)
		if node.suffix:
			text += node.suffix
		TTS.speak(text)

func range_value_changed(value, node):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	if node.has_focus():
		var n = node
		while n:
			if n.has_method("tts_range_value_text"):
				var text : String = n.tts_range_value_text(value, node)
				if not text.is_empty():
					TTS.speak(text)
					return
			n = n.get_parent()
		TTS.speak("%s" % value)


func text_edit_focus():
	var tokens = PackedStringArray([])
	if node.text:
		tokens.append(node.text)
	else:
		tokens.append("blank")
	if node.readonly:
		tokens.append("read-only edit text")
	else:
		tokens.append("edit text")
	TTS.": ".join(speak(tokens))

var button_index

func _tree_item_render(node):
	if not node.has_focus():
		return
	var n : Node = node
	var cell = node.get_selected()
	while n:
		if n.has_method("tts_tree_item_text"):
			await get_tree().process_frame
			var text : String = n.tts_tree_item_text(cell, node)
			if not text.is_empty():
				TTS.speak(text)
				return
		n = n.get_parent()
	var tokens = PackedStringArray([])
	if cell:
		for i in range(node.columns):
			if node.select_mode == Tree.SELECT_MULTI or cell.is_selected(i):
				var title = node.get_column_title(i)
				if title:
					tokens.append(title)
				var column_text = cell.get_text(i)
				if column_text:
					tokens.append(column_text)
				if cell.get_children():
					if cell.collapsed:
						tokens.append("collapsed")
					else:
						tokens.append("expanded")
				var button_count = cell.get_button_count(i)
				if button_count != 0:
					var column
					for j in range(node.columns):
						if cell.is_selected(j):
							column = j
							break
					if column == i:
						button_index = 0
					else:
						button_index = null
					tokens.append(
						(
							str(button_count)
							+ " "
							+ TTS.singular_or_plural(button_count, "button", "buttons")
						)
					)
					if button_index != null:
						var button_tooltip = cell.get_button_tooltip(i, button_index)
						if button_tooltip:
							tokens.append(button_tooltip)
							tokens.append("button")
						if button_count > 1:
							tokens.append("Use Home and End to switch focus.")
		tokens.append("tree item")
		TTS.": ".join(speak(tokens), true)


var prev_selected_cell


func _tree_item_or_cell_selected(node):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	button_index = null
	_tree_item_render(node)


func tree_item_multi_selected(item, column, selected):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	if selected:
		TTS.speak("selected", true)
	else:
		TTS.speak("unselected", true)


func _tree_input(event):
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		node.accept_event()
	var item = node.get_selected()
	var column
	if item:
		for i in range(node.columns):
			if item.is_selected(i):
				column = i
				break
	if item and event is InputEventKey and event.pressed and not event.echo:
		var area
		if column:
			area = node.get_item_area_rect(item, column)
		else:
			area = node.get_item_area_rect(item)
		var position = Vector2(
			node.global_position.x + area.position.x + area.size.x / 2,
			node.global_position.y + area.position.y + area.size.y / 2
		)
		node.get_tree().root.warp_mouse(position)
	if item and column != null and item.get_button_count(column):
		if Input.is_action_just_pressed("ui_accept"):
			node.accept_event()
			return node.emit_signal("button_pressed", item, column, button_index + 1)
		var new_button_index = button_index
		if event.is_action_pressed("ui_home"):
			node.accept_event()
			new_button_index += 1
			if new_button_index >= item.get_button_count(column):
				new_button_index = 0
		elif event.is_action_pressed("ui_end"):
			node.accept_event()
			new_button_index -= 1
			if new_button_index < 0:
				new_button_index = item.get_button_count(column) - 1
		if new_button_index != button_index and item.has_method("get_button_tooltip"):
			button_index = new_button_index
			var tokens = PackedStringArray([])
			var tooltip = item.get_button_tooltip(column, button_index)
			if tooltip:
				tokens.append(tooltip)
			tokens.append("button")
			TTS.": ".join(speak(tokens), true)


func tree_focused():
	if node.get_selected():
		_tree_item_render(node)
	else:
		TTS.speak("tree", true)


var _was_collapsed


func _tree_item_collapsed(item, node):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	if node.has_focus():
		var selected = false
		for column in range(node.columns):
			if item.is_selected(column):
				selected = true
				break
		if selected and item.collapsed != _was_collapsed:
			if item.collapsed:
				TTS.speak("collapsed", true)
			else:
				TTS.speak("expanded", true)
	_was_collapsed = item.collapsed


func progress_bar_focused():
	var percentage = int(node.ratio * 100)
	TTS.speak("%s percent" % percentage)
	TTS.speak("progress bar")


var last_percentage_spoken

var last_percentage_spoken_at = 0


func progress_bar_value_changed(value, node):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	var percentage = node.value / (node.max_value - node.min_value) * 100
	percentage = int(percentage)
	if (
		percentage != last_percentage_spoken
		and Time.get_ticks_msec() - last_percentage_spoken_at >= 10000
	):
		TTS.speak("%s percent" % percentage)
		last_percentage_spoken_at = Time.get_ticks_msec()
		last_percentage_spoken = percentage


func tab_container_focused():
	var text = node.get_tab_title(node.current_tab)
	text += ": tab: " + str(node.current_tab + 1) + " of " + str(node.get_tab_count())
	TTS.speak(text)


func tab_container_tab_changed(tab, node):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	if node.has_focus():
		TTS.stop()
		tab_container_focused()

func tab_container_handler_changed(tab, enter_tab, node):
	var n = node
	while n:
		if n.has_method("tts_text"):
			var text = n.tts_text(node)
			if text:
				TTS.speak(text)
				return


func gui_focus_changed(_node: Control):
	node = _node
	connect_signals()
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	print_debug("Focus: %s" % node)
	# Check if any node implements a custom TTS message
	var n : Node = node
	while n:
		if n.has_method("tts_text"):
			var text : String = n.tts_text(node)
			if not text.is_empty():
				TTS.speak(text)
				return
		n = n.get_parent()
	if node is MenuButton:
		menu_button_focused()
	elif node is AcceptDialog:
		_accept_dialog_focused(node)
	elif node is CheckBox:
		checkbox_focused()
	elif node is CheckButton:
		_checkbutton_focused()
	elif node is Button:
		_button_focused()
	elif node is ItemList:
		item_list_focused()
	elif node is Label or node is RichTextLabel:
		_label_focused()
	elif node is LineEdit:
		line_edit_focused()
	elif node is LinkButton:
		_button_focused()
	elif node is PopupMenu:
		popup_menu_focused()
	elif node is ProgressBar:
		progress_bar_focused()
	elif node is Range:
		range_focused()
	elif node is TabContainer:
		tab_container_focused()
	elif node is TextEdit:
		text_edit_focus()
	elif node is TextureButton:
		_texturebutton_focused()
	elif node is Tree:
		tree_focused()
	else:
		#TTS.speak(node.get_class(), true)
		print_debug("No handler")
	if node.tooltip_text and not spoke_hint_tooltip:
		TTS.speak(node.tooltip_text, false)
	spoke_hint_tooltip = false


func _input(event):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled or \
		not is_instance_valid(node):
		return
	if (
		event is InputEventKey
		and Input.is_action_just_pressed("ui_accept")
		and event.control
		and event.alt
	):
		TTS.speak("click")
		click()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_MENU:
		node.get_tree().root.warp_mouse(node.global_position)
		return click(null, MOUSE_BUTTON_RIGHT)
	elif node is ItemList:
		return item_list_input(event)
	elif event is InputEventKey and event.is_pressed() and node is LineEdit:
		if event.keycode & SPKEY:
			if (RetroHubUI.is_event_from_virtual_keyboard() and \
				(event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT)) or \
			(event.is_action("ui_left") or event.is_action("ui_right")):
				await get_tree().process_frame
				if node.caret_column < node.text.length():
					TTS.speak(node.text.substr(node.caret_column))
		else:
			TTS.speak(OS.get_keycode_string(event.keycode))

func connect_signals():
	if node.is_in_group("rh_accessible"):
		return
	node.add_to_group("rh_accessible")
	if node is BaseButton:
		node.connect("button_down", Callable(self, "_basebutton_button_down"))
	if node is AcceptDialog:
		node.connect("about_to_popup", Callable(self, "_accept_dialog_about_to_show").bind(node))
	elif node is CheckBox or node is CheckButton:
		node.connect("toggled", Callable(self, "_checkbox_or_checkbutton_toggled").bind(node))
	elif node is ItemList:
		node.connect("item_selected", Callable(self, "item_list_item_selected").bind(node))
		node.connect("multi_selected", Callable(self, "item_list_multi_selected"))
		node.connect("nothing_selected", Callable(self, "item_list_nothing_selected"))
	elif node is PopupMenu:
		node.connect("id_focused", Callable(self, "popup_menu_item_id_focused").bind(node))
		node.connect("id_pressed", Callable(self, "popup_menu_item_id_pressed").bind(node))
	elif node is ProgressBar:
		node.connect("value_changed", Callable(self, "progress_bar_value_changed").bind(node))
	elif node is Range:
		if node is SpinBox:
			node.connect("value_changed", Callable(self, "spinbox_value_changed").bind(node))
		else:
			node.connect("value_changed", Callable(self, "range_value_changed").bind(node))
	elif node is TabContainer:
		node.connect("tab_changed", Callable(self, "tab_container_tab_changed").bind(node))
	elif node is TabContainerHandler:
		node.connect("tab_changed", Callable(self, "tab_container_handler_changed").bind(node))
	elif node is Tree:
		node.connect("item_collapsed", Callable(self, "_tree_item_collapsed").bind(node))
		node.connect("multi_selected", Callable(self, "tree_item_multi_selected"))
		if node.select_mode == Tree.SELECT_MULTI:
			node.connect("cell_selected", Callable(self, "_tree_item_or_cell_selected").bind(node))
		else:
			node.connect("item_selected", Callable(self, "_tree_item_or_cell_selected").bind(node))
		node.connect("item_edited", Callable(self, "_tree_item_or_cell_selected").bind(node))
		node.connect("item_activated", Callable(self, "_tree_item_or_cell_selected").bind(node))
