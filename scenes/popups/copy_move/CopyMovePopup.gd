extends Window

signal import_begin(importer, copy_mode)

@onready var n_intro_lbl := $"%IntroLabel"
@onready var n_move_section := $"%MoveSection"
@onready var n_copy_section := $"%CopySection"
@onready var n_section_labels := [
	$"%MoveFiles",
	$"%CopyFiles",
	$"%MoveDisadvantage",
	$"%CopyAdvantage"
]
@onready var n_size := $"%Size"
@onready var n_space_left := $"%SpaceLeft"
@onready var n_move_copy_button := $"%MoveCopyButton"
@onready var n_cancel := $"%Cancel"
@onready var n_import := $"%Import"

var base_texts := []
var file_size : int
var space_left : int

var importer : RetroHubImporter
var thread := Thread.new()

func _ready():
	for label in n_section_labels:
		base_texts.push_back((label as Label).text)

func set_importer(_importer):
	importer = _importer
	for idx in range(n_section_labels.size()):
		n_section_labels[idx].text = base_texts[idx] % importer.get_importer_name()

	n_size.text = "Calculating..."
	n_space_left.text = "Calculating..."
	if thread.start(Callable(self, "t_get_size")):
		push_error("Thread start failed [t_get_size]")

func t_get_size():
	file_size = importer.get_estimated_size()
	space_left = FileUtils.get_space_left()
	call_deferred("thread_finished")

func thread_finished():
	thread.wait_to_finish()
	n_size.text = get_human_readable_size(file_size)
	n_space_left.text = get_human_readable_size(space_left) if space_left > 0 else "Could not measure"

func get_human_readable_size(size_raw: int):
	var value := float(size_raw)
	var multiplier := 0
	while value > 1024:
		value /= 1024
		multiplier += 1
	value = snapped(value, 0.01)
	match multiplier:
		0:
			return str(value) + " bytes"
		1:
			return str(value) + " KB"
		2:
			return str(value) + " MB"
		3:
			return str(value) + " GB"
		4:
			return str(value) + " TB"
		_:
			# Eventually we will have smartwaches with petabytes of storage,
			# but we're still not there yet
			return "too big"


func _on_Cancel_pressed():
	hide()


func _on_MoveCopyButton_toggled(button_pressed):
	n_move_section.modulate.a = 0.25 if button_pressed else 1.0
	n_copy_section.modulate.a = 1.0 if button_pressed else 0.25
	TTS.speak(tts_move_copy_button())


func _on_Import_pressed():
	emit_signal("import_begin", importer, n_move_copy_button.button_pressed)
	hide()

func tts_text(focused: Control) -> String:
	match focused:
		n_move_section:
			return tts_move_section()
		n_copy_section:
			return tts_copy_section()
		n_move_copy_button:
			return tts_move_copy_button()
		_:
			return ""

func tts_move_section() -> String:
	return $"%MoveFiles".text + ". Advantage: " + $VBoxContainer/HBoxContainer/MoveSection/HBoxContainer/Label.text \
		+ ". Disadvantage: " + $"%MoveDisadvantage".text

func tts_copy_section() -> String:
	return $"%CopyFiles".text + ". Advantage: " + $"%CopyAdvantage".text \
		+ ". Disadvantage: " + $VBoxContainer/HBoxContainer/CopySection/HBoxContainer2/Label.text \
		+ ". " + $VBoxContainer/HBoxContainer/CopySection/HBoxContainer3/Label.text \
		+ $"%Size".text + ". " + $VBoxContainer/HBoxContainer/CopySection/HBoxContainer4/Label.text \
		+ $"%SpaceLeft".text

func tts_move_copy_button() -> String:
	return "CheckButton. Currently selected mode: " + ("copy" if n_move_copy_button.button_pressed else "move") \
	+ ". Press to toggle mode."

func _on_CopyMovePopup_about_to_show():
	if RetroHubConfig.config.accessibility_screen_reader_enabled:
		n_intro_lbl.grab_focus()
	else:
		n_move_copy_button.grab_focus()
