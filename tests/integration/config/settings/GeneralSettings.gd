extends UI_GdUnitTestSuite

func setup():
	root_path = "res://scenes/config/settings/GeneralSettings.tscn"

func test_unique_name_children():
	assert_array(get_unique_named_nodes()).has_size(15)

func test_vertical_focus():
	await focus_vertical([
		"%SetGamePath",
		"%SetThemePath",
		"%Language",
		"%SetupWizardButton",
		"%UIVolume",
		"%GraphicsMode",
		"%VSync",
		"%RenderRes",
		"%ScreenReader"
	])

func test_horizontal_focus():
	var groups := [
		["%SetGamePath"],
		["%Themes", "%SetThemePath"],
		["%Language"],
		["%SetupWizardButton"],
		["%UIVolume"],
		["%GraphicsMode"],
		["%VSync"],
		["%RenderRes"],
		["%ScreenReader"]
	]

	for group in groups:
		await focus_horizontal(group)
