extends Node

class_name RetroHubIntegration

# Returns whether the integration is enabled. The theme can only safely use it if it is, otherwise it can cause issues.
static func is_available() -> bool:
	return false


