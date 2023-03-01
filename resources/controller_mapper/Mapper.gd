extends ControllerMapper

func _convert_joypad_path(path: String, fallback: int) -> String:
	if Engine.editor_hint:
		return ._convert_joypad_path(path, fallback)

	match RetroHubConfig.config.input_controller_icon_type:
		"xbox360":
			return ._convert_joypad_to_xbox360(path)
		"xboxone":
			return ._convert_joypad_to_xboxone(path)
		"xboxseries":
			return ._convert_joypad_to_xboxseries(path)
		"ps3":
			return ._convert_joypad_to_ps3(path)
		"ps4":
			return ._convert_joypad_to_ps4(path)
		"ps5":
			return ._convert_joypad_to_ps5(path)
		"switch":
			return ._convert_joypad_to_switch(path)
		"joycon":
			return ._convert_joypad_to_joycon(path)
		"steam":
			return ._convert_joypad_to_steam(path)
		"steamdeck":
			return ._convert_joypad_to_steamdeck(path)
		"luna":
			return ._convert_joypad_to_luna(path)
		"stadia":
			return ._convert_joypad_to_stadia(path)
		"auto", _:
			return ._convert_joypad_path(path, fallback)
