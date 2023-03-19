extends Node

var node

var position_in_children = 0

var column_in_row = 0


func get_siblings():
	var parent = node.get_parent()
	if parent:
		return parent.get_children()
	return null


func click(item := node, button_index = BUTTON_LEFT):
	print_debug("Click")
	var click = InputEventMouseButton.new()
	click.button_index = button_index
	click.pressed = true
	if item is Node:
		click.position = item.rect_global_position
	else:
		click.position = node.get_tree().root.get_mouse_position()
	node.get_tree().input_event(click)
	click.pressed = false
	node.get_tree().input_event(click)


func _guess_label():
	if node is Label:
		return
	if not node is LineEdit and not node is TextEdit and node.get("text"):
		return
	var tokens = PoolStringArray([])
	var to_check = node
	while to_check:
		if to_check.is_class("AcceptDialog"):
			return
		if to_check.is_class("EditorProperty") and to_check.label:
			tokens.append(to_check.label)
		if (
			(to_check.is_class("EditorProperty") or to_check.is_class("EditorInspectorCategory"))
			and to_check.get_tooltip_text()
		):
			tokens.append(to_check.get_tooltip_text())
		var label = tokens.join(": ")
		if label:
			return label
		for child in to_check.get_children():
			if child is Label:
				return child
		to_check = to_check.get_parent()


func _accept_dialog_speak():
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


func _accept_dialog_focused():
	_accept_dialog_speak()
	if node.get_parent() and node.get_parent().is_class("ProjectSettingsEditor"):
		yield(node.get_tree().create_timer(5), "timeout")
		node.get_ok().emit_signal("pressed")


func _accept_dialog_about_to_show():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	_accept_dialog_speak()
	#ScreenReader.should_stop_on_focus = false


func _basebutton_button_down():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	TTS.stop()


func checkbox_focused():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	var tokens = PoolStringArray([])
	if node.text:
		tokens.append(node.text)
	if node.pressed:
		tokens.append("checked")
	else:
		tokens.append("unchecked")
	tokens.append(" checkbox")
	TTS.speak(tokens.join(" "))


func _checkbox_or_checkbutton_toggled(checked):
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
	var tokens = PoolStringArray([])
	if node.text:
		tokens.append(node.text)
	if node.pressed:
		tokens.append("checked")
	else:
		tokens.append("unchecked")
	tokens.append(" check button")
	TTS.speak(tokens.join(" "))


var spoke_hint_tooltip


func _button_focused():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	var tokens = PoolStringArray([])
	if node.text:
		tokens.append(node.text)
	elif node.hint_tooltip:
		spoke_hint_tooltip = true
		tokens.append(node.hint_tooltip)
	else:
		tokens.append(_get_graphical_button_text(node.icon))
	tokens.append("button")
	if node.disabled:
		tokens.append("disabled")
	TTS.speak(tokens.join(": "))


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
	var tokens = PoolStringArray([])
	tokens.append(_get_graphical_button_text(node.texture_normal))
	tokens.append("button")
	TTS.speak(tokens.join(": "))


func item_list_item_focused(idx):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	var tokens = PoolStringArray([])
	var text = node.get_item_text(idx)
	if text:
		tokens.append(text)
	text = node.get_item_tooltip(idx)
	if text:
		tokens.append(text)
	tokens.append("%s of %s" % [idx + 1, node.get_item_count()])
	TTS.speak(tokens.join(": "))


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
	position_in_children = selected
	item_list_item_focused(selected)


func item_list_item_selected(index):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	item_list_item_focused(index)


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
	var old_pos = position_in_children
	if event.is_action_pressed("ui_up"):
		node.accept_event()
		if position_in_children == 0:
			return
		position_in_children -= 1
	elif event.is_action_pressed("ui_down"):
		node.accept_event()
		if position_in_children >= node.get_item_count() - 1:
			return
		position_in_children += 1
	elif event.is_action_pressed("ui_home"):
		node.accept_event()
		position_in_children = 0
	elif event.is_action_pressed("ui_end"):
		node.accept_event()
		position_in_children = node.get_item_count() - 1
	if old_pos != position_in_children:
		if position_in_children >= node.get_item_count():
			position_in_children = 0
		node.unselect_all()
		node.select(position_in_children)
		node.emit_signal("item_list_item_selected", position_in_children)
		item_list_item_focused(position_in_children)


func _label_focused():
	var tokens = PoolStringArray([])
	if node.get_parent() is WindowDialog:
		tokens.append("Dialog")
	var text = node.text
	if text == "":
		text = "blank"
	tokens.append(text)
	TTS.speak(tokens.join(": "))


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


var old_text = ""

var old_pos


func line_edit_text_changed(text):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	if text == null or old_text == null:
		return
	if len(text) > len(old_text):
		for i in range(len(text)):
			if text.substr(i, 1) != old_text.substr(i, 1):
				TTS.speak(text.substr(i, 1))
				return
	else:
		for i in range(len(old_text)):
			if old_text.substr(i, 1) != text.substr(i, 1):
				TTS.speak(old_text.substr(i, 1))
				return


