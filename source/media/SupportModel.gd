extends Node3D
class_name RetroHubSupportModel

@export var texture: Texture2D : Texture2D: set = set_texture

var mesh_path : MeshInstance3D
var surface_idx : int
var material : StandardMaterial3D

func extract_material():
	var mesh : Mesh = mesh_path.mesh
	material = mesh.surface_get_material(surface_idx).duplicate()
	mesh.surface_set_material(surface_idx, material)
	set_texture(texture)

func set_texture(_texture: Texture2D):
	texture = _texture
	if material:
		material.albedo_texture = texture

func scale_to_wu():
	var aabb := mesh_path.mesh.get_aabb()
	print("Short axis:", aabb.get_longest_axis_size())
	var scalar := 1.0 / aabb.get_longest_axis_size()
	print("Scaling by a factor of x", scalar)
	scale *= scalar
