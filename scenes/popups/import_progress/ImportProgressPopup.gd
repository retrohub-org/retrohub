extends Window

signal import_finished

@onready var n_import := %Import
@onready var n_major := %Major
@onready var n_major_progress := %MajorProgress
@onready var n_minor := %Minor
@onready var n_minor_progress := %MinorProgress

@onready var base_text : String = n_import.text

var importer : RetroHubImporter

var thread := Thread.new()

func _on_CopyMovePopup_import_begin(_importer: RetroHubImporter, copy_mode: bool):
	popup_centered()
	importer = _importer
	n_import.text = base_text % importer.get_name()
	#warning-ignore:return_value_discarded
	importer.import_major_step.connect(_on_import_major_step)
	#warning-ignore:return_value_discarded
	importer.import_minor_step.connect(_on_import_minor_step)
	TTS.speak(n_import.text + ". " + $Panel/VBoxContainer/Label2.text + ". Press the Control key to check the current progress.")

	if thread.start(Callable(self, "t_import_begin").bind(copy_mode)):
		push_error("Thread start failed [t_import_begin]")

func _input(event: InputEvent):
	if RetroHubConfig.config.accessibility_screen_reader_enabled and visible:
		if event is InputEventKey and event.keycode == KEY_CTRL:
			tts_progress()

func tts_progress():
	var text := "Progress: " + str((float(n_major_progress.value) / n_major_progress.max_value) * 100) + " percent."
	text += n_major.text
	text += "File: " + n_minor.text
	TTS.speak(text)

func t_import_begin(copy_mode: bool):
	importer.begin_import(copy_mode)
	call_deferred("thread_finished")

func thread_finished():
	thread.wait_to_finish()
	hide()
	emit_signal("import_finished")

func _on_import_major_step(curr: int, total: int, description: String):
	n_major.text = description
	n_major_progress.value = curr
	n_major_progress.max_value = total

func _on_import_minor_step(curr: int, total: int, description: String):
	n_minor.text = description
	n_minor_progress.value = curr
	n_minor_progress.max_value = total
