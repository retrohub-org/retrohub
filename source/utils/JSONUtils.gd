extends Node

func load_json_file(filepath: String):
	var file := FileAccess.open(filepath, FileAccess.READ)
	if not file:
		push_error("Error when opening " + filepath)
		return {}
	var json = load_json_buffer(file.get_as_text())
	if not json:
		push_error("Error when parsing JSON for " + filepath)
	return json

func load_json_buffer(data: String):
	var json = JSON.new()
	if json.parse(data):
		push_error("Error when parsing JSON buffer")
		return {}
	return json.get_data()

func save_json_file(json, file_path: String):
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(json, "\t"))
	file.close()

func make_system_specific(json: Dictionary, curr_system: String):
	for key in json.keys():
		var value = json[key]
		if value is Array:
			# Possibly the thing we are looking for, test further
			if value.size() and value[0] is Dictionary and value[0].has("windows"):
				# Found system-specific data
				var found := false
				for system in value:
					if system.has(curr_system):
						json[key] = system[curr_system]
						found = true
						break

				if not found:
					push_error("Error, JSON doesn't have required system, leaving as is...")
			else:
				# Not what we're looking for, recurse it
				for arr_value in value:
					if arr_value is Dictionary:
						make_system_specific(arr_value, curr_system)
		# Not what we're looking for, append to output
		elif value is Dictionary:
			make_system_specific(value, curr_system)


func map_array_by_key(input: Array, key: String) -> Dictionary:
	var dict := {}
	var subkeys := []
	for value in input:
		subkeys.push_back(value[key])
	subkeys.sort()
	for subkey in subkeys:
		for value in input:
			if value[key] == subkey:
				dict[subkey] = value
				continue

	return dict

func format_string_with_substitutes(raw_str: String, substitutes: Dictionary, tk_start: String = "{", tk_end: String = "}", remove_empty: bool = false) -> String:
	var format_str := raw_str
	var idx := format_str.find(tk_start)
	while idx != -1:
		if idx > 0 and format_str[idx - 1] == "\\":
			format_str.erase(idx - 1, 1)
			idx = format_str.find(tk_start, idx)
			continue
		var end_idx := format_str.find(tk_end, idx)
		if end_idx == -1:
			push_error("Invalid format string" + raw_str + "!")
			return raw_str
		var token := format_str.substr(idx + tk_start.length(), end_idx - (idx + tk_start.length()))
		if token in substitutes:
			format_str = format_str.replace(tk_start + token + tk_end, substitutes[token])
		elif remove_empty:
			format_str = format_str.replace(tk_start + token + tk_end, "")
		else:
			idx = end_idx
		idx = format_str.find(tk_start, idx)
	return format_str
