# GdUnit generated TestSuite
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://source/utils/JSONUtils.gd'

var test_buffer := {
	"path": [
		{"windows": ["a.exe", "b.exe"]},
		{"macos": ["A.app", "B.app"]},
		{"linux": ["a", "b"]}
	]
}

func test_empty() -> void:
	var buffer := {}
	JSONUtils.make_system_specific(buffer, "")
	assert_dict(buffer).is_empty()

func test_invalid() -> void:
	var buffer = test_buffer.duplicate(true)
	JSONUtils.make_system_specific(buffer, "null")
	assert_dict(buffer).is_equal({
		"path": []
	})

func test_valid() -> void:
	var mock_FileUtils = mock("res://source/utils/FileUtils.gd")
	do_return("windows").on(mock_FileUtils).get_os_string()
	
	var system = mock_FileUtils.get_os_string()
	assert_str(system).is_equal("windows")
	var buffer = test_buffer.duplicate(true)
	JSONUtils.make_system_specific(buffer, system)
	assert_dict(buffer).is_equal({
		"path": ["a.exe", "b.exe"]
	})
