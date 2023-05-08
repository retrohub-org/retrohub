extends ControllerMapper

func _convert_joypad_path(path: String, fallback: int) -> String:
	if Engine.is_editor_hint():
		return super._convert_joypad_path(path, fallback)

	match RetroHubConfig.config.input_controller_icon_type:
		"xbox360":
			return super._convert_joypad_to_xbox360(path)
		"xboxone":
			return super._convert_joypad_to_xboxone(path)
		"xboxseries":
			return super._convert_joypad_to_xboxseries(path)
		"ps3":
			return super._convert_joypad_to_ps3(path)
		"ps4":
			return super._convert_joypad_to_ps4(path)
		"ps5":
			return super._convert_joypad_to_ps5(path)
		"switch":
			return super._convert_joypad_to_switch(path)
		"joycon":
			return super._convert_joypad_to_joycon(path)
		"steam":
			return super._convert_joypad_to_steam(path)
		"steamdeck":
			return super._convert_joypad_to_steamdeck(path)
		"luna":
			return super._convert_joypad_to_luna(path)
		"stadia":
			return super._convert_joypad_to_stadia(path)
		"auto", _:
			return super._convert_joypad_path(path, fallback)
