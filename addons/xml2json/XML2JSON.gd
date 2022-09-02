extends Node

class_name XML2JSON

# Author: @ev1lbl0w (https://github.com/ev1lbl0w)
#
# Converts an XML file into a JSON/Dictionary:
#
# var dict = XML2JSON.parse("example.xml") # "example.xml" in JSON/Dictionary format
#
# The following example:
#
# """
# <root>
# 	<!-- This is a comment -->
# 	<emptyNode1 />
# 	<emptyNode2></emptyNode2>
# 	<nodeWithSingleChild>child</nodeWithSingleChild>
# 	<repeatedNode>1</repeatedNode>
# 	<repeatedNode>3</repeatedNode>
# 	<nodeWithMultipleChild>
# 		<childOne>1</childOne>
# 		<childTwo>"2"</childTwo>
# 	</nodeWithMultipleChild>
# 	<nodeWithData foo="bar" />
# 	<complexNode data_str="my_data" data_int="3">
# 		<childNode>Hello!</childNode>
# 	</complexNode>
# </root>
# """
#
# is converted into JSON like this:
#
# """
# {
# 	"root": {
# 		"#comment": " This is a comment ",
# 		"emptyNode1": {
#
# 		},
# 		"nodeWithSingleChild": "child",
# 		"repeatedNode": [
# 			"1",
# 			"3"
# 		],
# 		"nodeWithMultipleChild": {
# 			"childOne": "1",
# 			"childTwo": "\"2\""
# 		},
# 		"nodeWithData": {
# 			"#attributes": {
# 				"foo": "bar"
# 			}
# 		},
# 		"complexNode": {
# 			"childNode": "Hello!",
# 			"#attributes": {
# 				"data_str": "my_data",
# 				"data_int": "3"
# 			}
# 		}
# 	}
# }
# """
#
# This process is not perfect due to the way how XML is structured. One major drawback is that
# the XML node's order is lost when translated to JSON, which may be important in some
# scenarios:
#
# """
# <root>
# 	<a>1</a>
# 	<b>2</b>
# 	<a>3</a>
# </root>
# """
#
# and
#
# """
# <root>
# 	<a>1</a>
# 	<a>3</a>
# 	<b>2</b>
# </root>
# """
#
# will produce the same JSON:
#
# """
# {
# 	"root": {
# 		"a": [
# 			"1",
# 			"3"
# 		],
# 		"b": "2"
# 	}
# }
# """
#
# Also be aware that XMLParser might be unexposed to GDScript in 4.0 (https://github.com/godotengine/godot-proposals/issues/1234),
# and that there are security risks associated with it (https://github.com/godotengine/godot/issues/51622)

# Parse an XML file
static func parse(xml_file: String) -> Dictionary:
	var xml_raw := XMLParser.new()
	if xml_raw.open(xml_file):
		print("Error at opening file ", xml_file)
		return {}

	var dict = _parse_xml(xml_raw)
	return dict

# Internal, don't use
static func _parse_xml(xml_raw: XMLParser, skip: bool = false) -> Dictionary:
	var ret = {}
	var element_begin := false
	var element_name := ""
	var element_attr = {}
	while skip or xml_raw.read() == OK:
		skip = false
		match xml_raw.get_node_type():
			XMLParser.NODE_ELEMENT:
				if element_begin:
					element_begin = false
					_add_child_to_dict(ret, element_name, _parse_xml(xml_raw, true))
					if not element_attr.empty():
						_get_child_from_dict(ret, element_name)["#attributes"] = element_attr
				else:
					element_begin = true
					element_name = xml_raw.get_node_name()
					var attr_count = xml_raw.get_attribute_count()
					if attr_count > 0:
						#print("\tElement \"%s\" with %s attributes" % [element_name, attr_count])
						element_attr = {}
						for i in range(attr_count):
							var attr_name = xml_raw.get_attribute_name(i)
							var attr_val = xml_raw.get_attribute_value(i)
							#print("\t\t%s=%s" % [attr_name, attr_val])
							element_attr[attr_name] = attr_val

					if xml_raw.is_empty():
						element_begin = false
						_add_child_to_dict(ret, element_name, {})
						if attr_count > 0:
							_get_child_from_dict(ret, element_name)["#attributes"] = element_attr
			XMLParser.NODE_ELEMENT_END:
				#print("\tElement end of \"%s\"" % xml_raw.get_node_name())
				if element_begin:
					element_begin = false
				else:
					return ret
			XMLParser.NODE_TEXT:
				if _is_text_empty(xml_raw.get_node_data()):
					continue
				else:
					#print("\tText: " + xml_raw.get_node_data())
					_add_child_to_dict(ret, element_name, xml_raw.get_node_data())
			XMLParser.NODE_COMMENT:
				if element_begin:
					element_begin = false
					_add_child_to_dict(ret, element_name, _parse_xml(xml_raw, true))
				else:
					_add_child_to_dict(ret, "#comment", xml_raw.get_node_name())
					#print("\tComment: " + xml_raw.get_node_name())
	return ret

# Internal, don't use
static func _add_child_to_dict(dict: Dictionary, key: String, child):
	if dict.has(key):
		if dict[key] is Array:
			dict[key].push_back(child)
		else:
			dict[key] = [dict[key], child]
	else:
		dict[key] = child

# Internal, don't use
static func _get_child_from_dict(dict: Dictionary, key: String):
	if dict[key] is Array:
		return dict[key][dict[key].size()-1]
	else:
		return dict[key]

# Internal, don't use
static func _is_text_empty(s: String):
	return s.strip_edges().strip_escapes().empty()