func line_edit_input(event):
	var pos = node.caret_position
	if old_pos != null and old_pos != pos:
		var text = node.text
		if old_text == text:
			if pos > len(text) - 1:
				TTS.speak("blank", true)
			else:
				TTS.speak(text[pos], true)
		old_pos = pos
	elif old_pos == null:
		old_pos = pos
	old_text = node.text


func menu_button_focused():
	var tokens = PoolStringArray([])
	if node.text:
		tokens.append(node.text)
	if node.hint_tooltip:
		tokens.append(node.hint_tooltip)
		spoke_hint_tooltip = true
	tokens.append("menu")
	TTS.speak(tokens.join(": "))


func popup_menu_focused():
	TTS.speak("menu")


func popup_menu_item_id_focused(index):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	print_debug("item id focus %s" % index)
	var tokens = PoolStringArray([])
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
	if item and item != name:
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
	TTS.speak(tokens.join(": "), true)


func popup_menu_item_id_pressed(index):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	if node.is_item_checkable(index):
		if node.is_item_checked(index):
			TTS.speak("checked", true)
		else:
			TTS.speak("unchecked", true)


func range_focused():
	var tokens = PoolStringArray([])
	tokens.append(str(node.value))
	if node is HSlider:
		tokens.append("horizontal slider")
	elif node is VSlider:
		tokens.append("vertical slider")
	elif node is SpinBox:
		tokens.append("spin box")
	else:
		tokens.append("range")
	tokens.append("minimum %s" % node.min_value)
	tokens.append("maximum %s" % node.max_value)
	if OS.has_touchscreen_ui_hint():
		tokens.append("Swipe up and down to change.")
	TTS.speak(tokens.join(": "))


func range_value_changed(value):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	if node.has_focus():
		TTS.speak("%s" % value, true)


func text_edit_focus():
	var tokens = PoolStringArray([])
	if node.text:
		tokens.append(node.text)
	else:
		tokens.append("blank")
	if node.readonly:
		tokens.append("read-only edit text")
	else:
		tokens.append("edit text")
	TTS.speak(tokens.join(": "))


func text_edit_input(event):
	pass


var _last_tree_item_tokens

var button_index


func _tree_item_render():
	if not node.has_focus():
		return
	var cell = node.get_selected()
	var tokens = PoolStringArray([])
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
	if tokens != _last_tree_item_tokens:
		TTS.speak(tokens.join(": "), true)
	_last_tree_item_tokens = tokens


var prev_selected_cell


func _tree_item_or_cell_selected():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	button_index = null
	_tree_item_render()


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
			node.rect_global_position.x + area.position.x + area.size.x / 2,
			node.rect_global_position.y + area.position.y + area.size.y / 2
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
			var tokens = PoolStringArray([])
			var tooltip = item.get_button_tooltip(column, button_index)
			if tooltip:
				tokens.append(tooltip)
			tokens.append("button")
			TTS.speak(tokens.join(": "), true)


func tree_focused():
	_last_tree_item_tokens = null
	if node.get_selected():
		_tree_item_render()
	else:
		TTS.speak("tree", true)


var _was_collapsed


func _tree_item_collapsed(item):
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


func progress_bar_value_changed(value):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	var percentage = node.value / (node.max_value - node.min_value) * 100
	percentage = int(percentage)
	if (
		percentage != last_percentage_spoken
		and OS.get_ticks_msec() - last_percentage_spoken_at >= 10000
	):
		TTS.speak("%s percent" % percentage)
		last_percentage_spoken_at = OS.get_ticks_msec()
		last_percentage_spoken = percentage


func tab_container_focused():
	var text = node.get_tab_title(node.current_tab)
	text += ": tab: " + str(node.current_tab + 1) + " of " + str(node.get_tab_count())
	TTS.speak(text)


func tab_container_tab_changed(tab):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	if node.has_focus():
		TTS.stop()
		tab_container_focused()


func tab_container_input(event):
	var new_tab = node.current_tab
	if event.is_action_pressed("ui_right"):
		node.accept_event()
		new_tab += 1
	elif event.is_action_pressed("ui_left"):
		node.accept_event()
		new_tab -= 1
	if new_tab < 0:
		new_tab = node.get_tab_count() - 1
	elif new_tab >= node.get_tab_count():
		new_tab = 0
	if node.current_tab != new_tab:
		node.current_tab = new_tab


func focused():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	print_debug("Focus: %s" % node)
	if not node is Label:
		var label = _guess_label()
		if label:
			if label is Label:
				label = label.text
			if label and label != "":
				TTS.speak(label)
	# Check if any node implements a custom TTS message
	var n : Node = node
	while n:
		if n.has_method("tts_text"):
			var text : String = n.tts_text(node)
			if not text.empty():
				TTS.speak(text)
				return
		n = n.get_parent()
	if node is MenuButton:
		menu_button_focused()
	elif node is AcceptDialog:
		_accept_dialog_focused()
	elif node is CheckBox:
		checkbox_focused()
	elif node is CheckButton:
		_checkbutton_focused()
	elif node is Button:
		_button_focused()
	elif node.is_class("EditorInspectorSection"):
		editor_inspector_section_focused()
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
	if node.hint_tooltip and not spoke_hint_tooltip:
		TTS.speak(node.hint_tooltip)
	spoke_hint_tooltip = false


