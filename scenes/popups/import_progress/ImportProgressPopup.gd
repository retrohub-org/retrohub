extends PopupDialog

signal import_finished

onready var n_import := $"%Import"
onready var n_major := $"%Major"
onready var n_major_progress := $"%MajorProgress"
onready var n_minor := $"%Minor"
onready var n_minor_progress := $"%MinorProgress"

onready var base_text : String = n_import.text

var importer : RetroHubImporter

var thread := Thread.new()

func _on_CopyMovePopup_import_begin(_importer: RetroHubImporter, copy_mode: bool):
	popup()
	importer = _importer
	n_import.text = base_text % importer.get_name()
	#warning-ignore:return_value_discarded
	importer.connect("import_major_step", self, "_on_import_major_step")
	#warning-ignore:return_value_discarded
	importer.connect("import_minor_step", self, "_on_import_minor_step")

	if thread.start(self, "t_import_begin", copy_mode):
		push_error("Thread start failed [t_import_begin]")

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
