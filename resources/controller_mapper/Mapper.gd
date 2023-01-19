extends ControllerMapper

func _convert_joypad_path(path: String, fallback: int) -> String:
	match RetroHubConfig.config.input_controller_icon_type:
		1: # Xbox 360
			return ._convert_joypad_to_xbox360(path)
		2: # Xbox One
			return ._convert_joypad_to_xboxone(path)
		3: # Xbox Series
			return ._convert_joypad_to_xboxseries(path)
		4: # PS3
			return ._convert_joypad_to_ps3(path)
		5: # PS4
			return ._convert_joypad_to_ps4(path)
		6: # PS5
			return ._convert_joypad_to_ps5(path)
		7: # Switch (Controller)
			return ._convert_joypad_to_switch(path)
		8: # Switch (Joy-Con)
			return ._convert_joypad_to_joycon(path)
		9: # Steam Controller
			return ._convert_joypad_to_steam(path)
		10: # Steam Deck
			return ._convert_joypad_to_steamdeck(path)
		11: # Amazon Luna
			return ._convert_joypad_to_luna(path)
		12: # Google Stadia
			return ._convert_joypad_to_stadia(path)
		_: # 0 or something new; Automatic
			return ._convert_joypad_path(path, fallback)