func unfocused():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	position_in_children = 0


func click_focused():
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	if node.has_focus():
		return
	if node.focus_mode == Control.FOCUS_ALL:
		node.grab_focus()


func gui_input(event):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return
	if (
		event is InputEventKey
		and Input.is_action_just_pressed("ui_accept")
		and event.control
		and event.alt
	):
		TTS.speak("click")
		click()
	elif event is InputEventKey and event.pressed and not event.echo and event.scancode == KEY_MENU:
		node.get_tree().root.warp_mouse(node.rect_global_position)
		return click(null, BUTTON_RIGHT)
	if node is TabContainer:
		return tab_container_input(event)
	elif node is ItemList:
		return item_list_input(event)
	elif node is LineEdit:
		return line_edit_input(event)
	elif node is TextEdit:
		return text_edit_input(event)
	elif node is Tree:
		pass
		#return _tree_input(event)
	elif node.is_class("EditorInspectorSection"):
		return editor_inspector_section_input(event)


func _is_focusable(node):
	if node.is_class("SceneTreeEditor"):
		return false
	if node.is_class("MultiMeshEditor"):
		return false
	if node.is_class("MeshInstanceEditor"):
		return false
	if node.is_class("SpriteEditor"):
		return false
	if node.is_class("Skeleton2DEditor"):
		return false
	if node.is_class("CollisionShape2DEditor"):
		return false
	if node is Panel:
		return false
	if node is TabContainer:
		return true
	if node.is_class("EditorInspectorSection"):
		return true
	if node is AcceptDialog:
		return true
	if node is Label and node.get_parent() and node.get_parent() is AcceptDialog:
		return false
	if (
		node is Container
		or node is Separator
		or node is ScrollBar
		or node is Popup
		or node.get_class() == "Control"
	):
		return false
	return false


func editor_inspector_section_focused():
	var child = node.get_children()[0]
	var tokens = PoolStringArray(["editor inspector section"])
	if child is CanvasItem or child is Spatial:
		var expanded = child.is_visible_in_tree()
		if expanded:
			tokens.append("expanded")
		else:
			tokens.append("collapsed")
	TTS.speak(tokens.join(": "))


func editor_inspector_section_input(event):
	if event.is_action_pressed("ui_accept"):
		click()
		var child = node.get_children()[0]
		var expanded = child.is_visible_in_tree()
		if expanded:
			TTS.speak("expanded", true)
		else:
			TTS.speak("collapsed", true)


func _init(node):
	name = "Accessible for " + node.name
	if node.is_in_group("accessible"):
		return
	node.add_to_group("accessible")
	self.add_to_group("rh_access")
	node.call_deferred("add_child", self)
	self.node = node
	#if _is_focusable(node):
	#	node.set_focus_mode(Control.FOCUS_ALL)
	node.connect("focus_entered", self, "focused")
	node.connect("mouse_entered", self, "click_focused")
	node.connect("focus_exited", self, "unfocused")
	node.connect("mouse_exited", self, "unfocused")
	node.connect("gui_input", self, "gui_input")
	if node is BaseButton:
		node.connect("button_down", self, "_basebutton_button_down")
	if node is AcceptDialog:
		node.connect("about_to_show", self, "_accept_dialog_about_to_show")
	elif node is CheckBox or node is CheckButton:
		node.connect("toggled", self, "_checkbox_or_checkbutton_toggled")
	elif node is ItemList:
		node.connect("item_selected", self, "item_list_item_selected")
		node.connect("multi_selected", self, "item_list_multi_selected")
		node.connect("nothing_selected", self, "item_list_nothing_selected")
	elif node is LineEdit:
		node.connect("text_changed", self, "line_edit_text_changed")
	elif node is PopupMenu:
		node.connect("id_focused", self, "popup_menu_item_id_focused")
		node.connect("id_pressed", self, "popup_menu_item_id_pressed")
	elif node is ProgressBar:
		node.connect("value_changed", self, "progress_bar_value_changed")
	elif node is Range:
		node.connect("value_changed", self, "range_value_changed")
	elif node is TabContainer:
		node.connect("tab_changed", self, "tab_container_tab_changed")
	elif node is Tree:
		node.connect("item_collapsed", self, "_tree_item_collapsed")
		node.connect("multi_selected", self, "tree_item_multi_selected")
		if node.select_mode == Tree.SELECT_MULTI:
			node.connect("cell_selected", self, "_tree_item_or_cell_selected")
		else:
			node.connect("item_selected", self, "_tree_item_or_cell_selected")
	node.connect("tree_exiting", self, "queue_free", [], Object.CONNECT_DEFERRED)
