extends HBoxContainer

export(Array) var mapping : Array
var raw_age : int setget set_raw_age
export(Color) var disabled_modulate : Color

onready var n_age := $"%Age"

onready var n_unknown := $"%Unknown"

onready var n_images := [
	$"%1", $"%2", $"%3", $"%4", $"%5"
]

func _gui_input(event):
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		get_tree().set_input_as_handled()
		var age := get_actual_age()
		if raw_age == age:
			var age_idx := mapping.find(age)
			if event.is_action_pressed("ui_left") and age_idx > 0:
				set_raw_age(mapping[age_idx-1])
			elif event.is_action_pressed("ui_right") and age_idx < mapping.size() - 1:
				set_raw_age(mapping[age_idx+1])
		else:
			set_raw_age(age)

func _ready():
	set_raw_age(raw_age)
	_on_AgeRatingPicker_focus_exited()

func set_idx(idx: int):
	set_raw_age(mapping[idx])

func set_raw_age(_raw_age: int):
	if _raw_age == 0:
		raw_age = 0
		n_unknown.modulate = Color(1, 1, 1, 1)
		for image in n_images:
			image.modulate = disabled_modulate
		n_age.text = "unknown"
	else:
		n_unknown.modulate = disabled_modulate

		raw_age = int(clamp(_raw_age, 3, 18))
		if not n_images or not n_age:
			return

		var age := get_actual_age()
		for i in range(n_images.size()):
			if age > mapping[i+1]:
				n_images[i].modulate = disabled_modulate
			else:
				n_images[i].modulate = Color(1, 1, 1, 1)
		n_age.text = str(age) + ("+" if age >= 18 else "") + " years"

func get_age_index():
	return mapping.find(get_actual_age())

func get_actual_age() -> int:
	var last_age := -1
	for val in mapping:
		if val > raw_age:
			return last_age
		else:
			last_age = val
	return last_age

func _on_AgeRatingPicker_focus_entered():
	for image in n_images:
		image.self_modulate.a = 1

func _on_AgeRatingPicker_focus_exited():
	for image in n_images:
		image.self_modulate.a = 0.6


func _on_1_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		set_raw_age(mapping[1])


func _on_2_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		set_raw_age(mapping[2])


func _on_3_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		set_raw_age(mapping[3])


func _on_4_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		set_raw_age(mapping[4])


func _on_5_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		set_raw_age(mapping[5])


func _on_Unknown_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		set_raw_age(mapping[0])
