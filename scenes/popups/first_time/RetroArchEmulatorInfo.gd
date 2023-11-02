extends HBoxContainer

@onready var n_logo := %Logo
@onready var n_name := %Name
@onready var n_path_section := %PathSection
@onready var n_core_section := %CoreSection
@onready var n_accessibility_focus := %AccessibilityFocus

var found := false

func _ready():
	n_accessibility_focus._on_config_ready(RetroHubConfig.config)

func set_path_found(_found: bool, details: String):
	found = _found
	n_path_section.set_found(found, details)
	modulate.a = 1.0 if found else 0.5
	n_core_section.visible = found

func set_core_found(_found: bool, details: String):
	found = _found
	n_core_section.set_found(found, details)
	modulate.a = 1.0 if found else 0.5

func tts_text(_focused: Control):
	return n_name.text + ": " + ("supported" if found else "not supported") + ". " \
		+ n_path_section.tts_prompt() + ". " + n_core_section.tts_prompt()
