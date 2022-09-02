extends Node

func load_json_file(filepath : String) -> Dictionary:
	var file = File.new()
	if file.open(filepath, File.READ):
		print("Error when opening " + filepath)
		return {}
	var json := JSON.parse(file.get_as_text())
	if json.error:
		print("Error when parsing JSON for " + filepath)
		return {}
	return json.result

func make_system_specific(input_json: Dictionary, curr_system: String):
	var output_json := {}
	
	for key in input_json.keys():
		var value = input_json[key]
		if value is Array:
			# Possibly the thing we are looking for, test further
			if value.size() and value[0] is Dictionary and value[0].has("windows"):
				# Found system-specific data, now find appropriate child
				var system_data = null
				for system in value:
					if system.has(curr_system):
						system_data = system[curr_system]
						break
				
				if system_data != null:
					output_json[key] = system_data
				else:
					print("Error, JSON doesn't have required system, leaving as is...")
					output_json[key] = value
			else:
				# Not what we're looking for, recurse it
				output_json[key] = []
				for arr_value in value:
					if arr_value is Dictionary:
						output_json[key].append(make_system_specific(arr_value, curr_system))
					else:
						output_json[key].append(arr_value)
		# Not what we're looking for, append to output
		elif value is Dictionary:
			output_json[key] = make_system_specific(value, curr_system)
		else:
			output_json[key] = value
	
	return output_json

func find_by_key(input_arr: Array, key: String, values: Array) -> Dictionary:
	for val in values:
		for input in input_arr:
			if input.has(key) and input[key] == val:
				return input
	return {}

func find_all_by_key(input_arr: Array, key: String, values: Array) -> Array:
	var output := []
	for val in values:
		for input in input_arr:
			if input.has(key) and input[key] == val:
				output.push_back(input)
	return output

func map_array_by_key(input: Array, key: String) -> Dictionary:
	var dict := {}
	for value in input:
		dict[value[key]] = value

	return dict

func format_string_with_substitutes(raw_str: String, substitutes: Dictionary, tk_start: String = "{", tk_end: String = "}", remove_empty: bool = false) -> String:
	var format_str = raw_str
	var idx = format_str.find(tk_start)
	while idx != -1:
		if idx > 0 and format_str[idx - 1] == "\\":
			format_str.erase(idx - 1, 1)
			idx = format_str.find(tk_start, idx)
			continue
		var end_idx = format_str.find(tk_end, idx)
		if end_idx == -1:
			print("Invalid format string" + raw_str + "!")
			return raw_str
		var token = format_str.substr(idx + tk_start.length(), end_idx - (idx + tk_start.length()))
		if token in substitutes:
			format_str = format_str.replace(tk_start + token + tk_end, substitutes[token])
		elif remove_empty:
			format_str = format_str.replace(tk_start + token + tk_end, "")
		else:
			idx = end_idx
		idx = format_str.find(tk_start, idx)
	return format_str
