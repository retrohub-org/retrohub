# GdUnit generated TestSuite
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://source/utils/JSONUtils.gd'

func test_empty() -> void:
	assert_dict(JSONUtils.load_json_file("")).is_equal({})

func test_invalid() -> void:
	assert_dict(JSONUtils.load_json_file("non_existing_file")).is_equal({})

func test_valid() -> void:
	var buffer = '{"test": 1}'
	var file := create_temp_file("load_json_file", "test.json", FileAccess.WRITE)
	assert_object(file).is_not_null()
	file.store_string(buffer)
	file.close()
	
	assert_dict(JSONUtils.load_json_file("user://tmp/load_json_file/test.json")) \
		.is_equal({
			"test": 1.0
		})
