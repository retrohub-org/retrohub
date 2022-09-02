tool
extends Control

onready var gen_rnd_titles_container := $VBoxContainer/GenRndTitlesContainer
onready var gen_rnd_titles_check_btn := $VBoxContainer/GenRndTitlesCheckBtn
onready var gen_rnd_titles_spin_box := $VBoxContainer/GenRndTitlesContainer/GenRndTitlesSpinBox
onready var fetch_path_container := $VBoxContainer/FetchPathContainer
onready var fetch_path_check_btn := $VBoxContainer/FetchPathCheckBtn
onready var fetch_path_path_btn := $VBoxContainer/FetchPathContainer/FetchPathBtn

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Dock called")
	_on_GenRndTitlesCheckButton_toggled(gen_rnd_titles_check_btn.pressed)
	_on_FetchPathCheckBtn_toggled(fetch_path_check_btn.pressed)
	update_values()

func update_values():
	RetroHub._num_games_to_generate = int(gen_rnd_titles_spin_box.value)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_GenRndTitlesCheckButton_toggled(button_pressed):
	gen_rnd_titles_container.visible = button_pressed


func _on_FetchPathCheckBtn_toggled(button_pressed):
	fetch_path_container.visible = button_pressed
